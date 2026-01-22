import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_common/login/circle_service.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/common_loading.dart' as Loading;
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_common/utils/file_server_helper.dart';
import 'package:ox_common/repository/file_server_repository.dart';
import 'package:ox_common/log_util.dart';

import 'file_server_page.dart';
import 'profile_settings_page.dart';
import 'subscription_detail_page.dart';

enum _MenuAction { edit, delete }
enum _PlanAction { changePlan, cancelSubscription }
enum _StorageAction { clearAllStorage }

class CircleDetailPage extends StatefulWidget {
  const CircleDetailPage({
    super.key,
    required this.circle,
    this.previousPageTitle,
    this.description = '',
  });

  final Circle circle;

  final String? previousPageTitle;

  final String description;

  String get title => Localized.text('ox_usercenter.circle_settings');

  @override
  State<CircleDetailPage> createState() => _CircleDetailPageState();
}

class _CircleDetailPageState extends State<CircleDetailPage> {
  late String _circleName;
  bool _isOwner = false;
  late ValueNotifier<String> _planName$;
  late ValueNotifier<String> _renewDate$;
  int _currentMembers = 1;
  int _maxMembers = 6;
  late ValueNotifier<String> _storageUsed$;
  late ValueNotifier<String> _fileServerName$;
  List<UserDBISAR> _members = [];
  bool _autoDeleteEnabled = false;

  @override
  void initState() {
    super.initState();
    _circleName = widget.circle.name ?? '';
    _planName$ = ValueNotifier<String>('Family');
    _renewDate$ = ValueNotifier<String>('Dec 31, 2025');
    _storageUsed$ = ValueNotifier<String>('45.2 GB');
    _fileServerName$ = ValueNotifier<String>('');
    _checkIfOwner();
    _loadSubscriptionInfo();
    _loadFileServerInfo();
  }

  @override
  void dispose() {
    _planName$.dispose();
    _renewDate$.dispose();
    _storageUsed$.dispose();
    _fileServerName$.dispose();
    super.dispose();
  }

  void _checkIfOwner() {
    final currentPubkey = LoginManager.instance.currentPubkey;
    _isOwner = widget.circle.pubkey == currentPubkey;
  }

  Future<void> _loadSubscriptionInfo() async {
    try {
      // Load tenant info to get member count, limits, and members list
      final tenantInfo = await CircleMemberService.sharedInstance.getTenantInfo();
      
      // Extract member count and limits
      final currentMembers = tenantInfo['current_members'] as int? ?? 0;
      final maxMembers = tenantInfo['max_members'] as int? ?? 100;
      
      // Extract and convert members list
      final membersList = <UserDBISAR>[];
      final membersData = tenantInfo['members'] as List<dynamic>?;
      if (membersData != null) {
        for (final memberData in membersData) {
          final memberMap = memberData as Map<String, dynamic>;
          final pubkey = memberMap['pubkey'] as String?;
          if (pubkey != null && pubkey.isNotEmpty) {
            final user = await Account.sharedInstance.getUserInfo(pubkey);
            if (user != null) {
              // Update display name if provided
              final displayName = memberMap['display_name'] as String?;
              if (displayName != null && displayName.isNotEmpty) {
                user.name = displayName;
              }
              membersList.add(user);
            }
          }
        }
      }
      
      // Extract expires_at and format renew date
      String renewDateText = 'Dec 31, 2025'; // Default
      final expiresAt = tenantInfo['expires_at'] as int?;
      if (expiresAt != null && expiresAt > 0) {
        try {
          // expires_at is in seconds, convert to milliseconds
          final date = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
          renewDateText = DateFormat('MMM d, yyyy').format(date);
        } catch (e) {
          LogUtil.w(() => 'Failed to format expires_at: $e');
        }
      }
      
      // Extract tenant name if available
      final tenantName = tenantInfo['name'] as String?;
      if (tenantName != null && tenantName.isNotEmpty && tenantName != _circleName) {
        // Optionally update circle name if different
        // _circleName = tenantName;
      }
      
      setState(() {
        _currentMembers = currentMembers;
        _maxMembers = maxMembers;
        _members = membersList;
        _renewDate$.value = renewDateText;
        _planName$.value = 'Family'; // TODO: Load actual plan name from API if available
        _storageUsed$.value = '45.2 GB'; // TODO: Load actual storage from API if available
      });
    } catch (e) {
      // If not a member or error, use defaults
      LogUtil.w(() => 'Failed to load subscription info: $e');
      setState(() {
        _currentMembers = _members.length;
        _maxMembers = 100;
        // Try to load at least current user as fallback
        _loadCurrentUserFallback();
      });
    }
  }
  
  Future<void> _loadCurrentUserFallback() async {
    try {
      final currentPubkey = LoginManager.instance.currentPubkey;
      if (currentPubkey.isNotEmpty) {
        final currentUser = await Account.sharedInstance.getUserInfo(currentPubkey);
        if (currentUser != null && _members.isEmpty) {
          setState(() {
            _members = [currentUser];
            _currentMembers = 1;
          });
        }
      }
    } catch (e) {
      LogUtil.e(() => 'Failed to load current user: $e');
    }
  }

  Future<void> _loadFileServerInfo() async {
    final selectedUrl = widget.circle.selectedFileServerUrl;
    String displayName = '';
    
    if (FileServerHelper.isDefaultFileServerGroupSelected(selectedUrl)) {
      displayName = Localized.text('ox_usercenter.default_file_server_group');
    } else {
      try {
        final repo = FileServerRepository(DBISAR.sharedInstance.isar);
        final servers = repo.fetch();
        final matched = servers.firstWhere((e) => e.url == selectedUrl);
        displayName = matched.name.isNotEmpty ? matched.name : matched.url;
      } catch (e) {
        displayName = selectedUrl ?? '';
      }
    }
    
    _fileServerName$.value = displayName;
  }


  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(
        previousPageTitle: widget.previousPageTitle,
        title: widget.title,
        actions: [_buildMenuButton(context)],
        backgroundColor: ColorToken.primaryContainer.of(context),
      ),
      body: CLSectionListView(
        padding: EdgeInsets.zero,
        items: [
          SectionListViewItem(
            headerWidget: _buildHeader(context),
            data: [],
          ),
          ..._buildMainItems(context),
        ],
      ),
      isSectionListPage: true,
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return CLButton.icon(
      icon: CupertinoIcons.ellipsis,
      onTap: () async {
        final action = await CLPicker.show<_MenuAction>(
          context: context,
          items: [
            // CLPickerItem(label: Localized.text('ox_usercenter.edit_profile'), value: _MenuAction.edit),
            CLPickerItem(
              label: Localized.text('ox_usercenter.delete_circle'),
              value: _MenuAction.delete,
              isDestructive: true,
            ),
          ],
        );
        if (action != null) {
          _handleMenuAction(context, action);
        }
      },
    );
  }

  void _handleMenuAction(BuildContext context, _MenuAction action) {
    switch (action) {
      case _MenuAction.edit:
        OXNavigator.pushPage(context, (_) =>
            ProfileSettingsPage(previousPageTitle: widget.title));
        break;
      case _MenuAction.delete:
        _confirmDelete(context);
        break;
    }
  }

  void _confirmDelete(BuildContext context) async {
    final bool? confirmed = await CLAlertDialog.show<bool>(
      context: context,
      title: Localized.text('ox_usercenter.delete_circle_confirm_title'),
      content: Localized.text('ox_usercenter.delete_circle_confirm_content'),
      actions: [
        CLAlertAction.cancel(),
        CLAlertAction<bool>(
          label: Localized.text('ox_usercenter.delete_circle'),
          value: true,
          isDestructiveAction: true,
        ),
      ],
    );

    if (confirmed == true) {
      try {
        await LoginManager.instance.deleteCircle(widget.circle.id);
      } catch (e) {
        CommonToast.instance.show(context, e.toString());
      }
      OXNavigator.popToRoot(context);
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: PlatformStyle.isUseMaterial
          ? ColorToken.primaryContainer.of(context)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 8.px),
      
          CircleAvatar(
            radius: 40.px,
            backgroundColor: ColorToken.onPrimary.of(context),
            child: CLText.titleLarge(
              _circleName.isNotEmpty ? _circleName[0].toUpperCase() : '?',
            ),
          ),
      
          SizedBox(height: 12.px),

          GestureDetector(
            onTap: () => _editCircleName(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CLText.titleLarge(
                  _circleName,
                  textAlign: TextAlign.center,
                ),
                SizedBox(width: 8.px),
                Icon(
                  CupertinoIcons.create_solid,
                  size: 18.px,
                  color: ColorToken.onSurfaceVariant.of(context),
                ),
              ],
            ),
          ),
      
          SizedBox(height: 12.px),
      
          // Padding(
          //   padding: EdgeInsets.symmetric(
          //     horizontal: PlatformStyle.isUseMaterial
          //         ? 24.px
          //         : 4.px,
          //     vertical: 12.px,
          //   ),
          //   child: Column(
          //     mainAxisSize: MainAxisSize.min,
          //     crossAxisAlignment: CrossAxisAlignment.stretch,
          //     children: [
          //       CLText.bodyLarge(Localized.text('ox_chat.description')),
          //       CLText.bodyMedium(description),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Future<void> _editCircleName(BuildContext context) async {
    await CLDialog.showInputDialog(
      context: context,
      title: Localized.text('ox_usercenter.edit_circle_name'),
      inputLabel: Localized.text('ox_usercenter.circle_name'),
      initialValue: _circleName,
      onConfirm: (newName) async {
        if (newName.trim().isEmpty) {
          CommonToast.instance.show(context, Localized.text('ox_common.input_cannot_be_empty'));
          return false;
        }
        
        if (newName.trim() == _circleName) {
          return true; // No change needed
        }

        try {
          Loading.OXLoading.show();
          
          final updatedCircle = await CircleService.updateCircleName(
            widget.circle.id,
            newName.trim(),
          );

          if (updatedCircle == null) {
            Loading.OXLoading.dismiss();
            CommonToast.instance.show(context, Localized.text('ox_common.operation_failed'));
            return false;
          }

          Loading.OXLoading.dismiss();
          
          setState(() {
            _circleName = newName.trim();
          });

          return true;
        } catch (e) {
          Loading.OXLoading.dismiss();
          CommonToast.instance.show(context, e.toString());
          return false;
        }
      },
    );
  }

  List<SectionListViewItem> _buildMainItems(BuildContext context) {
    final items = <SectionListViewItem>[
      // Relay Server
      SectionListViewItem(
        header: Localized.text('ox_usercenter.subscription_and_usage'),
        footer: Localized.text('ox_usercenter.relay_server_description'),
        data: [
          LabelItemModel(
            icon: ListViewIcon.data(CupertinoIcons.antenna_radiowaves_left_right),
            title: Localized.text('ox_usercenter.relay_server'),
            subtitle: widget.circle.relayUrl,
            onTap: null,
          ),
          LabelItemModel(
            icon: ListViewIcon.data(CupertinoIcons.settings),
            title: Localized.text('ox_usercenter.file_server_setting'),
            // subtitle: _fileServerName$.value,
            onTap: () {
              OXNavigator.pushPage(context, (_) => FileServerPage(
                previousPageTitle: widget.title,
              )).then((_) {
                // Reload file server info when returning from file server page
                _loadFileServerInfo();
              });
            },
          ),
        ],
      ),
    ];

    // Add subscription and members sections if user is owner
    if (_isOwner) {
      items.addAll([
        _buildSubscriptionSection(context),
        _buildMembersSection(context),
      ]);
    }

    return items;
  }

  SectionListViewItem _buildSubscriptionSection(BuildContext context) {
    return SectionListViewItem(
      header: Localized.text('ox_usercenter.subscription_and_usage'),
      data: [
        // Plan
        LabelItemModel(
          icon: ListViewIcon.data(Icons.workspace_premium),
          title: Localized.text('ox_usercenter.plan'),
          subtitle: Localized.text('ox_usercenter.renews_on').replaceAll('{date}', _renewDate$.value),
          value$: _planName$,
          onTap: () {
            OXNavigator.pushPage(
              context,
              (context) => SubscriptionDetailPage(
                previousPageTitle: widget.title,
              ),
            );
          },
        ),
        // Storage
        LabelItemModel(
          icon: ListViewIcon.data(Icons.storage),
          title: Localized.text('ox_usercenter.storage'),
          value$: _storageUsed$,
          onTap: () {
            _showStorageOptions(context);
          },
        ),
      ],
    );
  }

  SectionListViewItem _buildMembersSection(BuildContext context) {
    final currentPubkey = LoginManager.instance.currentPubkey;
    final memberItems = <ListViewItem>[];

    // Add owner (current user)
    UserDBISAR? ownerUser;
    try {
      ownerUser = _members.firstWhere(
        (user) => user.pubKey == currentPubkey,
      );
    } catch (e) {
      // Owner not found in members list, use first member if available
      if (_members.isNotEmpty) {
        ownerUser = _members.first;
      }
    }
    
    if (ownerUser != null) {
      memberItems.add(
        LabelItemModel(
          icon: ListViewIcon.data(Icons.person),
          title: Localized.text('ox_usercenter.you_owner'),
          subtitle: Localized.text('ox_usercenter.owner'),
          onTap: null,
        ),
      );
    }

    // Add other members
    for (final member in _members) {
      if (member.pubKey != currentPubkey) {
        final memberName = member.name ?? '';
        final displayName = memberName.isNotEmpty 
            ? memberName 
            : (member.pubKey.length >= 8 
                ? member.pubKey.substring(0, 8) 
                : member.pubKey);
        memberItems.add(
          LabelItemModel(
            icon: ListViewIcon.data(Icons.person),
            title: displayName,
            subtitle: Localized.text('ox_usercenter.member'),
            value$: ValueNotifier<String>(Localized.text('ox_usercenter.remove')),
            valueMapper: (value) => value,
            onTap: () => _removeMember(member),
          ),
        );
      }
    }

    // Add "Add Member" option
    memberItems.add(
      LabelItemModel(
        icon: ListViewIcon.data(Icons.person_add),
        title: Localized.text('ox_usercenter.add_member'),
        onTap: _addMember,
      ),
    );

    return SectionListViewItem(
      header: Localized.text('ox_usercenter.members'),
      data: memberItems,
    );
  }

  Future<void> _removeMember(UserDBISAR member) async {
    final memberName = member.name ?? '';
    final displayName = memberName.isNotEmpty 
        ? memberName 
        : (member.pubKey.length >= 8 
            ? member.pubKey.substring(0, 8) 
            : member.pubKey);
    
    final confirmed = await CLAlertDialog.show<bool>(
      context: context,
      title: Localized.text('ox_usercenter.remove_member_title'),
      content: Localized.text('ox_usercenter.remove_member_content').replaceAll('{name}', displayName),
      actions: [
        CLAlertAction.cancel(),
        CLAlertAction<bool>(
          label: Localized.text('ox_usercenter.remove'),
          value: true,
          isDestructiveAction: true,
        ),
      ],
    );

    if (confirmed == true) {
      Loading.OXLoading.show();
      try {
        await CircleMemberService.sharedInstance.removeMember(
          memberPubkey: member.pubKey,
        );
        
        if (mounted) {
          CommonToast.instance.show(context, Localized.text('ox_common.operation_success'));
          await _loadSubscriptionInfo();
        }
      } catch (e) {
        if (mounted) {
          CommonToast.instance.show(context, e.toString());
        }
      } finally {
        Loading.OXLoading.dismiss();
      }
    }
  }

  Future<void> _addMember() async {
    // Check if member limit is reached
    if (_currentMembers >= _maxMembers) {
      CommonToast.instance.show(
        context,
        Localized.text('ox_usercenter.member_limit_reached'),
      );
      return;
    }

    // Show dialog to enter pubkey
    final pubkey = await CLDialog.showInputDialog(
      context: context,
      title: Localized.text('ox_usercenter.add_member'),
      description: Localized.text('ox_usercenter.enter_pubkey_description'),
      inputLabel: Localized.text('ox_usercenter.pubkey_or_npub'),
      confirmText: Localized.text('ox_common.confirm'),
      onConfirm: (input) async {
        final trimmedInput = input.trim();
        if (trimmedInput.isEmpty) {
          CommonToast.instance.show(
            context,
            Localized.text('ox_common.input_cannot_be_empty'),
          );
          return false;
        }
        return true;
      },
    );

    if (pubkey == null || pubkey.trim().isEmpty) return;

    Loading.OXLoading.show();
    try {
      await CircleMemberService.sharedInstance.addMember(
        memberPubkey: pubkey.trim(),
      );
      
      if (mounted) {
        CommonToast.instance.show(context, Localized.text('ox_common.operation_success'));
        await _loadSubscriptionInfo();
      }
    } catch (e) {
      if (mounted) {
        CommonToast.instance.show(context, e.toString());
      }
    } finally {
      Loading.OXLoading.dismiss();
    }
  }


  void _showStorageOptions(BuildContext context) async {
    final action = await CLPicker.show<_StorageAction>(
      context: context,
      items: [
        CLPickerItem(
          label: Localized.text('ox_usercenter.clear_all_storage'),
          value: _StorageAction.clearAllStorage,
          isDestructive: true,
        ),
      ],
    );

    if (action == null) return;

    switch (action) {
      case _StorageAction.clearAllStorage:
        _showClearStorageDialog(context);
        break;
    }
  }

  void _showCancelSubscriptionDialog(BuildContext context) {
    CLAlertDialog.show<bool>(
      context: context,
      title: Localized.text('ox_usercenter.cancel_subscription_title'),
      content: Localized.text('ox_usercenter.cancel_subscription_content'),
      actions: [
        CLAlertAction.cancel(),
        CLAlertAction<bool>(
          label: Localized.text('ox_usercenter.cancel_subscription'),
          value: true,
          isDestructiveAction: true,
        ),
      ],
    ).then((confirmed) {
      if (confirmed == true) {
        // TODO: Implement cancel subscription logic
        CommonToast.instance.show(context, Localized.text('ox_common.operation_success'));
      }
    });
  }

  void _showClearStorageDialog(BuildContext context) {
    CLAlertDialog.show<bool>(
      context: context,
      title: Localized.text('ox_usercenter.clear_all_storage_title'),
      content: Localized.text('ox_usercenter.clear_all_storage_content'),
      actions: [
        CLAlertAction.cancel(),
        CLAlertAction<bool>(
          label: Localized.text('ox_usercenter.clear_all_storage'),
          value: true,
          isDestructiveAction: true,
        ),
      ],
    ).then((confirmed) {
      if (confirmed == true) {
        // TODO: Implement clear all storage logic
        CommonToast.instance.show(context, Localized.text('ox_common.operation_success'));
        _storageUsed$.value = '0.0 GB';
      }
    });
  }
}