import 'package:flutter/material.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/purchase/inactive_group_utils.dart';
import 'package:ox_common/purchase/subscription_registry.dart';
import 'package:ox_common/utils/account_credentials_utils.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_login/controller/onboarding_controller.dart';
import 'package:ox_login/page/circle_restore_page.dart';

/// Unified helper for circle-related entry flows: restore check, navigation,
/// and subscription group resolution. Use this when navigating to add-circle
/// or capacity-selection flows.
abstract class CircleEntryHelper {
  CircleEntryHelper._();

  // ----- Restore check & navigation (add-circle entry) -----

  /// Fetches relay addresses for the current account for the circle-restore
  /// flow. Returns null when credentials are unavailable, the API returns
  /// empty, or the API throws.
  static Future<List<RelayAddressInfo>?> fetchCirclesToRestore() async {
    try {
      final credentials = await AccountCredentialsUtils.getCredentials();
      if (credentials == null) {
        return null;
      }

      final circles = await CircleApi.getRelayAddresses(
        pubkey: credentials['pubkey']!,
        privkey: credentials['privkey']!,
      );
      return circles.isNotEmpty ? circles : null;
    } catch (e) {
      debugPrint('CircleEntryHelper: failed to fetch circles to restore: $e');
      return null;
    }
  }

  /// If the current account has circles to restore (fetched relays that are
  /// not already in the account's circles), pushes [CircleRestorePage] and
  /// returns `true`. Caller should then do nothing.
  /// Otherwise returns `false`; caller should proceed with original logic
  /// (e.g. push [CircleSelectionPage]).
  static Future<bool> tryNavigateToCircleRestoreIfNeeded(
      BuildContext context, {
        OnboardingController? controller,
        OXPushPageType type = OXPushPageType.slideToLeft,
        bool fullscreenDialog = false,
      }) async {
    OXLoading.show();
    final fetched = await fetchCirclesToRestore();
    OXLoading.dismiss();
    if (!context.mounted) return false;
    if (fetched == null || fetched.isEmpty) return false;

    final currentRelayUrls = LoginManager.instance.currentState.account?.circles
        .map((c) => c.relayUrl)
        .toSet() ?? {};
    final circlesToRestore =
    fetched.where((r) => !currentRelayUrls.contains(r.relayUrl)).toList();
    if (circlesToRestore.isEmpty) return false;

    OXNavigator.pushPage(
      context,
          (_) => CircleRestorePage(circles: circlesToRestore, controller: controller),
      type: type,
      fullscreenDialog: fullscreenDialog,
    );
    return true;
  }

  // ----- Subscription group (capacity entry) -----

  /// Current inactive subscription group id. Caller passes this into
  /// [CapacitySelectionPage]. Returns the first subscription group that is not
  /// occupied by an owned circle (circle with pubkey == account.pubkey and matching
  /// groupId counts as occupied). Returns null if all groups are occupied.
  static Future<String?> getCurrentInactiveGroupId() async {
    final account = LoginManager.instance.currentState.account;
    final groups = SubscriptionRegistry.instance.groups;
    return InactiveGroupSelection.firstInactiveId(
      account?.pubkey,
      account?.circles ?? [],
      groups,
    );
  }
}