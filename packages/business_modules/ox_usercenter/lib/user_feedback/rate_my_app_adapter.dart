import 'dart:async';

import 'package:rate_my_app/rate_my_app.dart';

class RateMyAppAdapter {
  RateMyAppAdapter({
    RateMyApp? rateMyApp,
    required String preferencesPrefix,
    required int minDays,
    required int remindDays,
    required int minLaunches,
    required int remindLaunches,
    String? appStoreIdentifier,
    String? googlePlayIdentifier,
  }) : _rateMyApp = rateMyApp ??
      RateMyApp(
        preferencesPrefix: preferencesPrefix,
        minDays: minDays,
        remindDays: remindDays,
        minLaunches: minLaunches,
        remindLaunches: remindLaunches,
        appStoreIdentifier: appStoreIdentifier,
        googlePlayIdentifier: googlePlayIdentifier,
      );

  final RateMyApp _rateMyApp;
  bool _initialized = false;

  RateMyApp get rawInstance => _rateMyApp;

  Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }
    await _rateMyApp.init();
    _initialized = true;
  }

  Future<void> reset() async {
    await ensureInitialized();
    await _rateMyApp.reset();
  }

  Future<void> markLater() async {
    await ensureInitialized();
    await _rateMyApp.callEvent(RateMyAppEventType.laterButtonPressed);
  }

  Future<void> markRated() async {
    await ensureInitialized();
    await _rateMyApp.callEvent(RateMyAppEventType.rateButtonPressed);
  }

  Future<void> markDeclined() async {
    await ensureInitialized();
    await _rateMyApp.callEvent(RateMyAppEventType.noButtonPressed);
  }

  Future<void> markRequestReview() async {
    await ensureInitialized();
    await _rateMyApp.callEvent(RateMyAppEventType.requestReview);
  }

  bool get shouldPrompt {
    return _rateMyApp.shouldOpenDialog;
  }

  Future<bool> launchStore() async {
    await ensureInitialized();
    final LaunchStoreResult result = await _rateMyApp.launchStore();
    return result == LaunchStoreResult.storeOpened ||
        result == LaunchStoreResult.browserOpened;
  }
}