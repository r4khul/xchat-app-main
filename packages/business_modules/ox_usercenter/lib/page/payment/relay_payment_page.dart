import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pay/pay.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';

/// Payment page for private relay subscription using Apple Pay or Google Pay
class RelayPaymentPage extends StatefulWidget {
  const RelayPaymentPage({
    super.key,
    required this.groupId,
    required this.level,
    required this.levelPeriod,
    required this.amount,
    this.previousPageTitle,
  });

  final String groupId;
  final int level;
  final String levelPeriod;
  final int amount; // Amount in cents (USD)
  final String? previousPageTitle;

  @override
  State<RelayPaymentPage> createState() => _RelayPaymentPageState();
}

class _RelayPaymentPageState extends State<RelayPaymentPage> {
  Future<PaymentConfiguration>? _applePayConfigFuture;
  Future<PaymentConfiguration>? _googlePayConfigFuture;
  bool _isProcessing = false;
  StreamSubscription? _paymentResultSubscription;

  @override
  void initState() {
    super.initState();
    _loadPaymentConfigs();
    _setupPaymentResultListener();
  }

  void _loadPaymentConfigs() {
    if (Platform.isIOS) {
      _applePayConfigFuture = PaymentConfiguration.fromAsset('payment_configs/apple_pay_config.json');
    } else if (Platform.isAndroid) {
      _googlePayConfigFuture = PaymentConfiguration.fromAsset('payment_configs/google_pay_config.json');
    }
  }

  void _setupPaymentResultListener() {
    // Android only: Listen to payment results via event channel
    if (Platform.isAndroid) {
      const eventChannel = EventChannel('plugins.flutter.io/pay/payment_result');
      _paymentResultSubscription = eventChannel
          .receiveBroadcastStream()
          .map((result) => jsonDecode(result as String) as Map<String, dynamic>)
          .listen(
            (result) => _handlePaymentResult(result),
            onError: (error) => _handlePaymentError(error),
          );
    }
  }

  @override
  void dispose() {
    _paymentResultSubscription?.cancel();
    super.dispose();
  }

  String get _title => Localized.text('ox_usercenter.payment');

  List<PaymentItem> get _paymentItems => [
        PaymentItem(
          label: Localized.text('ox_usercenter.private_relay_subscription'),
          amount: (widget.amount / 100).toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ),
      ];

  Future<void> _handleApplePayResult(paymentResult) async {
    if (!mounted) return;
    
    try {
      setState(() => _isProcessing = true);
      
      // Extract payment token from result
      final paymentData = paymentResult as Map<String, dynamic>;
      final paymentToken = jsonEncode(paymentData);
      
      // Create payment on server
      final paymentResponse = await RelayGroup.sharedInstance.createApplePayPayment(
        widget.groupId,
        widget.level,
        widget.levelPeriod,
        widget.amount,
        paymentToken,
      );

      if (paymentResponse != null && mounted) {
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

  Future<void> _handleGooglePayResult(paymentResult) async {
    if (!mounted) return;
    
    try {
      setState(() => _isProcessing = true);
      
      // Extract payment token from result
      final paymentData = paymentResult as Map<String, dynamic>;
      final paymentToken = jsonEncode(paymentData);
      
      // Create payment on server
      final paymentResponse = await RelayGroup.sharedInstance.createGooglePayPayment(
        widget.groupId,
        widget.level,
        widget.levelPeriod,
        widget.amount,
        paymentToken,
      );

      if (paymentResponse != null && mounted) {
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

  void _handlePaymentResult(Map<String, dynamic> result) {
    // Android payment result handler
    _handleGooglePayResult(result);
  }

  void _handlePaymentError(dynamic error) {
    if (mounted) {
      _showError('Payment error: $error');
      setState(() => _isProcessing = false);
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
        _showError('Payment verification timeout. Please check your subscription status.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to verify payment: $e');
      }
    }
  }

  void _showSuccess() {
    CommonToast.instance.show(context, Localized.text('ox_usercenter.payment_success'));
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
      body: _isProcessing
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
          if (Platform.isIOS) _buildApplePayButton(),
          if (Platform.isAndroid) _buildGooglePayButton(),
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
              widget.levelPeriod,
            ),
            SizedBox(height: 8.px),
            Divider(),
            SizedBox(height: 8.px),
            _buildSummaryRow(
              Localized.text('ox_usercenter.total'),
              '\$${(widget.amount / 100).toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
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

  Widget _buildApplePayButton() {
    return FutureBuilder<PaymentConfiguration>(
      future: _applePayConfigFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return CLButton.filled(
            text: Localized.text('ox_usercenter.apple_pay_unavailable'),
            onTap: null,
          );
        }

        return ApplePayButton(
          paymentConfiguration: snapshot.data!,
          paymentItems: _paymentItems,
          style: ApplePayButtonStyle.black,
          type: ApplePayButtonType.buy,
          margin: const EdgeInsets.only(top: 15.0),
          onPaymentResult: _handleApplePayResult,
          loadingIndicator: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _buildGooglePayButton() {
    return FutureBuilder<PaymentConfiguration>(
      future: _googlePayConfigFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return CLButton.filled(
            text: Localized.text('ox_usercenter.google_pay_unavailable'),
            onTap: null,
          );
        }

        return GooglePayButton(
          paymentConfiguration: snapshot.data!,
          paymentItems: _paymentItems,
          type: GooglePayButtonType.buy,
          margin: const EdgeInsets.only(top: 15.0),
          onPaymentResult: _handleGooglePayResult,
          loadingIndicator: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

