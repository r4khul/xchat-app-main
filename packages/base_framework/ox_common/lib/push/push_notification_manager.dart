import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ox_common/push/core/local_push_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:chatcore/chat-core.dart';

class CLUserPushNotificationManager implements PushPermissionChecker {
  static final CLUserPushNotificationManager instance = CLUserPushNotificationManager._internal();
  CLUserPushNotificationManager._internal() {
    NotificationHelper.sharedInstance.permissionChecker = this;
  }

  final ValueNotifier<bool> _allowSendNotificationNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _allowReceiveNotificationNotifier = ValueNotifier<bool>(false);

  ValueNotifier<bool> get allowSendNotificationNotifier => _allowSendNotificationNotifier;
  ValueNotifier<bool> get allowReceiveNotificationNotifier => _allowReceiveNotificationNotifier;

  bool get allowSendNotification => _allowSendNotificationNotifier.value;
  bool get allowReceiveNotification => _allowReceiveNotificationNotifier.value;

  Completer _initCmp = Completer();

  Future<void> initialize() async {
    final currentState = LoginManager.instance.currentState;
    final circle = currentState.currentCircle;

    if (circle == null) return;

    await _loadConfiguration(circle);

    _initCmp.complete();

    if (allowReceiveNotification || allowSendNotification) {
      NotificationHelper.sharedInstance.connectServerRelay();
    }

    await checkAndUpdatePermissionStatus();
  }

  Future registerPushTokenHandler(String token) async {
    final currentState = LoginManager.instance.currentState;
    final circle = currentState.currentCircle;

    if (circle == null) return;

    await _initCmp.future;

    if (!_isConfigurationInitialized(circle)) {
      await _initializeDefaultConfiguration(circle);
      return;
    }

    final allowReceive = _allowReceiveNotificationNotifier.value;
    if (allowReceive) {
      NotificationHelper.sharedInstance.updateNotificationDeviceId(token);
    }
  }

  Future<void> setAllowSendNotification(bool value) async {
    if (_allowSendNotificationNotifier.value == value) return;

    final currentState = LoginManager.instance.currentState;
    final circle = currentState.currentCircle;
    if (circle == null) return;

    await circle.updateAllowSendNotification(value);

    _allowSendNotificationNotifier.value = value;
  }

  // Return error message
  Future<String?> setAllowReceiveNotification(bool value) async {
    if (_allowReceiveNotificationNotifier.value == value) return null;

    final currentState = LoginManager.instance.currentState;
    final circle = currentState.currentCircle;
    if (circle == null) return Localized.text('ox_common.logged_circle_not_found');

    if (value) {
      // Check push permission
      final hasPermission = await _checkNativePushPermission();
      if (!hasPermission) {
        _showPermissionDialog().then((shouldGoToSettings) {
          if (shouldGoToSettings) {
            openAppSettings();
          }
        });
        return null;
      }

      final pushToken = currentState.account?.pushToken;
      if (pushToken == null || pushToken.isEmpty) {
        return Localized.text('ox_common.push_token_is_null');
      }

      final event = await NotificationHelper.sharedInstance.updateNotificationDeviceId(pushToken);
      if (!event.status) {
        return event.message;
      }
    } else {
      final event = await NotificationHelper.sharedInstance.removeNotification();
      if (!event.status) {
        return event.message;
      }
    }

    await circle.updateAllowReceiveNotification(value);

    _allowReceiveNotificationNotifier.value = value;

    return null;
  }

  Future<void> checkAndUpdatePermissionStatus() async {
    if (!allowReceiveNotification) return;

    final hasPermission = await _checkNativePushPermission();
    if (!hasPermission) {
      await setAllowReceiveNotification(false);
    }
  }

  Future<void> _loadConfiguration(Circle circle) async {
    _allowSendNotificationNotifier.value = circle.allowSendNotification;
    _allowReceiveNotificationNotifier.value = circle.allowReceiveNotification;
  }

  bool _isConfigurationInitialized(Circle circle) {
    return circle.isNotificationSettingsInitialized;
  }

  Future<void> _initializeDefaultConfiguration(Circle circle) async {
    final hasPermission = await _checkNativePushPermission();
    await setAllowSendNotification(hasPermission);
    await setAllowReceiveNotification(hasPermission).then((err) {
      if (err != null) setAllowReceiveNotification(false);
    });
  }

  Future<bool> _checkNativePushPermission() async {
    return LocalPushKit.instance.requestPermission();
  }

  Future<bool> _showPermissionDialog() async {
    final context = OXNavigator.navigatorKey.currentContext;
    if (context == null) return false;

    final result = await CLAlertDialog.show<bool>(
      context: context,
      title: Localized.text('ox_common.tips'),
      content: Localized.text('ox_common.push_permission_required_hint'),
      actions: [
        CLAlertAction.cancel(),
        CLAlertAction<bool>(
          label: Localized.text('ox_common.str_go_to_settings'),
          value: true,
          isDefaultAction: true,
        ),
      ],
    );
    
    return result ?? false;
  }

  void dispose() {
    _initCmp = Completer();
    _allowSendNotificationNotifier.dispose();
    _allowReceiveNotificationNotifier.dispose();
  }

  @override
  Future<bool> canReceiveNotification() async => allowReceiveNotification;

  @override
  Future<bool> canSendNotification() async => allowSendNotification;
}
