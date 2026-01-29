/// Subscription group id constants.
abstract class SubscriptionGroupIds {
  SubscriptionGroupIds._();

  static const String loc1 = 'loc1';
  static const String loc2 = 'loc2';
}

/// Subscription group: one server location. Same tier structure per group.
class SubscriptionGroup {
  final String id;
  final String displayName;
  final int sortOrder;

  const SubscriptionGroup({
    required this.id,
    required this.displayName,
    this.sortOrder = 0,
  });
}
