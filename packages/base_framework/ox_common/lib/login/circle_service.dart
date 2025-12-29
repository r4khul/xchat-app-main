import 'package:isar/isar.dart';
import 'package:ox_common/log_util.dart';
import 'login_models.dart';
import 'circle_repository.dart';
import 'login_manager.dart';

class CircleService {
  CircleService._();

  static Future<Circle?> createCircle(Isar accountDb, Circle circle) async {
    final isar = await CircleRepository.create(accountDb, circle);
    if (isar == null) return null;
    final result = Circle.fromISAR(isar);
    result.pubkey = isar.pubkey;
    return result;
  }

  static Future<List<Circle>> getAllCircles(Isar accountDb, String pubkey) async {
    final circles = await CircleRepository.getAll(accountDb, pubkey);
    return circles.map((isar) {
      final circle = Circle.fromISAR(isar);
      circle.pubkey = isar.pubkey;
      return circle;
    }).toList();
  }

  static Future<Circle?> getCircleById(Isar accountDb, String circleId, {String? pubkey}) async {
    final isar = await CircleRepository.getById(accountDb, circleId, pubkey: pubkey);
    if (isar == null) return null;
    final result = Circle.fromISAR(isar);
    result.pubkey = isar.pubkey;
    return result;
  }

  static Future<Circle?> getCircleByName(Isar accountDb, String name, String pubkey) async {
    final isar = await CircleRepository.getByName(accountDb, name, pubkey);
    if (isar == null) return null;
    final result = Circle.fromISAR(isar);
    result.pubkey = isar.pubkey;
    return result;
  }

  static Future<bool> deleteCircle(Isar accountDb, String circleId, String pubkey) async {
    return await CircleRepository.delete(accountDb, circleId, pubkey);
  }

  static Future<int> deleteAllCircles(Isar accountDb, String pubkey) async {
    return await CircleRepository.deleteAll(accountDb, pubkey);
  }

  static Future<Circle?> updateCircleName(String circleId, String name) async {
    try {
      final newName = name.trim();
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

      // Validate name
      if (newName.isEmpty) {
        LogUtil.w(() => 'Circle name cannot be empty');
        return null;
      }

      // Create updated circle
      final updatedCircle = Circle(
        id: existingCircle.id,
        name: newName,
        relayUrl: existingCircle.relayUrl,
        type: existingCircle.type,
        pubkey: account.pubkey,
      );

      // Update in accountDB using CircleRepository
      final accountDb = account.db;
      final success = await CircleRepository.update(accountDb, updatedCircle);
      if (!success) {
        LogUtil.e(() => 'Failed to update circle in repository');
        return null;
      }

      // Update LoginManager's circle list
      final updatedCircles = existingCircles.map((c) {
        if (c.id == circleId) {
          return updatedCircle;
        }
        return c;
      }).toList();

      await loginManager.updatedCircles(updatedCircles);

      if (loginManager.currentCircle?.id == circleId) {
        loginManager.currentCircle?.name = newName;
      }

      LogUtil.v(() => 'Circle name updated: $circleId -> ${newName}');
      return updatedCircle;
    } catch (e) {
      LogUtil.e(() => 'Failed to update circle name: $e');
      return null;
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

      // Create updated circle
      final updatedCircle = Circle(
        id: existingCircle.id,
        name: existingCircle.name,
        relayUrl: relayUrl,
        type: existingCircle.type,
        pubkey: account.pubkey,
      );

      // Update in accountDB using CircleRepository
      final accountDb = account.db;
      final success = await CircleRepository.update(accountDb, updatedCircle);
      if (!success) {
        LogUtil.e(() => 'Failed to update circle in repository');
        return null;
      }

      // Update LoginManager's circle list
      final updatedCircles = existingCircles.map((c) {
        if (c.id == circleId) {
          return updatedCircle;
        }
        return c;
      }).toList();

      await loginManager.updatedCircles(updatedCircles);

      LogUtil.v(() => 'Circle relay URL updated: $circleId');
      return updatedCircle;
    } catch (e) {
      LogUtil.e(() => 'Failed to update circle relay URL: $e');
      return null;
    }
  }

  static Future<Circle?> updateCircle({
    required String circleId,
    String? name,
    String? relayUrl,
  }) async {
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

      // Create updated circle with provided values or existing values
      final updatedCircle = Circle(
        id: existingCircle.id,
        name: name?.trim() ?? existingCircle.name,
        relayUrl: relayUrl ?? existingCircle.relayUrl,
        type: existingCircle.type,
        pubkey: account.pubkey,
      );

      // Validate name if provided
      if (name != null && updatedCircle.name.isEmpty) {
        LogUtil.w(() => 'Circle name cannot be empty');
        return null;
      }

      // Update in accountDB using CircleRepository
      final accountDb = account.db;
      final success = await CircleRepository.update(accountDb, updatedCircle);
      if (!success) {
        LogUtil.e(() => 'Failed to update circle in repository');
        return null;
      }

      // Update LoginManager's circle list
      final updatedCircles = existingCircles.map((c) {
        if (c.id == circleId) {
          return updatedCircle;
        }
        return c;
      }).toList();

      await loginManager.updatedCircles(updatedCircles);

      LogUtil.v(() => 'Circle updated: $circleId');
      return updatedCircle;
    } catch (e) {
      LogUtil.e(() => 'Failed to update circle: $e');
      return null;
    }
  }
}

