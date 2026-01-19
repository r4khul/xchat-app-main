import 'package:flutter/material.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/page/circle_introduction_page.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/circle_join_utils.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import '../controller/onboarding_controller.dart';
import 'private_relay_upgrade_page.dart';

enum CircleType { invite, private, custom }

class CircleSelectionPage extends StatefulWidget {
  const CircleSelectionPage({
    super.key,
    this.controller,
  });

  final OnboardingController? controller;

  @override
  State<CircleSelectionPage> createState() => _CircleSelectionPageState();
}

class _CircleSelectionPageState extends State<CircleSelectionPage> {
  bool _isProcessing = false;
  CircleType? _selectedCircleType;

  OnboardingController? get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(),
      body: _buildBody(),
      bottomWidget: _buildConnectButton(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: CLLayout.horizontalPadding,
        right: CLLayout.horizontalPadding,
        top: 24.px,
        bottom: 100.px, // Add bottom padding to avoid button overlap
      ),
      child: Column(
        children: [
          _buildHeader(),
          SizedBox(height: 32.px),
          _buildCircleOptions(),
          SizedBox(height: 24.px),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        CLText.titleLarge(
          Localized.text('ox_login.join_circle'),
          colorToken: ColorToken.onSurface,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.px),
        CLText.bodyMedium(
          Localized.text('ox_login.join_circle_subtitle'),
          colorToken: ColorToken.onSurfaceVariant,
          textAlign: TextAlign.center,
          maxLines: null,
        ),
      ],
    );
  }

  Widget _buildCircleOptions() {
    return Column(
      children: [
        _buildInviteOption(),
        SizedBox(height: 24.px),
        _buildSeparator(),
        // SizedBox(height: 24.px),
        _buildPrivateCloudOption(),
        SizedBox(height: 16.px),
        _buildCustomRelayOption(),
      ],
    );
  }

  Widget _buildInviteOption() {
    return _buildOptionCard(
      icon: Icons.link_rounded,
      iconColor: ColorToken.xChat.of(context),
      title: Localized.text('ox_login.i_have_an_invite'),
      subtitle: Localized.text('ox_login.enter_invitation_code'),
      showArrow: true,
      isSelected: _selectedCircleType == CircleType.invite,
      onTap: () => setState(() => _selectedCircleType = CircleType.invite),
    );
  }

  Widget _buildSeparator() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: ColorToken.onSurfaceVariant.of(context).withValues(alpha: 0.2),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.px),
          child: CLText.labelSmall(
            Localized.text('ox_login.or_connect_via'),
            colorToken: ColorToken.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Divider(
            color: ColorToken.onSurfaceVariant.of(context).withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivateCloudOption() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildOptionCard(
          icon: Icons.diamond_rounded,
          iconColor: Colors.purple,
          title: Localized.text('ox_login.private_cloud'),
          subtitle: Localized.text('ox_login.private_cloud_desc'),
          showArrow: false,
          isSelected: _selectedCircleType == CircleType.private,
          isRecommended: true,
          onTap: () => setState(() => _selectedCircleType = CircleType.private),
        ),
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
    );
  }

  Widget _buildCustomRelayOption() {
    return _buildOptionCard(
      icon: Icons.dns_rounded,
      iconColor: ColorToken.xChat.of(context),
      title: Localized.text('ox_login.custom_relay'),
      subtitle: Localized.text('ox_login.custom_relay_desc'),
      showArrow: true,
      isSelected: _selectedCircleType == CircleType.custom,
      onTap: () => setState(() => _selectedCircleType = CircleType.custom),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool showArrow,
    required bool isSelected,
    bool isRecommended = false,
    List<Widget>? tags,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    final borderRadius = BorderRadius.circular(16.px);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.5 : 1.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: borderRadius,
              child: Container(
                color: ColorToken.cardContainer.of(context),
                padding: EdgeInsets.all(20.px),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56.px,
                          height: 56.px,
                          decoration: BoxDecoration(
                            color: Color.lerp(iconColor, Colors.white, 0.7),
                            borderRadius: BorderRadius.circular(12.px),
                          ),
                          child: Icon(
                            icon,
                            size: 28.px,
                            color: iconColor,
                          ),
                        ),
                        SizedBox(width: 16.px),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CLText.titleMedium(
                                title,
                                colorToken: ColorToken.onSurface,
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
                        if (showArrow) ...[
                          SizedBox(width: 8.px),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16.px,
                            color: ColorToken.onSurfaceVariant.of(context),
                          ),
                        ],
                      ],
                    ),
                    if (tags != null && tags.isNotEmpty) ...[
                      SizedBox(height: 12.px),
                      Wrap(
                        spacing: 8.px,
                        runSpacing: 8.px,
                        children: tags,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: isSelected
                        ? ColorToken.xChat.of(context)
                        : ColorToken.onSurfaceVariant.of(context).withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
              ),
            )
          ],
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

  Widget _buildConnectButton() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 16.px,
      ),
      child: CLButton.filled(
        text: Localized.text('ox_login.connect'),
        onTap: _selectedCircleType != null && !_isProcessing ? _onConnectTap : null,
        expanded: true,
        height: 48.px,
      ),
    );
  }

  Future<void> _onConnectTap() async {
    if (_selectedCircleType == CircleType.invite) {
      await _onUseInvite();
    } else if (_selectedCircleType == CircleType.private) {
      await _onUsePrivateCircle();
    } else if (_selectedCircleType == CircleType.custom) {
      await _onUseCustomRelay();
    }
  }

  Future<void> _onUseInvite() async {
    // Show dialog to enter invite code
    final inviteCode = await _showInviteCodeDialog();
    if (inviteCode == null || inviteCode.isEmpty) return;

    setState(() => _isProcessing = true);
    OXLoading.show();

    try {
      if (_controller != null) {
        // Use onboarding controller for new users
        final result = await _controller!.joinPrivateCircle(
          relayUrl: inviteCode,
          context: context,
        );
        _handleOnboardingResult(result);
      } else {
        // Use CircleJoinUtils for existing users
        await CircleJoinUtils.processJoinCircle(
          input: inviteCode,
          context: context,
        );
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        CommonToast.instance.show(context, e.toString());
      }
    } finally {
      OXLoading.dismiss();
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _onUsePrivateCircle() async {
    // Navigate to payment/upgrade page as modal
    OXNavigator.pushPage(
      context,
      (context) => PrivateRelayUpgradePage(
        groupId: null, // Will be set after payment
      ),
    );
  }

  Future<void> _onUseCustomRelay() async {
    // Show dialog directly
    final relayUrl = await _showAddCircleDialog();
    if (relayUrl == null || relayUrl.isEmpty) return;

    setState(() => _isProcessing = true);
    OXLoading.show();

    try {
      if (_controller != null) {
        // Use onboarding controller for new users
        final result = await _controller!.joinPrivateCircle(
          relayUrl: relayUrl,
          context: context,
        );
        _handleOnboardingResult(result);
      } else {
        // Use CircleJoinUtils for existing users
        await CircleJoinUtils.processJoinCircle(
          input: relayUrl,
          context: context,
        );
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        CommonToast.instance.show(context, e.toString());
      }
    } finally {
      OXLoading.dismiss();
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String?> _showInviteCodeDialog() async {
    return await CLDialog.showInputDialog(
      context: context,
      title: Localized.text('ox_login.enter_invitation_code'),
      description: Localized.text('ox_login.enter_invitation_code_desc'),
      inputLabel: Localized.text('ox_login.invitation_code'),
      confirmText: Localized.text('ox_common.confirm'),
      onConfirm: (input) async {
        final trimmedInput = input.trim();
        if (trimmedInput.isEmpty) {
          CommonToast.instance.show(context, Localized.text('ox_login.invitation_code_empty'));
          return false;
        }
        return true;
      },
    );
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
      initialValue: 'damus',
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
