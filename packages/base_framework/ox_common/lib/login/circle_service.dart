import 'package:isar/isar.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/log_util.dart';
import 'package:ox_common/utils/account_credentials_utils.dart';
import 'login_models.dart';
import 'circle_repository.dart';
import 'login_manager.dart';

class CircleService {
  CircleService._();

  static Future<Circle?> createCircle(Isar accountDb, Circle circle) async {
    final isar = await CircleRepository.create(accountDb, circle);
    if (isar == null) return null;
    final result = Circle.fromISAR(isar);
    return result;
  }

  static Future<List<Circle>> getAllCircles(Isar accountDb) async {
    final circles = await CircleRepository.getAll(accountDb);
    return circles.map((isar) {
      final circle = Circle.fromISAR(isar);
      return circle;
    }).toList();
  }

  static Future<Circle?> getCircleById(Isar accountDb, String circleId) async {
    final isar = await CircleRepository.getById(accountDb, circleId);
    if (isar == null) return null;
    final result = Circle.fromISAR(isar);
    return result;
  }

  static Future<bool> deleteCircle(Isar accountDb, String circleId) async {
    return await CircleRepository.delete(accountDb, circleId);
  }

  static Future<int> deleteAllCircles(Isar accountDb) async {
    return await CircleRepository.deleteAll(accountDb);
  }

  static Future<Circle?> updateCircleName(String circleId, String name) async {
    try {
      final newName = name.trim();
      final loginManager = LoginManager.instance;
      final account = loginManager.currentState.account;
      if (account == null) {
        LogUtil.w(() => 'Account is null, cannot update circle');
        throw Exception('Account is null, cannot update circle');
      }

      // Get existing circle
      final existingCircles = account.circles;
      Circle existingCircle;
      try {
        existingCircle = existingCircles.firstWhere(
          (c) => c.id == circleId,
        );
      } catch (e) {
        LogUtil.e(() => 'Circle not found: $circleId');
        throw Exception('Circle not found');
      }

      // Validate name
      if (newName.isEmpty) {
        LogUtil.w(() => 'Circle name cannot be empty');
        throw Exception('Circle name cannot be empty');
      }

      // Check if name conflicts with other circles (case-insensitive)
      try {
        existingCircles.firstWhere(
          (c) => c.id != circleId && c.name.toLowerCase() == newName.toLowerCase(),
        );
        // If we reach here, there's a conflict
        LogUtil.w(() => 'Circle name "$newName" already exists');
        throw Exception('Circle name "$newName" already exists');
      } on StateError {
        // No conflict, continue
      }

      // Update circle name
      existingCircle.name = newName;

      // Update in accountDB using CircleRepository
      final accountDb = account.db;
      final success = await CircleRepository.update(accountDb, existingCircle);
      if (!success) {
        LogUtil.e(() => 'Failed to update circle in repository for circleId: $circleId, newName: $newName');
        throw Exception('Failed to update circle in database. The circle may not exist in the database or the update operation failed.');
      }

      LogUtil.v(() => 'Circle name updated: $circleId -> ${newName}');
      return existingCircle;
    } catch (e) {
      // Re-throw if it's already an Exception
      if (e is Exception) {
        rethrow;
      }
      LogUtil.e(() => 'Failed to update circle name: $e');
      throw Exception('Failed to update circle name: $e');
    }
  }

  static Future<Circle?> updateCircleRelayUrl(String circleId, String relayUrl) async {
    try {
      final loginManager = LoginManager.instance;
      final account = loginManager.currentState.account;
      if (account == null) {
        LogUtil.w(() => 'Account is null, cannot update circle');
        return null;
      }

      // Get existing circle
      final existingCircles = account.circles;
      final existingCircle = existingCircles.firstWhere(
        (c) => c.id == circleId,
        orElse: () => throw Exception('Circle not found'),
      );

      existingCircle.relayUrl = relayUrl;

      // Update in accountDB using CircleRepository
      final accountDb = account.db;
      final success = await CircleRepository.update(accountDb, existingCircle);
      if (!success) {
        LogUtil.e(() => 'Failed to update circle in repository');
        return null;
      }

      return existingCircle;
    } catch (e) {
      LogUtil.e(() => 'Failed to update circle relay URL: $e');
      return null;
    }
  }

  /// Fetches remote circle (relay address) info and updates local circles.
  ///
  /// Strongly bound to [RelayAddressInfo]: every persisted [Circle]/[CircleISAR]
  /// field that has a corresponding value in the remote response is updated:
  /// - [RelayAddressInfo.tenantName] → [Circle.name]
  /// - [RelayAddressInfo.relayUrl] → [Circle.relayUrl]
  /// - When a match is found, [Circle.category] is set to [CircleCategory.paid].
  ///
  /// Only circles that are paid relays (by [CircleApi.isPaidRelay]) are
  /// considered; others are skipped. Caller may call [LoginManager.instance.refreshState()]
  /// after this to refresh UI.
  static Future<void> fetchRemoteCircleInfoAndUpdateLocal(List<Circle> circles) async {
    if (circles.isEmpty) return;
    final account = LoginManager.instance.currentState.account;
    if (account == null) return;
    final creds = await AccountCredentialsUtils.getCredentials();
    if (creds == null) return;
    final pubkey = creds['pubkey']!;
    final privkey = creds['privkey']!;
    if (privkey.isEmpty || privkey == 'androidSigner' || privkey == 'remoteSigner') return;

    List<RelayAddressInfo> relays;
    try {
      relays = await CircleApi.getRelayAddresses(pubkey: pubkey, privkey: privkey);
    } catch (e) {
      LogUtil.w(() => 'fetchRemoteCircleInfoAndUpdateLocal: getRelayAddresses failed: $e');
      return;
    }

    final accountDb = account.db;
    for (final circle in circles) {
      if (!CircleApi.isPaidRelay(circle.relayUrl)) continue;
      final iter = relays.where((r) => r.relayUrl == circle.relayUrl);
      if (iter.isEmpty) continue;
      final info = iter.first;

      // Update all persisted properties that remote returns (strong binding to RelayAddressInfo)
      if (info.tenantName.isNotEmpty) {
        circle.name = info.tenantName;
      }
      circle.relayUrl = info.relayUrl;
      circle.category = CircleCategory.paid;

      final ok = await CircleRepository.update(accountDb, circle);
      if (!ok) {
        LogUtil.w(() => 'fetchRemoteCircleInfoAndUpdateLocal: update failed for ${circle.id}');
      }
    }
  }
}

