import 'package:ox_common/login/login_models.dart';
import 'package:ox_common/purchase/subscription_group.dart';

/// Pure logic for selecting the first inactive subscription group (circle purchase entry).
///
/// Use [firstInactiveId] with (accountPubkey, circles, groups); avoid global state.
/// Call site is responsible for passing data (e.g. from LoginManager and SubscriptionRegistry).
class InactiveGroupSelection {
  InactiveGroupSelection._();

  /// Returns the first [SubscriptionGroup.id] that is not occupied by an owned circle
  /// (circle with [Circle.ownerPubkey] == [accountPubkey] and non-empty [Circle.groupId]).
  /// Returns null if all groups are occupied, or if [groups] is empty.
  ///
  /// When [accountPubkey] is null or empty, no circle counts as "owned", so the first
  /// group is returned if [groups] is non-empty (caller may use this for "not logged in" edge case).
  static String? firstInactiveId(
    String? accountPubkey,
    List<Circle> circles,
    List<SubscriptionGroup> groups,
  ) {
    if (groups.isEmpty) return null;
    if (accountPubkey == null || accountPubkey.isEmpty) {
      return groups.first.id;
    }
    final occupiedGroupIds = circles
        .where((c) =>
            c.groupId != null &&
            c.groupId!.isNotEmpty &&
            c.ownerPubkey != null &&
            c.ownerPubkey!.isNotEmpty &&
            c.ownerPubkey == accountPubkey)
        .map((c) => c.groupId!)
        .toSet();
    for (final group in groups) {
      if (!occupiedGroupIds.contains(group.id)) {
        return group.id;
      }
    }
    return null;
  }
}
