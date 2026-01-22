import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_common/utils/account_credentials_utils.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'circle_activated_page.dart';
import 'private_relay_upgrade_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.selectedPlan,
    required this.selectedPeriod,
  });

  final SubscriptionPlan selectedPlan;
  final SubscriptionPeriod selectedPeriod;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  bool _isProcessing = false;
  bool _purchasePending = false;

  @override
  void initState() {
    super.initState();

    // Listen to purchase updates
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (Object error) {
        _handleError(error);
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

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
          // Complete purchase even on error to free up the queue
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Handle purchase success
          await _handlePurchaseSuccess(purchaseDetails);
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
      OXLoading.show();

      // Get receipt/purchase token
      String receipt = purchaseDetails.verificationData.serverVerificationData;
      if (receipt.isEmpty) {
        receipt = purchaseDetails.verificationData.source;
      }

      // Get credentials for API call
      final credentials = await AccountCredentialsUtils.getCredentials();
      if (credentials == null) {
        throw Exception('Failed to get account credentials');
      }

      // Verify payment and get relay URL using CircleApi
      final PaymentVerificationResult result;
      if (Platform.isIOS) {
        // Apple App Store
        result = await CircleApi.verifyApplePayment(
          pubkey: credentials['pubkey'] as String,
          privkey: credentials['privkey'] as String,
          productId: purchaseDetails.productID,
          receiptData: receipt,
        );
      } else {
        // Google Play - need to get purchase token
        // For Google Play, the receipt should be the purchase token
        result = await CircleApi.verifyGooglePayment(
          pubkey: credentials['pubkey'] as String,
          privkey: credentials['privkey'] as String,
          productId: purchaseDetails.productID,
          purchaseToken: receipt,
        );
      }

      if (result.relayUrl.isEmpty) {
        throw Exception('Failed to get relay URL from server');
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }

      // Create and join Circle with the relay URL
      final failure = await LoginManager.instance.joinCircle(
        result.relayUrl,
        type: CircleType.relay,
      );

      OXLoading.dismiss();

      if (failure != null) {
        if (mounted) {
          CommonToast.instance
              .show(context, 'Failed to create circle: ${failure.message}');
        }
      } else {
        // Success - navigate to circle activated page
        if (mounted) {
          // Close all checkout pages
          Navigator.of(context).popUntil((route) => route.isFirst);
          OXNavigator.pushPage(
            context,
            (context) => CircleActivatedPage(
              maxUsers: widget.selectedPlan.maxUsers,
              planName: widget.selectedPlan.name,
            ),
          );
        }
      }
    } catch (e) {
      OXLoading.dismiss();
      // On error, still complete purchase to free up the queue
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
      if (mounted) {
        CommonToast.instance.show(context, 'Failed to process payment: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }


  void _handleError(dynamic error) {
    if (mounted) {
      CommonToast.instance.show(context, 'Purchase error: ${error.toString()}');
      setState(() {
        _isProcessing = false;
        _purchasePending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(),
      body: _buildBody(),
      bottomWidget: _buildPaymentButtons(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: CLLayout.horizontalPadding,
        right: CLLayout.horizontalPadding,
        top: 24.px,
        bottom: 100.px,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressIndicator(3, 3),
          SizedBox(height: 24.px),
          _buildHeader(),
          SizedBox(height: 24.px),
          _buildOrderSummary(),
          SizedBox(height: 24.px),
          _buildGuarantees(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(int currentStep, int totalSteps) {
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index < currentStep;
            return Expanded(
              child: Container(
                height: 2.px,
                margin: EdgeInsets.only(right: index < totalSteps - 1 ? 4.px : 0),
                decoration: BoxDecoration(
                  color: isActive
                      ? ColorToken.xChat.of(context)
                      : ColorToken.onSurfaceVariant.of(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(1.px),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 8.px),
        Row(
          children: [
            Expanded(
              child: CLText.labelSmall(
                'CAPACITY',
                colorToken: ColorToken.onSurfaceVariant,
                textAlign: TextAlign.left,
              ),
            ),
            Expanded(
              child: CLText.labelSmall(
                'DURATION',
                colorToken: ColorToken.onSurfaceVariant,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: CLText.labelSmall(
                'CHECKOUT',
                colorToken: ColorToken.onSurfaceVariant,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CLText.titleLarge(
          Localized.text('ox_login.checkout_title'),
          colorToken: ColorToken.onSurface,
          isBold: true,
        ),
        SizedBox(height: 8.px),
        CLText.bodyMedium(
          Localized.text('ox_login.checkout_subtitle'),
          colorToken: ColorToken.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    final price = widget.selectedPlan.getPrice(widget.selectedPeriod);
    final periodText = widget.selectedPeriod == SubscriptionPeriod.monthly
        ? Localized.text('ox_login.monthly')
        : Localized.text('ox_login.yearly');
    final planName = widget.selectedPlan.name;
    final membersText = '${widget.selectedPlan.maxUsers} ${Localized.text('ox_login.max_users')}';
    final storageText = Localized.text('ox_login.tb_storage');

    return Container(
      padding: EdgeInsets.all(20.px),
      decoration: BoxDecoration(
        color: ColorToken.cardContainer.of(context),
        borderRadius: BorderRadius.circular(16.px),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CLText.labelSmall(
                      Localized.text('ox_login.plan'),
                      colorToken: ColorToken.onSurfaceVariant,
                    ),
                    SizedBox(height: 4.px),
                    CLText.titleMedium(
                      planName,
                      colorToken: ColorToken.onSurface,
                      isBold: true,
                    ),
                    SizedBox(height: 4.px),
                    CLText.bodySmall(
                      '$membersText • $storageText',
                      colorToken: ColorToken.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CLText.labelSmall(
                      Localized.text('ox_login.billing'),
                      colorToken: ColorToken.onSurfaceVariant,
                    ),
                    SizedBox(height: 4.px),
                    CLText.titleMedium(
                      periodText,
                      colorToken: ColorToken.onSurface,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.px),
          Divider(
            color: ColorToken.onSurfaceVariant.of(context).withValues(alpha: 0.2),
          ),
          SizedBox(height: 16.px),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CLText.titleMedium(
                Localized.text('ox_login.total'),
                colorToken: ColorToken.onSurface,
                isBold: true,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CLText.titleLarge(
                    '\$${price.toStringAsFixed(2)}',
                    colorToken: ColorToken.onSurface,
                    isBold: true,
                  ),
                  CLText.bodySmall(
                    widget.selectedPeriod == SubscriptionPeriod.yearly
                        ? Localized.text('ox_login.per_year')
                        : '/month',
                    colorToken: ColorToken.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuarantees() {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20.px,
            ),
            SizedBox(width: 8.px),
            CLText.bodySmall(
              Localized.text('ox_login.money_back_guarantee'),
              colorToken: ColorToken.onSurfaceVariant,
            ),
          ],
        ),
        SizedBox(height: 12.px),
        Row(
          children: [
            Icon(
              Icons.lock,
              color: ColorToken.onSurfaceVariant.of(context),
              size: 20.px,
            ),
            SizedBox(width: 8.px),
            CLText.bodySmall(
              Platform.isIOS
                  ? Localized.text('ox_login.secure_payment_apple')
                  : Localized.text('ox_login.secure_payment_google'),
              colorToken: ColorToken.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentButtons() {
    final isEnabled = !_isProcessing && !_purchasePending;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 16.px,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (Platform.isIOS)
            Container(
              width: double.infinity,
              height: 50.px,
              decoration: BoxDecoration(
                color: isEnabled ? Colors.black : Colors.grey,
                borderRadius: BorderRadius.circular(12.px),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled ? _handlePay : null,
                  borderRadius: BorderRadius.circular(12.px),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isProcessing || _purchasePending)
                        SizedBox(
                          width: 20.px,
                          height: 20.px,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Icon(
                          Icons.apple,
                          color: Colors.white,
                          size: 20.px,
                        ),
                      SizedBox(width: 8.px),
                      CLText.titleMedium(
                        _isProcessing || _purchasePending
                            ? Localized.text('ox_usercenter.processing')
                            : Localized.text('ox_login.pay'),
                        customColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            CLButton.filled(
              text: _isProcessing || _purchasePending
                  ? Localized.text('ox_usercenter.processing')
                  : Localized.text('ox_login.pay'),
              onTap: isEnabled ? _handlePay : null,
              expanded: true,
              height: 50.px,
            ),
        ],
      ),
    );
  }

  Future<void> _handlePay() async {
    // Query product details for the selected plan and period
    final String productId = widget.selectedPlan.getProductId(widget.selectedPeriod);
    await _queryAndBuyProduct(productId);
  }

  Future<void> _queryAndBuyProduct(String productId) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        setState(() {
          _isProcessing = false;
        });
        CommonToast.instance.show(context, 'Store not available');
        return;
      }

      final ProductDetailsResponse productDetailResponse =
          await _inAppPurchase.queryProductDetails({productId});

      if (productDetailResponse.error != null) {
        setState(() {
          _isProcessing = false;
        });
        CommonToast.instance.show(
          context,
          'Error: ${productDetailResponse.error!.message}',
        );
        return;
      }

      if (productDetailResponse.productDetails.isEmpty) {
        setState(() {
          _isProcessing = false;
        });
        CommonToast.instance.show(
          context,
          'Product not found: $productId\nPlease check if the product is configured in ${Platform.isIOS ? "App Store Connect" : "Google Play Console"}',
        );
        return;
      }

      final ProductDetails productDetails =
          productDetailResponse.productDetails.first;
      await _buyProduct(productDetails);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      CommonToast.instance.show(context, 'Error: $e');
    }
  }

  Future<void> _buyProduct(ProductDetails productDetails) async {
    try {
      setState(() => _isProcessing = true);

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      // Use buyNonConsumable for subscriptions (the system recognizes subscription products)
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        if (mounted) {
          setState(() => _isProcessing = false);
          CommonToast.instance.show(
            context,
            'Failed to initiate purchase. Please try again.',
          );
        }
      }
      // Purchase status will be handled by _listenToPurchaseUpdated
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        CommonToast.instance.show(context, 'Purchase error: $e');
      }
    }
  }
}

