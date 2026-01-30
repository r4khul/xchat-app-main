import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/purchase/purchase_manager.dart';
import 'package:ox_common/purchase/purchase_plan.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/color_extension.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'circle_activated_page.dart';

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
  SubscriptionPeriod _selectedPeriod = SubscriptionPeriod.monthly;
  SubscriptionPlan? _selectedPlan;
  bool _isRestoring = false;
  bool _isProcessing = false;
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
  }

  @override
  void dispose() {
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

    final isEnabled = !_isProcessing;

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
        SizedBox(height: 8.px),
        CLText.bodySmall(
          Localized.text('ox_login.recurring_billing'),
          colorToken: ColorToken.onSurfaceVariant,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Initiate purchase for the selected plan
  /// 
  /// All purchase logic (query, validation, debouncing) is handled by PurchaseManager.
  /// We handle UI state changes here based on the result.
  Future<void> _handlePay() async {
    if (_selectedPlan == null) return;

    final String productId = _selectedPlan!.getProductId(_selectedPeriod);
    
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
        } else if (result.isCanceled) {
          // Purchase canceled by user - no need to show error message
          // Just reset UI state (already done above)
        } else if (result.isSubscriptionExpired) {
          // Expired subscription was delivered; transaction finished so user can tap again to renew
          CommonToast.instance.show(
            context,
            result.errorMessage ?? 'Subscription has expired. Please tap again to renew.',
          );
        } else {
          // Purchase failed - show user-friendly error message
          final errorMessage = result.errorMessage ?? 'Purchase failed. Please try again.';
          CommonToast.instance.show(
            context,
            errorMessage,
          );
        }
      }
    } catch (e) {
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


  Future<void> _restorePurchases() async {
    try {
      setState(() => _isRestoring = true);
      
      // Get all product IDs from available plans
      final productIds = <String>{};
      for (final plan in plans) {
        productIds.add(plan.getProductId(SubscriptionPeriod.monthly));
        productIds.add(plan.getProductId(SubscriptionPeriod.yearly));
      }
      
      final results = await PurchaseManager.instance.restorePurchases(
        productIds: productIds.isNotEmpty ? productIds : null,
      );
      
      if (mounted) {
        final successCount = results.where((r) => r.success).length;
        if (successCount > 0) {
          CommonToast.instance.show(
            context,
            Localized.text('ox_usercenter.restoring_purchases'),
          );
        } else {
          CommonToast.instance.show(
            context,
            'No purchases found to restore',
          );
        }
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
