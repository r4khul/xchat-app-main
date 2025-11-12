import 'dart:async';

import 'package:ox_common/log_util.dart';

import 'app_review_service.dart';
import 'review_prompt_controller.dart';

class AppReviewManager {
  AppReviewManager._internal() : controller = AppReviewPromptController(
    service: AppReviewService(
      config: const AppReviewConfig(
        appStoreId: '6747972868',
      ),
    ),
  );

  static final AppReviewManager instance = AppReviewManager._internal();

  final AppReviewPromptController controller;
  bool _prepared = false;

  Future<void> prepare() async {
    if (_prepared) {
      return;
    }
    try {
      await controller.prepare();
      _prepared = true;
    } catch (error, stack) {
      LogUtil.e('AppReviewManager.prepare failed: $error\n$stack');
    }
  }

  Future<void> onProfileUpdated() async {
    await _maybeTriggerReview();
  }

  Future<void> onEnterAboutPage() async {
    await _maybeTriggerReview();
  }

  Future<void> _maybeTriggerReview() async {
    await prepare();
    try {
      final outcome = await controller.triggerReview();
      LogUtil.d('App review outcome: $outcome');
    } catch (error, stack) {
      LogUtil.e('Failed to trigger app review: $error\n$stack');
    }
  }
}