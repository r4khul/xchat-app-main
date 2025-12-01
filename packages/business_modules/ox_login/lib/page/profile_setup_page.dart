import 'package:flutter/material.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/avatar.dart';
import 'package:ox_localizable/ox_localizable.dart';
import '../controller/onboarding_controller.dart';
import 'circle_selection_page.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  
  final OnboardingController _onboardingController = OnboardingController(isCreateNewAccount: true);
  
  bool _hasValidInput = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_onInputChanged);
    _lastNameController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _onboardingController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    // Sync input to controller
    _onboardingController.setFirstName(_firstNameController.text);
    _onboardingController.setLastName(_lastNameController.text);
    
    // Update button state
    final hasValidInput = _onboardingController.hasValidProfile;
    if (hasValidInput != _hasValidInput) {
      setState(() {
        _hasValidInput = hasValidInput;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoseFocusWrap(
      child: CLScaffold(
        appBar: CLAppBar(),
        body: _buildBody(),
        bottomWidget: _buildNextButton(),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: EdgeInsets.symmetric(
        vertical: 24.px,
        horizontal: CLLayout.horizontalPadding,
      ),
      children: [
        _buildHeader(),
        SizedBox(height: 32.px),
        _buildAvatarPreview(),
        SizedBox(height: 24.px),
        _buildNameInput(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        CLText.titleLarge(
          Localized.text('ox_login.profile_setup_title'),
          colorToken: ColorToken.onSurface,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.px),
        CLText.bodyMedium(
          Localized.text('ox_login.profile_setup_subtitle'),
          colorToken: ColorToken.onSurfaceVariant,
          textAlign: TextAlign.center,
          maxLines: null,
        ),
      ],
    );
  }

  Widget _buildAvatarPreview() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100.px,
            height: 100.px,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ColorToken.primary.of(context).withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: OXUserAvatar(
              imageUrl: _onboardingController.avatarFile?.path,
              size: 100.px,
            ),
          ),
          SizedBox(height: 12.px),
          CLText.bodySmall(
            Localized.text('ox_login.profile_setup_avatar_hint'),
            colorToken: ColorToken.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CLTextField(
              controller: _firstNameController,
              placeholder: Localized.text('ox_login.first_name_placeholder'),
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 12.px),
            CLTextField(
              controller: _lastNameController,
              placeholder: Localized.text('ox_login.last_name_placeholder'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onNextTap(),
            ),
          ],
        ),
        SizedBox(height: 8.px),
        CLDescription(Localized.text('ox_login.profile_setup_name_hint')),
      ],
    );
  }

  Widget _buildNextButton() {
    return CLButton.filled(
      text: Localized.text('ox_common.next'),
      onTap: _hasValidInput ? _onNextTap : null,
      expanded: true,
      height: 48.px,
    );
  }

  void _onNextTap() {
    // Navigate to circle selection page with controller
    OXNavigator.pushPage(
      context,
      (context) => CircleSelectionPage(controller: _onboardingController),
    );
  }
}
