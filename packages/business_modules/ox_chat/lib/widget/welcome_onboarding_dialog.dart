import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/const/app_config.dart';
import 'package:ox_common/login/account_models.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/took_kit.dart';
import 'package:ox_common/utils/compression_utils.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_cache_manager/ox_cache_manager.dart';
import 'package:chatcore/chat-core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ox_chat/utils/chat_session_utils.dart';

/// Welcome onboarding dialog shown after registration or first login
class WelcomeOnboardingDialog extends StatefulWidget {
  final bool isNewRegistration;

  const WelcomeOnboardingDialog({
    super.key,
    required this.isNewRegistration,
  });

  static Future<void> show({
    required BuildContext context,
    required bool isNewRegistration,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WelcomeOnboardingDialog(
        isNewRegistration: isNewRegistration,
      ),
    );
  }

  @override
  State<WelcomeOnboardingDialog> createState() =>
      _WelcomeOnboardingDialogState();
}

class _WelcomeOnboardingDialogState extends State<WelcomeOnboardingDialog> {
  int _currentStep = 0;
  bool _isPrivateKeyRevealed = false;
  String? _publicKey;
  String? _privateKey;
  String? _inviteLink;
  bool _isLoadingInviteLink = false;
  late PageController _pageController;

  // Steps to show based on registration type
  List<int> get _stepsToShow {
    if (widget.isNewRegistration) {
      // New registration: show all 4 steps
      return [0, 1, 2, 3];
    } else {
      // First login: show only step 0 and 3
      return [0, 3];
    }
  }

  @override
  void initState() {
    super.initState();
    _loadKeys();
    if (!widget.isNewRegistration) {
      // For first login, skip to step 3 (index 1 in _stepsToShow)
      _currentStep = 1;
    }
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadKeys() async {
    try {
      final account = LoginManager.instance.currentState.account;
      if (account == null) return;

      _publicKey = account.getEncodedPubkey();
      _privateKey = await account.getEncodedPrivkey();
      setState(() {});
    } catch (e) {
      debugPrint('Error loading keys: $e');
    }
  }

  Future<void> _generateInviteLink() async {
    if (_inviteLink != null) return;

    setState(() {
      _isLoadingInviteLink = true;
    });

    try {
      OXLoading.show();

      // Get relay URL
      List<String> relays = Account.sharedInstance.getCurrentCircleRelay();
      if (relays.isEmpty) {
        await OXLoading.dismiss();
        setState(() {
          _isLoadingInviteLink = false;
        });
        if (mounted) {
          CommonToast.instance.show(context, 'Error circle info');
        }
        return;
      }

      // Create permanent key package
      final keyPackageEvent =
          await Groups.sharedInstance.createPermanentKeyPackage(relays);

      if (keyPackageEvent == null) {
        await OXLoading.dismiss();
        setState(() {
          _isLoadingInviteLink = false;
        });
        if (mounted) {
          // Check if it's a keypackage expiration issue
          // Show dialog asking if user wants to refresh their keypackage
          final shouldRefresh = await CLAlertDialog.show<bool>(
            context: context,
            title: Localized.text('ox_chat.key_package_expired'),
            content: Localized.text('ox_chat.key_package_may_expired'),
            actions: [
              CLAlertAction.cancel(),
              CLAlertAction<bool>(
                label: Localized.text('ox_chat.refresh'),
                value: true,
                isDefaultAction: true,
              ),
            ],
          );

          if (shouldRefresh == true) {
            // Refresh keypackage and retry
            await Groups.sharedInstance.recreatePermanentKeyPackage(relays);
            // Retry generating invite link
            await _generateInviteLink();
          }
        }
        return;
      }

      String? relayUrl = relays.firstOrNull;
      if (relayUrl == null || relayUrl.isEmpty) {
        await OXLoading.dismiss();
        setState(() {
          _isLoadingInviteLink = false;
        });
        if (mounted) {
          CommonToast.instance.show(context, 'Error circle info');
        }
        return;
      }

      // Generate invite link with compression (same as qr_code_display_page.dart)
      final senderPubkey = Account.sharedInstance.currentPubkey;

      // Try to compress the keypackage data
      String? compressedKeyPackage = await CompressionUtils.compressWithPrefix(
          keyPackageEvent.encoded_key_package);
      String keyPackageParam =
          compressedKeyPackage ?? keyPackageEvent.encoded_key_package;

      _inviteLink =
          '${AppConfig.inviteBaseUrl}?keypackage=$keyPackageParam&pubkey=${Uri.encodeComponent(senderPubkey)}&relay=${Uri.encodeComponent(relayUrl)}';

      // Log compression results
      if (compressedKeyPackage != null) {
        double ratio = CompressionUtils.getCompressionRatio(
            keyPackageEvent.encoded_key_package, compressedKeyPackage);
        debugPrint(
            'Keypackage compressed: ${(ratio * 100).toStringAsFixed(1)}% of original size');
      }

      await OXLoading.dismiss();
    } catch (e) {
      await OXLoading.dismiss();
      debugPrint('Error generating invite link: $e');
      if (mounted) {
        // Handle KeyPackageError
        final handled = await ChatSessionUtils.handleKeyPackageError(
          context: context,
          error: e,
          onRetry: () async {
            // Retry generating invite link
            await _generateInviteLink();
          },
          onOtherError: (message) {
            CommonToast.instance.show(context,
                '${Localized.text('ox_usercenter.invite_link_generation_failed')}: $e');
          },
        );

        if (!handled) {
          // Other errors
          CommonToast.instance.show(context,
              '${Localized.text('ox_usercenter.invite_link_generation_failed')}: $e');
        }
      }
    } finally {
      setState(() {
        _isLoadingInviteLink = false;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < _stepsToShow.length - 1) {
      final nextStep = _currentStep + 1;
      _pageController
          .animateToPage(
        nextStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        setState(() {
          _currentStep = nextStep;
          if (_stepsToShow[_currentStep] == 3) {
            // Step 3: Start Connecting - generate invite link
            _generateInviteLink();
          }
        });
      });
    } else {
      _complete();
    }
  }

  void _skip() {
    _complete();
  }

  void _complete() {
    // Mark onboarding as completed
    final pubkey = LoginManager.instance.currentPubkey;
    if (pubkey.isNotEmpty) {
      OXCacheManager.defaultOXCacheManager.saveForeverData(
        '${pubkey}_welcome_onboarding_completed',
        true,
      );
    }
    Navigator.of(context).pop();
  }

  void _copyPublicKey() {
    if (_publicKey != null) {
      TookKit.copyKey(context, _publicKey!);
    }
  }

  void _copyPrivateKey() {
    if (_privateKey != null) {
      TookKit.copyKey(context, _privateKey!);
    }
  }

  void _shareInviteLink() {
    if (_inviteLink != null) {
      Share.share(_inviteLink!);
    }
  }

  double _getStepHeight() {
    final stepIndex = _stepsToShow[_currentStep];
    // First step (welcome) uses adaptive height, others use fixed 400.px
    if (stepIndex == 0) {
      return 280.px; // Smaller height for welcome step
    }
    return 400.px; // Fixed height for other steps
  }

  Widget _buildProgressBar() {
    final totalSteps = _stepsToShow.length;
    final progress = (_currentStep + 1) / totalSteps;

    return Container(
      height: 4.px,
      margin: EdgeInsets.only(bottom: 24.px),
      decoration: BoxDecoration(
        color: ColorToken.surfaceContainer.of(context),
        borderRadius: BorderRadius.circular(2.px),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: ColorToken.xChat.of(context),
            borderRadius: BorderRadius.circular(2.px),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContentForIndex(int index) {
    final stepIndex = _stepsToShow[index];

    switch (stepIndex) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildPublicKeyStep();
      case 2:
        return _buildPrivateKeyStep();
      case 3:
        return _buildStartConnectingStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Shield icon
          Container(
            width: 120.px,
            height: 120.px,
            decoration: BoxDecoration(
              color: ColorToken.xChat.of(context).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield,
              size: 64.px,
              color: ColorToken.xChat.of(context),
            ),
          ),
          SizedBox(height: 24.px),
          // Title
          CLText.titleLarge(
            Localized.text('ox_chat.welcome_to_xchat'),
            textAlign: TextAlign.center,
            isBold: true,
          ),
          SizedBox(height: 12.px),
          // Description
          CLText.bodyMedium(
            Localized.text('ox_chat.welcome_description'),
            textAlign: TextAlign.center,
            colorToken: ColorToken.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildPublicKeyStep() {
    final displayKey = _publicKey ?? '';

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ID icon
          Container(
            width: 120.px,
            height: 120.px,
            decoration: BoxDecoration(
              color: ColorToken.xChat.of(context).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: ColorToken.xChat.of(context).withOpacity(0.3),
                width: 2.px,
              ),
            ),
            child: Center(
              child: CLText.titleLarge(
                'ID',
                customColor: ColorToken.xChat.of(context),
                isBold: true,
              ),
            ),
          ),
          SizedBox(height: 32.px),
          // Title
          CLText.titleLarge(
            Localized.text('ox_chat.your_public_identity'),
            textAlign: TextAlign.center,
            isBold: true,
          ),
          SizedBox(height: 16.px),
          // Description
          CLText.bodyMedium(
            Localized.text('ox_chat.public_identity_description'),
            textAlign: TextAlign.center,
            colorToken: ColorToken.onSurfaceVariant,
          ),
          SizedBox(height: 32.px),
          // Public key display
          Container(
            padding: EdgeInsets.all(16.px),
            decoration: BoxDecoration(
              color: ColorToken.surfaceContainer.of(context),
              borderRadius: BorderRadius.circular(12.px),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CLText.bodySmall(
                        Localized.text('ox_chat.public_key_label'),
                        colorToken: ColorToken.onSurfaceVariant,
                      ),
                      SizedBox(height: 8.px),
                      CLText.bodySmall(
                        displayKey,
                        maxLines: null,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.px),
                GestureDetector(
                  onTap: _copyPublicKey,
                  child: Container(
                    padding: EdgeInsets.all(8.px),
                    child: Icon(
                      Icons.copy_all,
                      size: 20.px,
                      color: ColorToken.onSurfaceVariant.of(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateKeyStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Key icon
          Container(
            width: 120.px,
            height: 120.px,
            decoration: BoxDecoration(
              color: ColorToken.xChat.of(context).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.vpn_key,
              size: 64.px,
              color: ColorToken.xChat.of(context),
            ),
          ),
          SizedBox(height: 32.px),
          // Title
          CLText.titleLarge(
            Localized.text('ox_chat.your_secret_key'),
            textAlign: TextAlign.center,
            isBold: true,
          ),
          SizedBox(height: 16.px),
          // Description
          CLText.bodyMedium(
            Localized.text('ox_chat.secret_key_description'),
            textAlign: TextAlign.center,
            colorToken: ColorToken.onSurfaceVariant,
          ),
          SizedBox(height: 32.px),
          // Private key display
          Container(
            padding: EdgeInsets.all(16.px),
            decoration: BoxDecoration(
              color: ColorToken.surfaceContainer.of(context),
              borderRadius: BorderRadius.circular(12.px),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CLText.bodySmall(
                            Localized.text('ox_chat.private_key_label'),
                            colorToken: ColorToken.onSurfaceVariant,
                          ),
                          SizedBox(width: 8.px),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.px, vertical: 4.px),
                            decoration: BoxDecoration(
                              color: ColorToken.xChat.of(context),
                              borderRadius: BorderRadius.circular(12.px),
                            ),
                            child: CLText.bodySmall(
                              Localized.text('ox_chat.do_not_share'),
                              customColor: Colors.white,
                              isBold: true,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.px),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPrivateKeyRevealed = !_isPrivateKeyRevealed;
                          });
                        },
                        child: _isPrivateKeyRevealed
                            ? CLText.bodySmall(
                                _privateKey ?? '',
                                maxLines: null,
                              )
                            : Row(
                                children: [
                                  Icon(
                                    Icons.visibility,
                                    size: 16.px,
                                    color:
                                        ColorToken.onSurfaceVariant.of(context),
                                  ),
                                  SizedBox(width: 8.px),
                                  Flexible(
                                    child: CLText.bodySmall(
                                      Localized.text('ox_chat.tap_to_reveal'),
                                      colorToken: ColorToken.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.px),
                if (_isPrivateKeyRevealed && _privateKey != null)
                  GestureDetector(
                    onTap: _copyPrivateKey,
                    child: Container(
                      padding: EdgeInsets.all(8.px),
                      child: Icon(
                        Icons.copy_all,
                        size: 20.px,
                        color: ColorToken.onSurfaceVariant.of(context),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartConnectingStep() {
    // Generate invite link after build completes
    if (_isLoadingInviteLink && _inviteLink == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _generateInviteLink();
        }
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
            // Share icon
            Container(
              width: 120.px,
              height: 120.px,
              decoration: BoxDecoration(
                color: ColorToken.xChat.of(context).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.share,
                size: 64.px,
                color: ColorToken.xChat.of(context),
              ),
            ),
            SizedBox(height: 28.px),
            // Title
            CLText.titleLarge(
              Localized.text('ox_chat.start_connecting'),
              textAlign: TextAlign.center,
              isBold: true,
            ),
            SizedBox(height: 14.px),
            // Description
            CLText.bodyMedium(
              Localized.text('ox_chat.start_connecting_description'),
              textAlign: TextAlign.center,
              colorToken: ColorToken.onSurfaceVariant,
            ),
            SizedBox(height: 24.px),
            // Hint text
            CLText.bodySmall(
              Localized.text('ox_chat.invite_friends_hint'),
              textAlign: TextAlign.center,
              colorToken: ColorToken.onSurfaceVariant,
            ),
            SizedBox(height: 16.px),
            // Share Invite Link button
            CLButton.filled(
              text: Localized.text('ox_chat.share_invite_link'),
              onTap: _inviteLink != null ? _shareInviteLink : null,
              expanded: true,
            ),
            // Get Started button
            CLButton.text(
              text: Localized.text('ox_chat.get_started'),
              onTap: _complete,
              expanded: true,
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.px),
      child: Container(
        padding: EdgeInsets.all(24.px),
        decoration: BoxDecoration(
          color: ColorToken.surface.of(context),
          borderRadius: BorderRadius.circular(20.px),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            _buildProgressBar(),
            // Step content with PageView for slide animation
            Flexible(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _getStepHeight(),
                child: PageView.builder(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable manual swiping
                  itemCount: _stepsToShow.length,
                  itemBuilder: (context, index) {
                    return _buildStepContentForIndex(index);
                  },
                ),
              ),
            ),
            SizedBox(height: 32.px),
            // Next button (not shown on last step)
            if (_currentStep < _stepsToShow.length - 1)
              CLButton.filled(
                text: Localized.text('ox_chat.next'),
                onTap: _nextStep,
                expanded: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CLText(
                      Localized.text('ox_chat.next'),
                      customColor: Colors.white,
                    ),
                    SizedBox(width: 8.px),
                    Icon(
                      Icons.arrow_forward,
                      size: 20.px,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            // Skip button (not shown on last step)
            if (_currentStep < _stepsToShow.length - 1) ...[
              SizedBox(height: 12.px),
              GestureDetector(
                onTap: _skip,
                child: CLText.bodySmall(
                  Localized.text('ox_chat.skip_setup'),
                  textAlign: TextAlign.center,
                  colorToken: ColorToken.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
