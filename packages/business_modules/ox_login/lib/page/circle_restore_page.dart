import 'package:flutter/material.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/circle_join_utils.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import '../controller/onboarding_controller.dart';
import 'circle_selection_page.dart';

/// Circle restore data model
class _CircleRestoreItem {
  final RelayAddressInfo relayInfo;
  bool isSelected;
  String? role; // "Admin" or "Member"
  int? memberCount;

  _CircleRestoreItem({
    required this.relayInfo,
  }) : isSelected = true, role = null, memberCount = null;
}

class CircleRestorePage extends StatefulWidget {
  const CircleRestorePage({
    super.key,
    required this.circles,
    this.controller,
  });

  final List<RelayAddressInfo> circles;
  final OnboardingController? controller;

  @override
  State<CircleRestorePage> createState() => _CircleRestorePageState();
}

class _CircleRestorePageState extends State<CircleRestorePage> {
  late List<_CircleRestoreItem> _circleItems;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _circleItems = widget.circles
        .map((circle) => _CircleRestoreItem(relayInfo: circle))
        .toList();
    _loadCircleDetails();
  }

  Future<void> _loadCircleDetails() async {
    // Load role and member count for each circle
    final currentPubkey = Account.sharedInstance.currentPubkey;
    
    for (final item in _circleItems) {
      try {
        // Try to get admin info first
        try {
          final tenantInfoAdmin = await CircleMemberService.sharedInstance.getTenantInfoAdmin();
          
          setState(() {
            item.memberCount = tenantInfoAdmin['current_members'] as int?;
            final adminPubkey = tenantInfoAdmin['tenant_admin_pubkey'] as String?;
            if (adminPubkey != null && adminPubkey.toLowerCase() == currentPubkey.toLowerCase()) {
              item.role = Localized.text('ox_login.admin');
            } else {
              item.role = Localized.text('ox_login.member');
            }
          });
        } catch (e) {
          // If admin check fails, try member-visible info
          try {
            final tenantInfo = await CircleMemberService.sharedInstance.getTenantInfo();
            
            setState(() {
              item.memberCount = tenantInfo['current_members'] as int?;
              item.role = Localized.text('ox_login.member');
            });
          } catch (e2) {
            // If both fail, use defaults
            setState(() {
              item.role = Localized.text('ox_login.member');
            });
          }
        }
      } catch (e) {
        // If failed to get info, default to Member
        setState(() {
          item.role = Localized.text('ox_login.member');
        });
      }
    }
  }

  int get _selectedCount {
    return _circleItems.where((item) => item.isSelected).length;
  }


  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(),
      body: _buildBody(),
      bottomWidget: _buildBottomActions(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: CLLayout.horizontalPadding,
        right: CLLayout.horizontalPadding,
        top: 24.px,
        bottom: 100.px,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 24.px),
          _buildCirclesList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          width: 48.px,
          height: 48.px,
          decoration: BoxDecoration(
            color: ColorToken.primaryContainer.of(context),
            borderRadius: BorderRadius.circular(12.px),
          ),
          child: Icon(
            Icons.cloud_outlined,
            size: 24.px,
            color: ColorToken.primary.of(context),
          ),
        ),
        SizedBox(height: 16.px),
        // Title
        CLText.titleLarge(
          Localized.text('ox_login.welcome_back'),
          colorToken: ColorToken.onSurface,
        ),
        SizedBox(height: 12.px),
        // Description
        CLText.bodyMedium(
          Localized.text('ox_login.found_circles_description')
              .replaceAll('{count}', '${widget.circles.length}'),
          colorToken: ColorToken.onSurfaceVariant,
          maxLines: null,
        ),
      ],
    );
  }

  Widget _buildCirclesList() {
    return Column(
      children: _circleItems.map((item) => _buildCircleItem(item)).toList(),
    );
  }

  Widget _buildCircleItem(_CircleRestoreItem item) {
    final relayInfo = item.relayInfo;
    final name = relayInfo.tenantName.isNotEmpty 
        ? relayInfo.tenantName 
        : relayInfo.tenantId;
    final initials = _getInitials(name);
    final color = _getColorForCircle(name);
    final isCloud = relayInfo.subscriptionStatus.isNotEmpty &&
        relayInfo.subscriptionStatus != 'inactive';

    return Container(
      margin: EdgeInsets.only(bottom: 12.px),
      decoration: BoxDecoration(
        color: ColorToken.cardContainer.of(context),
        borderRadius: BorderRadius.circular(16.px),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              item.isSelected = !item.isSelected;
            });
          },
          borderRadius: BorderRadius.circular(16.px),
          child: Padding(
            padding: EdgeInsets.all(16.px),
            child: Row(
              children: [
                // Circle avatar
                Container(
                  width: 48.px,
                  height: 48.px,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CLText.titleMedium(
                      initials,
                      customColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12.px),
                // Circle info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CLText.titleMedium(
                              name,
                              colorToken: ColorToken.onSurface,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCloud) ...[
                            SizedBox(width: 8.px),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.px,
                                vertical: 4.px,
                              ),
                              decoration: BoxDecoration(
                                color: ColorToken.onSurfaceVariant.of(context).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.px),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 12.px,
                                    color: ColorToken.onSurfaceVariant.of(context),
                                  ),
                                  SizedBox(width: 4.px),
                                  CLText.labelSmall(
                                    'CLOUD',
                                    colorToken: ColorToken.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.px),
                      CLText.bodySmall(
                        item.relayInfo.relayUrl,
                        colorToken: ColorToken.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.px),
                // Checkbox
                Container(
                  width: 24.px,
                  height: 24.px,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.isSelected
                          ? ColorToken.primary.of(context)
                          : ColorToken.onSurfaceVariant.of(context).withOpacity(0.3),
                      width: 2,
                    ),
                    color: item.isSelected
                        ? ColorToken.primary.of(context)
                        : Colors.transparent,
                  ),
                  child: item.isSelected
                      ? Icon(
                          Icons.check,
                          size: 16.px,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Set up as new device link
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.px),
          child: GestureDetector(
            onTap: _onSetUpAsNewDevice,
            child: CLText.bodyMedium(
              Localized.text('ox_login.skip'),
              colorToken: ColorToken.primary,
            ),
          ),
        ),
        // Restore button
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: 16.px,
          ),
          child: CLButton.filled(
            text: _selectedCount > 0
                ? Localized.text('ox_login.restore_circles')
                    .replaceAll('{count}', '$_selectedCount')
                : Localized.text('ox_login.restore_circle'),
            onTap: _selectedCount > 0 && !_isRestoring ? _onRestore : null,
            expanded: true,
            height: 48.px,
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
  }

  Color _getColorForCircle(String name) {
    // Generate a consistent color based on name
    final colors = [
      Color(0xFF2196F3), // Blue
      Color(0xFF4CAF50), // Green
      Color(0xFF9C27B0), // Purple
      Color(0xFFFF9800), // Orange
      Color(0xFFF44336), // Red
      Color(0xFF00BCD4), // Cyan
    ];
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }

  void _onSetUpAsNewDevice() {
    // Navigate to circle selection page
    OXNavigator.pushPage(
      context,
      (_) => CircleSelectionPage(
        controller: widget.controller,
      ),
    );
  }

  Future<void> _onRestore() async {
    final selectedItems = _circleItems.where((item) => item.isSelected).toList();
    if (selectedItems.isEmpty) return;

    setState(() {
      _isRestoring = true;
    });

    OXLoading.show();

    try {
      // Restore circles one by one
      for (final item in selectedItems) {
        try {
          await CircleJoinUtils.processJoinCircle(
            input: item.relayInfo.relayUrl,
            context: context,
            usePreCheck: false, // Skip pre-check for restore
          );
        } catch (e) {
          debugPrint('Failed to restore circle ${item.relayInfo.tenantId}: $e');
          // Continue with other circles even if one fails
        }
      }

      // Profile update will be handled by onboarding controller if needed

      if (mounted) {
        OXLoading.dismiss();
        OXNavigator.popToRoot(context);
      }
    } catch (e) {
      OXLoading.dismiss();
      if (mounted) {
        CommonToast.instance.show(context, e.toString());
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }
}

