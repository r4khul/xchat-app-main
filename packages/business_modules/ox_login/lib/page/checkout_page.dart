import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/log_util.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/purchase/purchase_manager.dart';
import 'package:ox_common/utils/adapt.dart';
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
  bool _isProcessing = false;

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
    final isEnabled = !_isProcessing;
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
                      if (_isProcessing)
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
                        _isProcessing
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
              text: _isProcessing
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

  /// Initiate purchase for the selected plan
  /// 
  /// All purchase logic (query, validation, debouncing) is handled by PurchaseManager.
  /// We handle UI state changes here based on the result.
  Future<void> _handlePay() async {
    final String productId = widget.selectedPlan.getProductId(widget.selectedPeriod);
    
    // Set processing state before calling
    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }
    
    try {
      final result = await PurchaseManager.instance.purchaseProduct(productId);
      
      // Update UI based on result
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        if (result.success) {
          // Purchase successful - navigate to success page
          Navigator.of(context).popUntil((route) => route.isFirst);
          OXNavigator.pushPage(
            context,
            (context) => CircleActivatedPage(
              maxUsers: widget.selectedPlan.maxUsers,
              planName: widget.selectedPlan.name,
            ),
          );
        } else if (result.isCanceled) {
          // Purchase canceled by user - no need to show error message
          // Just reset UI state (already done above)
        } else {
          // Purchase failed - show user-friendly error message
          final errorMessage = result.errorMessage ?? 'Purchase failed. Please try again.';
          CommonToast.instance.show(
            context,
            errorMessage,
          );
        }
      }
    } catch (e, stack) {
      LogUtil.e(() => '''
        [CheckoutPage] Error initiating purchase:
        - productId: "$productId"
        - error: $e
        - stack: $stack
      ''');
      // Handle unexpected errors
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        CommonToast.instance.show(
          context,
          'Failed to initiate purchase. Please try again.',
        );
      }
    }
  }
}

