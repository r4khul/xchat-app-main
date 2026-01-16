import 'package:flutter/material.dart';
import 'package:ox_chat/utils/chat_session_utils.dart';
import 'package:ox_common/business_interface/ox_chat/utils.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/model/chat_type.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_common/widgets/avatar.dart';
import 'package:ox_localizable/ox_localizable.dart';

import '../contact_group_member_page.dart';
import '../contact_user_info_page.dart';
import 'group_add_members_page.dart';
import 'group_name_settings_page.dart';
import 'group_remove_members_page.dart';

import 'package:chatcore/chat-core.dart';

enum _MemberAction {
  viewProfile,
  removeFromGroup,
}

class GroupInfoPage extends StatefulWidget {
  final String privateGroupId;

  GroupInfoPage({Key? key, required this.privateGroupId}) : super(key: key);

  @override
  _GroupInfoPageState createState() => new _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  bool _isMute = false;
  List<UserDBISAR> groupMember = [];
  late ValueNotifier<GroupDBISAR> _groupNotifier;
  static const int _maxDisplayMembers = 5; // Maximum number of members to display before "See All"

  @override
  void initState() {
    super.initState();
    _groupNotifier = Groups.sharedInstance.getPrivateGroupNotifier(widget.privateGroupId);
    _groupInfoInit();
    
    // Listen to group changes and update member list
    _groupNotifier.addListener(_onGroupChanged);
  }

  void _groupInfoInit() async {
    String groupId = widget.privateGroupId;
    List<UserDBISAR>? groupList =
    await Groups.sharedInstance.getAllGroupMembers(groupId);

    setState(() {
      groupMember = groupList;
      _isMute = _groupNotifier.value.mute;
    });
  }

  void _onGroupChanged() {
    // Reload member list when group changes
    _groupInfoInit();
  }

  @override
  void dispose() {
    _groupNotifier.removeListener(_onGroupChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(
        title: Localized.text('ox_chat.group_info'),
      ),
      isSectionListPage: true,
      body: ValueListenableBuilder<GroupDBISAR>(
        valueListenable: _groupNotifier,
        builder: (context, groupInfo, child) {
          return CLSectionListView(
            header: _buildHeaderWidget(),
            items: [
              _buildGroupNameSection(),
              _buildMembersSectionItem(),
              _buildSettingsSection(),
              _buildDangerSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderWidget() {
    return ValueListenableBuilder<GroupDBISAR>(
      valueListenable: _groupNotifier,
      builder: (context, groupInfo, child) {
        return Column(
          children: [
            SizedBox(height: 16.px),
            // Group avatar or member avatars
            SmartGroupAvatar(
              group: groupInfo,
              size: 80.px,
            ),
            SizedBox(height: 6.px),
            // Group name
            CLText.titleLarge(
              groupInfo.name.isEmpty ? '--' : groupInfo.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 16.px),
            // // Action buttons
            // _buildActionButtons(),
            // SizedBox(height: 8.px),
          ],
        );
      },
    );
  }




  SectionListViewItem _buildGroupNameSection() {
    return SectionListViewItem(
      data: [
        LabelItemModel(
          title: Localized.text('ox_chat.group_name'),
          value$: ValueNotifier(_groupNotifier.value.name.isEmpty ? '--' : _groupNotifier.value.name),
          onTap: _isGroupOwner ? _updateGroupNameFn : null,
        ),
      ],
    );
  }

  SectionListViewItem _buildMembersSectionItem() {
    return SectionListViewItem(
      headerWidget: FutureBuilder<List<UserDBISAR>>(
        future: Groups.sharedInstance.getAllGroupMembers(_groupNotifier.value.privateGroupId),
        builder: (context, snapshot) {
          final memberCount = snapshot.data?.length ?? groupMember.length;
          return Padding(
            padding: EdgeInsets.only(
              left: 20.px,
              top: 16.px,
            ),
            child: CLText.titleSmall(
              '$memberCount ${Localized.text('ox_chat.group_member')}',
            ),
          );
        },
      ),
      data: [
        CustomItemModel(
          customWidgetBuilder: (context) => _buildMembersSection(),
        ),
      ],
    );
  }

  Widget _buildMembersSection() {
    return FutureBuilder<List<UserDBISAR>>(
      future: Groups.sharedInstance.getAllGroupMembers(_groupNotifier.value.privateGroupId),
      builder: (context, snapshot) {
        final members = snapshot.data ?? groupMember;
        final memberCount = members.length;
        final displayMembers = members.take(_maxDisplayMembers).toList();
        final hasMoreMembers = memberCount > _maxDisplayMembers;
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.px),
          ),
          child: Column(
            children: [
              // Add Members button (if group owner)
              if (_isGroupOwner) ...[
                _buildAddMemberButton(),
                if (displayMembers.isNotEmpty)
                  Divider(
                    height: 1,
                    color: ColorToken.onSurfaceVariant.of(context).withOpacity(0.2),
                  ),
              ],
              // Member list
              ...displayMembers.asMap().entries.map((entry) {
                final index = entry.key;
                final member = entry.value;
                final isLast = index == displayMembers.length - 1 && !hasMoreMembers;
                return Column(
                  children: [
                    _buildMemberItem(member),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: ColorToken.onSurfaceVariant.of(context).withOpacity(0.2),
                      ),
                  ],
                );
              }),
              // See All button
              if (hasMoreMembers) ...[
                Divider(
                  height: 1,
                  color: ColorToken.onSurfaceVariant.of(context).withOpacity(0.2),
                ),
                _buildSeeAllButton(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddMemberButton() {
    return GestureDetector(
      onTap: _addMembersFn,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.px, vertical: 12.px),
        child: Row(
          children: [
            Container(
              width: 40.px,
              height: 40.px,
              decoration: BoxDecoration(
                color: ColorToken.surface.of(context),
                borderRadius: BorderRadius.circular(20.px),
                border: Border.all(
                  color: ColorToken.onSurfaceVariant.of(context).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.add,
                size: 24.px,
                color: ColorToken.onSurface.of(context),
              ),
            ),
            SizedBox(width: 12.px),
            Expanded(
              child: CLText.bodyMedium(
                Localized.text('ox_chat.add_member_title'),
                colorToken: ColorToken.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberItem(UserDBISAR user) {
    final isOwner = user.pubKey == _groupNotifier.value.owner;
    final isMe = user.pubKey == Account.sharedInstance.me?.pubKey;
    
    return GestureDetector(
      onTap: () => _showMemberActionSheet(user, isMe),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.px, vertical: 12.px),
        child: Row(
          children: [
            OXUserAvatar(
              user: user,
              size: 40.px,
            ),
            SizedBox(width: 12.px),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: CLText.bodyMedium(
                          isMe ? Localized.text('ox_chat.you') : user.getUserShowName(),
                          colorToken: ColorToken.onSurface,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOwner) ...[
                        SizedBox(width: 8.px),
                        CLText.bodySmall(
                          'Admin',
                          colorToken: ColorToken.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeeAllButton() {
    return GestureDetector(
      onTap: _memberItemOnTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.px, vertical: 12.px),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.keyboard_arrow_down,
              size: 24.px,
              color: ColorToken.onSurface.of(context),
            ),
            SizedBox(width: 4.px),
            CLText.bodyMedium(
              Localized.text('ox_chat.see_all'),
              colorToken: ColorToken.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  SectionListViewItem _buildSettingsSection() {
    final muteNotifier = ValueNotifier(_isMute);
    muteNotifier.addListener(() {
      _changeMuteFn(muteNotifier.value);
    });
    
    return SectionListViewItem(
      data: [
        SwitcherItemModel(
          title: Localized.text('ox_chat.mute_item'),
          value$: muteNotifier,
        ),
      ],
    );
  }

  SectionListViewItem _buildDangerSection() {
    String buttonText = _isGroupOwner 
        ? Localized.text('ox_chat.delete_and_leave_item')
        : Localized.text('ox_chat.str_leave_group');
    
    return SectionListViewItem(
      data: [
        CustomItemModel(
          customWidgetBuilder: (context) => GestureDetector(
            onTap: () {
              ChatSessionUtils.leaveConfirmWidget(
                context, 
                ChatType.chatGroup, 
                widget.privateGroupId,
                isGroupOwner: _isGroupOwner,
              );
            },
            child: Container(
              width: double.infinity,
              height: 48.px,
              decoration: BoxDecoration(
                color: ColorToken.surface.of(context),
                borderRadius: BorderRadius.circular(12.px),
              ),
              alignment: Alignment.center,
              child: CLText.bodyLarge(
                buttonText,
                colorToken: ColorToken.error,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool get _isGroupOwner {
    UserDBISAR? userInfo = Account.sharedInstance.me;
    if (userInfo == null) return false;

    return userInfo.pubKey == _groupNotifier.value.owner;
  }

  bool get _isGroupMember {
    UserDBISAR? userInfo = Account.sharedInstance.me;
    if (userInfo == null || groupMember.length == 0) return false;
    bool hasMember =
        groupMember.any((userDB) => userDB.pubKey == userInfo.pubKey);
    return hasMember;
  }

  void _updateGroupNameFn() async {
    if (!_isGroupOwner) return;

    OXNavigator.pushPage(
      context,
      (context) => GroupNameSettingsPage(
        groupInfo: _groupNotifier.value,
        previousPageTitle: Localized.text('ox_chat.group_info'),
      ),
    );
  }

  void _addMembersFn() async {
    if (!_isGroupOwner) return;
    
    OXNavigator.pushPage(
      context,
      (context) => GroupAddMembersPage(
        groupInfo: _groupNotifier.value,
        previousPageTitle: Localized.text('ox_chat.group_info'),
      ),
    );
  }

  void _removeMembersFn() async {
    if (!_isGroupOwner) return;
    
    OXNavigator.pushPage(
      context,
      (context) => GroupRemoveMembersPage(
        groupInfo: _groupNotifier.value,
        previousPageTitle: Localized.text('ox_chat.group_info'),
      ),
    );
  }

  void _memberItemOnTap() async {
    if (!_isGroupMember) return;
    OXNavigator.pushPage(
      context, (context) => ContactGroupMemberPage(
        groupId: widget.privateGroupId,
      ),
    );
  }

  void _changeMuteFn(bool value) async {
    if (!_isGroupMember) {
      CommonToast.instance.show(context, Localized.text('ox_chat.group_mute_no_member_toast'));
      return;
    }
    if (value) {
      await Groups.sharedInstance.muteGroup(widget.privateGroupId);
      CommonToast.instance.show(context, Localized.text('ox_chat.group_mute_operate_success_toast'));
    } else {
      await Groups.sharedInstance.unMuteGroup(widget.privateGroupId);
      CommonToast.instance.show(context, Localized.text('ox_chat.group_mute_operate_success_toast'));
    }
    setState(() {
      _isMute = value;
    });
  }

  Future<void> _showMemberActionSheet(UserDBISAR user, bool isMe) async {
    final items = <CLPickerItem<_MemberAction>>[
      CLPickerItem(
        label: Localized.text('ox_chat.view_profile'),
        value: _MemberAction.viewProfile,
      ),
    ];

    // Only show remove option if user is group owner and the member is not themselves
    if (_isGroupOwner && !isMe) {
      items.add(
        CLPickerItem(
          label: Localized.text('ox_chat.remove_from_group'),
          value: _MemberAction.removeFromGroup,
          isDestructive: true,
        ),
      );
    }

    final action = await CLPicker.show<_MemberAction>(
      context: context,
      items: items,
    );

    if (action == null) return;

    switch (action) {
      case _MemberAction.viewProfile:
        OXNavigator.pushPage(
          context,
          (context) => ContactUserInfoPage(user: user),
        );
        break;
      case _MemberAction.removeFromGroup:
        await _removeMemberFromGroup(user);
        break;
    }
  }

  Future<void> _removeMemberFromGroup(UserDBISAR user) async {
    if (!_isGroupOwner) return;

    final confirmed = await CLAlertDialog.show<bool>(
      context: context,
      title: Localized.text('ox_chat.remove_member_title'),
      content: Localized.text('ox_chat.remove_member_confirm_content')
          .replaceAll('{count}', '1'),
      actions: [
        CLAlertAction.cancel(),
        CLAlertAction<bool>(
          label: Localized.text('ox_chat.remove_member_title'),
          value: true,
          isDestructiveAction: true,
        ),
      ],
    );

    if (confirmed != true) return;

    OXLoading.show();
    try {
      final result = await Groups.sharedInstance.removeMembersFromPrivateGroup(
        widget.privateGroupId,
        [user.pubKey],
      );

      await OXLoading.dismiss();

      if (result != null) {
        // Trigger notifier update
        final notifier = Groups.sharedInstance.getPrivateGroupNotifier(widget.privateGroupId);
        notifier.value = result;
        
        // Reload member list
        _groupInfoInit();
        
        if (!mounted) return;
        CommonToast.instance.show(context, Localized.text('ox_chat.remove_member_success_tips'));
      } else {
        if (!mounted) return;
        CommonToast.instance.show(context, Localized.text('ox_chat.remove_member_fail_tips'));
      }
    } catch (e) {
      await OXLoading.dismiss();
      if (!mounted) return;
      CommonToast.instance.show(context, '${Localized.text('ox_chat.remove_member_fail_tips')}: $e');
    }
  }
}
