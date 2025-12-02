import 'package:flutter/material.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/page/circle_introduction_page.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import '../controller/onboarding_controller.dart';

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
          isRecommended: true,
          onTap: _isProcessing ? null : _onUsePublicCircle,
        ),
        SizedBox(height: 16.px),
        _buildCircleOption(
          icon: Icons.lock_rounded,
          title: Localized.text('ox_login.use_private_circle'),
          subtitle: Localized.text('ox_login.use_private_circle_desc'),
          isRecommended: false,
          onTap: _isProcessing ? null : _onUsePrivateCircle,
        ),
      ],
    );
  }

  Widget _buildCircleOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isRecommended,
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
            border: isRecommended
                ? Border.all(
                    color: ColorToken.xChat.of(context),
                    width: 2,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 56.px,
                height: 56.px,
                decoration: BoxDecoration(
                  color: isRecommended
                      ? ColorToken.xChat.of(context).withValues(alpha: 0.1)
                      : ColorToken.surfaceContainerHigh.of(context),
                  borderRadius: BorderRadius.circular(12.px),
                ),
                child: Icon(
                  icon,
                  size: 28.px,
                  color: isRecommended
                      ? ColorToken.xChat.of(context)
                      : ColorToken.onSurfaceVariant.of(context),
                ),
              ),
              SizedBox(width: 16.px),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CLText.titleMedium(
                            title,
                            colorToken: ColorToken.onSurface,
                          ),
                        ),
                        // if (isRecommended)
                        //   Container(
                        //     padding: EdgeInsets.symmetric(
                        //       horizontal: 8.px,
                        //       vertical: 4.px,
                        //     ),
                        //     decoration: BoxDecoration(
                        //       color: ColorToken.xChat.of(context),
                        //       borderRadius: BorderRadius.circular(4.px),
                        //     ),
                        //     child: CLText.labelSmall(
                        //       Localized.text('ox_login.recommended'),
                        //       customColor: ColorToken.onPrimary.of(context),
                        //     ),
                        //   ),
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
              Icon(
                Icons.chevron_right_rounded,
                color: ColorToken.onSurfaceVariant.of(context),
                size: 24.px,
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

  Future<void> _onUsePublicCircle() async {
    OXLoading.show();

    final result = await _controller.joinPublicCircle();
    _handleOnboardingResult(result);
  }

  Future<void> _onUsePrivateCircle() async {
    final relayUrl = await _showAddCircleDialog();
    if (relayUrl == null || relayUrl.isEmpty) return;

    OXLoading.show();

    final result = await _controller.joinPrivateCircle(
      relayUrl: relayUrl,
      context: context,
    );
    _handleOnboardingResult(result);
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