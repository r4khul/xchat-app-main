import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ox_common/purchase/purchase_idempotency_manager.dart';

/// Fake verification data for testing getTransactionId (Android path).
class FakeVerificationData {
  FakeVerificationData({this.serverVerificationData, this.source});

  final String? serverVerificationData;
  final String? source;
}

/// Fake purchase details for testing getTransactionId without in_app_purchase.
class FakePurchaseDetails {
  FakePurchaseDetails({
    this.purchaseID,
    this.verificationData,
    this.productID,
    this.transactionDate,
  });

  final String? purchaseID;
  final FakeVerificationData? verificationData;
  final String? productID;
  final String? transactionDate;
}

void main() {
  group('PurchaseIdempotencyManager', () {
    group('getTransactionId', () {
      test('iOS: uses purchaseID when non-empty', () {
        final details = FakePurchaseDetails(
          purchaseID: 'tx_ios_123',
          productID: 'loc1.level2.monthly',
          transactionDate: '2025-01-01',
        );
        expect(
          PurchaseIdempotencyManager.getTransactionId(details),
          'tx_ios_123',
        );
      });

      test('iOS: ignores purchaseID when empty string', () {
        final details = FakePurchaseDetails(
          purchaseID: '',
          verificationData: FakeVerificationData(serverVerificationData: 'android_token'),
          productID: 'loc1.level2.monthly',
          transactionDate: '2025-01-01',
        );
        expect(
          PurchaseIdempotencyManager.getTransactionId(details),
          'android_token',
        );
      });

      test('Android: uses serverVerificationData when non-empty', () {
        final details = FakePurchaseDetails(
          purchaseID: null,
          verificationData: FakeVerificationData(serverVerificationData: 'android_purchase_token_456'),
          productID: 'loc1.level2.monthly',
          transactionDate: '2025-01-01',
        );
        expect(
          PurchaseIdempotencyManager.getTransactionId(details),
          'android_purchase_token_456',
        );
      });

      test('Android: uses source when serverVerificationData is empty', () {
        final details = FakePurchaseDetails(
          purchaseID: null,
          verificationData: FakeVerificationData(
            serverVerificationData: '',
            source: 'google_play_source',
          ),
          productID: 'loc1.level2.monthly',
          transactionDate: '2025-01-01',
        );
        expect(
          PurchaseIdempotencyManager.getTransactionId(details),
          'google_play_source',
        );
      });

      test('fallback: uses productID_transactionDate when no purchaseID or verificationData', () {
        final details = FakePurchaseDetails(
          purchaseID: null,
          verificationData: null,
          productID: 'loc1.level2.monthly',
          transactionDate: '2025-01-01T12:00:00Z',
        );
        expect(
          PurchaseIdempotencyManager.getTransactionId(details),
          'loc1.level2.monthly_2025-01-01T12:00:00Z',
        );
      });

      test('fallback: empty productID and transactionDate', () {
        final details = FakePurchaseDetails(
          purchaseID: null,
          verificationData: null,
          productID: null,
          transactionDate: null,
        );
        expect(
          PurchaseIdempotencyManager.getTransactionId(details),
          '_',
        );
      });
    });

    group('isProcessed / markAsProcessed / clearProcessed', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
      });

      test('isProcessed returns false for new transactionId', () async {
        final result = await PurchaseIdempotencyManager.isProcessed('tx_new_123');
        expect(result, false);
      });

      test('markAsProcessed then isProcessed returns true', () async {
        await PurchaseIdempotencyManager.markAsProcessed('tx_123');
        final result = await PurchaseIdempotencyManager.isProcessed('tx_123');
        expect(result, true);
      });

      test('clearProcessed then isProcessed returns false', () async {
        await PurchaseIdempotencyManager.markAsProcessed('tx_123');
        await PurchaseIdempotencyManager.clearProcessed('tx_123');
        final result = await PurchaseIdempotencyManager.isProcessed('tx_123');
        expect(result, false);
      });

      test('empty transactionId: isProcessed returns false', () async {
        final result = await PurchaseIdempotencyManager.isProcessed('');
        expect(result, false);
      });

      test('empty transactionId: markAsProcessed does not throw', () async {
        await PurchaseIdempotencyManager.markAsProcessed('');
      });

      test('empty transactionId: clearProcessed does not throw', () async {
        await PurchaseIdempotencyManager.clearProcessed('');
      });
    });
  });
}
