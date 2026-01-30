import 'package:flutter_test/flutter_test.dart';
import 'package:ox_common/purchase/subscription_registry.dart';
import 'package:ox_common/purchase/subscription_group.dart';
import 'package:ox_common/purchase/subscription_period.dart';
import 'package:ox_common/purchase/subscription_tier.dart';

void main() {
  late SubscriptionRegistry registry;

  setUp(() {
    registry = SubscriptionRegistry.instance;
  });

  group('SubscriptionRegistry', () {
    group('groups', () {
      test('returns non-empty list', () {
        expect(registry.groups, isNotEmpty);
      });

      test('contains loc1', () {
        final ids = registry.groups.map((g) => g.id).toList();
        expect(ids, contains(SubscriptionGroupIds.loc1));
      });

      test('groups have displayName and sortOrder', () {
        for (final g in registry.groups) {
          expect(g.displayName, isNotEmpty);
          expect(g.sortOrder, isNonNegative);
        }
      });
    });

    group('productIdFor', () {
      test('returns correct productId for loc1 family monthly', () {
        expect(
          registry.productIdFor(
            SubscriptionGroupIds.loc1,
            SubscriptionTierIds.family,
            SubscriptionPeriod.monthly,
          ),
          'loc1.level2.monthly',
        );
      });

      test('returns correct productId for loc1 lovers yearly', () {
        expect(
          registry.productIdFor(
            SubscriptionGroupIds.loc1,
            SubscriptionTierIds.lovers,
            SubscriptionPeriod.yearly,
          ),
          'loc1.level1.yearly',
        );
      });

      test('returns correct productId for loc1 community monthly', () {
        expect(
          registry.productIdFor(
            SubscriptionGroupIds.loc1,
            SubscriptionTierIds.community,
            SubscriptionPeriod.monthly,
          ),
          'loc1.level3.monthly',
        );
      });

      test('throws StateError for unknown groupId', () {
        expect(
          () => registry.productIdFor(
            'unknown_group',
            SubscriptionTierIds.family,
            SubscriptionPeriod.monthly,
          ),
          throwsStateError,
        );
      });

      test('throws StateError for unknown tierId', () {
        expect(
          () => registry.productIdFor(
            SubscriptionGroupIds.loc1,
            'unknown_tier',
            SubscriptionPeriod.monthly,
          ),
          throwsStateError,
        );
      });
    });

    group('groupForProductId', () {
      test('returns group for valid productId', () {
        final group = registry.groupForProductId('loc1.level2.monthly');
        expect(group, isNotNull);
        expect(group!.id, SubscriptionGroupIds.loc1);
      });

      test('returns null for unknown productId', () {
        expect(registry.groupForProductId('unknown.product.id'), isNull);
      });
    });

    group('tierForProductId', () {
      test('returns tier for valid productId', () {
        final tier = registry.tierForProductId('loc1.level2.monthly');
        expect(tier, isNotNull);
        expect(tier!.id, SubscriptionTierIds.family);
      });

      test('returns null for unknown productId', () {
        expect(registry.tierForProductId('unknown.product.id'), isNull);
      });
    });

    group('allProductIds', () {
      test('returns non-empty set', () {
        expect(registry.allProductIds, isNotEmpty);
      });

      test('contains loc1 productIds', () {
        expect(registry.allProductIds, contains('loc1.level1.monthly'));
        expect(registry.allProductIds, contains('loc1.level2.yearly'));
      });
    });

    group('tiersForGroup', () {
      test('returns non-empty tiers for valid groupId', () {
        final tiers = registry.tiersForGroup(SubscriptionGroupIds.loc1);
        expect(tiers, isNotEmpty);
      });

      test('returns empty list for unknown groupId', () {
        final tiers = registry.tiersForGroup('unknown_group');
        expect(tiers, isEmpty);
      });
    });
  });
}
