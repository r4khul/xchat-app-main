import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ox_common/log_util.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/login/account_models.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_common/purchase/purchase_idempotency_manager.dart';

/// Purchase processing result
enum PurchaseProcessResult {
  success,
  alreadyProcessed,
  serverVerificationFailed,
  deliveryFailed,
  error,
}

/// Purchase processing callback
typedef PurchaseProcessCallback = void Function(
  PurchaseProcessResult result,
  String? message,
  PaymentVerificationResult? verificationResult,
);

/// Service for processing purchases (server verification and delivery)
/// 
/// This service handles the business logic of purchase processing:
/// - Server-side verification
/// - Subscription status checking
/// - Delivery (joinCircle)
/// 
/// This is separated from UI to ensure purchases can be processed even
/// if the purchase page is closed or the app is restarted.
class PurchaseService {
  static final PurchaseService instance = PurchaseService._();
  
  PurchaseService._();

  /// Process a purchased transaction
  /// 
  /// [purchaseDetails] The purchase details from purchaseStream
  /// [onResult] Optional callback for processing result
  /// 
  /// Returns true if processing was successful or already processed, false on error
  Future<bool> processPurchase(
    PurchaseDetails purchaseDetails, {
    PurchaseProcessCallback? onResult,
  }) async {
    // Get transaction ID
    final transactionId = PurchaseIdempotencyManager.getTransactionId(
      purchaseDetails,
    );

    // Check idempotency
    if (await PurchaseIdempotencyManager.isProcessed(transactionId)) {
      LogUtil.d(() => 'Purchase already processed, skipping: $transactionId');
      
      // Still need to complete the purchase to free up the queue
      if (purchaseDetails.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchaseDetails);
      }
      
      onResult?.call(PurchaseProcessResult.alreadyProcessed, null, null);
      return true;
    }

    try {
      LogUtil.d(() => '''
        [PurchaseService] Processing purchase:
        - productID: ${purchaseDetails.productID}
        - purchaseID: ${purchaseDetails.purchaseID}
        - transactionId: $transactionId
        - transactionDate: ${purchaseDetails.transactionDate}
      ''');

      // Get receipt/purchase token
      String receipt = purchaseDetails.verificationData.serverVerificationData;
      if (receipt.isEmpty) {
        receipt = purchaseDetails.verificationData.source;
      }

      // Step 1: Server-side verification
      LogUtil.d(() => '''
        [PurchaseService] Starting server verification:
        - platform: ${Platform.isIOS ? 'iOS' : 'Android'}
        - productId: ${purchaseDetails.productID}
        - receipt length: ${receipt.length}
      ''');
      
      // Get account credentials for API call
      final account = LoginManager.instance.currentState.account;
      if (account == null) {
        throw Exception('User not logged in');
      }
      
      final pubkey = account.pubkey;
      final privkey = AccountHelperEx.getPrivateKey(
        account.encryptedPrivKey,
        account.defaultPassword,
      );
      
      if (privkey.isEmpty) {
        throw Exception('Private key not available');
      }
      
      final PaymentVerificationResult verificationResult;
      try {
        if (Platform.isIOS) {
          verificationResult = await CircleApi.verifyApplePayment(
            pubkey: pubkey,
            privkey: privkey,
            productId: purchaseDetails.productID,
            receiptData: receipt,
          );
        } else {
          verificationResult = await CircleApi.verifyGooglePayment(
            pubkey: pubkey,
            privkey: privkey,
            productId: purchaseDetails.productID,
            purchaseToken: receipt,
          );
        }
        
        LogUtil.d(() => '''
          [PurchaseService] Server verification successful:
          - tenantId: ${verificationResult.tenantId}
          - relayUrl: ${verificationResult.relayUrl}
          - subscriptionStatus: ${verificationResult.subscriptionStatus}
        ''');
      } catch (e, stack) {
        LogUtil.e(() => '''
          [PurchaseService] Server verification failed:
          - productId: ${purchaseDetails.productID}
          - error: $e
          - stack: $stack
        ''');
        onResult?.call(
          PurchaseProcessResult.serverVerificationFailed,
          'Server verification failed: $e',
          null,
        );
        return false;
      }

      // Check subscription status
      if (verificationResult.subscriptionStatus != 'active') {
        LogUtil.w(() => 'Subscription status: ${verificationResult.subscriptionStatus}');
        if (verificationResult.subscriptionStatus == 'expired') {
          final error = 'Subscription has expired. Please renew your subscription.';
          onResult?.call(
            PurchaseProcessResult.serverVerificationFailed,
            error,
            verificationResult,
          );
          return false;
        }
      }

      if (verificationResult.relayUrl.isEmpty) {
        final error = 'Failed to get relay URL from server';
        LogUtil.e(() => '[PurchaseService] $error');
        onResult?.call(
          PurchaseProcessResult.serverVerificationFailed,
          error,
          verificationResult,
        );
        return false;
      }

      // Step 2: Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        LogUtil.d(() => '[PurchaseService] Completing purchase...');
        await InAppPurchase.instance.completePurchase(purchaseDetails);
        LogUtil.d(() => '[PurchaseService] Purchase completed');
      } else {
        LogUtil.d(() => '[PurchaseService] No pending complete purchase');
      }

      // Step 3: Mark as processed before delivery (prevents duplicate if delivery fails)
      LogUtil.d(() => '[PurchaseService] Marking purchase as processed: $transactionId');
      await PurchaseIdempotencyManager.markAsProcessed(transactionId);

      // Step 4: Delivery - join Circle with the relay URL
      LogUtil.d(() => '''
        [PurchaseService] Starting delivery (joinCircle):
        - relayUrl: ${verificationResult.relayUrl}
        - tenantId: ${verificationResult.tenantId}
      ''');
      
      final failure = await LoginManager.instance.joinCircle(
        verificationResult.relayUrl,
        type: CircleType.relay,
      );

      if (failure != null) {
        LogUtil.e(() => '''
          [PurchaseService] Delivery failed:
          - relayUrl: ${verificationResult.relayUrl}
          - failure type: ${failure.type}
          - failure message: ${failure.message}
          - circleId: ${failure.circleId}
        ''');
        onResult?.call(
          PurchaseProcessResult.deliveryFailed,
          failure.message,
          verificationResult,
        );
        return false;
      }
      
      LogUtil.d(() => '[PurchaseService] Delivery successful - circle joined');

      LogUtil.d(() => '[PurchaseService] Purchase processed successfully');
      onResult?.call(
        PurchaseProcessResult.success,
        null,
        verificationResult,
      );
      return true;

    } catch (e, stack) {
      LogUtil.e(() => '[PurchaseService] Error processing purchase: $e\n$stack');
      
      // On error, still complete purchase to free up the queue
      if (purchaseDetails.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchaseDetails);
      }
      
      onResult?.call(
        PurchaseProcessResult.error,
        'Failed to process purchase: $e',
        null,
      );
      return false;
    }
  }

  /// Process a restored purchase
  /// 
  /// Restored purchases should sync entitlements, not create new purchases
  Future<bool> processRestoredPurchase(
    PurchaseDetails purchaseDetails, {
    PurchaseProcessCallback? onResult,
  }) async {
    // Get transaction ID
    final transactionId = PurchaseIdempotencyManager.getTransactionId(
      purchaseDetails,
    );

    // Check idempotency
    if (await PurchaseIdempotencyManager.isProcessed(transactionId)) {
      LogUtil.d(() => 'Restored purchase already processed: $transactionId');
      if (purchaseDetails.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchaseDetails);
      }
      onResult?.call(PurchaseProcessResult.alreadyProcessed, null, null);
      return true;
    }

    try {
      LogUtil.d(() => '''
        [PurchaseService] Processing restored purchase:
        - productID: ${purchaseDetails.productID}
        - purchaseID: ${purchaseDetails.purchaseID}
        - transactionId: $transactionId
      ''');

      // Get receipt/purchase token
      String receipt = purchaseDetails.verificationData.serverVerificationData;
      if (receipt.isEmpty) {
        receipt = purchaseDetails.verificationData.source;
      }

      // Server-side verification
      LogUtil.d(() => '''
        [PurchaseService] Starting server verification for restored purchase:
        - platform: ${Platform.isIOS ? 'iOS' : 'Android'}
        - productId: ${purchaseDetails.productID}
        - receipt length: ${receipt.length}
      ''');
      
      // Get account credentials for API call
      final account = LoginManager.instance.currentState.account;
      if (account == null) {
        throw Exception('User not logged in');
      }
      
      final pubkey = account.pubkey;
      final privkey = AccountHelperEx.getPrivateKey(
        account.encryptedPrivKey,
        account.defaultPassword,
      );
      
      if (privkey.isEmpty) {
        throw Exception('Private key not available');
      }
      
      final PaymentVerificationResult verificationResult;
      try {
        if (Platform.isIOS) {
          verificationResult = await CircleApi.verifyApplePayment(
            pubkey: pubkey,
            privkey: privkey,
            productId: purchaseDetails.productID,
            receiptData: receipt,
          );
        } else {
          verificationResult = await CircleApi.verifyGooglePayment(
            pubkey: pubkey,
            privkey: privkey,
            productId: purchaseDetails.productID,
            purchaseToken: receipt,
          );
        }
        
        LogUtil.d(() => '''
          [PurchaseService] Server verification successful for restored:
          - tenantId: ${verificationResult.tenantId}
          - relayUrl: ${verificationResult.relayUrl}
          - subscriptionStatus: ${verificationResult.subscriptionStatus}
        ''');
      } catch (e, s) {
        LogUtil.e(() => '''
          [PurchaseService] Server verification failed for restored:
          - productId: ${purchaseDetails.productID}
          - error: $e
          - stack: $s
        ''');
        onResult?.call(
          PurchaseProcessResult.serverVerificationFailed,
          'Server verification failed: $e',
          null,
        );
        return false;
      }

      // Check subscription status
      if (verificationResult.subscriptionStatus != 'active') {
        LogUtil.w(() => 'Restored subscription status: ${verificationResult.subscriptionStatus}');
        if (verificationResult.subscriptionStatus == 'expired') {
          final error = 'Subscription has expired. Please renew your subscription.';
          onResult?.call(
            PurchaseProcessResult.serverVerificationFailed,
            error,
            verificationResult,
          );
          return false;
        }
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchaseDetails);
      }

      // Mark as processed
      await PurchaseIdempotencyManager.markAsProcessed(transactionId);

      // For restored purchases, sync entitlements (user may already have a circle)
      LogUtil.d(() => '''
        [PurchaseService] Starting delivery for restored purchase (joinCircle):
        - relayUrl: ${verificationResult.relayUrl}
        - tenantId: ${verificationResult.tenantId}
      ''');
      
      final failure = await LoginManager.instance.joinCircle(
        verificationResult.relayUrl,
        type: CircleType.relay,
      );

      // For restored purchases, it's OK if circle already exists
      if (failure != null) {
        LogUtil.w(() => '''
          [PurchaseService] Restored purchase - circle may already exist:
          - relayUrl: ${verificationResult.relayUrl}
          - failure type: ${failure.type}
          - failure message: ${failure.message}
          - circleId: ${failure.circleId}
        ''');
        // Still consider it successful for restored purchases
      } else {
        LogUtil.d(() => '[PurchaseService] Restored purchase - circle joined successfully');
      }

      LogUtil.d(() => '[PurchaseService] Restored purchase processed');
      onResult?.call(
        PurchaseProcessResult.success,
        failure?.message,
        verificationResult,
      );
      return true;

    } catch (e, stack) {
      LogUtil.e(() => '[PurchaseService] Error processing restored purchase: $e\n$stack');
      
      if (purchaseDetails.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchaseDetails);
      }
      
      onResult?.call(
        PurchaseProcessResult.error,
        'Failed to restore purchase: $e',
        null,
      );
      return false;
    }
  }
}
