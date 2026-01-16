import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/circle_join_utils.dart';
import 'package:ox_common/utils/string_utils.dart';
import 'package:ox_common/widgets/avatar.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_usercenter/page/settings/about_xchat_page.dart';
import 'package:ox_usercenter/page/settings/notification_settings_page.dart';
import 'package:ox_usercenter/page/settings/advanced_settings_page.dart';

import 'circle_detail_page.dart';
import 'profile_settings_page.dart';
import 'settings_detail_page.dart';
import 'qr_code_display_page.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_login/page/circle_selection_page.dart' show CircleSelectionPage;

class SettingSlider extends StatefulWidget {
  const SettingSlider({super.key});

  @override
  State<StatefulWidget> createState() => SettingSliderState();
}

class SettingSliderState extends State<SettingSlider> {

  String get title => Localized.text('ox_usercenter.str_settings');

  late LoginUserNotifier userNotifier;
  late List<SectionListViewItem> pageData;

  @override
  void initState() {
    super.initState();

    prepareData();
  }

  void prepareData() {
    prepareLiteData();
    userNotifier = LoginUserNotifier.instance;
  }

  void prepareLiteData() {
    // Build first section items
    List<ListViewItem> firstSectionItems = [
      CustomItemModel(
        customWidgetBuilder: buildUserInfoWidget,
      ),
    ];
    
    // // Only add circle settings when user has a circle
    // if (hasCircle) {
    //   firstSectionItems.add(
    //     LabelItemModel(
    //       icon: ListViewIcon(iconName: 'icon_setting_circles.png', package: 'ox_usercenter'),
    //       title: Localized.text('ox_usercenter.circle_settings'),
    //       onTap: circleItemOnTap,
    //     ),
    //   );
    // }
    
    // Build circles section
    final account = LoginManager.instance.currentState.account;
    final circles = account?.circles ?? [];
    final currentCircle = LoginManager.instance.currentCircle;
    
    List<SectionListViewItem> sections = [
      SectionListViewItem(data: firstSectionItems),
    ];
    
    // Add CIRCLES section if there are any circles
    if (circles.isNotEmpty) {
      final circleItems = circles.map((circle) => _buildCircleItem(circle, currentCircle)).toList();
      
      // Add "Add a Circle" button item
      circleItems.add(
        CustomItemModel(
          customWidgetBuilder: buildAddCircleButton,
        ),
      );
      
      sections.add(
        SectionListViewItem(
          headerWidget: _buildCirclesSectionHeader(),
          data: circleItems,
        ),
      );
    } else {
      // If no circles, show add circle button in a separate section
      sections.add(
        SectionListViewItem(
          headerWidget: _buildCirclesSectionHeader(),
          data: [
            CustomItemModel(
              customWidgetBuilder: buildAddCircleButton,
            ),
          ],
        ),
      );
    }
    
    // Add PREFERENCES section (Preferences, Notifications, Advanced)
    sections.add(
      SectionListViewItem(
        data: [
          LabelItemModel(
            icon: ListViewIcon(iconName: 'icon_setting_theme.png', package: 'ox_usercenter'),
            title: Localized.text('ox_usercenter.preferences'),
            onTap: settingsItemOnTap,
          ),
          LabelItemModel(
            icon: ListViewIcon(iconName: 'icon_setting_notification.png', package: 'ox_usercenter'),
            title: Localized.text('ox_usercenter.notification'),
            onTap: notificationItemOnTap,
          ),
          LabelItemModel(
            icon: ListViewIcon.data(CupertinoIcons.gear_alt),
            title: Localized.text('ox_usercenter.advanced_settings'),
            onTap: advancedItemOnTap,
          ),
        ],
      ),
    );
    
    // Add HELP section
    sections.add(
      SectionListViewItem(
        data: [
          LabelItemModel(
            icon: ListViewIcon.data(CupertinoIcons.info),
            title: Localized.text('ox_usercenter.about_xchat'),
            onTap: aboutXChatItemOnTap,
          ),
        ],
      ),
    );
    
    pageData = sections;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: PlatformStyle.isUseMaterial ? null : CLAppBar(title: title),
      isSectionListPage: true,
      body: buildBody(),
    );
  }

  Widget buildBody() {
    return ValueListenableBuilder(
      valueListenable: LoginManager.instance.state$,
      builder: (context, loginState, _) {
        // Rebuild data when circle state changes
        prepareLiteData();
        return CLSectionListView(
          items: pageData,
        );
      },
    );
  }

  Widget _buildCirclesSectionHeader() {
    final title = Localized.text('ox_common.circles').toUpperCase();
    Widget widget = CLText.titleSmall(title);
    if (PlatformStyle.isUseMaterial) {
      widget = Padding(
        padding: EdgeInsets.only(
          left: 20.px,
          top: 16.px,
        ),
        child: widget,
      );
    }
    return widget;
  }


  ListViewItem _buildCircleItem(Circle circle, Circle? currentCircle) {
    return CustomItemModel(
      customWidgetBuilder: (context) => _buildCircleItemWidget(context, circle, currentCircle),
    );
  }

  Widget _buildCircleItemWidget(BuildContext context, Circle circle, Circle? currentCircle) {
    final isSelected = circle.id == currentCircle?.id;
    
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _onCircleTap(circle),
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: CLLayout.horizontalPadding,
          vertical: 12.px,
        ),
        child: Row(
          children: [
            // Circle avatar
            CircleAvatar(
              radius: 20.px,
              backgroundColor: isSelected 
                ? ColorToken.primaryContainer.of(context)
                : ColorToken.surfaceContainer.of(context),
              child: Text(
                circle.name.isNotEmpty ? circle.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: isSelected
                    ? ColorToken.onPrimaryContainer.of(context)
                    : ColorToken.onSurfaceVariant.of(context),
                  fontSize: 16.px,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: 12.px),
            // Circle name and relay URL
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CLText.bodyLarge(
                    circle.name,
                    isBold: true,
                  ),
                  if (circle.type != CircleType.bitchat)
                    CLText.bodyMedium(
                      circle.relayUrl,
                      colorToken: ColorToken.onSurfaceVariant,
                    ),
                ],
              ),
            ),
            // Selected indicator and settings icon
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Padding(
                    padding: EdgeInsets.only(right: 8.px),
                    child: Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: ColorToken.primary.of(context),
                      size: 24.px,
                    ),
                  ),
                GestureDetector(
                  onTap: () => _onCircleSettingsTap(circle),
                  child: Icon(
                    CupertinoIcons.gear,
                    color: ColorToken.onSurfaceVariant.of(context),
                    size: 20.px,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAddCircleButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: addCircleItemOnTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: CLLayout.horizontalPadding,
          vertical: 12.px,
        ),
        child: Row(
          children: [
            Container(
              width: 40.px,
              height: 40.px,
              decoration: BoxDecoration(
                color: ColorToken.primaryContainer.of(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.add,
                color: ColorToken.onPrimaryContainer.of(context),
                size: 20.px,
              ),
            ),
            SizedBox(width: 12.px),
            Expanded(
              child: CLText.bodyLarge(
                Localized.text('ox_home.add_circle'),
                colorToken: ColorToken.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUserInfoWidget(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: LoginManager.instance.state$,
      builder: (context, loginState, _) {
        final circle = loginState.currentCircle;
        final hasCircle = circle != null;
        
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: profileItemOnTap,
          child: Container(
            height: 72.px,
            margin: EdgeInsets.symmetric(vertical: 12.px),
            child: Row(
              children: [
                // Avatar area
                Container(
                  width: 60.px,
                  height: 60.px,
                  margin: EdgeInsets.symmetric(horizontal: CLLayout.horizontalPadding),
                  child: hasCircle
                    ? ValueListenableBuilder(
                        valueListenable: userNotifier.userInfo$,
                        builder: (context, userInfo, _) {
                          return OXUserAvatar(
                            user: userInfo,
                            size: 60.px,
                          );
                        }
                      )
                    : CircleAvatar(
                        radius: 30.px,
                        backgroundColor: ColorToken.surfaceContainer.of(context),
                        child: Icon(
                          CupertinoIcons.person,
                          size: 30.px,
                          color: ColorToken.onSurfaceVariant.of(context),
                        ),
                      ),
                ),
                // Content area
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: hasCircle
                      ? [
                          // Show actual user info when logged in circle
                          ValueListenableBuilder(
                            valueListenable: userNotifier.name$,
                            builder: (context, name, _) {
                              return CLText.bodyLarge(name);
                            }
                          ),
                          ValueListenableBuilder(
                            valueListenable: userNotifier.encodedPubkey$,
                            builder: (context, encodedPubkey, _) {
                              return CLText.bodyMedium(encodedPubkey.truncate(20));
                            }
                          ),
                        ]
                      : [
                          // Show guide info when no circle
                          CLText.bodyLarge(
                            Localized.text('ox_usercenter.profile'),
                          ),
                          CLText.bodyMedium(
                            Localized.text('ox_home.join_or_create_circle_now'),
                          ),
                        ],
                  ),
                ),
                // Trailing - QR code button
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: GestureDetector(
                    onTap: inviteItemOnTap,
                    child: Icon(
                      CupertinoIcons.qrcode,
                      color: ColorToken.onSurfaceVariant.of(context),
                      size: 24.px,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void circleItemOnTap() {
    final circle = LoginManager.instance.currentCircle;
    if (circle == null) return;

    OXNavigator.pushPage(context, (_) => CircleDetailPage(
      previousPageTitle: title,
      circle: circle,
    ));
  }

  void _onCircleTap(Circle circle) async {
    final currentCircle = LoginManager.instance.currentCircle;
    if (currentCircle?.id == circle.id) {
      // Already selected, do nothing
      return;
    }

    // Show confirmation dialog
    final shouldSwitch = await CLAlertDialog.show<bool>(
      context: context,
      title: Localized.text('ox_usercenter.switch_circle_confirm_title'),
      content: Localized.text('ox_usercenter.switch_circle_confirm_content'),
      actions: [
        CLAlertAction.cancel(),
        CLAlertAction<bool>(
          label: Localized.text('ox_common.confirm'),
          value: true,
        ),
      ],
    );

    if (!mounted || shouldSwitch != true) {
      return;
    }

    OXLoading.show();
    try {
      final failure = await LoginManager.instance.switchToCircle(circle);
      OXLoading.dismiss();

      if (failure != null) {
        CommonToast.instance.show(context, failure.message);
      } else {
        // Switch successful, close settings page after a short delay
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          OXNavigator.pop(context);
        }
      }
    } catch (e) {
      OXLoading.dismiss();
      CommonToast.instance.show(context, e.toString());
    }
  }

  void _onCircleSettingsTap(Circle circle) {
    OXNavigator.pushPage(context, (_) => CircleDetailPage(
      previousPageTitle: title,
      circle: circle,
    ));
  }

  void addCircleItemOnTap() {
    OXNavigator.pushPage(
      context,
      (context) => const CircleSelectionPage(controller: null),
      type: OXPushPageType.present,
      fullscreenDialog: true,
    );
  }

  void profileItemOnTap() {
    final circle = LoginManager.instance.currentCircle;
    if (circle == null) {
      CircleJoinUtils.showJoinCircleGuideDialog(context: OXNavigator.rootContext);
      return;
    }
    
    OXNavigator.pushPage(context, (_) => ProfileSettingsPage(previousPageTitle: title,));
  }

  void inviteItemOnTap() {
    final circle = LoginManager.instance.currentCircle;
    if (circle == null) {
      CircleJoinUtils.showJoinCircleGuideDialog(context: OXNavigator.rootContext);
      return;
    }
    
    OXNavigator.pushPage(
      context, 
      (context) => QRCodeDisplayPage(previousPageTitle: title),
    );
  }

  void settingsItemOnTap() {
    OXNavigator.pushPage(context, (_) => SettingsDetailPage(previousPageTitle: title,));
  }

  void notificationItemOnTap() {
    OXNavigator.pushPage(context, (_) => NotificationSettingsPage(previousPageTitle: title,));
  }

  void advancedItemOnTap() {
    OXNavigator.pushPage(context, (_) => AdvancedSettingsPage(previousPageTitle: title,));
  }

  void aboutXChatItemOnTap() {
    OXNavigator.pushPage(context, (_) => AboutXChatPage(previousPageTitle: title,));
  }

}
