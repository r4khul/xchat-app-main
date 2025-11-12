import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:ox_common/log_util.dart';

import 'rate_my_app_adapter.dart';

enum AppReviewOutcome {
  prompted,
  openedStoreListing,
  unavailable,
  unsupportedPlatform,
  error,
}

class AppReviewConfig {
  const AppReviewConfig({
    this.appStoreId,
    this.googlePlayId,
    this.openStoreListingFallback = true,
    this.minimumIntervalBetweenPrompts = const Duration(days: 90),
    this.minimumInstallDuration = const Duration(days: 7),
    this.minimumAppLaunches = 10,
    this.remindLaunches = 10,
    this.preferencesPrefix = 'ox_rate_my_app_',
    this.bypassAvailabilityCheck = false,
  });

  final String? appStoreId;
  final String? googlePlayId;
  final bool openStoreListingFallback;
  final Duration minimumIntervalBetweenPrompts;
  final Duration minimumInstallDuration;
  final int minimumAppLaunches;
  final int remindLaunches;
  final String preferencesPrefix;
  final bool bypassAvailabilityCheck;
}

class AppReviewService {
  AppReviewService({
    required AppReviewConfig config,
    InAppReview? inAppReview,
    RateMyAppAdapter? rateMyAppAdapter,
    DateTime Function()? nowProvider,
  })  : _config = config,
        _inAppReview = inAppReview ?? InAppReview.instance,
        _rateMyAppAdapter = rateMyAppAdapter ??
            RateMyAppAdapter(
              preferencesPrefix: config.preferencesPrefix,
              minDays: _durationToPositiveDays(config.minimumInstallDuration),
              remindDays:
              _durationToPositiveDays(config.minimumIntervalBetweenPrompts),
              minLaunches: config.minimumAppLaunches,
              remindLaunches: config.remindLaunches,
              appStoreIdentifier: config.appStoreId,
              googlePlayIdentifier: config.googlePlayId,
            ),
        _now = nowProvider ?? DateTime.now;

  final AppReviewConfig _config;
  final InAppReview _inAppReview;
  final RateMyAppAdapter _rateMyAppAdapter;
  final DateTime Function() _now;
  DateTime? _lastPrompt;

  AppReviewOutcome? get lastOutcome => _lastOutcome;
  AppReviewOutcome? _lastOutcome;

  DateTime? get lastPromptedAt => _lastPrompt;

  Future<void> prepare() async {
    await _rateMyAppAdapter.ensureInitialized();
  }

  Future<AppReviewOutcome> requestReview({
    bool? openStoreListingFallback,
  }) async {
    await _rateMyAppAdapter.ensureInitialized();

    if (!_rateMyAppAdapter.shouldPrompt) {
      LogUtil.d('RateMyApp conditions not met for review prompt');
      return _storeOutcome(AppReviewOutcome.unavailable);
    }

    if (kIsWeb || _isUnsupportedPlatform()) {
      LogUtil.d('App review request skipped: unsupported platform');
      return _storeOutcome(AppReviewOutcome.unsupportedPlatform);
    }

    try {
      final bool isAvailable =
          _config.bypassAvailabilityCheck || await _inAppReview.isAvailable();
      if (!isAvailable) {
        LogUtil.d('In-app review unavailable on this device');
        return await _handleUnavailable(openStoreListingFallback);
      }
      await _rateMyAppAdapter.markRequestReview();
      await _inAppReview.requestReview();
      _lastPrompt = _now();
      return _storeOutcome(AppReviewOutcome.prompted);
    } catch (error, stack) {
      LogUtil.e('In-app review request failed: $error\n$stack');
      return await _handleError(openStoreListingFallback);
    }
  }

  Future<AppReviewOutcome> openStoreListing() async {
    if (_config.appStoreId == null || _config.appStoreId!.isEmpty) {
      LogUtil.w('openStoreListing skipped: appStoreId is not configured');
      return _storeOutcome(AppReviewOutcome.unavailable);
    }
    await _rateMyAppAdapter.ensureInitialized();
    try {
      final bool opened = await _rateMyAppAdapter.launchStore();
      if (opened) {
        await _rateMyAppAdapter.markRated();
        return _storeOutcome(AppReviewOutcome.openedStoreListing);
      }
      LogUtil.w('Failed to open store listing via RateMyApp launchStore');
      return _storeOutcome(AppReviewOutcome.error);
    } catch (error, stack) {
      LogUtil.e('Failed to open store listing: $error\n$stack');
      return _storeOutcome(AppReviewOutcome.error);
    }
  }

  Future<void> markUserRated() => _rateMyAppAdapter.markRated();

  Future<void> markUserDeclined() => _rateMyAppAdapter.markDeclined();

  Future<void> markRemindLater() => _rateMyAppAdapter.markLater();

  Future<AppReviewOutcome> _handleUnavailable(bool? openStoreListingFallback) async {
    final bool shouldFallback =
        openStoreListingFallback ?? _config.openStoreListingFallback;
    if (!shouldFallback) {
      return _storeOutcome(AppReviewOutcome.unavailable);
    }
    return await openStoreListing();
  }

  Future<AppReviewOutcome> _handleError(bool? openStoreListingFallback) async {
    final bool shouldFallback =
        openStoreListingFallback ?? _config.openStoreListingFallback;
    if (shouldFallback) {
      final AppReviewOutcome outcome = await openStoreListing();
      if (outcome == AppReviewOutcome.openedStoreListing) {
        return outcome;
      }
    }
    return _storeOutcome(AppReviewOutcome.error);
  }

  bool _isUnsupportedPlatform() {
    // Only iOS is supported for now.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return false;
    }
    return true;
  }

  AppReviewOutcome _storeOutcome(AppReviewOutcome outcome) {
    _lastOutcome = outcome;
    return outcome;
  }

  static int _durationToPositiveDays(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) {
      return 0;
    }
    final int days = duration.inDays;
    if (days > 0) {
      return days;
    }
    return 1;
  }
}