import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/font_size_notifier.dart';
import 'package:ox_common/utils/extension.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_theme/ox_theme.dart';
import 'package:ox_usercenter/page/settings/language_settings_page.dart';
import 'package:ox_usercenter/page/settings/theme_settings_page.dart';
import 'package:ox_usercenter/page/settings/font_size_settings_page.dart';

class SettingsDetailPage extends StatefulWidget {
  const SettingsDetailPage({
    super.key,
    this.previousPageTitle,
  });

  final String? previousPageTitle;

  @override
  State<SettingsDetailPage> createState() => _SettingsDetailPageState();
}

class _SettingsDetailPageState extends State<SettingsDetailPage> {
  late ValueNotifier themeItemNty;
  late ValueNotifier languageItemNty;
  late ValueNotifier textSizeItemNty;

  String get title => Localized.text('ox_usercenter.preferences');

  @override
  void initState() {
    super.initState();
    prepareNotifier();

    languageItemNty.addListener(() {
      // Update label notifier when language changed.
      themeItemNty.value = themeManager.themeStyle.text;
      setState(() {});
    });
  }

  void prepareNotifier() {
    themeItemNty = themeManager.styleNty.map((style) => style.text);
    languageItemNty = Localized.localized.localeTypeNty.map((type) => type.languageText);
    textSizeItemNty = textScaleFactorNotifier.map((scale) => getFormattedTextSize(scale));
  }

  @override
  void dispose() {
    languageItemNty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(
        title: title,
        previousPageTitle: widget.previousPageTitle,
      ),
      isSectionListPage: true,
      body: CLSectionListView(
        items: [
          SectionListViewItem(
            data: [
              LabelItemModel(
                icon: ListViewIcon(iconName: 'icon_setting_theme.png', package: 'ox_usercenter'),
                title: Localized.text('ox_usercenter.theme'),
                value$: themeItemNty,
                onTap: themeItemOnTap,
              ),
              LabelItemModel(
                icon: ListViewIcon(iconName: 'icon_setting_lang.png', package: 'ox_usercenter'),
                title: Localized.text('ox_usercenter.language'),
                value$: languageItemNty,
                onTap: languageItemOnTap,
              ),
              LabelItemModel(
                icon: ListViewIcon(iconName: 'icon_setting_textsize.png', package: 'ox_usercenter'),
                title: Localized.text('ox_usercenter.text_size'),
                value$: textSizeItemNty,
                onTap: textSizeItemOnTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void themeItemOnTap() {
    OXNavigator.pushPage(context, (_) => ThemeSettingsPage(previousPageTitle: title,));
  }

  void languageItemOnTap() {
    OXNavigator.pushPage(context, (_) => LanguageSettingsPage(previousPageTitle: title,));
  }

  void textSizeItemOnTap() {
    OXNavigator.pushPage(context, (_) => FontSizeSettingsPage(previousPageTitle: title,));
  }
}

