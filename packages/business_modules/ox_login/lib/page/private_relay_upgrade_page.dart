import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_common/login/circle_api.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/color_extension.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'circle_activated_page.dart';

enum SubscriptionPeriod { monthly, yearly }

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final int maxUsers;
  final int fileSizeLimitMB;
  final double monthlyPrice;
  final double yearlyPrice;
  final Color cardColor;
  final bool isPopular;
  final String monthlyProductId; // Product ID for monthly subscription
  final String yearlyProductId; // Product ID for yearly subscription

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.maxUsers,
    required this.fileSizeLimitMB,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.cardColor,
    required this.monthlyProductId,
    required this.yearlyProductId,
    this.isPopular = false,
  });

  double getPrice(SubscriptionPeriod period) {
    return period == SubscriptionPeriod.monthly ? monthlyPrice : yearlyPrice;
  }

  String getPriceDisplay(SubscriptionPeriod period) {
    final price = getPrice(period);
    return period == SubscriptionPeriod.monthly
        ? '\$${price.toStringAsFixed(2)}/mo'
        : '\$${price.toStringAsFixed(2)}/yr';
  }

  int getAmountInCents(SubscriptionPeriod period) {
    return (getPrice(period) * 100).toInt();
  }

  String getLevelPeriod(SubscriptionPeriod period) {
    // Return period in seconds
    return period == SubscriptionPeriod.monthly
        ? '2592000' // 30 days
        : '31536000'; // 365 days
  }

  String getProductId(SubscriptionPeriod period) {
    return period == SubscriptionPeriod.monthly
        ? monthlyProductId
        : yearlyProductId;
  }

  int getLevel() {
    // Map plan to level: 1 = Lovers, 2 = Family, 3 = Community
    switch (id) {
      case 'lovers':
        return 1;
      case 'family':
        return 2;
      case 'community':
        return 3;
      default:
        return 1;
    }
  }

  /// Get file limit display text
  /// Returns "Unlimited file server" if fileSizeLimitMB is -1, otherwise returns "XMB file limit"
  String getFileLimitDisplay() {
    if (fileSizeLimitMB == -1) {
      return Localized.text('ox_login.unlimited_file_server');
    }
    return '${fileSizeLimitMB}MB ${Localized.text('ox_login.file_limit')}';
  }
}

class PrivateRelayUpgradePage extends StatefulWidget {
  const PrivateRelayUpgradePage({
    super.key,
    this.groupId,
  });

  final String? groupId;

  @override
  State<PrivateRelayUpgradePage> createState() =>
      _PrivateRelayUpgradePageState();
}

class _FeatureCard {
  final IconData icon;
  final String title;
  final String description;
  final Color tintColor;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.tintColor,
  });
}

class _PrivateRelayUpgradePageState extends State<PrivateRelayUpgradePage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  SubscriptionPeriod _selectedPeriod = SubscriptionPeriod.monthly;
  SubscriptionPlan? _selectedPlan;
  bool _isRestoring = false;
  bool _isProcessing = false;
  bool _purchasePending = false;
  late PageController _featurePageController;
  int _currentFeatureIndex = 0;
  Timer? _featureCarouselTimer;

  List<_FeatureCard> get _features => [
        _FeatureCard(
          icon: Icons.bolt,
          title: Localized.text('ox_login.feature_high_speed_relay'),
          description: Localized.text('ox_login.feature_high_speed_relay_desc'),
          tintColor: const Color(0xFFE88D3A),
        ),
        _FeatureCard(
          icon: Icons.lock,
          title: Localized.text('ox_login.feature_encrypted_storage'),
          description: Localized.text('ox_login.feature_encrypted_storage_desc'),
          tintColor: const Color(0xFF4A90E2),
        ),
        _FeatureCard(
          icon: Icons.visibility_off,
          title: Localized.text('ox_login.feature_zero_logging'),
          description: Localized.text('ox_login.feature_zero_logging_desc'),
          tintColor: const Color(0xFF525B6B),
        ),
        _FeatureCard(
          icon: Icons.delete_outline,
          title: Localized.text('ox_login.feature_total_control'),
          description: Localized.text('ox_login.feature_total_control_desc'),
          tintColor: const Color(0xFFE53935),
        ),
      ];

  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'lovers',
      name: '2 Members',
      description: 'Perfect for couples or best friends',
      maxUsers: 2,
      fileSizeLimitMB: -1, // -1 means unlimited
      monthlyPrice: 1.99,
      yearlyPrice: 19.99, // ~$1.67/month with 17% discount
      cardColor: Color(0xFFFFE5F1), // Pink
      monthlyProductId: 'level1.monthly',
      yearlyProductId: 'level1.yearly',
    ),
    SubscriptionPlan(
      id: 'family',
      name: '6 Members',
      description: 'Great for small groups and families',
      maxUsers: 6,
      fileSizeLimitMB: -1, // -1 means unlimited
      monthlyPrice: 5.99,
      yearlyPrice: 59.99, // ~$5.00/month with 17% discount
      cardColor: Color(0xFFE5F0FF), // Blue
      isPopular: true,
      monthlyProductId: 'level2.monthly',
      yearlyProductId: 'level2.yearly',
    ),
    SubscriptionPlan(
      id: 'community',
      name: '20 Members',
      description: 'For larger groups and communities',
      maxUsers: 20,
      fileSizeLimitMB: -1, // -1 means unlimited
      monthlyPrice: 19.99,
      yearlyPrice: 199.99, // ~$16.67/month with 17% discount
      cardColor: Color(0xFFF0E5FF), // Purple
      monthlyProductId: 'level3.monthly',
      yearlyProductId: 'level3.yearly',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Select the popular plan by default
    _selectedPlan =
        plans.firstWhere((p) => p.isPopular, orElse: () => plans[1]);
    
    // Initialize feature carousel page controller
    _featurePageController = PageController();
    
    // Start auto-play carousel
    _startFeatureCarousel();

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

    // Initialize store info
    _initStoreInfo();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _featureCarouselTimer?.cancel();
    _featurePageController.dispose();
    super.dispose();
  }
  
  void _startFeatureCarousel() {
    _featureCarouselTimer?.cancel();
    _featureCarouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final nextIndex = (_currentFeatureIndex + 1) % _features.length;
      _featurePageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }
  
  void _resetFeatureCarousel() {
    _startFeatureCarousel();
  }

  Future<void> _initStoreInfo() async {
    // Store info will be queried when user taps pay button
    // No need to pre-fetch here
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
    if (!mounted || _selectedPlan == null) return;

    try {
      setState(() => _isProcessing = true);
      OXLoading.show();

      // Get receipt/purchase token
      String receipt = purchaseDetails.verificationData.serverVerificationData;
      if (receipt.isEmpty) {
        receipt = purchaseDetails.verificationData.source;
      }

      // Verify payment and get relay URL using CircleApi
      final PaymentVerificationResult result;
      if (Platform.isIOS) {
        // Apple App Store
        result = await CircleApi.verifyApplePayment(
          productId: purchaseDetails.productID,
          receiptData: receipt,
        );
      } else {
        // Google Play - need to get purchase token
        // For Google Play, the receipt should be the purchase token
        result = await CircleApi.verifyGooglePayment(
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
          Navigator.of(context).pop(); // Close upgrade page
          OXNavigator.pushPage(
            context,
            (context) => CircleActivatedPage(
              maxUsers: _selectedPlan!.maxUsers,
              planName: _selectedPlan!.name,
            ),
            type: OXPushPageType.present,
            fullscreenDialog: true,
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
      appBar: CLAppBar(
        title: Localized.text('ox_login.private_relay'),
        actions: [
          // Test button for simulating subscription success
          if (kDebugMode)
            IconButton(
              icon: Icon(Icons.check_circle),
              tooltip: 'Test: Simulate Success',
              onPressed: _isProcessing ? null : _simulatePurchaseSuccess,
            ),
          IconButton(
            icon: Icon(Icons.restore),
            tooltip: Localized.text('ox_usercenter.restore_purchases'),
            onPressed: _isRestoring ? null : _restorePurchases,
          ),
        ],
      ),
      body: _buildBody(),
      bottomWidget: _buildPayButton(),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 100.px,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: CLLayout.horizontalPadding,
          right: CLLayout.horizontalPadding,
          top: 24.px,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 32.px),
            Center(child: _buildPeriodSelector()),
            SizedBox(height: 24.px),
            _buildPlansList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.only(left: 20.px, right: 20.px),
          height: 70.px,
          child: PageView.builder(
            controller: _featurePageController,
            onPageChanged: (index) {
              setState(() {
                _currentFeatureIndex = index;
              });
              // Reset timer when user manually swipes
              _resetFeatureCarousel();
            },
            itemCount: _features.length,
            itemBuilder: (context, index) {
              return _buildFeatureCard(_features[index]);
            },
          ),
        ),
        SizedBox(height: 12.px),
        _buildFeatureIndicator(),
      ],
    );
  }

  Widget _buildFeatureCard(_FeatureCard feature) {
    final tintColor = feature.tintColor;
    final iconColor = tintColor;
    Color iconBgColor = tintColor.asIconBackground();
    Color containerBgColor = tintColor.asBackgroundTint();
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.px),
      padding: EdgeInsets.symmetric(horizontal: 16.px),
      decoration: BoxDecoration(
        color: containerBgColor,
        borderRadius: BorderRadius.circular(12.px),
        border: Border.all(color: iconBgColor, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40.px,
            height: 40.px,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              feature.icon,
              color: iconColor,
              size: 24.px,
            ),
          ),
          SizedBox(width: 16.px),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CLText.titleSmall(
                  feature.title,
                  colorToken: ColorToken.onSurface,
                  isBold: true,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.px),
                CLText.bodySmall(
                  feature.description,
                  colorToken: ColorToken.onSurfaceVariant,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_features.length, (index) {
        final isActive = index == _currentFeatureIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 3.px),
          width: isActive ? 24.px : 8.px,
          height: 8.px,
          decoration: BoxDecoration(
            color: isActive
                ? ColorToken.xChat.of(context)
                : ColorToken.onSurfaceVariant.of(context).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4.px),
          ),
        );
      }),
    );
  }

  Widget _buildPeriodSelector() {
    return SizedBox(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            width: 260.px,
            height: 50.px,
            decoration: BoxDecoration(
              color: ColorToken.surfaceContainer.of(context),
              borderRadius: BorderRadius.circular(12.px),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildPeriodOption(
                    period: SubscriptionPeriod.monthly,
                    label: Localized.text('ox_login.monthly'),
                  ),
                ),
                Expanded(
                  child: _buildPeriodOption(
                    period: SubscriptionPeriod.yearly,
                    label: Localized.text('ox_login.yearly'),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -8.px,
            right: -16.px,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.px, vertical: 2.px),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4.px),
              ),
              child: CLText.labelSmall(
                Localized.text('ox_login.save_17_percent'),
                customColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodOption({
    required SubscriptionPeriod period,
    required String label,
  }) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected ? ColorToken.surface.of(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.px),
        ),
        child: Center(
          child: CLText.titleSmall(
            label,
            colorToken:
                isSelected ? ColorToken.onSurface : ColorToken.onSurfaceVariant,
            isBold: isSelected,
          ),
        ),
      ),
    );
  }

  Widget _buildPlansList() {
    return Column(
      children: [
        ...plans.map((plan) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16.px),
            child: _buildPlanCard(plan),
          );
        }).toList(),
        SizedBox(height: 24.px),
        _buildFooterLinks(),
        SizedBox(height: 24.px),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isSelected = _selectedPlan?.id == plan.id;
    final price = plan.getPriceDisplay(_selectedPeriod);

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(20.px),
            decoration: BoxDecoration(
              color: ColorToken.cardContainer.of(context),
              borderRadius: BorderRadius.circular(16.px),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CLText.titleMedium(
                            plan.name,
                            colorToken: ColorToken.onSurface,
                          ),
                          // SizedBox(height: 4.px),
                          // CLText.bodySmall(
                          //   plan.description,
                          //   colorToken: ColorToken.onSurfaceVariant,
                          // ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.px),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CLText.titleMedium(
                              price.split('/')[0],
                              colorToken: ColorToken.onSurface,
                            ),
                            SizedBox(width: 2.px),
                            Padding(
                              padding: EdgeInsets.only(top: 2.px),
                              child: CLText.bodySmall(
                                '/${price.split('/')[1]}',
                                colorToken: ColorToken.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(width: 8.px),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: ColorToken.xChat.of(context),
                                size: 20.px,
                              )
                            else
                              Container(
                                width: 20.px,
                                height: 20.px,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ColorToken.onSurfaceVariant
                                        .of(context)
                                        .withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16.px),
                Row(
                  children: [
                    _buildFeature(
                      icon: Icons.people_rounded,
                      text:
                          '${plan.maxUsers} ${Localized.text('ox_login.max_users')}',
                    ),
                    SizedBox(width: 16.px),
                    _buildFeature(
                      icon: Icons.attach_file_rounded,
                      text: plan.getFileLimitDisplay(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.px),
                border: Border.all(
                  color: isSelected
                      ? ColorToken.xChat.of(context)
                      : ColorToken.onSurfaceVariant.of(context).withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
            ),
          ),
          if (plan.isPopular)
            Positioned(
              top: -8.px,
              right: 8.px,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.px,
                  vertical: 4.px,
                ),
                decoration: BoxDecoration(
                  color: ColorToken.xChat.of(context),
                  borderRadius: BorderRadius.circular(6.px),
                ),
                child: CLText.labelSmall(
                  Localized.text('ox_login.most_popular'),
                  customColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.px,
          color: ColorToken.onSurfaceVariant.of(context),
        ),
        SizedBox(width: 4.px),
        CLText.bodySmall(
          text,
          colorToken: ColorToken.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildFooterLinks() {
    return Column(
      children: [
        _buildLink(
          text: Localized.text('ox_login.need_more_users'),
          highlightedText: Localized.text('ox_login.contact_our_team'),
          onTap: () {
            // TODO: Handle contact team
          },
        ),
      ],
    );
  }

  Widget _buildLink({
    required String text,
    String? highlightedText,
    required VoidCallback onTap,
  }) {
    if (highlightedText != null) {
      final parts = text.split(highlightedText);
      return GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: ColorToken.onSurfaceVariant.of(context),
              fontSize: 14.px,
            ),
            children: [
              TextSpan(text: parts[0]),
              TextSpan(
                text: highlightedText,
                style: TextStyle(
                  color: ColorToken.xChat.of(context),
                ),
              ),
              if (parts.length > 1) TextSpan(text: parts[1]),
            ],
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: onTap,
        child: CLText.bodySmall(
          text,
          colorToken: ColorToken.xChat,
        ),
      );
    }
  }

  Widget _buildPayButton() {
    if (_selectedPlan == null) return const SizedBox.shrink();

    final isEnabled = !_isProcessing && !_purchasePending;

    return Column(
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
        SizedBox(height: 8.px),
        CLText.bodySmall(
          Localized.text('ox_login.recurring_billing'),
          colorToken: ColorToken.onSurfaceVariant,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _handlePay() async {
    if (_selectedPlan == null) return;

    // Query product details for the selected plan and period
    final String productId = _selectedPlan!.getProductId(_selectedPeriod);
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

      // Print complete productDetailResponse for debugging
      if (true) {
        print('========== ProductDetailsResponse ==========');
        print('Product ID queried: $productId');
        print('Error: ${productDetailResponse.error}');
        if (productDetailResponse.error != null) {
          print('Error code: ${productDetailResponse.error!.code}');
          print('Error message: ${productDetailResponse.error!.message}');
          print('Error details: ${productDetailResponse.error!.details}');
        }
        print('Not found IDs: ${productDetailResponse.notFoundIDs}');
        print('Product details count: ${productDetailResponse.productDetails.length}');
        print('--- Product Details ---');
        for (var product in productDetailResponse.productDetails) {
          print('  Product ID: ${product.id}');
          print('  Title: ${product.title}');
          print('  Description: ${product.description}');
          print('  Price: ${product.price}');
          print('  Raw price: ${product.rawPrice}');
          print('  Currency code: ${product.currencyCode}');
          print('  Currency symbol: ${product.currencySymbol}');
          // Additional product information
          print('  Platform: ${Platform.isAndroid ? "Android" : "iOS"}');
        }
        print('===========================================');
      }

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

  Future<void> _restorePurchases() async {
    try {
      setState(() => _isRestoring = true);
      await _inAppPurchase.restorePurchases();
      // Restored purchases will be delivered via purchaseStream
      // and handled by _listenToPurchaseUpdated
      if (mounted) {
        CommonToast.instance
            .show(context, Localized.text('ox_usercenter.restoring_purchases'));
      }
    } catch (e) {
      if (mounted) {
        CommonToast.instance.show(context, 'Failed to restore purchases: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  /// Simulate purchase success for testing
  Future<void> _simulatePurchaseSuccess() async {
    if (_selectedPlan == null) {
      CommonToast.instance.show(context, 'Please select a plan first');
      return;
    }

    try {
      setState(() => _isProcessing = true);
        if (mounted) {
          Navigator.of(context).pop(); // Close upgrade page
          OXNavigator.pushPage(
            context,
            (context) => CircleActivatedPage(
              maxUsers: _selectedPlan!.maxUsers,
              planName: _selectedPlan!.name,
            ),
            type: OXPushPageType.present,
            fullscreenDialog: true,
          );
        }
    } catch (e) {
      if (mounted) {
        CommonToast.instance.show(context, 'Failed to simulate purchase: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
