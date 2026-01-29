import 'package:flutter/material.dart';
import 'package:ox_common/login/login_models.dart';

// common
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_common/utils/nip46_status_notifier.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_login/utils/circle_entry_helper.dart';
import 'package:ox_common/component.dart';

// plugin
import 'package:ox_localizable/ox_localizable.dart';
import 'package:chatcore/chat-core.dart';

// local
import '../controller/onboarding_controller.dart';
import 'circle_selection_page.dart';
import 'nostr_introduction_page.dart';

class AccountKeyLoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AccountKeyLoginPageState();
  }
}

class _AccountKeyLoginPageState extends State<AccountKeyLoginPage> with LoginManagerObserver {
  final OnboardingController _onboardingController = OnboardingController(isCreateNewAccount: false);

  TextEditingController _accountKeyEditingController = new TextEditingController();
  bool _isShowLoginBtn = false;
  String _accountKeyInput = '';
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _accountKeyEditingController.addListener(_checkAccountKey);
    LoginManager.instance.addObserver(this);
  }

  @override
  void dispose() {
    LoginManager.instance.removeObserver(this);
    _onboardingController.dispose();
    _accountKeyEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(
        title: Localized.text('ox_login.login_button'),
      ),
      body: LoseFocusWrap(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(30.px, 32.px, 30.px, 120.px), // bottom padding to avoid overlap with button
          children: [
            _buildKeyInputView(),
          ]
        ),
        Positioned(
          left: 30.px,
          right: 30.px,
          bottom: 24.px,
          child: SafeArea(
            child: CLButton.filled(
              text: _isLoggingIn ? Localized.text('ox_common.loading') : Localized.text('ox_login.login_button'),
              onTap: _isShowLoginBtn && !_isLoggingIn ? _loginButtonOnTap : null,
              expanded: true,
              height: 48.px,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyInputView() {
    final inputStr = _accountKeyEditingController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add title and description
        CLText.headlineSmall(
          Localized.text('ox_login.enter_account_key_login_hint'),
          colorToken: ColorToken.onSurface,
        ),
        SizedBox(height: 16.px),
        
        // Input field with improved placeholder
        CLTextField(
          controller: _accountKeyEditingController,
          placeholder: Localized.text('ox_login.account_key_placeholder'),
          maxLines: null,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            _checkAccountKey();
            if (_accountKeyInput.isNotEmpty && !_isLoggingIn) {
              _loginButtonOnTap();
            }
          },
        ),
        
        SizedBox(height: 12.px),

        // Simple section footer with "Learn More" link
        CLDescription.forSectionFooter(
          '${Localized.text('ox_login.enter_nostr_key_or_remote_signer')} ${Localized.text('ox_login.learn_more')}',
          rules: [
            CLHighlightRule(
              pattern: Localized.text('ox_login.learn_more'),
              onTap: (_) => _showNostrExplanationDialog(context),
            ),
          ],
        ),
        
        SizedBox(height: 8.px),
        
        // Error hint for invalid nsec
        if (!_isShowLoginBtn && inputStr.trim().startsWith('nsec') && inputStr.length >= 63)
          CLText.bodySmall(
            Localized.text('ox_login.str_nesc_invalid_hint'),
            colorToken: ColorToken.error,
          ),
      ],
    );
  }

  void _checkAccountKey() {
    if (_isLoggingIn) return;
    
    String textContent = _accountKeyEditingController.text.trim();
    if (textContent.startsWith('bunker://')){
      _isShowLoginBtn = true;
      _accountKeyInput = textContent;
    } else {
      if (textContent.length >= 63) {
        final String? decodeResult = UserDBISAR.decodePrivkey(textContent);
        if (decodeResult == null || decodeResult.isEmpty) {
          _isShowLoginBtn = false;
        } else {
          _accountKeyInput = decodeResult;
          _isShowLoginBtn = true;
        }
      } else {
        _isShowLoginBtn = false;
      }
    }
    setState(() {});
  }

  void _loginButtonOnTap() async {
    if (_isLoggingIn || _accountKeyInput.isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoggingIn = true;
    });

    final isSuccess = await _loginWithKey();
    if (mounted && !isSuccess) {
      setState(() {
        _isLoggingIn = false;
      });
    }
  }

  Future<void> loginHandler() async {
    final account = LoginManager.instance.currentState.account;
    if (account == null || account.circles.isNotEmpty) {
      OXNavigator.popToRoot(context);
      return;
    }

    _onboardingController.loginAction = _loginWithKey;

    final didNavigateToRestore = await CircleEntryHelper.tryNavigateToCircleRestoreIfNeeded(
        context,
        controller: _onboardingController,
      );
    if (!mounted) return;
    if (didNavigateToRestore) return;

    OXNavigator.pushPage(
      context,
      (_) => CircleSelectionPage(
        controller: _onboardingController,
      ),
    );
  }


  Future<bool> _loginWithKey() async {
    if (_accountKeyInput.startsWith('bunker://')) {
      // Handle NIP-46 login
      return _loginWithNip46();
    } else {
      // Handle private key login with LoginManager
      return LoginManager.instance.loginWithPrivateKey(_accountKeyInput);
    }
  }

  Future<bool> _loginWithNip46() async {
    try {
      bool result = await NIP46StatusNotifier.remoteSignerTips(Localized.text('ox_login.wait_link_service'));
      if (!result) {
        return false;
      }

      // Use LoginManager for NIP-46 login
      return await LoginManager.instance.loginWithNostrConnect(_accountKeyInput);
    } catch (e) {
      debugPrint('NIP-46 login failed: $e');
      if (mounted) {
        CommonToast.instance.show(context, 'Login failed: ${e.toString()}');
      }
      return false;
    }
  }

  @override
  void onLoginSuccess(LoginState state) {
    setState(() {
      _isLoggingIn = false;
    });

    loginHandler();
  }

  @override
  void onLoginFailure(LoginFailure failure) {
    setState(() {
      _isLoggingIn = false;
    });
    
    if (!mounted) return;
    
    // Show error message based on failure type
    String errorMessage;
    switch (failure.type) {
      case LoginFailureType.invalidKeyFormat:
        errorMessage = Localized.text('ox_login.private_key_regular_failed');
        break;
      case LoginFailureType.errorEnvironment:
        errorMessage = 'Environment error: ${failure.message}';
        break;
      case LoginFailureType.accountDbFailed:
        errorMessage = 'Failed to initialize account database';
        break;
      case LoginFailureType.circleDbFailed:
        errorMessage = 'Failed to initialize circle database';
        break;
    }
    
    CommonToast.instance.show(context, errorMessage);
  }

  /// Show dialog explaining Nostr concepts
  void _showNostrExplanationDialog(BuildContext context) {
    OXNavigator.pushPage(
      context,
      (context) => const NostrIntroductionPage(),
      type: OXPushPageType.present,
    );
  }
}
