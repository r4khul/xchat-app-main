import 'package:flutter/widgets.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_usercenter/page/settings/single_setting_page.dart';

class UserRemarkSettingsPage extends StatelessWidget {
  const UserRemarkSettingsPage({
    super.key,
    required this.user,
    this.previousPageTitle,
  });

  final UserDBISAR user;
  final String? previousPageTitle;

  @override
  Widget build(BuildContext context) {
    return SingleSettingPage(
      previousPageTitle: previousPageTitle,
      title: Localized.text('ox_chat.set_user_remark'),
      initialValue: user.nickName ?? '',
      saveAction: (context, value) => _updateUserRemark(context, value),
    );
  }

  void _updateUserRemark(BuildContext context, String newRemark) async {
    final currentRemark = user.nickName ?? '';
    if (currentRemark == newRemark) {
      OXNavigator.pop(context, true);
      return;
    }

    OXLoading.show();
    try {
      final okEvent = await Contacts.sharedInstance.updateContactNickName(
        user.pubKey,
        newRemark,
      );
      await OXLoading.dismiss();
      
      if (okEvent.status) {
        // Update allContacts and Account userCache to ensure UI refresh
        final updatedUser = await Account.sharedInstance.getUserInfo(user.pubKey, false);
        if (updatedUser != null) {
          // Update allContacts if user is in contacts
          if (Contacts.sharedInstance.allContacts.containsKey(user.pubKey)) {
            Contacts.sharedInstance.allContacts[user.pubKey] = updatedUser;
          }
          // Update Account userCache (ValueNotifier) to trigger UI refresh
          Account.sharedInstance.updateOrCreateUserNotifier(user.pubKey, updatedUser);
        }
        
        CommonToast.instance.show(context, Localized.text('ox_chat.update_remark_success'));
        OXNavigator.pop(context, true);
      } else {
        CommonToast.instance.show(context, Localized.text('ox_chat.update_remark_failed'));
      }
    } catch (e) {
      await OXLoading.dismiss();
      CommonToast.instance.show(context, Localized.text('ox_chat.update_remark_failed'));
    }
  }
}

