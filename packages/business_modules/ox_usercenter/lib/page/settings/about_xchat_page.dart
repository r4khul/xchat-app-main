import 'package:flutter/cupertino.dart';
import 'package:ox_chat/widget/welcome_onboarding_dialog.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/purchase/purchase_manager.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_module_service/ox_module_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ox_usercenter/user_feedback/app_review_manager.dart';

class AboutXChatPage extends StatefulWidget {
  final String previousPageTitle;

  const AboutXChatPage({
    super.key,
    required this.previousPageTitle,
  });

  @override
  State<AboutXChatPage> createState() => _AboutXChatPageState();
}

class _AboutXChatPageState extends State<AboutXChatPage> {
  String get title => Localized.text('ox_usercenter.about_xchat');
  
  late ValueNotifier<String> versionItemNty;

  @override
  void initState() {
    super.initState();
    _prepareData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppReviewManager.instance.onEnterAboutPage();
    });
  }

  void _prepareData() {
    versionItemNty = ValueNotifier<String>('');
    _loadAppVersion();
  }

  @override
  void dispose() {
    versionItemNty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(title: title),
      isSectionListPage: true,
      body: CLSectionListView(
        items: [
          SectionListViewItem(data: [
            LabelItemModel(
              icon: ListViewIcon.data(CupertinoIcons.chat_bubble_2),
              title: Localized.text('ox_usercenter.contact_us'),
              onTap: _contactUsOnTap,
            )
          ]),

          SectionListViewItem(
            header: Localized.text('ox_usercenter.about_xchat'),
            data: [
              LabelItemModel(
                icon: ListViewIcon(
                  iconName: 'icon_setting_version.png',
                  package: 'ox_usercenter',
                ),
                title: Localized.text('ox_usercenter.version'),
                value$: versionItemNty,
              ),
              LabelItemModel(
                icon: ListViewIcon.data(CupertinoIcons.link),
                title: 'GitHub',
                onTap: _githubProjectOnTap,
              ),
              LabelItemModel(
                icon: ListViewIcon.data(CupertinoIcons.doc_text),
                title: Localized.text('ox_login.terms_of_service'),
                onTap: _termsOfServiceOnTap,
              ),
              LabelItemModel(
                icon: ListViewIcon.data(CupertinoIcons.shield),
                title: Localized.text('ox_login.privacy_policy'),
                onTap: _privacyPolicyOnTap,
              ),
              LabelItemModel(
                icon: ListViewIcon.data(CupertinoIcons.book),
                title: Localized.text('ox_usercenter.show_welcome_guide'),
                onTap: _showWelcomeGuideOnTap,
              ),
              LabelItemModel(
                icon: ListViewIcon.data(CupertinoIcons.arrow_2_circlepath),
                title: Localized.text('ox_usercenter.restore_purchases'),
                onTap: _restorePurchasesOnTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _restorePurchasesOnTap() async {
    try {
      // Show a single loading while performing restore.
      OXLoading.show(status: Localized.text('ox_usercenter.restoring_purchases'));

      final results = await PurchaseManager.instance.restorePurchases();
      if (!mounted) return;
      await OXLoading.dismiss();

      final successes = results.where((r) => r.success).toList();
      final failures = results.where((r) => !r.success).toList();

      final realFailures = failures.where(
        (r) {
          final msg = (r.errorMessage ?? '').trim();
          if (msg.isEmpty) return false;
          return msg != 'No purchase to restore for this product';
        },
      ).toList();

      var message = '';
      if (successes.isNotEmpty) {
        message = Localized.text('ox_usercenter.restore_purchases_success');
      } else if (realFailures.isNotEmpty) {
        final firstError = realFailures.first;
        message =  firstError.errorMessage
            ?? 'Failed to restore purchases. Please try again.';
      } else if (results.any((r) => r.isAlreadyRestored)) {
        message = Localized.text('ox_usercenter.restore_purchases_already_restored');
      } else {
        message = 'No purchases found to restore';
      }

      await CLAlertDialog.show<bool>(
        context: context,
        content: message,
        actions: [CLAlertAction.ok()],
      );
    } catch (e) {
      if (mounted) {
        await OXLoading.dismiss();
        CommonToast.instance.show(
          context,
          'Failed to restore purchases: $e',
        );
      }
    } finally {
      // Ensure loading is dismissed even if we returned early.
      await OXLoading.dismiss();
    }
  }

  void _contactUsOnTap() {
    const contactUrl = 'https://primal.net/p/nprofile1qqs9ajjs5p904ml92evlkayppdpx2n3zdrq6ejnw2wqphxrzmd62swswfwcse';
    
    try {
      OXModuleService.invoke('ox_common', 'gotoWebView', [
        context, 
        contactUrl, 
        null, 
        null, 
        null, 
        null
      ]);
    } catch (e) {
      CommonToast.instance.show(context, 'Failed to open contact page: $e');
    }
  }

  void _termsOfServiceOnTap() {
    OXModuleService.invoke('ox_common', 'gotoWebView', [
      context,
      'https://0xchat.com/protocols/xchat-terms-of-use.html',
      null,
      null,
      null,
      null
    ]);
  }

  void _privacyPolicyOnTap() {
    OXModuleService.invoke('ox_common', 'gotoWebView', [
      context,
      'https://0xchat.com/protocols/xchat-privacy-policy.html',
      null,
      null,
      null,
      null
    ]);
  }

  void _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final String version = packageInfo.version;
      final String buildNumber = packageInfo.buildNumber;
      versionItemNty.value = '$version+$buildNumber';
    } catch (_) {
      versionItemNty.value = '';
    }
  }

  void _githubProjectOnTap() {
    const githubUrl = 'https://github.com/0xchat-app/xchat-app-main';
    
    try {
      OXModuleService.invoke('ox_common', 'gotoWebView', [
        context, 
        githubUrl, 
        null, 
        null, 
        null, 
        null
      ]);
    } catch (e) {
      CommonToast.instance.show(context, 'Failed to open GitHub project: $e');
    }
  }

  void _showWelcomeGuideOnTap() {
    // Show welcome onboarding dialog
    // For manual trigger, we show all steps (as if it's a new registration)
    WelcomeOnboardingDialog.show(
      context: context,
      isNewRegistration: true,
    );
  }
}
