import 'package:flutter/foundation.dart';
import 'package:ox_cache_manager/ox_cache_manager.dart';
import 'package:ox_common/log_util.dart';

enum AppConfigKeys {
  showMessageInfoOption('app_config_show_message_info_option'),
  useTorNetwork('app_config_use_tor_network');

  const AppConfigKeys(this.value);
  final String value;
}

class AppConfigHelper {
  static final Map<AppConfigKeys, ValueNotifier> _notifierCache = {};

  static ValueNotifier<bool> showMessageInfoOptionNotifier() {
    return AppConfigKeys.showMessageInfoOption._getNotifier(defaultValue: false);
  }

  static Future<void> updateShowMessageInfoOption(bool value) async {
    await AppConfigKeys.showMessageInfoOption._updateNotifier(value);
  }

  static ValueNotifier<bool> useTorNetworkNotifier() {
    return AppConfigKeys.useTorNetwork._getNotifier(defaultValue: false);
  }

  static Future<void> updateUseTorNetwork(bool value) async {
    await AppConfigKeys.useTorNetwork._updateNotifier(value);
  }

  /// Preload advanced settings before presenting UI to avoid toggle flicker.
  static Future<void> preloadAdvancedSettings() async {
    final showMessageInfo =
        await AppConfigKeys.showMessageInfoOption._getValue(defaultValue: false);
    AppConfigKeys.showMessageInfoOption
        ._setNotifierValue(defaultValue: false, value: showMessageInfo);

    final useTor = await AppConfigKeys.useTorNetwork._getValue(defaultValue: false);
    AppConfigKeys.useTorNetwork
        ._setNotifierValue(defaultValue: false, value: useTor);
  }
}

extension _AppConfigKeysExtension on AppConfigKeys {
  Future<T> _getValue<T>({required T defaultValue}) async {
    try {
      final value = await OXCacheManager.defaultOXCacheManager.getForeverData(
        this.value,
        defaultValue: defaultValue,
      );
      if (value is T) {
        return value;
      }
      return defaultValue;
    } catch (e) {
      LogUtil.e('Failed to get app config ${this.value}: $e');
      return defaultValue;
    }
  }

  ValueNotifier<T> _getNotifier<T>({required T defaultValue}) {
    ValueNotifier? notifier = AppConfigHelper._notifierCache[this];
    if (notifier is ValueNotifier<T>) return notifier;

    notifier = ValueNotifier<T>(defaultValue);
    AppConfigHelper._notifierCache[this] = notifier;

    // Load initial value
    _getValue(defaultValue: defaultValue).then((value) {
      notifier?.value = value;
    });

    return notifier;
  }

  Future<void> _updateNotifier<T>(T value) async {
    await OXCacheManager.defaultOXCacheManager.saveForeverData(this.value, value);
    // Update cached notifier if exists
    final notifier = AppConfigHelper._notifierCache[this];
    if (notifier is ValueNotifier<T>) {
      notifier.value = value;
    }
  }

  void _setNotifierValue<T>({required T defaultValue, required T value}) {
    final notifier = _getNotifier(defaultValue: defaultValue);
    notifier.value = value;
  }
}