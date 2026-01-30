import 'package:flutter_test/flutter_test.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_common/purchase/inactive_group_utils.dart';
import 'package:ox_common/purchase/subscription_group.dart';

void main() {
  const loc1 = SubscriptionGroup(
    id: SubscriptionGroupIds.loc1,
    displayName: 'Server location 1',
    sortOrder: 0,
  );
  const loc2 = SubscriptionGroup(
    id: SubscriptionGroupIds.loc2,
    displayName: 'Server location 2',
    sortOrder: 1,
  );
  const groupsLoc1Only = [loc1];
  const groupsLoc1Loc2 = [loc1, loc2];

  Circle circle({
    required String name,
    required String relayUrl,
    String? ownerPubkey,
    String? groupId,
  }) {
    return Circle(
      name: name,
      relayUrl: relayUrl,
      ownerPubkey: ownerPubkey,
      groupId: groupId,
    );
  }

  group('InactiveGroupSelection.firstInactiveId', () {
    test('E-01: returns first group when no circles (no account slots occupied)', () {
      expect(
        InactiveGroupSelection.firstInactiveId('pk1', [], groupsLoc1Only),
        SubscriptionGroupIds.loc1,
      );
      expect(
        InactiveGroupSelection.firstInactiveId('pk1', [], groupsLoc1Loc2),
        SubscriptionGroupIds.loc1,
      );
    });

    test('E-02: returns first group when circles exist but none owned by account', () {
      final circles = [
        circle(name: 'c1', relayUrl: 'wss://a', ownerPubkey: 'other', groupId: SubscriptionGroupIds.loc1),
      ];
      expect(
        InactiveGroupSelection.firstInactiveId('pk1', circles, groupsLoc1Loc2),
        SubscriptionGroupIds.loc1,
      );
    });

    test('E-03: returns null when all groups occupied by owned circles', () {
      final circles = [
        circle(name: 'c1', relayUrl: 'wss://a', ownerPubkey: 'pk1', groupId: SubscriptionGroupIds.loc1),
      ];
      expect(
        InactiveGroupSelection.firstInactiveId('pk1', circles, groupsLoc1Only),
        isNull,
      );
    });

    test('E-03: returns second group when first occupied', () {
      final circles = [
        circle(name: 'c1', relayUrl: 'wss://a', ownerPubkey: 'pk1', groupId: SubscriptionGroupIds.loc1),
      ];
      expect(
        InactiveGroupSelection.firstInactiveId('pk1', circles, groupsLoc1Loc2),
        SubscriptionGroupIds.loc2,
      );
    });

    test('E-05: accountPubkey null returns first group when groups non-empty', () {
      expect(
        InactiveGroupSelection.firstInactiveId(null, [], groupsLoc1Only),
        SubscriptionGroupIds.loc1,
      );
    });

    test('E-06: empty groups returns null', () {
      expect(
        InactiveGroupSelection.firstInactiveId('pk1', [], []),
        isNull,
      );
      expect(
        InactiveGroupSelection.firstInactiveId(null, [], []),
        isNull,
      );
    });

    test('ignores circles with empty groupId', () {
      final circles = [
        circle(name: 'c1', relayUrl: 'wss://a', ownerPubkey: 'pk1', groupId: null),
        circle(name: 'c2', relayUrl: 'wss://b', ownerPubkey: 'pk1', groupId: ''),
      ];
      expect(
        InactiveGroupSelection.firstInactiveId('pk1', circles, groupsLoc1Only),
        SubscriptionGroupIds.loc1,
      );
    });

    test('ignores circles with empty ownerPubkey', () {
      final circles = [
        circle(name: 'c1', relayUrl: 'wss://a', ownerPubkey: null, groupId: SubscriptionGroupIds.loc1),
        circle(name: 'c2', relayUrl: 'wss://b', ownerPubkey: '', groupId: SubscriptionGroupIds.loc2),
      ];
      expect(
        InactiveGroupSelection.firstInactiveId('pk1', circles, groupsLoc1Loc2),
        SubscriptionGroupIds.loc1,
      );
    });

    test('empty accountPubkey returns first group (same as null)', () {
      expect(
        InactiveGroupSelection.firstInactiveId('', [], groupsLoc1Only),
        SubscriptionGroupIds.loc1,
      );
    });
  });
}
