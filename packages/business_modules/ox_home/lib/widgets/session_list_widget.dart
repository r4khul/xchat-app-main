import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/circle_join_utils.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_chat/page/session/find_people_page.dart';
import 'package:ox_usercenter/page/settings/qr_code_display_page.dart';

import '../page/archived_chats_page.dart';
import 'session_list_data_controller.dart';
import 'session_list_item_widget.dart';
import 'session_view_model.dart';

class SessionListWidget extends StatefulWidget {
  const SessionListWidget({
    super.key,
    required this.ownerPubkey,
    required this.circle,
  });

  final String ownerPubkey;
  final Circle circle;

  @override
  State<SessionListWidget> createState() => _SessionListWidgetState();
}

class _SessionListWidgetState extends State<SessionListWidget> {
  SessionListDataController? controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(SessionListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize controller if ownerPubkey or circle changed
    if (oldWidget.ownerPubkey != widget.ownerPubkey ||
        oldWidget.circle.id != widget.circle.id) {
      _initializeController();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeController() {
    if (widget.ownerPubkey.isNotEmpty) {
      controller = SessionListDataController(widget.ownerPubkey, widget.circle);
      controller!.initialized();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if controller is not initialized or ownerPubkey is empty
    if (controller == null || widget.ownerPubkey.isEmpty) {
      return Center(
        child: CLProgressIndicator.circular(),
      );
    }

    return ValueListenableBuilder(
      valueListenable: controller!.sessionList$,
      builder: (context, sessionList, _) {
        return ValueListenableBuilder(
          valueListenable: controller!.hasArchivedChats$,
          builder: (context, hasArchived, _) {
            if (sessionList.isEmpty && !hasArchived) {
              return _buildEmptyState(context);
            }

            return ListView.separated(
              padding:
                  EdgeInsets.only(bottom: Adapt.bottomSafeAreaHeightByKeyboard),
              itemBuilder: (context, index) {
                if (hasArchived && index == sessionList.length) {
                  // This is the footer
                  return _buildArchivedChatsFooter(context);
                }
                return itemBuilder(context, sessionList[index]);
              },
              separatorBuilder: (context, index) {
                if (hasArchived && index == sessionList.length - 1) {
                  // No separator before footer
                  return const SizedBox.shrink();
                }
                return buildSeparator(context, index, sessionList);
              },
              itemCount: sessionList.length + (hasArchived ? 1 : 0),
            );
          },
        );
      },
    );
  }

  Widget? itemBuilder(BuildContext context, SessionListViewModel item) {
    return SessionListItemWidget(
      item: item,
      sessionListController: controller,
      showPinnedBackground: true,
    );
  }

  Widget buildSeparator(BuildContext context, int index, List<SessionListViewModel> sessionList) {
    if (PlatformStyle.isUseMaterial) return const SizedBox.shrink();

    final currentItem = sessionList[index];

    // Is between pinned and unpinned items
    if (index < sessionList.length - 1) {
      final nextItem = sessionList[index + 1];

      // No separator between pinned and unpinned items
      if (currentItem.isAlwaysTop && !nextItem.isAlwaysTop) {
        return const SizedBox.shrink();
      }
    }

    return Container(
      color: currentItem.isAlwaysTop ? ColorToken.surfaceContainer.of(context) : null,
      child: Padding(
        padding: EdgeInsets.only(left: 72.px),
        child: Container(
          height: 0.5,
          color: CupertinoColors.separator,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -120.px),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.px),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Empty state icon
              CommonImage(
                iconName: 'empty.png',
                size: 80.px,
                package: 'ox_home',
              ),

              SizedBox(height: 24.px),

              // Title
              CLText.titleLarge(
                Localized.text('ox_chat.no_sessions_title'),
                colorToken: ColorToken.onSurface,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8.px),

              // Description
              CLText.bodyMedium(
                Localized.text('ox_chat.no_sessions_description'),
                colorToken: ColorToken.onSurfaceVariant,
                textAlign: TextAlign.center,
                maxLines: 3,
              ),

              SizedBox(height: 32.px),

              // Find People to Chat button
              CLButton.filled(
                backgroundColor: ColorToken.primary.of(context),
                expanded: true,
                onTap: () => _navigateToFindPeople(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PlatformStyle.isUseMaterial
                          ? Icons.person_add
                          : CupertinoIcons.person_add,
                      size: 20.px,
                      color: ColorToken.onPrimary.of(context),
                    ),
                    SizedBox(width: 8.px),
                    CLText.bodyMedium(
                      Localized.text('ox_chat.find_people_to_chat'),
                      customColor: ColorToken.onPrimary.of(context),
                    ),
                  ],
                ),
              ),

              // SizedBox(height: 16.px),

              // Invite Friends link
              CupertinoButton(
                onPressed: () => _navigateToInviteFriends(context),
                padding: EdgeInsets.zero,
                child: CLText.bodyMedium(
                  Localized.text('ox_chat.invite_friends_link'),
                  customColor: ColorToken.primary.of(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToFindPeople(BuildContext context) {
    OXNavigator.pushPage(
      context,
      (context) => const FindPeoplePage(),
      type: OXPushPageType.present,
    );
  }

  void _navigateToInviteFriends(BuildContext context) {
    final circle = LoginManager.instance.currentCircle;
    if (circle == null) {
      CircleJoinUtils.showJoinCircleGuideDialog(context: OXNavigator.rootContext);
      return;
    }
    
    OXNavigator.pushPage(
      context,
      (context) => const QRCodeDisplayPage(),
    );
  }

  Widget _buildArchivedChatsFooter(BuildContext context) {
    return CupertinoButton(
      onPressed: () => _navigateToArchivedChats(context),
      padding: EdgeInsets.symmetric(vertical: 8.px),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CLText.bodyMedium(
            Localized.text('ox_chat.archived_chats'),
            customColor: ColorToken.primary.of(context),
          ),
          SizedBox(width: 4.px),
          Icon(
            CupertinoIcons.chevron_right,
            size: 16.px,
            color: ColorToken.primary.of(context),
          ),
        ],
      ),
    );
  }

  void _navigateToArchivedChats(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArchivedChatsPage(
          ownerPubkey: widget.ownerPubkey,
          circle: widget.circle,
        ),
      ),
    );
  }
}
