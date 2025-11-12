import 'package:flutter/foundation.dart';

import 'app_review_service.dart';

enum AppReviewStatus {
  idle,
  requesting,
  resolved,
  unavailable,
  unsupported,
  error,
}

@immutable
class AppReviewPromptState {
  const AppReviewPromptState({
    this.status = AppReviewStatus.idle,
    this.lastOutcome,
    this.error,
    this.stackTrace,
  });

  final AppReviewStatus status;
  final AppReviewOutcome? lastOutcome;
  final Object? error;
  final StackTrace? stackTrace;

  AppReviewPromptState copyWith({
    AppReviewStatus? status,
    Object? lastOutcome = _sentinel,
    Object? error = _sentinel,
    Object? stackTrace = _sentinel,
  }) {
    return AppReviewPromptState(
      status: status ?? this.status,
      lastOutcome: identical(lastOutcome, _sentinel)
          ? this.lastOutcome
          : lastOutcome as AppReviewOutcome?,
      error: identical(error, _sentinel) ? this.error : error,
      stackTrace: identical(stackTrace, _sentinel)
          ? this.stackTrace
          : stackTrace as StackTrace?,
    );
  }

  static const Object _sentinel = Object();
}

class AppReviewPromptController extends ValueNotifier<AppReviewPromptState> {
  AppReviewPromptController({
    required AppReviewService service,
  })  : _service = service,
        super(const AppReviewPromptState());

  final AppReviewService _service;

  Future<void> prepare() => _service.prepare();

  Future<AppReviewOutcome> triggerReview({
    bool? openStoreListingFallback,
  }) async {
    value = value.copyWith(
      status: AppReviewStatus.requesting,
      lastOutcome: null,
      error: null,
      stackTrace: null,
    );
    try {
      final outcome = await _service.requestReview(
        openStoreListingFallback: openStoreListingFallback,
      );
      value = value.copyWith(
        status: _mapOutcomeToStatus(outcome),
        lastOutcome: outcome,
      );
      return outcome;
    } catch (error, stack) {
      value = value.copyWith(
        status: AppReviewStatus.error,
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  void reset() {
    value = const AppReviewPromptState();
  }

  AppReviewStatus _mapOutcomeToStatus(AppReviewOutcome outcome) {
    switch (outcome) {
      case AppReviewOutcome.prompted:
      case AppReviewOutcome.openedStoreListing:
        return AppReviewStatus.resolved;
      case AppReviewOutcome.unavailable:
        return AppReviewStatus.unavailable;
      case AppReviewOutcome.unsupportedPlatform:
        return AppReviewStatus.unsupported;
      case AppReviewOutcome.error:
        return AppReviewStatus.error;
    }
  }

  Future<void> markUserRated() => _service.markUserRated();

  Future<void> markUserDeclined() => _service.markUserDeclined();

  Future<void> markRemindLater() => _service.markRemindLater();
}