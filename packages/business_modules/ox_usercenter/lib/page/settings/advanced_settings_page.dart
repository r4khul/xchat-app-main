import 'package:flutter/cupertino.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/network/tor_network_helper.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_usercenter/utils/app_config_helper.dart';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({
    super.key,
    this.previousPageTitle,
  });

  final String? previousPageTitle;

  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  late ValueNotifier<bool> showMessageInfoOption$;
  late ValueNotifier<bool> useTorNetwork$;

  @override
  void initState() {
    super.initState();
    // Notifier is cached in AppConfigHelper, no need to dispose
    showMessageInfoOption$ = AppConfigHelper.showMessageInfoOptionNotifier();
    useTorNetwork$ = AppConfigHelper.useTorNetworkNotifier();
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(
        title: Localized.text('ox_usercenter.advanced_settings'),
        previousPageTitle: widget.previousPageTitle,
      ),
      isSectionListPage: true,
      body: CLSectionListView(
        items: [
          SectionListViewItem(
            footer: Localized.text('ox_usercenter.show_message_info_option_description'),
            data: [
              SwitcherItemModel(
                icon: ListViewIcon.data(CupertinoIcons.info),
                title: Localized.text('ox_usercenter.show_message_info_option'),
                value$: showMessageInfoOption$,
                onChanged: (value) async {
                  await AppConfigHelper.updateShowMessageInfoOption(value);
                },
              ),
            ],
          ),
          SectionListViewItem(
            footer: Localized.text('ox_usercenter.use_tor_network_description'),
            data: [
              SwitcherItemModel(
                icon: ListViewIcon.data(CupertinoIcons.lock_shield),
                title: Localized.text('ox_usercenter.use_tor_network'),
                value$: useTorNetwork$,
                onChanged: (value) async {
                  await AppConfigHelper.updateUseTorNetwork(value);
                  if (value) {
                    TorNetworkHelper.initialize();
                  } else {
                    TorNetworkHelper.stop();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}