import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';

/// Payment page for private relay subscription using App Store / Google Play in-app purchases
class RelayPaymentPage extends StatefulWidget {
  const RelayPaymentPage({
    super.key,
    required this.groupId,
    required this.level,
    required this.levelPeriod,
    required this.amount,
    required this.productId, // Product ID from App Store Connect / Google Play Console
    this.previousPageTitle,
  });

  final String groupId;
  final int level;
  final String levelPeriod;
  final int amount; // Amount in cents (USD)
  final String productId; // Subscription product ID
  final String? previousPageTitle;

  @override
  State<RelayPaymentPage> createState() => _RelayPaymentPageState();
}

class _RelayPaymentPageState extends State<RelayPaymentPage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isProcessing = false;
  bool _purchasePending = false;
  String? _queryProductError;

  @override
  void initState() {
    super.initState();
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (Object error) {
      // Handle error here.
      _handleError(error);
    });
    initStoreInfo();
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
        _products = [];
        _queryProductError = 'Store not available';
      });
      return;
    }

    final ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails({widget.productId});
    if (productDetailResponse.error != null) {
      setState(() {
        _queryProductError = productDetailResponse.error!.message;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError = 'Product not found';
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
      });
      return;
    }

    setState(() {
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _queryProductError = null;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  String get _title => Localized.text('ox_usercenter.payment');

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        setState(() {
          _purchasePending = true;
        });
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _handlePurchaseSuccess(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        setState(() {
          _purchasePending = false;
        });
      }
    }
  }

  Future<void> _handlePurchaseSuccess(PurchaseDetails purchaseDetails) async {
    if (!mounted) return;

    try {
      setState(() => _isProcessing = true);

      // Get receipt/purchase token
      String receipt = '';
      if (Platform.isIOS) {
        // iOS: Get the base64 encoded receipt
        receipt = purchaseDetails.verificationData.source;
      } else if (Platform.isAndroid) {
        // Android: Get the purchase token
        receipt = purchaseDetails.verificationData.serverVerificationData;
      }

      // Create payment on server
      final paymentResponse = await RelayGroup.sharedInstance.createInAppPurchasePayment(
        widget.groupId,
        widget.level,
        widget.levelPeriod,
        widget.amount,
        receipt,
        Platform.isIOS ? 'ios' : 'android',
      );

      if (paymentResponse != null && mounted) {
        // Complete the purchase
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        // Check payment status
        await _checkPaymentStatus(paymentResponse.id);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to process payment: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleError(dynamic error) {
    if (mounted) {
      _showError('Purchase error: ${error.toString()}');
      setState(() {
        _isProcessing = false;
        _purchasePending = false;
      });
    }
  }

  Future<void> _buyProduct(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    if (productDetails.id == widget.productId) {
      setState(() => _isProcessing = true);
      // For subscriptions, use buyNonConsumable
      // The platform will handle subscription vs one-time purchase based on product type
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> _checkPaymentStatus(String paymentId) async {
    try {
      // Poll payment status
      PaymentResponse? paymentResponse;
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(seconds: 2));
        paymentResponse = await RelayGroup.sharedInstance.checkPaymentStatus(
          widget.groupId,
          paymentId,
        );

        if (paymentResponse?.status == 'settled') {
          if (mounted) {
            _showSuccess();
            Navigator.of(context).pop(true);
          }
          return;
        } else if (paymentResponse?.status == 'expired' ||
            paymentResponse?.status == 'canceled') {
          if (mounted) {
            _showError('Payment ${paymentResponse?.status}');
          }
          return;
        }
      }

      // Timeout
      if (mounted) {
        _showError(
            'Payment verification timeout. Please check your subscription status.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to verify payment: $e');
      }
    }
  }

  void _showSuccess() {
    CommonToast.instance.show(
        context, Localized.text('ox_usercenter.payment_success'));
  }

  void _showError(String message) {
    CommonToast.instance.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(
        title: _title,
        previousPageTitle: widget.previousPageTitle,
      ),
      body: _isProcessing || _purchasePending
          ? const Center(child: CircularProgressIndicator())
          : _buildPaymentContent(),
    );
  }

  Widget _buildPaymentContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.px),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPaymentSummary(),
          SizedBox(height: 24.px),
          if (_queryProductError != null)
            _buildErrorWidget(_queryProductError!)
          else if (_products.isEmpty)
            _buildLoadingWidget()
          else
            _buildPurchaseButton(),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.px),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CLText.titleMedium(Localized.text('ox_usercenter.payment_summary')),
            SizedBox(height: 16.px),
            _buildSummaryRow(
              Localized.text('ox_usercenter.subscription_level'),
              'Level ${widget.level}',
            ),
            SizedBox(height: 8.px),
            _buildSummaryRow(
              Localized.text('ox_usercenter.subscription_period'),
              _formatPeriod(widget.levelPeriod),
            ),
            SizedBox(height: 8.px),
            if (_products.isNotEmpty)
              _buildSummaryRow(
                'Product',
                _products.first.title,
              ),
            SizedBox(height: 8.px),
            Divider(),
            SizedBox(height: 8.px),
            _buildSummaryRow(
              Localized.text('ox_usercenter.total'),
              _products.isNotEmpty
                  ? _products.first.price
                  : '\$${(widget.amount / 100).toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  String _formatPeriod(String periodInSeconds) {
    try {
      final seconds = int.parse(periodInSeconds);
      if (seconds >= 31536000) {
        // 365 days
        return '1 year';
      } else if (seconds >= 2592000) {
        // 30 days
        final months = (seconds / 2592000).round();
        return '$months ${months == 1 ? 'month' : 'months'}';
      } else if (seconds >= 86400) {
        // 1 day
        final days = (seconds / 86400).round();
        return '$days ${days == 1 ? 'day' : 'days'}';
      }
      return periodInSeconds;
    } catch (e) {
      return periodInSeconds;
    }
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CLText.bodyMedium(label),
        CLText.bodyMedium(
          value,
          isBold: isTotal,
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.px),
        child: Column(
          children: [
            CLText.bodyMedium(
              'Error: $error',
              customColor: Colors.red,
            ),
            SizedBox(height: 16.px),
            CLButton.filled(
              text: 'Retry',
              onTap: () => initStoreInfo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    final product = _products.first;
    return CLButton.filled(
      text: Platform.isIOS
          ? 'Subscribe with App Store'
          : 'Subscribe with Google Play',
      onTap: _isAvailable && !_isProcessing
          ? () => _buyProduct(product)
          : null,
    );
  }
}
