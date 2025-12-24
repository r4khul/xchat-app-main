import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/common_loading.dart' as Loading;
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';

import 'file_server_page.dart';
import 'profile_settings_page.dart';

enum _MenuAction { edit, delete }

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

  @override
  void initState() {
    super.initState();
    _circleName = widget.circle.name;
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
          
          // Update circle name in database
          final updatedCircle = await Account.sharedInstance.updatecircle(
            circleId: widget.circle.id,
            name: newName.trim(),
          );

          if (updatedCircle == null) {
            Loading.OXLoading.dismiss();
            CommonToast.instance.show(context, Localized.text('ox_common.operation_failed'));
            return false;
          }

          // Update LoginManager's circle list
          final account = LoginManager.instance.currentState.account;
          if (account != null) {
            final circles = account.circles.map((c) {
              if (c.id == widget.circle.id) {
                return Circle(
                  id: c.id,
                  name: newName.trim(),
                  relayUrl: c.relayUrl,
                  type: c.type,
                );
              }
              return c;
            }).toList();
            await LoginManager.instance.updatedCircles(circles);
          }

          Loading.OXLoading.dismiss();
          
          setState(() {
            _circleName = newName.trim();
          });

          CommonToast.instance.show(context, Localized.text('ox_common.save_success'));
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
    return [
      // Relay Server
      SectionListViewItem(
        footer: Localized.text('ox_usercenter.relay_server_description'),
        data: [
          LabelItemModel(
            icon: ListViewIcon.data(CupertinoIcons.antenna_radiowaves_left_right),
            title: Localized.text('ox_usercenter.relay_server'),
            value$: ValueNotifier(widget.circle.relayUrl),
            onTap: null,
          ),
        ],
      ),
      // File Server Setting (Server Settings)
      SectionListViewItem(
        footer: Localized.text('ox_usercenter.file_server_setting_description'),
        data: [
          CustomItemModel(
            leading: const Icon(CupertinoIcons.settings),
            titleWidget: CLText(Localized.text('ox_usercenter.file_server_setting')),
            onTap: () {
              OXNavigator.pushPage(context, (_) => FileServerPage(
                previousPageTitle: widget.title,
              ));
            },
          ),
        ],
      ),
    ];
  }
}