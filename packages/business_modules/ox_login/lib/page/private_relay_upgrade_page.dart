import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/page/circle_introduction_page.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_usercenter/page/payment/relay_payment_page.dart';

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

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.maxUsers,
    required this.fileSizeLimitMB,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.cardColor,
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
}

class PrivateRelayUpgradePage extends StatefulWidget {
  const PrivateRelayUpgradePage({
    super.key,
    this.groupId,
  });

  final String? groupId;

  @override
  State<PrivateRelayUpgradePage> createState() => _PrivateRelayUpgradePageState();
}

class _PrivateRelayUpgradePageState extends State<PrivateRelayUpgradePage> {
  SubscriptionPeriod _selectedPeriod = SubscriptionPeriod.monthly;
  SubscriptionPlan? _selectedPlan;

  static const List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      id: 'lovers',
      name: 'Lovers & Friends',
      description: 'Perfect for couples or best friends',
      maxUsers: 2,
      fileSizeLimitMB: 50,
      monthlyPrice: 1.99,
      yearlyPrice: 19.99, // ~$1.67/month with 17% discount
      cardColor: Color(0xFFFFE5F1), // Pink
    ),
    SubscriptionPlan(
      id: 'family',
      name: 'Family & Team',
      description: 'Great for small groups and families',
      maxUsers: 6,
      fileSizeLimitMB: 100,
      monthlyPrice: 5.99,
      yearlyPrice: 59.99, // ~$5.00/month with 17% discount
      cardColor: Color(0xFFE5F0FF), // Blue
      isPopular: true,
    ),
    SubscriptionPlan(
      id: 'community',
      name: 'Community',
      description: 'For larger groups and communities',
      maxUsers: 20,
      fileSizeLimitMB: 200,
      monthlyPrice: 19.99,
      yearlyPrice: 199.99, // ~$16.67/month with 17% discount
      cardColor: Color(0xFFF0E5FF), // Purple
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Select the popular plan by default
    _selectedPlan = _plans.firstWhere((p) => p.isPopular, orElse: () => _plans[1]);
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(
        title: Localized.text('ox_login.private_relay'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(),
          ),
          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: CLLayout.horizontalPadding,
        vertical: 24.px,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 32.px),
          _buildPeriodSelector(),
          SizedBox(height: 24.px),
          _buildPlansList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CLText.titleLarge(
        //   Localized.text('ox_login.upgrade_your_circle'),
        //   colorToken: ColorToken.onSurface,
        // ),
        // SizedBox(height: 12.px),
        CLText.bodyMedium(
          Localized.text('ox_login.upgrade_description'),
          colorToken: ColorToken.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(4.px),
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
          right: 8.px,
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
        padding: EdgeInsets.symmetric(vertical: 12.px),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorToken.surface.of(context)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.px),
        ),
        child: Center(
          child: CLText.titleSmall(
            label,
            colorToken: isSelected
                ? ColorToken.onSurface
                : ColorToken.onSurfaceVariant,
            isBold: isSelected,
          ),
        ),
      ),
    );
  }

  Widget _buildPlansList() {
    return Column(
      children: _plans.map((plan) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16.px),
          child: _buildPlanCard(plan),
        );
      }).toList(),
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
              color: plan.cardColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16.px),
              border: Border.all(
                color: isSelected
                    ? ColorToken.xChat.of(context)
                    : Colors.transparent,
                width: 2,
              ),
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
                          SizedBox(height: 4.px),
                          CLText.bodySmall(
                            plan.description,
                            colorToken: ColorToken.onSurfaceVariant,
                          ),
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
                                    color: ColorToken.onSurfaceVariant.of(context).withValues(alpha: 0.3),
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
                      text: '${plan.maxUsers} ${Localized.text('ox_login.max_users')}',
                    ),
                    SizedBox(width: 16.px),
                    _buildFeature(
                      icon: Icons.attach_file_rounded,
                      text: '${plan.fileSizeLimitMB}MB ${Localized.text('ox_login.file_limit')}',
                    ),
                  ],
                ),
              ],
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
        SizedBox(height: 12.px),
        _buildLink(
          text: Localized.text('ox_login.custom_relay'),
          onTap: _showAddCircleDialog,
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

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: CLLayout.horizontalPadding,
        vertical: 16.px,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFooterLinks(),
          SizedBox(height: 24.px),
          if (Platform.isIOS)
            Container(
              width: double.infinity,
              height: 50.px,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12.px),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handlePay,
                  borderRadius: BorderRadius.circular(12.px),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.apple,
                        color: Colors.white,
                        size: 20.px,
                      ),
                      SizedBox(width: 8.px),
                      CLText.titleMedium(
                        Localized.text('ox_login.pay'),
                        customColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            CLButton.filled(
              text: Localized.text('ox_login.pay'),
              onTap: _handlePay,
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
      ),
    );
  }

  void _handlePay() {
    if (_selectedPlan == null || widget.groupId == null) return;

    OXNavigator.pushPage(
      context,
      (context) => RelayPaymentPage(
        groupId: widget.groupId!,
        level: _selectedPlan!.getLevel(),
        levelPeriod: _selectedPlan!.getLevelPeriod(_selectedPeriod),
        amount: _selectedPlan!.getAmountInCents(_selectedPeriod),
        previousPageTitle: Localized.text('ox_login.private_relay'),
      ),
    );
  }

  Future<void> _showAddCircleDialog() async {
    final relayUrl = await CLDialog.showInputDialog(
      context: context,
      title: Localized.text('ox_login.add_circle_title'),
      description: null,
      descriptionWidget: _buildCircleDialogDescription(),
      inputLabel: Localized.text('ox_login.circle_url_placeholder'),
      confirmText: Localized.text('ox_login.join'),
      onConfirm: (input) async {
        final trimmedInput = input.trim();
        if (trimmedInput.isEmpty) {
          CommonToast.instance.show(context, Localized.text('ox_login.circle_url_empty'));
          return false;
        }
        return true;
      },
      belowInputBuilder: (ctx, controller) => _buildCircleHintWidget(ctx, controller),
    );

    if (relayUrl != null && relayUrl.isNotEmpty) {
      // Handle the relay URL - you can navigate back or process it
      Navigator.of(context).pop(relayUrl);
    }
  }

  Widget _buildCircleDialogDescription() {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: Localized.text('ox_login.add_circle_description'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: ColorToken.onSurfaceVariant.of(context),
            ),
          ),
          const TextSpan(text: ' '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: _showLearnMore,
              child: Text(
                Localized.text('ox_login.what_is_circle'),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: ColorToken.xChat.of(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleHintWidget(BuildContext context, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.only(top: 8.px),
      child: CLText.bodySmall(
        Localized.text('ox_login.circle_url_hint'),
        colorToken: ColorToken.onSurfaceVariant,
        maxLines: null,
      ).highlighted(
        rules: [
          CLHighlightRule(
            pattern: RegExp(r'0xchat'),
            onTap: (match) {
              controller.text = '0xchat';
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            },
            cursor: SystemMouseCursors.click,
          ),
          CLHighlightRule(
            pattern: RegExp(r'damus'),
            onTap: (match) {
              controller.text = 'damus';
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            },
            cursor: SystemMouseCursors.click,
          ),
        ],
      ),
    );
  }

  void _showLearnMore() {
    OXNavigator.pushPage(
      context,
      (context) => const CircleIntroductionPage(),
      type: OXPushPageType.present,
    );
  }
}

