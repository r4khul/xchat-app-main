import 'subscription_period.dart';

/// Tier identifiers. Fixed mapping lovers→1, family→2, community→3.
abstract class SubscriptionTierIds {
  SubscriptionTierIds._();

  static const String lovers = 'lovers';
  static const String family = 'family';
  static const String community = 'community';
}

/// Subscription tier: capacity and pricing only. No UI fields, no productIds.
/// UI controls display (name, description, color, isPopular) via tier id.
class SubscriptionTier {
  final String id;
  final int maxUsers;
  final int fileSizeLimitMB;
  final double monthlyPrice;
  final double yearlyPrice;

  const SubscriptionTier({
    required this.id,
    required this.maxUsers,
    required this.fileSizeLimitMB,
    required this.monthlyPrice,
    required this.yearlyPrice,
  });

  double price(SubscriptionPeriod period) =>
      period == SubscriptionPeriod.monthly ? monthlyPrice : yearlyPrice;

  int amountInCents(SubscriptionPeriod period) =>
      (price(period) * 100).round();

  String levelPeriod(SubscriptionPeriod period) =>
      period == SubscriptionPeriod.monthly ? '2592000' : '31536000';

  /// lovers→1, family→2, community→3. Fixed, no extension.
  int get level {
    switch (id) {
      case SubscriptionTierIds.lovers:
        return 1;
      case SubscriptionTierIds.family:
        return 2;
      case SubscriptionTierIds.community:
        return 3;
      default:
        return 1;
    }
  }
}
