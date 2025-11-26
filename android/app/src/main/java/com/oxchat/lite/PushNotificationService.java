package com.oxchat.lite;

import android.app.ActivityManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;

import java.util.List;

import androidx.core.app.NotificationCompat;

import com.oxchat.lite.R;
import com.oxchat.nostr.MainActivity;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Random;
import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.WebSocket;
import okhttp3.WebSocketListener;

/**
 * Foreground service for push notification monitoring
 * Connects to push serverRelay via WebSocket and listens for events
 */
public class PushNotificationService extends Service {
    private static final String TAG = "PushNotificationService";
    private static final String CHANNEL_ID = "PushNotificationServiceChannel";
    private static final String PUSH_NOTIFICATION_CHANNEL_ID = "PushNotificationChannel";
    private static final int NOTIFICATION_ID = 1001;
    private static final int PUSH_NOTIFICATION_ID = 1002;
    
    public static final String EXTRA_SERVER_RELAY = "server_relay";
    public static final String EXTRA_DEVICE_ID = "device_id";
    public static final String EXTRA_PUBKEY = "pubkey";
    
    private WebSocket webSocket;
    private OkHttpClient httpClient;
    private String serverRelay;
    private String deviceId;
    private String pubkey;
    private String subscriptionId;
    private Handler reconnectHandler;
    private Runnable reconnectRunnable;
    private static final long RECONNECT_DELAY_MS = 5000; // 5 seconds
    private String pendingAuthChallenge;
    private String authEventId; // Track AUTH event ID to match OK response
    private boolean regenerateSubscriptionId; // Flag to regenerate subscription ID after AUTH
    private boolean isConnecting = false; // Track if we're currently connecting
    private boolean isReconnecting = false; // Track if we're reconnecting (to avoid duplicate reconnects)

    private static final String PREFS_NAME = "push_service";
    private static final String KEY_SERVER_RELAY = "server_relay";
    private static final String KEY_DEVICE_ID = "device_id";
    private static final String KEY_PUBKEY = "pubkey";
    
    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "PushNotificationService created");
        createNotificationChannel();
        
        httpClient = new OkHttpClient.Builder()
                .connectTimeout(10, TimeUnit.SECONDS)
                .readTimeout(30, TimeUnit.SECONDS)
                .writeTimeout(30, TimeUnit.SECONDS)
                .build();
        
        reconnectHandler = new Handler(Looper.getMainLooper());
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "PushNotificationService started");
        
        if (intent != null) {
            String action = intent.getAction();
            if ("com.oxchat.nostr.SEND_AUTH".equals(action)) {
                // Handle AUTH response from Flutter
                String authJson = intent.getStringExtra("authJson");
                sendAuthResponse(authJson);
                return START_STICKY;
            }
            
            serverRelay = intent.getStringExtra(EXTRA_SERVER_RELAY);
            deviceId = intent.getStringExtra(EXTRA_DEVICE_ID);
            pubkey = intent.getStringExtra(EXTRA_PUBKEY);
            persistConfig();
        } else {
            // Service restarted by system, load config from prefs
            loadConfigFromPrefs();
        }
        
        if (serverRelay == null || serverRelay.isEmpty() || pubkey == null || pubkey.isEmpty()) {
            Log.e(TAG, "Missing required config, cannot start service");
            stopSelf();
            return START_STICKY;
        }
            
        // For Android, if deviceId is not provided, use pubkey as deviceId
        if (deviceId == null || deviceId.isEmpty()) {
            deviceId = pubkey;
        }
        
        // Only connect if not already connecting
        if (!isConnecting && webSocket == null) {
            Log.d(TAG, "Connecting to relay: " + serverRelay + ", deviceId: " + deviceId);
            connectToRelay();
        } else {
            Log.d(TAG, "WebSocket already connected or connecting, skipping connection");
        }
        
        // Start foreground service
        startForeground(NOTIFICATION_ID, createNotification());
        
        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "PushNotificationService destroyed");
        disconnectFromRelay();
        if (reconnectRunnable != null) {
            reconnectHandler.removeCallbacks(reconnectRunnable);
        }
        isConnecting = false;
        isReconnecting = false;
        stopForeground(true);
    }

    /**
     * Create notification channel for Android O and above
     */
    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager == null) return;
            
            // Channel for foreground service
            NotificationChannel serviceChannel = new NotificationChannel(
                    CHANNEL_ID,
                    "Push Notification Service",
                    NotificationManager.IMPORTANCE_LOW
            );
            serviceChannel.setDescription("Service for monitoring push notifications");
            serviceChannel.setShowBadge(false);
            manager.createNotificationChannel(serviceChannel);
            
            // Channel for push notifications (higher priority)
            NotificationChannel pushChannel = new NotificationChannel(
                    PUSH_NOTIFICATION_CHANNEL_ID,
                    "Push Notifications",
                    NotificationManager.IMPORTANCE_HIGH
            );
            pushChannel.setDescription("Notifications for new messages");
            pushChannel.setShowBadge(true);
            pushChannel.enableLights(true);
            pushChannel.enableVibration(true);
            manager.createNotificationChannel(pushChannel);
        }
    }

    /**
     * Create foreground notification
     */
    private Notification createNotification() {
        Intent notificationIntent = new Intent(this, MainActivity.class);
        notificationIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        PendingIntent pendingIntent = PendingIntent.getActivity(
                this,
                0,
                notificationIntent,
                flags
        );

        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle(getString(R.string.push_service_title))
                .setContentText(getString(R.string.push_service_text))
                .setSmallIcon(R.drawable.ic_notification)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(NotificationCompat.CATEGORY_SERVICE);

        return builder.build();
    }

    /**
     * Connect to WebSocket relay
     */
    private void connectToRelay() {
        // Avoid duplicate connections
        if (isConnecting) {
            Log.d(TAG, "Already connecting, skipping duplicate connection attempt");
            return;
        }
        
        // If WebSocket is already connected and healthy, don't reconnect
        if (webSocket != null) {
            Log.d(TAG, "WebSocket already exists, closing existing connection first");
            isReconnecting = true; // Mark as reconnecting to avoid duplicate reconnect calls
            webSocket.close(1000, "Reconnecting");
            webSocket = null;
        }
        
        isConnecting = true;
        
        try {
            Request request = new Request.Builder()
                    .url(serverRelay)
                    .build();
            
            webSocket = httpClient.newWebSocket(request, new WebSocketListener() {
                @Override
                public void onOpen(WebSocket webSocket, Response response) {
                    Log.d(TAG, "WebSocket connected to: " + serverRelay);
                    isConnecting = false;
                    isReconnecting = false;
                    sendSubscriptionRequest();
                }

                @Override
                public void onMessage(WebSocket webSocket, String text) {
                    Log.d(TAG, "Received message: " + text);
                    handleMessage(text);
                }

                @Override
                public void onMessage(WebSocket webSocket, okio.ByteString bytes) {
                    Log.d(TAG, "Received bytes message");
                    handleMessage(bytes.utf8());
                }

                @Override
                public void onClosing(WebSocket webSocket, int code, String reason) {
                    Log.d(TAG, "WebSocket closing: " + code + " " + reason);
                    webSocket.close(1000, null);
                }

                @Override
                public void onClosed(WebSocket webSocket, int code, String reason) {
                    Log.d(TAG, "WebSocket closed: " + code + " " + reason);
                    isConnecting = false;
                    // Only schedule reconnect if we're not already reconnecting (to avoid duplicate reconnects)
                    if (!isReconnecting) {
                        scheduleReconnect();
                    } else {
                        isReconnecting = false;
                    }
                }

                @Override
                public void onFailure(WebSocket webSocket, Throwable t, Response response) {
                    Log.e(TAG, "WebSocket failure", t);
                    isConnecting = false;
                    isReconnecting = false;
                    scheduleReconnect();
                }
            });
        } catch (Exception e) {
            Log.e(TAG, "Failed to connect to WebSocket", e);
            isConnecting = false;
            isReconnecting = false;
            scheduleReconnect();
        }
    }

    /**
     * Send subscription request to relay
     * Format: ["REQ", subscriptionId, {"kinds": [20284], "#h": [pubkey], "since": now}]
     * subscriptionId is a random number
     */
    private void sendSubscriptionRequest() {
        if (pubkey == null) {
            Log.e(TAG, "Cannot send subscription: missing pubkey");
            return;
        }
        
        try {
            // Generate random subscription ID
            if (subscriptionId == null || regenerateSubscriptionId) {
                subscriptionId = generateRandomHex(16);
                regenerateSubscriptionId = false;
            }
            
            // Get current timestamp in seconds
            // long now = System.currentTimeMillis() / 1000;
            
            // Build Request: ["REQ", subscriptionId, {"kinds": [20284], "#h": [pubkey], "since": now}]
            JSONArray requestArray = new JSONArray();
            requestArray.put("REQ");
            requestArray.put(subscriptionId);
            
            JSONObject filter = new JSONObject();
            // NIP-29 group events
            JSONArray kindsArray = new JSONArray();
            kindsArray.put(20285);
            kindsArray.put(20284);
            filter.put("kinds", kindsArray);
            
            // h tag contains any of the groupIds (pubkey)
            JSONArray hArray = new JSONArray();
            hArray.put(pubkey);
            filter.put("#h", hArray);
            
            // since: current timestamp
            // filter.put("since", now);
            
            requestArray.put(filter);
            
            String requestMessage = requestArray.toString();
            Log.d(TAG, "Sending subscription request: " + requestMessage);
            
            if (webSocket != null) {
                webSocket.send(requestMessage);
            }
        } catch (JSONException e) {
            Log.e(TAG, "Failed to create subscription request", e);
        }
    }

    /**
     * Handle incoming WebSocket messages
     */
    private void handleMessage(String message) {
        try {
            JSONArray jsonArray = new JSONArray(message);
            String messageType = jsonArray.getString(0);
            
            if ("EVENT".equals(messageType)) {
                // Received an event, only wake app if process is not running
                Log.d(TAG, "Received EVENT");
                if (!isAppProcessRunning()) {
                    Log.d(TAG, "App process not running, activating");
                    activateApp();
                } else {
                    Log.d(TAG, "App process already running, skipping activation");
                }
            } else if ("EOSE".equals(messageType)) {
                // End of stored events
                Log.d(TAG, "End of stored events");
            } else if ("NOTICE".equals(messageType)) {
                String notice = jsonArray.getString(1);
                Log.d(TAG, "Relay notice: " + notice);
            } else if ("CLOSED".equals(messageType)) {
                Log.d(TAG, "Subscription closed");
                // scheduleReconnect();
            } else if ("AUTH".equals(messageType)) {
                // Handle AUTH challenge
                String challenge = jsonArray.getString(1);
                Log.d(TAG, "Received AUTH challenge: " + challenge);
                handleAuthChallenge(challenge);
            } else if ("OK".equals(messageType)) {
                // Handle OK response, check if it's AUTH response
                if (jsonArray.length() >= 3) {
                    String eventId = jsonArray.getString(1);
                    boolean status = jsonArray.getBoolean(2);
                    String okMessage = jsonArray.length() > 3 ? jsonArray.getString(3) : "";
                    Log.d(TAG, "Received OK: eventId=" + eventId + ", status=" + status + ", message=" + okMessage);
                    // If this is AUTH OK response and successful, resend subscription request
                    if (status && authEventId != null && authEventId.equals(eventId)) {
                        Log.d(TAG, "AUTH successful, resending subscription request");
                        authEventId = null;
                        pendingAuthChallenge = null;
                        regenerateSubscriptionId = true;
                        sendSubscriptionRequest();
                    }
                }
            }
        } catch (JSONException e) {
            Log.e(TAG, "Failed to parse message: " + message, e);
        }
    }

    /**
     * Handle AUTH challenge by requesting authJson from Flutter via MethodChannel
     */
    private void handleAuthChallenge(String challenge) {
        pendingAuthChallenge = challenge;
        // Request authJson from Flutter via MethodChannel
        // Note: This requires the app to be running. For background service,
        // we'll need to use a different approach or store the challenge for later
        Log.d(TAG, "AUTH challenge received: challenge=" + challenge + ", relay=" + serverRelay);
        // For now, we'll need Flutter to poll or use EventChannel
        // Store challenge for Flutter to retrieve
        android.content.SharedPreferences prefs = getSharedPreferences("push_service", MODE_PRIVATE);
        prefs.edit()
            .putString("auth_challenge", challenge)
            .putString("auth_relay", serverRelay)
            .apply();
        Log.d(TAG, "Stored AUTH challenge for Flutter to retrieve");
    }

    /**
     * Send AUTH response to relay
     * Called from Flutter via MethodChannel
     * After sending AUTH, wait for OK response before resending subscription
     */
    public void sendAuthResponse(String authJson) {
        if (webSocket != null && authJson != null && !authJson.isEmpty()) {
            try {
                // Extract event ID from authJson: ["AUTH", {"id": "...", ...}]
                JSONArray authArray = new JSONArray(authJson);
                if (authArray.length() >= 2) {
                    JSONObject eventObj = authArray.getJSONObject(1);
                    authEventId = eventObj.getString("id");
                    Log.d(TAG, "Extracted AUTH event ID: " + authEventId);
                }
            } catch (JSONException e) {
                Log.e(TAG, "Failed to extract event ID from authJson", e);
            }
            
            Log.d(TAG, "Sending AUTH response: " + authJson);
            webSocket.send(authJson);
            // Don't clear pendingAuthChallenge here, wait for OK response
            // The OK response handler will resend subscription request
        }
    }

    /**
     * Schedule reconnection
     */
    private void scheduleReconnect() {
        // Don't schedule reconnect if already connecting or reconnecting
        if (isConnecting || isReconnecting) {
            Log.d(TAG, "Already connecting/reconnecting, skipping schedule reconnect");
            return;
        }
        
        if (reconnectRunnable != null) {
            reconnectHandler.removeCallbacks(reconnectRunnable);
        }
        
        isReconnecting = true;
        reconnectRunnable = new Runnable() {
            @Override
            public void run() {
                Log.d(TAG, "Attempting to reconnect...");
                isReconnecting = false; // Reset flag before connecting
                connectToRelay();
            }
        };
        
        reconnectHandler.postDelayed(reconnectRunnable, RECONNECT_DELAY_MS);
    }

    /**
     * Disconnect from relay
     */
    private void disconnectFromRelay() {
        if (webSocket != null) {
            try {
                webSocket.close(1000, "Service stopping");
            } catch (Exception e) {
                Log.e(TAG, "Error closing WebSocket", e);
            }
            webSocket = null;
        }
    }

    /**
     * Generate random hex string
     */
    private String generateRandomHex(int length) {
        Random random = new Random();
        StringBuilder sb = new StringBuilder();
        String chars = "0123456789abcdef";
        for (int i = 0; i < length; i++) {
            sb.append(chars.charAt(random.nextInt(chars.length())));
        }
        return sb.toString();
    }

    /**
     * Show notification when push notification is received
     * User can click notification to open the app
     */
    private void activateApp() {
        try {
            // Create a fresh Intent for MainActivity
            // Use the same pattern as AndroidManifest launcher intent
            Intent intent = new Intent(this, MainActivity.class);
            intent.setAction(Intent.ACTION_MAIN);
            intent.addCategory(Intent.CATEGORY_LAUNCHER);
            // FLAG_ACTIVITY_NEW_TASK is required when starting from Service
            // FLAG_ACTIVITY_CLEAR_TOP with singleTop launchMode will reuse existing instance if on top
            // or bring it to front if it exists in the stack
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            
            // Create PendingIntent for notification
            int flags = PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_ONE_SHOT;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                flags |= PendingIntent.FLAG_IMMUTABLE;
            }
            PendingIntent pendingIntent = PendingIntent.getActivity(
                this,
                PUSH_NOTIFICATION_ID,
                intent,
                flags
            );
            
            // Show notification that will launch the app when clicked
            NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            if (notificationManager != null) {
                NotificationCompat.Builder builder = new NotificationCompat.Builder(this, PUSH_NOTIFICATION_CHANNEL_ID)
                    .setContentTitle(getString(R.string.push_notification_title))
                    .setContentText(getString(R.string.push_notification_text))
                    .setSmallIcon(R.mipmap.ic_launcher)
                    .setContentIntent(pendingIntent)
                    .setAutoCancel(true)
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setCategory(NotificationCompat.CATEGORY_MESSAGE)
                    .setDefaults(Notification.DEFAULT_SOUND | Notification.DEFAULT_VIBRATE)
                    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC);
                
                notificationManager.notify(PUSH_NOTIFICATION_ID, builder.build());
                Log.d(TAG, "Push notification shown");
            } else {
                Log.e(TAG, "NotificationManager is null");
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to show notification", e);
        }
    }

    /**
     * Check whether app has Activity in foreground
     * Returns true only if there's an Activity visible to the user
     * Returns false if only Service is running (app was killed)
     */
    private boolean isAppProcessRunning() {
        ActivityManager activityManager = (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
        if (activityManager == null) return false;
        List<ActivityManager.RunningAppProcessInfo> runningApps = activityManager.getRunningAppProcesses();
        if (runningApps == null) return false;
        String packageName = getPackageName();
        for (ActivityManager.RunningAppProcessInfo processInfo : runningApps) {
            if (processInfo.processName.equals(packageName)) {
                // Check if process has Activity in foreground
                // IMPORTANCE_FOREGROUND means there's an Activity visible to user
                // IMPORTANCE_SERVICE or other values mean only Service is running
                int importance = processInfo.importance;
                Log.d(TAG, "Process found, importance: " + importance + 
                    " (IMPORTANCE_FOREGROUND=" + ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND + ")");
                return importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND;
            }
        }
        Log.d(TAG, "Process not found in running apps");
        return false;
    }

    private void persistConfig() {
        if (serverRelay == null && deviceId == null && pubkey == null) return;
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        prefs.edit()
                .putString(KEY_SERVER_RELAY, serverRelay)
                .putString(KEY_DEVICE_ID, deviceId)
                .putString(KEY_PUBKEY, pubkey)
                .apply();
    }

    private void loadConfigFromPrefs() {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        if (serverRelay == null || serverRelay.isEmpty()) {
            serverRelay = prefs.getString(KEY_SERVER_RELAY, null);
        }
        if (deviceId == null || deviceId.isEmpty()) {
            deviceId = prefs.getString(KEY_DEVICE_ID, null);
        }
        if (pubkey == null || pubkey.isEmpty()) {
            pubkey = prefs.getString(KEY_PUBKEY, null);
        }
    }

}

