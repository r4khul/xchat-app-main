import 'package:flutter/material.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/purchase/subscription_period.dart';
import 'package:ox_common/purchase/subscription_tier.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'checkout_page.dart';

class DurationSelectionPage extends StatefulWidget {
  const DurationSelectionPage({
    super.key,
    required this.subscriptionGroupId,
    required this.selectedTier,
  });

  final String subscriptionGroupId;
  final SubscriptionTier selectedTier;

  @override
  State<DurationSelectionPage> createState() => _DurationSelectionPageState();
}

class _DurationSelectionPageState extends State<DurationSelectionPage> {
  SubscriptionPeriod _selectedPeriod = SubscriptionPeriod.yearly;

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(),
      body: _buildBody(),
      bottomWidget: _buildContinueButton(),
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
          _buildProgressIndicator(2, 3),
          SizedBox(height: 24.px),
          _buildHeader(),
          SizedBox(height: 32.px),
          _buildDurationOptions(),
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
          Localized.text('ox_login.duration_selection_title'),
          colorToken: ColorToken.onSurface,
          isBold: true,
        ),
        SizedBox(height: 8.px),
        CLText.bodyMedium(
          Localized.text('ox_login.duration_selection_subtitle'),
          colorToken: ColorToken.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildDurationOptions() {
    final t = widget.selectedTier;
    return Column(
      children: [
        _buildDurationOption(
          period: SubscriptionPeriod.yearly,
          price: t.yearlyPrice,
          label: Localized.text('ox_login.yearly'),
          billingText: Localized.text('ox_login.billed_every_12_months'),
          showSaveTag: true,
        ),
        SizedBox(height: 16.px),
        _buildDurationOption(
          period: SubscriptionPeriod.monthly,
          price: t.monthlyPrice,
          label: Localized.text('ox_login.monthly'),
          billingText: Localized.text('ox_login.billed_every_month'),
          showSaveTag: false,
        ),
      ],
    );
  }

  Widget _buildDurationOption({
    required SubscriptionPeriod period,
    required double price,
    required String label,
    required String billingText,
    required bool showSaveTag,
  }) {
    final isSelected = _selectedPeriod == period;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedPeriod = period),
          child: Container(
            padding: EdgeInsets.all(20.px),
            decoration: BoxDecoration(
              color: ColorToken.cardContainer.of(context),
              borderRadius: BorderRadius.circular(16.px),
              border: Border.all(
                color: isSelected
                    ? ColorToken.xChat.of(context)
                    : ColorToken.onSurfaceVariant.of(context).withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CLText.titleMedium(
                        label,
                        colorToken: ColorToken.onSurface,
                        isBold: true,
                      ),
                      SizedBox(height: 8.px),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CLText.titleLarge(
                            '\$${price.toStringAsFixed(2)}',
                            colorToken: ColorToken.onSurface,
                            isBold: true,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.px),
                      CLText.bodySmall(
                        billingText,
                        colorToken: ColorToken.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.px),
                Container(
                  width: 20.px,
                  height: 20.px,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? ColorToken.xChat.of(context)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? ColorToken.xChat.of(context)
                          : ColorToken.onSurfaceVariant.of(context).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 14.px,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (showSaveTag && isSelected)
          Positioned(
            top: -8.px,
            right: 8.px,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6.px,
                vertical: 2.px,
              ),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4.px),
              ),
              child: CLText.labelSmall(
                Localized.text('ox_login.save_20_percent'),
                customColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 16.px,
      ),
      child: CLButton.filled(
        text: Localized.text('ox_login.connect'),
        onTap: _onContinue,
        expanded: true,
        height: 50.px,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CLText.titleMedium(
              Localized.text('ox_login.connect'),
              customColor: Colors.white,
            ),
            SizedBox(width: 8.px),
            Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 20.px,
            ),
          ],
        ),
      ),
    );
  }

  void _onContinue() {
    OXNavigator.pushPage(
      context,
      (context) => CheckoutPage(
        subscriptionGroupId: widget.subscriptionGroupId,
        selectedTier: widget.selectedTier,
        selectedPeriod: _selectedPeriod,
      ),
    );
  }
}
