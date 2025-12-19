import 'package:flutter/material.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/page/circle_introduction_page.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import '../controller/onboarding_controller.dart';

enum CircleType { public, private }

class CircleSelectionPage extends StatefulWidget {
  const CircleSelectionPage({
    super.key,
    required this.controller,
  });

  final OnboardingController controller;

  @override
  State<CircleSelectionPage> createState() => _CircleSelectionPageState();
}

class _CircleSelectionPageState extends State<CircleSelectionPage> {
  bool _isProcessing = false;
  CircleType? _selectedCircleType;

  OnboardingController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(),
      body: _buildBody(),
      bottomWidget: _buildNextButton(),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 24.px,
        horizontal: CLLayout.horizontalPadding,
      ),
      child: Column(
        children: [
          _buildHeader(),
          SizedBox(height: 48.px),
          _buildCircleOptions(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        CLText.titleLarge(
          Localized.text('ox_login.circle_selection_title'),
          colorToken: ColorToken.onSurface,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.px),
        CLText.bodyMedium(
          Localized.text('ox_login.circle_selection_subtitle'),
          colorToken: ColorToken.onSurfaceVariant,
          textAlign: TextAlign.center,
          maxLines: null,
        ).highlighted(
          rules: [
            CLHighlightRule(
              pattern: RegExp(Localized.text('ox_login.learn_more')),
              onTap: (_) => _showLearnMore(),
              cursor: SystemMouseCursors.click,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleOptions() {
    return Column(
      children: [
        _buildCircleOption(
          icon: Icons.public_rounded,
          title: Localized.text('ox_login.use_public_circle'),
          subtitle: Localized.text('ox_login.use_public_circle_desc'),
          isRecommended: false,
          isSelected: _selectedCircleType == CircleType.public,
          onTap: () => setState(() => _selectedCircleType = CircleType.public),
        ),
        SizedBox(height: 16.px),
        _buildCircleOption(
          icon: Icons.lock_rounded,
          title: Localized.text('ox_login.use_private_circle'),
          subtitle: Localized.text('ox_login.use_private_circle_desc'),
          isRecommended: true,
          isSelected: _selectedCircleType == CircleType.private,
          onTap: () => setState(() => _selectedCircleType = CircleType.private),
        ),
      ],
    );
  }

  Widget _buildCircleOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isRecommended,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: EdgeInsets.all(20.px),
          decoration: BoxDecoration(
            color: ColorToken.surface.of(context),
            borderRadius: BorderRadius.circular(16.px),
            border: Border.all(
              color: isSelected
                  ? ColorToken.xChat.of(context)
                  : (isRecommended
                      ? ColorToken.xChat.of(context).withValues(alpha: 0.3)
                      : ColorToken.onSurfaceVariant.of(context).withValues(alpha: 0.2)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56.px,
                height: 56.px,
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorToken.xChat.of(context).withValues(alpha: 0.15)
                      : ColorToken.xChat.of(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.px),
                ),
                child: Icon(
                  icon,
                  size: 28.px,
                  color: ColorToken.xChat.of(context),
                ),
              ),
              SizedBox(width: 16.px),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: CLText.titleMedium(
                            title,
                            colorToken: ColorToken.onSurface,
                          ),
                        ),
                        if (isRecommended) ...[
                          SizedBox(width: 6.px),
                          Icon(
                            Icons.star_rounded,
                            size: 20.px,
                            color: Colors.amber,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.px),
                    CLText.bodySmall(
                      subtitle,
                      colorToken: ColorToken.onSurfaceVariant,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.px),
              // Radio button indicator
              Container(
                width: 24.px,
                height: 24.px,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? ColorToken.xChat.of(context)
                        : ColorToken.onSurfaceVariant.of(context),
                    width: 2,
                  ),
                  color: isSelected
                      ? ColorToken.xChat.of(context)
                      : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16.px,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildNextButton() {
    return CLButton.filled(
      text: Localized.text('ox_common.next'),
      onTap: _selectedCircleType != null && !_isProcessing ? _onNextTap : null,
      expanded: true,
      height: 48.px,
    );
  }

  Future<void> _onNextTap() async {
    if (_selectedCircleType == CircleType.public) {
      await _onUsePublicCircle();
    } else if (_selectedCircleType == CircleType.private) {
      await _onUsePrivateCircle();
    }
  }

  Future<void> _onUsePublicCircle() async {
    setState(() => _isProcessing = true);
    OXLoading.show();

    final result = await _controller.joinPublicCircle();
    _handleOnboardingResult(result);
    
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _onUsePrivateCircle() async {
    final relayUrl = await _showAddCircleDialog();
    if (relayUrl == null || relayUrl.isEmpty) return;

    setState(() => _isProcessing = true);
    OXLoading.show();

    final result = await _controller.joinPrivateCircle(
      relayUrl: relayUrl,
      context: context,
    );
    _handleOnboardingResult(result);
    
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  void _handleOnboardingResult(OnboardingResult result) {
    OXLoading.dismiss();

    if (result.success) {
      // Navigate to home
      if (mounted) {
        OXNavigator.popToRoot(context);
      }
    } else {
      // Show error
      if (mounted && result.errorMessage != null) {
        CommonToast.instance.show(context, result.errorMessage!);
      }
    }
  }

  Future<String?> _showAddCircleDialog() async {
    return await CLDialog.showInputDialog(
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
  }
}