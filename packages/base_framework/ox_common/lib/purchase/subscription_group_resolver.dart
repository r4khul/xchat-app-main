import 'subscription_group.dart';

/// Resolves which subscription group to use (e.g. current inactive).
/// Currently returns loc1 only; no dependencies.
class SubscriptionGroupResolver {
  SubscriptionGroupResolver._();

  static final SubscriptionGroupResolver instance = SubscriptionGroupResolver._();

  /// Current inactive subscription group id. Caller passes this into CapacitySelectionPage.
  /// Temporary: always returns loc1.
  Future<String?> getCurrentInactiveGroupId() async {
    return SubscriptionGroupIds.loc1;
  }
}
