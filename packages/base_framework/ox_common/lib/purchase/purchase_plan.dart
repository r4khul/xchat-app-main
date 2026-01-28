
import 'dart:ui';

import 'package:ox_localizable/ox_localizable.dart';

enum SubscriptionPeriod { monthly, yearly }

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final int maxUsers;
  final int fileSizeLimitMB;
  final double monthlyPrice;
  final double yearlyPrice;
  final Color cardColor;
  final bool isPopular;
  final String monthlyProductId; // Product ID for monthly subscription
  final String yearlyProductId; // Product ID for yearly subscription

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.maxUsers,
    required this.fileSizeLimitMB,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.cardColor,
    required this.monthlyProductId,
    required this.yearlyProductId,
    this.isPopular = false,
  });

  double getPrice(SubscriptionPeriod period) {
    return period == SubscriptionPeriod.monthly ? monthlyPrice : yearlyPrice;
  }

  String getPriceDisplay(SubscriptionPeriod period) {
    final price = getPrice(period);
    return period == SubscriptionPeriod.monthly
        ? '\$${price.toStringAsFixed(2)}/mo'
        : '\$${price.toStringAsFixed(2)}/yr';
  }

  int getAmountInCents(SubscriptionPeriod period) {
    return (getPrice(period) * 100).toInt();
  }

  String getLevelPeriod(SubscriptionPeriod period) {
    // Return period in seconds
    return period == SubscriptionPeriod.monthly
        ? '2592000' // 30 days
        : '31536000'; // 365 days
  }

  String getProductId(SubscriptionPeriod period) {
    return period == SubscriptionPeriod.monthly
        ? monthlyProductId
        : yearlyProductId;
  }

  int getLevel() {
    // Map plan to level: 1 = Lovers, 2 = Family, 3 = Community
    switch (id) {
      case 'lovers':
        return 1;
      case 'family':
        return 2;
      case 'community':
        return 3;
      default:
        return 1;
    }
  }

  /// Get file limit display text
  /// Returns "Unlimited file server" if fileSizeLimitMB is -1, otherwise returns "XMB file limit"
  String getFileLimitDisplay() {
    if (fileSizeLimitMB == -1) {
      return Localized.text('ox_login.unlimited_file_server');
    }
    return '${fileSizeLimitMB}MB ${Localized.text('ox_login.file_limit')}';
  }
}

extension SubscriptionPlanEx on SubscriptionPlan {
  static List<SubscriptionPlan> get allPlan => const [
    SubscriptionPlan(
      id: 'lovers',
      name: '2 Members',
      description: 'Perfect for couples or best friends',
      maxUsers: 2,
      fileSizeLimitMB: -1,
      monthlyPrice: 1.99,
      yearlyPrice: 19.99,
      cardColor: Color(0xFFFFE5F1),
      monthlyProductId: 'level1.monthly',
      yearlyProductId: 'level1.yearly',
    ),
    SubscriptionPlan(
      id: 'family',
      name: '6 Members',
      description: 'Great for small groups and families',
      maxUsers: 6,
      fileSizeLimitMB: -1,
      monthlyPrice: 5.99,
      yearlyPrice: 59.99,
      cardColor: Color(0xFFE5F0FF),
      isPopular: true,
      monthlyProductId: 'level2.monthly',
      yearlyProductId: 'level2.yearly',
    ),
    SubscriptionPlan(
      id: 'community',
      name: '20 Members',
      description: 'For larger groups and communities',
      maxUsers: 20,
      fileSizeLimitMB: -1,
      monthlyPrice: 19.99,
      yearlyPrice: 199.99,
      cardColor: Color(0xFFF0E5FF),
      monthlyProductId: 'level3.monthly',
      yearlyProductId: 'level3.yearly',
    ),
  ];
}