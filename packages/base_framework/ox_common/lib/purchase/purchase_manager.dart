import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/log_util.dart';
import 'package:ox_common/purchase/purchase_idempotency_manager.dart';
import 'package:ox_common/purchase/purchase_service.dart';

/// Purchase event with processing result
class PurchaseEvent {
  final PurchaseDetails purchaseDetails;
  final PurchaseProcessResult? processResult;
  final String? resultMessage;
  final PaymentVerificationResult? verificationResult;

  PurchaseEvent({
    required this.purchaseDetails,
    this.processResult,
    this.resultMessage,
    this.verificationResult,
  });
}

/// Purchase state for UI updates
enum PurchaseState {
  idle,
  pending,
  processing,
  success,
  error,
  canceled,
}

/// Purchase state change event
class PurchaseStateEvent {
  final String productId;
  final PurchaseState state;
  final String? errorMessage;
  final PaymentVerificationResult? verificationResult;

  PurchaseStateEvent({
    required this.productId,
    required this.state,
    this.errorMessage,
    this.verificationResult,
  });
}

/// Global purchase manager that handles purchase stream subscription at app startup
/// 
/// This ensures that purchase events are not missed even if the user closes
/// the purchase page or the app restarts during a purchase flow.
class PurchaseManager {
  static final PurchaseManager instance = PurchaseManager._();
  
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isInitialized = false;
  
  // Callbacks for handling purchases
  // Handler receives PurchaseEvent which includes both purchase details and processing result
  final List<Function(PurchaseEvent)> _purchaseHandlers = [];
  
  // Purchase state stream for UI updates
  final _purchaseStateController = StreamController<PurchaseStateEvent>.broadcast();
  
  // Debouncing map to prevent duplicate purchases
  final Map<String, bool> _pendingPurchases = {};
  
  PurchaseManager._();

  /// Initialize the purchase manager and subscribe to purchase stream
  /// 
  /// This should be called early in app initialization (e.g., in app_initializer.dart)
  Future<void> initialize() async {
    if (_isInitialized) {
      LogUtil.d(() => 'PurchaseManager already initialized');
      return;
    }

    try {
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (error) {
          LogUtil.e(() => 'Purchase stream error: $error');
        },
        cancelOnError: false,
      );
      
      _isInitialized = true;
      LogUtil.d(() => 'PurchaseManager initialized successfully');
    } catch (e) {
      LogUtil.e(() => 'Error initializing PurchaseManager: $e');
      rethrow;
    }
  }

  /// Handle purchase updates from the stream
  /// 
  /// This method processes all purchase updates and ensures idempotency
  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      try {
        // Log purchase details
        LogUtil.d(() => '''
          [PurchaseManager] Purchase update:
          - productID: ${purchaseDetails.productID}
          - purchaseID: ${purchaseDetails.purchaseID}
          - status: ${purchaseDetails.status}
          - transactionDate: ${purchaseDetails.transactionDate}
          - pendingCompletePurchase: ${purchaseDetails.pendingCompletePurchase}
        ''');

        // Get transaction ID for idempotency check
        final transactionId = PurchaseIdempotencyManager.getTransactionId(
          purchaseDetails,
        );

        // Handle different purchase statuses
        switch (purchaseDetails.status) {
          case PurchaseStatus.pending:
            LogUtil.d(() => 'Purchase pending: ${purchaseDetails.productID}');
            // Notify handlers about pending purchase (no result yet)
            _notifyHandlers(PurchaseEvent(purchaseDetails: purchaseDetails));
            // Notify state change
            _purchaseStateController.add(PurchaseStateEvent(
              productId: purchaseDetails.productID,
              state: PurchaseState.pending,
            ));
            break;

          case PurchaseStatus.purchased:
            await _handlePurchased(purchaseDetails, transactionId);
            break;

          case PurchaseStatus.restored:
            await _handleRestored(purchaseDetails, transactionId);
            break;

          case PurchaseStatus.error:
            await _handleError(purchaseDetails);
            break;

          case PurchaseStatus.canceled:
            await _handleCanceled(purchaseDetails);
            break;
        }
      } catch (e, stack) {
        LogUtil.e(() => 'Error handling purchase update: $e\n$stack');
      }
    }
  }

  /// Handle purchased status
  Future<void> _handlePurchased(
    PurchaseDetails purchaseDetails,
    String transactionId,
  ) async {
    LogUtil.d(() => '''
      [PurchaseManager] Processing new purchase:
      - productID: ${purchaseDetails.productID}
      - purchaseID: ${purchaseDetails.purchaseID}
      - transactionId: $transactionId
      - transactionDate: ${purchaseDetails.transactionDate}
      - pendingCompletePurchase: ${purchaseDetails.pendingCompletePurchase}
    ''');
    
    // Send processing state to UI (in case purchaseProduct didn't send it)
    _purchaseStateController.add(PurchaseStateEvent(
      productId: purchaseDetails.productID,
      state: PurchaseState.processing,
    ));
    
    // Process purchase through PurchaseService (server verification + delivery)
    // This ensures purchases are processed even if the purchase page is closed
    // [DEBUG] Temporary logging for issue diagnosis
    LogUtil.d(() => '''
      [PurchaseManager] Calling PurchaseService.processPurchase:
      - productID: ${purchaseDetails.productID}
      - transactionId: $transactionId
    ''');
    
    await PurchaseService.instance.processPurchase(
      purchaseDetails,
      onResult: (result, message, verificationResult) {
        // [DEBUG] Temporary logging for issue diagnosis
        LogUtil.d(() => '''
          [PurchaseManager] onResult callback called:
          - productID: "${purchaseDetails.productID}"
          - result: $result
          - message: $message
          - hasVerificationResult: ${verificationResult != null}
          - relayUrl: ${verificationResult?.relayUrl ?? 'N/A'}
          - tenantId: ${verificationResult?.tenantId ?? 'N/A'}
        ''');
        
        // Notify handlers with processing result
        _notifyHandlers(PurchaseEvent(
          purchaseDetails: purchaseDetails,
          processResult: result,
          resultMessage: message,
          verificationResult: verificationResult,
        ));
        
        // Notify state change
        if (result == PurchaseProcessResult.success) {
          LogUtil.d(() => '''
            [PurchaseManager] Purchase processed successfully:
            - productID: "${purchaseDetails.productID}"
            - transactionId: $transactionId
            - relayUrl: ${verificationResult?.relayUrl ?? 'N/A'}
            - tenantId: ${verificationResult?.tenantId ?? 'N/A'}
          ''');
          
          // [DEBUG] Temporary logging for issue diagnosis
          LogUtil.d(() => '''
            [PurchaseManager] About to send PurchaseStateEvent.success:
            - productId: "${purchaseDetails.productID}"
            - state: PurchaseState.success
          ''');
          
          _purchaseStateController.add(PurchaseStateEvent(
            productId: purchaseDetails.productID,
            state: PurchaseState.success,
            verificationResult: verificationResult,
          ));
          
          // [DEBUG] Temporary logging for issue diagnosis
          LogUtil.d(() => '''
            [PurchaseManager] PurchaseStateEvent.success sent:
            - productId: "${purchaseDetails.productID}"
            - state: PurchaseState.success
          ''');
        } else if (result == PurchaseProcessResult.alreadyProcessed) {
          LogUtil.d(() => '''
            [PurchaseManager] Purchase already processed:
            - productID: "${purchaseDetails.productID}"
            - transactionId: $transactionId
          ''');
          
          // [DEBUG] Temporary logging for issue diagnosis
          LogUtil.d(() => '''
            [PurchaseManager] About to send PurchaseStateEvent.success (alreadyProcessed):
            - productId: "${purchaseDetails.productID}"
            - state: PurchaseState.success
          ''');
          
          _purchaseStateController.add(PurchaseStateEvent(
            productId: purchaseDetails.productID,
            state: PurchaseState.success,
            verificationResult: verificationResult,
          ));
          
          LogUtil.d(() => '''
            [PurchaseManager] PurchaseStateEvent.success (alreadyProcessed) sent:
            - productId: "${purchaseDetails.productID}"
          ''');
        } else {
          LogUtil.e(() => '''
            [PurchaseManager] Purchase processing failed:
            - productID: "${purchaseDetails.productID}"
            - transactionId: $transactionId
            - result: $result
            - message: $message
          ''');
          
          // [DEBUG] Temporary logging for issue diagnosis
          LogUtil.e(() => '''
            [PurchaseManager] About to send PurchaseStateEvent.error:
            - productId: "${purchaseDetails.productID}"
            - state: PurchaseState.error
          ''');
          
          _purchaseStateController.add(PurchaseStateEvent(
            productId: purchaseDetails.productID,
            state: PurchaseState.error,
            errorMessage: message,
          ));
          
          LogUtil.e(() => '''
            [PurchaseManager] PurchaseStateEvent.error sent:
            - productId: "${purchaseDetails.productID}"
          ''');
        }
      },
    );
    
    // [DEBUG] Temporary logging for issue diagnosis
    LogUtil.d(() => '[PurchaseManager] PurchaseService.processPurchase await completed');
  }

  /// Handle restored status
  Future<void> _handleRestored(
    PurchaseDetails purchaseDetails,
    String transactionId,
  ) async {
    LogUtil.d(() => 'Purchase restored: ${purchaseDetails.productID}');
    
    // Process restored purchase through PurchaseService
    // Restored purchases should sync entitlements, not create new purchases
    await PurchaseService.instance.processRestoredPurchase(
      purchaseDetails,
      onResult: (result, message, verificationResult) {
        // [DEBUG] Temporary logging for issue diagnosis
        LogUtil.d(() => '''
          [PurchaseManager] _handleRestored onResult callback called:
          - productID: "${purchaseDetails.productID}"
          - result: $result
          - message: $message
          - hasVerificationResult: ${verificationResult != null}
        ''');
        
        // Notify handlers with processing result
        _notifyHandlers(PurchaseEvent(
          purchaseDetails: purchaseDetails,
          processResult: result,
          resultMessage: message,
          verificationResult: verificationResult,
        ));
        
        // Notify state change - same logic as _handlePurchased
        if (result == PurchaseProcessResult.success) {
          LogUtil.d(() => '''
            [PurchaseManager] Restored purchase processed successfully:
            - productID: ${purchaseDetails.productID}
            - transactionId: $transactionId
            - relayUrl: ${verificationResult?.relayUrl ?? 'N/A'}
          ''');
          
          // [DEBUG] Temporary logging for issue diagnosis
          LogUtil.d(() => '''
            [PurchaseManager] About to send PurchaseStateEvent.success (restored):
            - productId: "${purchaseDetails.productID}"
            - state: PurchaseState.success
          ''');
          
          _purchaseStateController.add(PurchaseStateEvent(
            productId: purchaseDetails.productID,
            state: PurchaseState.success,
            verificationResult: verificationResult,
          ));
          
          LogUtil.d(() => '''
            [PurchaseManager] PurchaseStateEvent.success (restored) sent:
            - productId: "${purchaseDetails.productID}"
          ''');
        } else if (result == PurchaseProcessResult.alreadyProcessed) {
          LogUtil.d(() => '''
            [PurchaseManager] Restored purchase already processed:
            - productID: ${purchaseDetails.productID}
            - transactionId: $transactionId
          ''');
          
          // [DEBUG] Temporary logging for issue diagnosis
          LogUtil.d(() => '''
            [PurchaseManager] About to send PurchaseStateEvent.success (restored, alreadyProcessed):
            - productId: "${purchaseDetails.productID}"
            - state: PurchaseState.success
          ''');
          
          // Send success state even if already processed, so UI can update
          _purchaseStateController.add(PurchaseStateEvent(
            productId: purchaseDetails.productID,
            state: PurchaseState.success,
            verificationResult: verificationResult,
          ));
          
          LogUtil.d(() => '''
            [PurchaseManager] PurchaseStateEvent.success (restored, alreadyProcessed) sent:
            - productId: "${purchaseDetails.productID}"
          ''');
        } else {
          LogUtil.w(() => '''
            [PurchaseManager] Restored purchase processing result:
            - productID: ${purchaseDetails.productID}
            - transactionId: $transactionId
            - result: $result
            - message: $message
          ''');
          
          // Send error state for other failure cases
          _purchaseStateController.add(PurchaseStateEvent(
            productId: purchaseDetails.productID,
            state: PurchaseState.error,
            errorMessage: message,
          ));
        }
      },
    );
  }

  /// Handle error status
  Future<void> _handleError(PurchaseDetails purchaseDetails) async {
    LogUtil.e(() => '''
      [PurchaseManager] Purchase error:
      - productID: ${purchaseDetails.productID}
      - purchaseID: ${purchaseDetails.purchaseID}
      - error code: ${purchaseDetails.error?.code}
      - error message: ${purchaseDetails.error?.message}
      - error details: ${purchaseDetails.error?.details}
      - pendingCompletePurchase: ${purchaseDetails.pendingCompletePurchase}
    ''');

    // Notify state change: error
    _purchaseStateController.add(PurchaseStateEvent(
      productId: purchaseDetails.productID,
      state: PurchaseState.error,
      errorMessage: purchaseDetails.error?.message ?? 'Purchase error',
    ));

    // Complete purchase even on error to free up the queue
    if (purchaseDetails.pendingCompletePurchase) {
      LogUtil.d(() => '[PurchaseManager] Completing purchase on error to free up queue');
      await _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  /// Handle canceled status
  /// 
  /// This status indicates that the user canceled the purchase.
  /// Unlike error, this is a user-initiated action and should be handled gracefully.
  Future<void> _handleCanceled(PurchaseDetails purchaseDetails) async {
    LogUtil.d(() => '''
      Purchase canceled by user:
      - productID: ${purchaseDetails.productID}
      - purchaseID: ${purchaseDetails.purchaseID}
    ''');

    // Notify handlers about canceled purchase (no processing result)
    _notifyHandlers(PurchaseEvent(purchaseDetails: purchaseDetails));

    // Notify state change: canceled
    _purchaseStateController.add(PurchaseStateEvent(
      productId: purchaseDetails.productID,
      state: PurchaseState.canceled,
    ));

    // Complete purchase to free up the queue
    // Note: canceled purchases may or may not have pendingCompletePurchase
    // depending on when the user canceled (before or after payment)
    if (purchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  /// Notify all registered handlers about a purchase update
  void _notifyHandlers(PurchaseEvent event) {
    LogUtil.d(() => '''
      [PurchaseManager] Notifying ${_purchaseHandlers.length} handler(s):
      - productID: ${event.purchaseDetails.productID}
      - status: ${event.purchaseDetails.status}
      - processResult: ${event.processResult}
    ''');
    
    for (final handler in _purchaseHandlers) {
      try {
        handler(event);
      } catch (e, stack) {
        LogUtil.e(() => '''
          [PurchaseManager] Error in purchase handler:
          - error: $e
          - stack: $stack
        ''');
      }
    }
  }

  /// Register a handler for purchase updates
  /// 
  /// [handler] Function that will be called when purchase updates are received.
  /// The handler receives a PurchaseEvent which includes both purchase details
  /// and processing result (if processing has completed).
  /// Returns a function to unregister the handler
  Function() registerHandler(Function(PurchaseEvent) handler) {
    _purchaseHandlers.add(handler);
    return () => _purchaseHandlers.remove(handler);
  }

  /// Dispose the purchase manager
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _purchaseHandlers.clear();
    _pendingPurchases.clear();
    _purchaseStateController.close();
    _isInitialized = false;
    LogUtil.d(() => 'PurchaseManager disposed');
  }

  /// Check if the manager is initialized
  bool get isInitialized => _isInitialized;

  /// Stream of purchase state changes for UI updates
  Stream<PurchaseStateEvent> get purchaseStateStream => _purchaseStateController.stream;

  /// Purchase a product by product ID
  /// 
  /// This method handles:
  /// - Store availability check
  /// - Product query
  /// - Purchase initiation
  /// - Debouncing to prevent duplicate purchases
  /// 
  /// [productId] The product ID to purchase
  /// 
  /// Returns true if purchase was initiated successfully, false otherwise
  /// Throws an exception if there's an error
  Future<bool> purchaseProduct(String productId) async {
    LogUtil.d(() => '[PurchaseManager] Starting purchase for product: $productId');
    
    // Debounce: prevent duplicate purchases
    if (_pendingPurchases[productId] == true) {
      LogUtil.w(() => '[PurchaseManager] Purchase already in progress for product: $productId');
      throw Exception('Purchase already in progress. Please wait...');
    }

    _pendingPurchases[productId] = true;
    try {
      // Notify state change: pending
      _purchaseStateController.add(PurchaseStateEvent(
        productId: productId,
        state: PurchaseState.pending,
      ));
      LogUtil.d(() => '[PurchaseManager] Purchase state: pending for $productId');

      // Check store availability
      LogUtil.d(() => '[PurchaseManager] Checking store availability...');
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        LogUtil.e(() => '[PurchaseManager] Store not available');
        throw Exception('Store not available');
      }
      LogUtil.d(() => '[PurchaseManager] Store is available');

      // Query product details
      LogUtil.d(() => '[PurchaseManager] Querying product details for: $productId');
      final ProductDetailsResponse productDetailResponse =
          await _inAppPurchase.queryProductDetails({productId});

      if (productDetailResponse.error != null) {
        LogUtil.e(() => '''
          [PurchaseManager] Product query error:
          - code: ${productDetailResponse.error!.code}
          - message: ${productDetailResponse.error!.message}
          - details: ${productDetailResponse.error!.details}
        ''');
        throw Exception(productDetailResponse.error!.message);
      }

      if (productDetailResponse.productDetails.isEmpty) {
        LogUtil.e(() => '''
          [PurchaseManager] Product not found:
          - productId: $productId
          - notFoundIDs: ${productDetailResponse.notFoundIDs}
        ''');
        throw Exception(
          'Product not found: $productId\n'
          'Please check if the product is configured in '
          '${Platform.isIOS ? "App Store Connect" : "Google Play Console"}',
        );
      }

      final ProductDetails productDetails =
          productDetailResponse.productDetails.first;
      LogUtil.d(() => '''
        [PurchaseManager] Product details retrieved:
        - productID: ${productDetails.id}
        - title: ${productDetails.title}
        - price: ${productDetails.price}
        - currencyCode: ${productDetails.currencyCode}
      ''');

      // Notify state change: processing (purchase is being initiated)
      _purchaseStateController.add(PurchaseStateEvent(
        productId: productId,
        state: PurchaseState.processing,
      ));
      LogUtil.d(() => '[PurchaseManager] Purchase state: processing for $productId');

      // Initiate purchase
      LogUtil.d(() => '[PurchaseManager] Initiating purchase...');
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      // Use buyNonConsumable for subscriptions
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        LogUtil.e(() => '[PurchaseManager] buyNonConsumable returned false');
        throw Exception('Failed to initiate purchase. Please try again.');
      }

      LogUtil.d(() => '[PurchaseManager] Purchase initiated successfully. Waiting for purchaseStream event...');
      // Purchase status will be handled by purchaseStream
      // The state will be updated when we receive the purchase event
      return true;
    } catch (e, stack) {
      LogUtil.e(() => '''
        [PurchaseManager] Error in purchaseProduct:
        - productId: $productId
        - error: $e
        - stack: $stack
      ''');
      // Notify state change: error
      _purchaseStateController.add(PurchaseStateEvent(
        productId: productId,
        state: PurchaseState.error,
        errorMessage: e.toString(),
      ));
      rethrow;
    } finally {
      // Clear debounce flag after a delay
      Future.delayed(const Duration(seconds: 5), () {
        _pendingPurchases[productId] = false;
        LogUtil.d(() => '[PurchaseManager] Debounce flag cleared for: $productId');
      });
    }
  }

  /// Restore purchases
  /// 
  /// This will trigger the restore flow, and restored purchases will be
  /// processed through the purchase stream.
  Future<void> restorePurchases() async {
    LogUtil.d(() => '[PurchaseManager] Starting restore purchases...');
    try {
      await _inAppPurchase.restorePurchases();
      LogUtil.d(() => '[PurchaseManager] restorePurchases() called successfully. Waiting for purchaseStream events...');
    } catch (e, stack) {
      LogUtil.e(() => '''
        [PurchaseManager] Error restoring purchases:
        - error: $e
        - stack: $stack
      ''');
      rethrow;
    }
  }
}
