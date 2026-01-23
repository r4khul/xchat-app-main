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
  StreamSubscription<PurchaseStateEvent>? _purchaseStateSubscription;
  bool _isProcessing = false;
  bool _purchasePending = false;

  @override
  void initState() {
    super.initState();

    // Listen to purchase state changes for UI updates
    _purchaseStateSubscription = PurchaseManager.instance.purchaseStateStream.listen(
      _onPurchaseStateChanged,
    );
    
    // [DEBUG] Temporary logging for issue diagnosis
    LogUtil.d(() => '''
      [CheckoutPage] initState:
      - selectedPlan: ${widget.selectedPlan.name}
      - selectedPeriod: ${widget.selectedPeriod}
      - productId: ${widget.selectedPlan.getProductId(widget.selectedPeriod)}
      - stream subscription created
    ''');
  }

  @override
  void dispose() {
    _purchaseStateSubscription?.cancel();
    LogUtil.d(() => '[CheckoutPage] dispose: stream subscription canceled');
    super.dispose();
  }

  /// Handle purchase state changes from PurchaseManager
  /// 
  /// This is called when purchase state changes (pending, processing, success, error, canceled).
  /// We only handle UI updates here - all purchase logic is in PurchaseManager.
  void _onPurchaseStateChanged(PurchaseStateEvent event) {
    // [DEBUG] Temporary logging for issue diagnosis
    LogUtil.d(() => '''
      [CheckoutPage] _onPurchaseStateChanged called:
      - mounted: $mounted
      - event.productId: ${event.productId}
      - event.state: ${event.state}
      - event.errorMessage: ${event.errorMessage}
      - current _isProcessing: $_isProcessing
      - current _purchasePending: $_purchasePending
    ''');

    if (!mounted) {
      LogUtil.w(() => '[CheckoutPage] _onPurchaseStateChanged: widget not mounted, ignoring event');
      return;
    }

    // Only handle events for the product we're purchasing
    final currentProductId = widget.selectedPlan.getProductId(widget.selectedPeriod);
    
    // [DEBUG] Temporary logging for issue diagnosis
    LogUtil.d(() => '''
      [CheckoutPage] Product ID comparison:
      - event.productId: "${event.productId}"
      - currentProductId: "$currentProductId"
      - match: ${event.productId == currentProductId}
      - event.productId.length: ${event.productId.length}
      - currentProductId.length: ${currentProductId.length}
    ''');

    if (event.productId != currentProductId) {
      LogUtil.w(() => '''
        [CheckoutPage] Ignoring purchase state event (different product):
        - event productId: "${event.productId}"
        - current productId: "$currentProductId"
        - This event will be ignored, UI will not update!
      ''');
      return;
    }

    LogUtil.d(() => '''
      [CheckoutPage] Processing purchase state event (product ID matches):
      - productId: ${event.productId}
      - state: ${event.state}
      - errorMessage: ${event.errorMessage}
      - verificationResult: ${event.verificationResult != null ? 'present' : 'null'}
    ''');

    switch (event.state) {
      case PurchaseState.pending:
        LogUtil.d(() => '[CheckoutPage] State: pending - setting _purchasePending = true');
        setState(() {
          _purchasePending = true;
        });
        break;

      case PurchaseState.processing:
        LogUtil.d(() => '[CheckoutPage] State: processing - setting _isProcessing = true');
        setState(() {
          _purchasePending = false;
          _isProcessing = true;
        });
        break;

      case PurchaseState.success:
        LogUtil.d(() => '''
          [CheckoutPage] State: success - updating UI and navigating:
          - productId: ${event.productId}
          - relayUrl: ${event.verificationResult?.relayUrl ?? 'N/A'}
          - tenantId: ${event.verificationResult?.tenantId ?? 'N/A'}
          - Before setState: _isProcessing = $_isProcessing
        ''');
        setState(() {
          _purchasePending = false;
          _isProcessing = false;
        });
        LogUtil.d(() => '[CheckoutPage] After setState: _isProcessing = $_isProcessing');
        
        // Purchase successful - navigate to success page
        if (mounted) {
          LogUtil.d(() => '[CheckoutPage] Navigating to CircleActivatedPage...');
          Navigator.of(context).popUntil((route) => route.isFirst);
          OXNavigator.pushPage(
            context,
            (context) => CircleActivatedPage(
              maxUsers: widget.selectedPlan.maxUsers,
              planName: widget.selectedPlan.name,
            ),
          );
          LogUtil.d(() => '[CheckoutPage] Navigation completed');
        } else {
          LogUtil.w(() => '[CheckoutPage] Widget not mounted after setState, cannot navigate');
        }
        break;

      case PurchaseState.error:
        LogUtil.e(() => '''
          [CheckoutPage] State: error - updating UI:
          - errorMessage: ${event.errorMessage}
          - Before setState: _isProcessing = $_isProcessing
        ''');
        setState(() {
          _purchasePending = false;
          _isProcessing = false;
        });
        LogUtil.d(() => '[CheckoutPage] After setState: _isProcessing = $_isProcessing');
        if (mounted && event.errorMessage != null) {
          CommonToast.instance.show(
            context,
            event.errorMessage!,
          );
        }
        break;

      case PurchaseState.canceled:
        LogUtil.d(() => '''
          [CheckoutPage] State: canceled - updating UI:
          - Before setState: _isProcessing = $_isProcessing
        ''');
        setState(() {
          _purchasePending = false;
          _isProcessing = false;
        });
        LogUtil.d(() => '[CheckoutPage] After setState: _isProcessing = $_isProcessing');
        // User canceled - no error message needed
        break;

      case PurchaseState.idle:
        // No action needed
        break;
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

  /// Initiate purchase for the selected plan
  /// 
  /// All purchase logic (query, validation, debouncing) is handled by PurchaseManager.
  /// We only need to call purchaseProduct and handle state changes.
  Future<void> _handlePay() async {
    final String productId = widget.selectedPlan.getProductId(widget.selectedPeriod);
    
    // [DEBUG] Temporary logging for issue diagnosis
    LogUtil.d(() => '''
      [CheckoutPage] User clicked pay button:
      - productId: "$productId"
      - plan: ${widget.selectedPlan.name}
      - period: ${widget.selectedPeriod}
      - current _isProcessing: $_isProcessing
      - current _purchasePending: $_purchasePending
    ''');
    
    try {
      LogUtil.d(() => '[CheckoutPage] Calling PurchaseManager.instance.purchaseProduct("$productId")...');
      await PurchaseManager.instance.purchaseProduct(productId);
      LogUtil.d(() => '[CheckoutPage] purchaseProduct() returned successfully');
      // Purchase state changes will be handled by _onPurchaseStateChanged
    } catch (e, stack) {
      LogUtil.e(() => '''
        [CheckoutPage] Error initiating purchase:
        - productId: "$productId"
        - error: $e
        - stack: $stack
      ''');
      // Error is already handled by PurchaseManager and will trigger state change
      // But we can show a toast here if needed
      if (mounted) {
        CommonToast.instance.show(
          context,
          'Failed to initiate purchase: $e',
        );
      }
    }
  }
}

