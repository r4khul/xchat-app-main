import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/scan_utils.dart';
import 'package:ox_common/widgets/common_scan_page.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:permission_handler/permission_handler.dart';

class FindPeoplePage extends StatefulWidget {
  const FindPeoplePage({super.key});

  @override
  State<FindPeoplePage> createState() => _FindPeoplePageState();
}

class _FindPeoplePageState extends State<FindPeoplePage> {
  final TextEditingController _userIdController = TextEditingController();
  final FocusNode _userIdFocusNode = FocusNode();

  @override
  void dispose() {
    _userIdController.dispose();
    _userIdFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(
        title: Localized.text('ox_chat.add_friends_to_chat'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(CLLayout.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16.px),
            
            // Privacy notice
            _buildPrivacyNotice(context),
            
            SizedBox(height: 32.px),
            
            // METHOD 1: SCAN
            _buildMethod1Scan(context),
            
            SizedBox(height: 32.px),
            
            // METHOD 2: PASTE ID
            _buildMethod2PasteId(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyNotice(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.px),
      decoration: BoxDecoration(
        color: ColorToken.surfaceContainer.of(context),
        borderRadius: BorderRadius.circular(12.px),
      ),
      child: Row(
        // crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24.px,
            height: 24.px,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: CLThemeData.themeGradientOf(context),
            ),
            child: Icon(
              PlatformStyle.isUseMaterial
                  ? Icons.help_outline
                  : CupertinoIcons.question_circle,
              size: 16.px,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12.px),
          Expanded(
            child: CLText.bodyMedium(
              Localized.text('ox_chat.find_people_privacy_notice'),
              colorToken: ColorToken.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethod1Scan(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CLText.titleMedium(
          Localized.text('ox_chat.method_1_scan'),
          colorToken: ColorToken.onSurface,
        ),
        SizedBox(height: 12.px),
        GestureDetector(
          onTap: () => _onScanQRCode(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 48.px),
            decoration: BoxDecoration(
              gradient: CLThemeData.themeGradientOf(context),
              borderRadius: BorderRadius.circular(16.px),
            ),
            child: Column(
              children: [
                Icon(
                  PlatformStyle.isUseMaterial
                      ? Icons.qr_code_scanner
                      : CupertinoIcons.qrcode_viewfinder,
                  size: 64.px,
                  color: Colors.white,
                ),
                SizedBox(height: 16.px),
                CLText.bodyLarge(
                  Localized.text('ox_chat.scan_friend_qr_code'),
                  customColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethod2PasteId(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CLText.titleMedium(
          Localized.text('ox_chat.method_2_paste_id'),
          colorToken: ColorToken.onSurface,
        ),
        SizedBox(height: 12.px),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.px),
            border: Border.all(
              color: CLThemeData.themeColorOf(context),
              width: 1.5.px,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: PlatformStyle.isUseMaterial
                    ? TextField(
                        controller: _userIdController,
                        focusNode: _userIdFocusNode,
                        decoration: InputDecoration(
                          hintText: Localized.text('ox_chat.enter_user_id'),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.px,
                            vertical: 12.px,
                          ),
                          hintStyle: TextStyle(
                            color: ColorToken.onSurfaceVariant.of(context).withOpacity(0.5),
                          ),
                        ),
                        style: TextStyle(
                          color: ColorToken.onSurface.of(context),
                          fontSize: 16.px,
                        ),
                      )
                    : CupertinoTextField(
                        controller: _userIdController,
                        focusNode: _userIdFocusNode,
                        placeholder: Localized.text('ox_chat.enter_user_id'),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.px,
                          vertical: 12.px,
                        ),
                        decoration: null,
                      ),
              ),
                    GestureDetector(
                      onTap: () async {
                        // Paste from clipboard
                        final clipboard = await Clipboard.getData('text/plain');
                        if (clipboard?.text != null) {
                          _userIdController.text = clipboard!.text!;
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.all(12.px),
                        child: Icon(
                          PlatformStyle.isUseMaterial
                              ? Icons.paste
                              : CupertinoIcons.doc_on_clipboard,
                          size: 20.px,
                          color: CLThemeData.themeColorOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        SizedBox(height: 16.px),
        CLButton.filled(
          // Use theme gradient (purple) by default when backgroundColor is null
          expanded: true,
          onTap: () => _onFindAndAdd(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PlatformStyle.isUseMaterial
                    ? Icons.person_add
                    : CupertinoIcons.person_add,
                size: 20.px,
                color: Colors.white,
              ),
              SizedBox(width: 8.px),
              CLText.bodyMedium(
                Localized.text('ox_chat.find_and_add'),
                customColor: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onScanQRCode(BuildContext context) async {
    // Check camera permission first
    if (await Permission.camera.request().isGranted) {
      // Navigate to scan page and get result
      String? result = await OXNavigator.pushPage(
        context,
        (context) => CommonScanPage(),
      );

      if (result != null && result.isNotEmpty) {
        // Use ScanUtils to analyze the scanned result
        // This will automatically handle npubkey and navigate to user detail page
        await ScanUtils.analysis(context, result);
      }
    } else {
      // Show permission dialog if camera permission is denied
      CLAlertDialog.show<bool>(
        context: context,
        content: Localized.text('ox_common.str_permission_camera_hint'),
        actions: [
          CLAlertAction.cancel(),
          CLAlertAction<bool>(
            label: Localized.text('ox_common.str_go_to_settings'),
            value: true,
            isDefaultAction: true,
          ),
        ],
      ).then((result) {
        if (result == true) {
          openAppSettings();
        }
      });
    }
  }

  void _onFindAndAdd(BuildContext context) async {
    final input = _userIdController.text.trim();
    if (input.isEmpty) {
      CommonToast.instance.show(context, Localized.text('ox_chat.enter_user_id'));
      return;
    }

    // Show loading
    OXLoading.show();

    try {
      // Use ScanUtils to analyze the input - it supports both invite links and user IDs (npub)
      // ScanUtils will automatically detect if it's an invite link or user ID
      await ScanUtils.analysis(context, input);
    } catch (e) {
      OXLoading.dismiss();
      // Check if it's an invite link to show appropriate error message
      if (input.contains('0xchat.com/x/invite') || 
          input.contains('0xchat.com/lite/invite') ||
          input.contains('www.0xchat.com/x/invite') ||
          input.contains('www.0xchat.com/lite/invite')) {
        CommonToast.instance.show(context, Localized.text('ox_common.failed_to_process_invite_link'));
      } else {
        CommonToast.instance.show(context, Localized.text('ox_common.user_not_found'));
      }
    } finally {
      // Note: ScanUtils.analysis may handle loading dismissal internally,
      // but we ensure it's dismissed here as a safety measure
      OXLoading.dismiss();
    }
  }
}

