import 'package:flutter/material.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/purchase/purchase_plan.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'duration_selection_page.dart';

class CapacitySelectionPage extends StatefulWidget {
  const CapacitySelectionPage({super.key});

  @override
  State<CapacitySelectionPage> createState() => _CapacitySelectionPageState();
}

class _CapacitySelectionPageState extends State<CapacitySelectionPage> {
  SubscriptionPlan? _selectedPlan;

  List<SubscriptionPlan> allPlan = SubscriptionPlanEx.allPlan;

  @override
  void initState() {
    super.initState();
    // Select the popular plan by default
    _selectedPlan = allPlan
        .firstWhere((p) => p.isPopular, orElse: () => allPlan[1]);
  }

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
            _buildProgressIndicator(1, 3),
            SizedBox(height: 24.px),
            _buildHeader(),
            SizedBox(height: 32.px),
            _buildCapacityOptions(),
            // SizedBox(height: 24.px),
            // _buildBottomInfo(),
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
          Localized.text('ox_login.capacity_selection_title'),
          colorToken: ColorToken.onSurface,
          isBold: true,
        ),
        SizedBox(height: 8.px),
        CLText.bodyMedium(
          Localized.text('ox_login.capacity_selection_subtitle'),
          colorToken: ColorToken.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildCapacityOptions() {
    return Column(
      children: [
        _buildCapacityOption(
          plan: allPlan[0], // 2 Members
          title: Localized.text('ox_login.capacity_2_members'),
          description: Localized.text('ox_login.capacity_2_members_desc'),
        ),
        SizedBox(height: 16.px),
        _buildCapacityOption(
          plan: allPlan[1], // 6 Members
          title: Localized.text('ox_login.capacity_6_members'),
          description: Localized.text('ox_login.capacity_6_members_desc'),
          isPopular: true,
        ),
        SizedBox(height: 16.px),
        _buildCapacityOption(
          plan: allPlan[2], // 20 Members (Community)
          title: Localized.text('ox_login.capacity_50_members'),
          description: Localized.text('ox_login.capacity_50_members_desc'),
        ),
      ],
    );
  }

  Widget _buildCapacityOption({
    required SubscriptionPlan plan,
    required String title,
    required String description,
    bool isPopular = false,
  }) {
    final isSelected = _selectedPlan?.id == plan.id;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedPlan = plan),
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
                Container(
                  width: 40.px,
                  height: 40.px,
                  decoration: BoxDecoration(
                    color: plan.cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.people_rounded,
                    color: ColorToken.xChat.of(context),
                    size: 24.px,
                  ),
                ),
                SizedBox(width: 16.px),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CLText.titleMedium(
                            title,
                            colorToken: ColorToken.onSurface,
                            isBold: true,
                          ),
                          if (isPopular) ...[
                            SizedBox(width: 8.px),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.px,
                                vertical: 2.px,
                              ),
                              decoration: BoxDecoration(
                                color: ColorToken.xChat.of(context),
                                borderRadius: BorderRadius.circular(4.px),
                              ),
                              child: CLText.labelSmall(
                                Localized.text('ox_login.most_popular'),
                                customColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.px),
                      CLText.bodySmall(
                        description,
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
        onTap: _selectedPlan != null ? _onContinue : null,
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
    if (_selectedPlan == null) return;

    OXNavigator.pushPage(
      context,
      (context) => DurationSelectionPage(selectedPlan: _selectedPlan!),
    );
  }
}

