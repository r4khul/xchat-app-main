import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_common/login/circle_service.dart';
import 'package:ox_common/login/circle_repository.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/common_loading.dart' as Loading;
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_common/utils/file_server_helper.dart';
import 'package:ox_common/repository/file_server_repository.dart';
import 'package:ox_common/log_util.dart';
import 'package:ox_common/model/file_server_model.dart';

import 'file_server_page.dart';
import 'profile_settings_page.dart';
import 'subscription_detail_page.dart';
import 'qr_code_display_page.dart';
import '../../utils/invite_link_manager.dart';

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
    _circleName = widget.circle.name;
    _planName$ = ValueNotifier<String>('Family');
    _renewDate$ = ValueNotifier<String>('Dec 31, 2025');
    _storageUsed$ = ValueNotifier<String>('45.2 GB');
    _fileServerName$ = ValueNotifier<String>('');
    _checkIfOwner();
    // Load local data first, then request server update
    _loadLocalData();
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

  /// Check if this circle is a paid relay (based on relayUrl matching privateRelayApiBaseUrl)
  bool _isPaidRelay() {
    return CircleApi.isPaidRelay(widget.circle.relayUrl);
  }

  /// Load local data first (for paid relays, load cached tenant info)
  Future<void> _loadLocalData() async {
    // From widget.circle get local data
    _circleName = widget.circle.name;

    // If it's a paid relay, load cached tenant info from CircleDBISAR
    if (_isPaidRelay()) {
      final cachedTenantInfo = await _loadCachedTenantInfo();
      if (cachedTenantInfo != null) {
        _updateUIWithTenantInfo(cachedTenantInfo);
      }
      // Update category if it's not already paid
      if (widget.circle.category != CircleCategory.paid) {
        await _updateCircleCategory(CircleCategory.paid);
      }
    }
  }

  /// Load cached tenant info from CircleDBISAR
  Future<Map<String, dynamic>?> _loadCachedTenantInfo() async {
    try {
      return await Account.sharedInstance.loadTenantInfoFromCircleDB(
        widget.circle.id,
      );
    } catch (e) {
      LogUtil.w(() => 'Failed to load cached tenant info: $e');
      return null;
    }
  }

  /// Update UI with tenant info
  Future<void> _updateUIWithTenantInfo(Map<String, dynamic> tenantInfo) async {
    // Check if current user is tenant admin
    final currentPubkey = LoginManager.instance.currentPubkey;
    final tenantAdminPubkey = tenantInfo['tenant_admin_pubkey'] as String?;
    if (tenantAdminPubkey != null && tenantAdminPubkey.isNotEmpty) {
      _isOwner = tenantAdminPubkey.toLowerCase() == currentPubkey.toLowerCase();
    } else {
      // Fallback to circle pubkey check
      _isOwner = widget.circle.pubkey == currentPubkey;
    }

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

    if (mounted) {
      setState(() {
        _currentMembers = currentMembers;
        _maxMembers = maxMembers;
        _members = membersList;
        _renewDate$.value = renewDateText;
        _planName$.value = 'Family'; // TODO: Load actual plan name from API if available
        _storageUsed$.value = '45.2 GB'; // TODO: Load actual storage from API if available
      });
    }
  }

  /// Save tenant info to cache (CircleDBISAR)
  /// This method is called when we successfully get tenant info, which means it's a paid circle
  Future<void> _saveTenantInfoToCache(Map<String, dynamic> tenantInfo) async {
    try {
      await Account.sharedInstance.saveTenantInfoToCircleDB(
        circleId: widget.circle.id,
        tenantInfo: tenantInfo,
      );
    } catch (e) {
      LogUtil.w(() => 'Failed to save tenant info to cache: $e');
    }
  }

  Future<void> _loadSubscriptionInfo() async {
    // Only load subscription info for paid relays
    if (!_isPaidRelay()) {
      return;
    }

    // Try to load cached data from local first and display immediately
    final cachedData = await _loadCachedTenantInfo();
    if (cachedData != null) {
      _updateUIWithTenantInfo(cachedData);
    }

    // Update category if it's not already paid
    if (widget.circle.category != CircleCategory.paid) {
      await _updateCircleCategory(CircleCategory.paid);
    }

    // Then request server update (request regardless of whether cached data exists)
    try {
      final tenantInfo = await CircleMemberService.sharedInstance.getTenantInfo();
      
      // Handle s3_config if present
      if (tenantInfo['s3_config'] != null) {
        try {
          final s3ConfigJson = tenantInfo['s3_config'] as Map<String, dynamic>;
          final s3Config = S3Config.fromJson(s3ConfigJson);
          
          // Save S3 config to CircleDBISAR
          await S3ConfigUtils.saveS3ConfigToCircleDB(
            circleId: widget.circle.id,
            s3Config: s3Config,
          );
          
          // Create/update FileServerModel in repository
          final repo = FileServerRepository(DBISAR.sharedInstance.isar);
          final s3Url = S3ConfigUtils.getS3FileServerUrl(s3Config);
          final fileServer = FileServerModel(
            id: 0,
            type: FileServerType.minio,
            name: tenantInfo['name'] as String? ?? widget.circle.name,
            url: s3Url,
            accessKey: s3Config.accessKeyId,
            secretKey: s3Config.secretAccessKey,
            bucketName: s3Config.bucket,
            pathPrefix: s3Config.pathPrefix,
            region: s3Config.region,
            sessionToken: s3Config.sessionToken,
            expiration: s3Config.expiration,
          );
          
          // Check if server already exists
          final existingServers = repo.fetch();
          try {
            final existing = existingServers.firstWhere(
              (s) => s.url == fileServer.url && 
                     s.bucketName == fileServer.bucketName &&
                     s.type == FileServerType.minio,
            );
            // Update existing
            existing.accessKey = fileServer.accessKey;
            existing.secretKey = fileServer.secretKey;
            existing.bucketName = fileServer.bucketName;
            existing.url = fileServer.url;
            existing.name = fileServer.name;
            existing.pathPrefix = fileServer.pathPrefix;
            existing.region = fileServer.region;
            existing.sessionToken = fileServer.sessionToken;
            existing.expiration = fileServer.expiration;
            await repo.create(existing);
          } catch (_) {
            // Create new
            await repo.create(fileServer);
          }
        } catch (e) {
          LogUtil.w(() => 'Failed to save S3 config from tenant info: $e');
        }
      }
      
      // Update UI
      await _updateUIWithTenantInfo(tenantInfo);

      // Save to local cache
      await _saveTenantInfoToCache(tenantInfo);

      // If server returns tenant_name different from local, update circle name
      final tenantName = tenantInfo['name'] as String?;
      if (tenantName != null &&
          tenantName.isNotEmpty &&
          tenantName != _circleName) {
        if (mounted) {
          setState(() {
            _circleName = tenantName;
          });
        }
      }
    } catch (e) {
      // Request failed, keep displaying local data (if any)
      LogUtil.w(() => 'Failed to load subscription info: $e');
      // If no cached data was loaded and request failed, try fallback
      if (_members.isEmpty && cachedData == null) {
        _loadCurrentUserFallback();
      }
    }
  }

  /// Update circle category in account-level database
  Future<void> _updateCircleCategory(CircleCategory category) async {
    try {
      final loginManager = LoginManager.instance;
      final account = loginManager.currentState.account;
      if (account == null) return;

      // Find the circle in account circles
      final circleIndex = account.circles.indexWhere((c) => c.id == widget.circle.id);
      if (circleIndex == -1) return;

      // Update category
      account.circles[circleIndex].category = category;

      // Save to account database
      final accountDb = account.db;
      final success = await CircleRepository.update(accountDb, account.circles[circleIndex]);
      if (success) {
        LogUtil.v(() => 'Updated circle category to $category for circle: ${widget.circle.id}');
        // Update LoginManager state to reflect the change
        loginManager.updateStateAccount(account);
      }
    } catch (e) {
      LogUtil.w(() => 'Failed to update circle category: $e');
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
        displayName = selectedUrl;
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
                Flexible(
                  child: CLText.titleLarge(
                    _circleName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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

    // Navigate to QR code display page for circle invite
    if (mounted) {
      await OXNavigator.pushPage(
        context,
        (context) => QRCodeDisplayPage(
          inviteType: InviteType.circle,
          circle: widget.circle,
        ),
      );
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