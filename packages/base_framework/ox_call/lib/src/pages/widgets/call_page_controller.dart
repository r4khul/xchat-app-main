import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_call/src/call_manager.dart';
import 'package:ox_call/src/models/call_state.dart';
import 'package:ox_call/src/models/call_session.dart';

/// Controller for managing call page state and business logic.
///
/// Encapsulates all interactions with CallManager,
/// exposing state via ValueNotifiers for UI consumption.
///
/// Directly listens to CallManager (not through CallService).
class CallPageController {
  CallPageController(CallSession initialSession) : _session = initialSession {
    callState$.value = _session.state;
    isConnected$.value = _session.state == CallState.connected;
    _initialize();
  }

  // Private state
  CallSession _session;
  Stopwatch? _stopwatch;
  Timer? _durationTimer;
  Timer? _autoHideTimer;
  void Function()? _removeStateListener;
  void Function()? _removeStreamListener;

  // Video renderers
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // Observable state
  final ValueNotifier<CallState> callState$ = ValueNotifier<CallState>(CallState.initiating);
  final ValueNotifier<bool> isConnected$ = ValueNotifier<bool>(false);
  final ValueNotifier<Duration> duration$ = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<bool> isMuted$ = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isCameraOn$ = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isSpeakerOn$ = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isControlsVisible$ = ValueNotifier<bool>(true);
  final ValueNotifier<bool> hasPopped$ = ValueNotifier<bool>(false);
  final ValueNotifier<bool> actionInProgress$ = ValueNotifier<bool>(false);

  // Derived state getters
  bool get isVideoCall => _session.callType == CallType.video;
  bool get isIncoming => _session.direction == CallDirection.incoming;
  bool get isActionInProgress => actionInProgress$.value;
  String get sessionId => _session.sessionId;

  ValueNotifier<UserDBISAR?> get remoteUser$ => _session.remoteUser$;
  ValueNotifier<UserDBISAR?> get localUser$ => _session.localUser$;

  // Initialization
  Future<void> _initialize() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    _setupListeners();
    _updateStreams();

    // Start auto-hide timer for video calls
    if (isVideoCall) {
      _startAutoHideTimer();
    }
  }

  void _setupListeners() {
    // Directly listen to CallManager
    _removeStateListener = CallManager().addStateListener(_onCallStateChanged);
    _removeStreamListener = CallManager().addStreamListener(_onRemoteStreamReady);
  }

  void _onCallStateChanged(CallSession session) {
    // Only handle events for this session
    if (session.sessionId != _session.sessionId) return;

    _session = session;
    callState$.value = session.state;
    
    if (session.state == CallState.connected && !isConnected$.value) {
      isConnected$.value = true;
    }

    if (session.state == CallState.connected) {
      _startDurationTimer();
      _updateStreams();
    }

    if (session.state == CallState.ended && !hasPopped$.value) {
      _stopDurationTimer();
      hasPopped$.value = true;
    }
  }

  void _onRemoteStreamReady(String sessionId, MediaStream stream) {
    if (sessionId != _session.sessionId) return;
    remoteRenderer.srcObject = stream;
  }

  void _updateStreams() {
    final localStream = CallManager().getLocalStream(_session.sessionId);
    final remoteStream = CallManager().getRemoteStream(_session.sessionId);

    if (localStream != null) {
      localRenderer.srcObject = localStream;
    }
    if (remoteStream != null) {
      remoteRenderer.srcObject = remoteStream;
    }
  }

  void _startDurationTimer() {
    final stopwatch = Stopwatch()..start();
    _stopwatch = stopwatch;
    duration$.value = stopwatch.elapsed;

    _durationTimer?.cancel();
    // Update ValueNotifier every second for UI refresh
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_stopwatch != null) {
        duration$.value = _stopwatch!.elapsed;
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
    // Update final duration
    if (_stopwatch != null) {
      _stopwatch!.stop();
      duration$.value = _stopwatch!.elapsed;
      _stopwatch = null;
    }
  }

  /// Formats duration as MM:SS.
  String formatDuration(Duration duration) {
    // Round to nearest second to handle timer jitter
    // This prevents "jumping" seconds when timer delays occur
    final totalSeconds = (duration.inMilliseconds / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Auto-hide controls timer (for video calls)
  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 5), () {
      if (isVideoCall && isConnected$.value) {
        isControlsVisible$.value = false;
      }
    });
  }

  void _resetAutoHideTimer() {
    if (isVideoCall && isConnected$.value) {
      _startAutoHideTimer();
    }
  }

  /// Toggle controls visibility (for video calls)
  void toggleControlsVisibility() {
    isControlsVisible$.value = !isControlsVisible$.value;
    if (isControlsVisible$.value) {
      _resetAutoHideTimer();
    }
  }

  /// Show controls and reset auto-hide timer
  void showControls() {
    isControlsVisible$.value = true;
    _resetAutoHideTimer();
  }

  // Call actions
  Future<void> accept() async {
    if (actionInProgress$.value) return;
    actionInProgress$.value = true;
    try {
      await CallManager().acceptCall(_session.sessionId);
    } finally {
      actionInProgress$.value = false;
    }
  }

  Future<void> reject() async {
    if (actionInProgress$.value) return;
    actionInProgress$.value = true;
    try {
      await CallManager().rejectCall(_session.sessionId);
    } finally {
      actionInProgress$.value = false;
    }
  }

  Future<void> hangUp() async {
    if (actionInProgress$.value) return;
    actionInProgress$.value = true;
    try {
      await CallManager().endCall(_session.sessionId);
    } finally {
      actionInProgress$.value = false;
    }
  }

  Future<void> toggleMute() async {
    final newValue = !isMuted$.value;
    await CallManager().setMuted(_session.sessionId, newValue);
    isMuted$.value = newValue;
  }

  Future<void> toggleCamera() async {
    final newValue = !isCameraOn$.value;
    await CallManager().setVideoEnabled(_session.sessionId, newValue);
    isCameraOn$.value = newValue;
  }

  Future<void> toggleSpeaker() async {
    // TODO: Implement speaker toggle / device selection
    isSpeakerOn$.value = !isSpeakerOn$.value;
  }

  Future<void> switchCamera() async {
    await CallManager().switchCamera(_session.sessionId);
  }

  // Cleanup
  void dispose() {
    _stopDurationTimer();
    _autoHideTimer?.cancel();

    _removeStateListener?.call();
    _removeStreamListener?.call();

    localRenderer.dispose();
    remoteRenderer.dispose();

    callState$.dispose();
    isConnected$.dispose();
    duration$.dispose();
    isMuted$.dispose();
    isCameraOn$.dispose();
    isSpeakerOn$.dispose();
    isControlsVisible$.dispose();
    hasPopped$.dispose();
    actionInProgress$.dispose();
  }
}