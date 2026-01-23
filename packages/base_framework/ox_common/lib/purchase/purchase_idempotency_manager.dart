import 'package:shared_preferences/shared_preferences.dart';
import 'package:ox_common/log_util.dart';

/// Manages purchase idempotency to prevent duplicate delivery
/// 
/// This class ensures that the same purchase transaction is only processed once,
/// even if it's received multiple times due to network retries, app restarts, or restore purchases.
class PurchaseIdempotencyManager {
  static const String _keyPrefix = 'purchase_processed_';
  static final Set<String> _inMemoryCache = {};

  /// Check if a purchase has already been processed
  /// 
  /// [transactionId] The unique transaction ID (purchaseID for iOS, purchaseToken for Android)
  /// Returns true if the purchase has been processed, false otherwise
  static Future<bool> isProcessed(String transactionId) async {
    if (transactionId.isEmpty) {
      LogUtil.w(() => '[PurchaseIdempotencyManager] Empty transactionId, returning false');
      return false;
    }

    // Check in-memory cache first
    if (_inMemoryCache.contains(transactionId)) {
      LogUtil.d(() => '''
        [PurchaseIdempotencyManager] Purchase already processed (in-memory):
        - transactionId: $transactionId
      ''');
      return true;
    }

    // Check persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$transactionId';
      final isProcessed = prefs.getBool(key) ?? false;
      
      if (isProcessed) {
        _inMemoryCache.add(transactionId);
        LogUtil.d(() => '''
          [PurchaseIdempotencyManager] Purchase already processed (persistent):
          - transactionId: $transactionId
          - key: $key
        ''');
      } else {
        LogUtil.d(() => '''
          [PurchaseIdempotencyManager] Purchase not processed yet:
          - transactionId: $transactionId
          - key: $key
        ''');
      }
      
      return isProcessed;
    } catch (e, stack) {
      LogUtil.e(() => '''
        [PurchaseIdempotencyManager] Error checking purchase idempotency:
        - transactionId: $transactionId
        - error: $e
        - stack: $stack
      ''');
      return false;
    }
  }

  /// Mark a purchase as processed
  /// 
  /// [transactionId] The unique transaction ID
  static Future<void> markAsProcessed(String transactionId) async {
    if (transactionId.isEmpty) {
      LogUtil.w(() => '[PurchaseIdempotencyManager] Empty transactionId, skipping markAsProcessed');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$transactionId';
      await prefs.setBool(key, true);
      _inMemoryCache.add(transactionId);
      
      LogUtil.d(() => '''
        [PurchaseIdempotencyManager] Purchase marked as processed:
        - transactionId: $transactionId
        - key: $key
      ''');
    } catch (e, stack) {
      LogUtil.e(() => '''
        [PurchaseIdempotencyManager] Error marking purchase as processed:
        - transactionId: $transactionId
        - error: $e
        - stack: $stack
      ''');
    }
  }

  /// Clear processed purchase record (for testing or manual cleanup)
  /// 
  /// [transactionId] The unique transaction ID
  static Future<void> clearProcessed(String transactionId) async {
    if (transactionId.isEmpty) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$transactionId';
      await prefs.remove(key);
      _inMemoryCache.remove(transactionId);
      
      LogUtil.d(() => 'Purchase record cleared: $transactionId');
    } catch (e) {
      LogUtil.e(() => 'Error clearing purchase record: $e');
    }
  }

  /// Get the transaction ID from PurchaseDetails
  /// 
  /// For iOS: returns purchaseID
  /// For Android: returns purchaseToken (from serverVerificationData or source)
  static String getTransactionId(dynamic purchaseDetails) {
    try {
      // iOS: use purchaseID
      if (purchaseDetails.purchaseID != null && 
          purchaseDetails.purchaseID.toString().isNotEmpty) {
        final transactionId = purchaseDetails.purchaseID.toString();
        LogUtil.d(() => '''
          [PurchaseIdempotencyManager] Got transaction ID (iOS purchaseID):
          - transactionId: $transactionId
          - productID: ${purchaseDetails.productID}
        ''');
        return transactionId;
      }
      
      // Android: use purchaseToken from verification data
      if (purchaseDetails.verificationData != null) {
        final serverData = purchaseDetails.verificationData.serverVerificationData;
        if (serverData != null && serverData.toString().isNotEmpty) {
          final transactionId = serverData.toString();
          LogUtil.d(() => '''
            [PurchaseIdempotencyManager] Got transaction ID (Android serverVerificationData):
            - transactionId: $transactionId
            - productID: ${purchaseDetails.productID}
          ''');
          return transactionId;
        }
        
        final source = purchaseDetails.verificationData.source;
        if (source != null && source.toString().isNotEmpty) {
          final transactionId = source.toString();
          LogUtil.d(() => '''
            [PurchaseIdempotencyManager] Got transaction ID (Android source):
            - transactionId: $transactionId
            - productID: ${purchaseDetails.productID}
          ''');
          return transactionId;
        }
      }
      
      // Fallback: use productID + transactionDate
      final productId = purchaseDetails.productID ?? '';
      final transactionDate = purchaseDetails.transactionDate ?? '';
      final transactionId = '${productId}_$transactionDate';
      LogUtil.w(() => '''
        [PurchaseIdempotencyManager] Using fallback transaction ID:
        - transactionId: $transactionId
        - productID: $productId
        - transactionDate: $transactionDate
      ''');
      return transactionId;
    } catch (e, stack) {
      LogUtil.e(() => '''
        [PurchaseIdempotencyManager] Error getting transaction ID:
        - productID: ${purchaseDetails?.productID ?? 'N/A'}
        - error: $e
        - stack: $stack
      ''');
      return '';
    }
  }
}
