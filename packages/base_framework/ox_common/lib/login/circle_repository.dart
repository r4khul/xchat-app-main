import 'package:isar/isar.dart';
import 'package:ox_common/log_util.dart';
import 'login_models.dart';
import 'circle_isar.dart';

class CircleRepository {
  CircleRepository._();
  
  static Future<CircleISAR?> create(Isar accountDb, Circle circle) async {
    try {
      final isar = circle.toISAR();
      if (isar.pubkey.isEmpty) {
        LogUtil.w(() => 'Circle pubkey is required for storage');
        return null;
      }

      // Check if circle with same ID already exists for this pubkey
      final existing = await getById(accountDb, circle.id, pubkey: isar.pubkey);
      if (existing != null) {
        LogUtil.w(() => 'Circle with id ${circle.id} already exists for pubkey ${isar.pubkey}');
        return null;
      }

      // Assign auto-increment ID
      if (isar.id == 0) {
        isar.id = accountDb.circleISARs.autoIncrement();
      }

      await accountDb.writeAsync((accountDb) {
        accountDb.circleISARs.put(isar);
      });

      LogUtil.v(() => 'Circle created: ${circle.id} for pubkey ${isar.pubkey}');
      return isar;
    } catch (e) {
      LogUtil.e(() => 'Failed to create circle: $e');
      return null;
    }
  }

  static Future<CircleISAR?> getById(Isar accountDb, String circleId, {String? pubkey}) async {
    try {
      // Since circleId has unique index, we can query directly
      final circle = await accountDb.circleISARs
          .where()
          .circleIdEqualTo(circleId)
          .findFirst();
      
      // If pubkey is provided, verify it matches
      if (circle != null && pubkey != null && pubkey.isNotEmpty) {
        if (circle.pubkey != pubkey) {
          return null;
        }
      }
      
      return circle;
    } catch (e) {
      LogUtil.e(() => 'Failed to get circle by id: $e');
      return null;
    }
  }

  static Future<CircleISAR?> getByName(Isar accountDb, String name, String pubkey) async {
    try {
      if (pubkey.isEmpty) {
        return null;
      }

      // Get all circles for this pubkey and filter by name
      final circles = await accountDb.circleISARs
          .where()
          .pubkeyEqualTo(pubkey)
          .findAll();
      
      return circles.where((c) => c.name == name).firstOrNull;
    } catch (e) {
      LogUtil.e(() => 'Failed to get circle by name: $e');
      return null;
    }
  }

  static Future<List<CircleISAR>> getAll(Isar accountDb, String pubkey) async {
    try {
      if (pubkey.isEmpty) {
        return [];
      }

      return await accountDb.circleISARs
          .where()
          .pubkeyEqualTo(pubkey)
          .findAll();
    } catch (e) {
      LogUtil.e(() => 'Failed to get all circles: $e');
      return [];
    }
  }

  static Future<bool> update(Isar accountDb, Circle circle) async {
    try {
      if (circle.pubkey == null || circle.pubkey!.isEmpty) {
        LogUtil.w(() => 'Circle pubkey is required for update');
        return false;
      }

      final existing = await getById(accountDb, circle.id, pubkey: circle.pubkey);
      if (existing == null) {
        LogUtil.w(() => 'Circle with id ${circle.id} not found for pubkey ${circle.pubkey}');
        return false;
      }

      // Check name uniqueness if name changed
      if (existing.name != circle.name) {
        final nameConflict = await getByName(accountDb, circle.name, circle.pubkey!);
        if (nameConflict != null && nameConflict.circleId != circle.id) {
          LogUtil.w(() => 'Circle with name "${circle.name}" already exists');
          return false;
        }
      }

      // Update fields
      existing.name = circle.name;
      existing.relayUrl = circle.relayUrl;
      existing.type = circle.type;

      await accountDb.writeAsync((accountDb) {
        accountDb.circleISARs.put(existing);
      });

      LogUtil.v(() => 'Circle updated: ${circle.id}');
      return true;
    } catch (e) {
      LogUtil.e(() => 'Failed to update circle: $e');
      return false;
    }
  }

  static Future<bool> delete(Isar accountDb, String circleId, String pubkey) async {
    try {
      if (pubkey.isEmpty) {
        return false;
      }

      final existing = await getById(accountDb, circleId, pubkey: pubkey);
      if (existing == null) {
        LogUtil.w(() => 'Circle with id $circleId not found for pubkey $pubkey');
        return false;
      }

      await accountDb.writeAsync((accountDb) {
        accountDb.circleISARs.delete(existing.id);
      });

      LogUtil.v(() => 'Circle deleted: $circleId');
      return true;
    } catch (e) {
      LogUtil.e(() => 'Failed to delete circle: $e');
      return false;
    }
  }

  static Future<int> deleteAll(Isar accountDb, String pubkey) async {
    try {
      if (pubkey.isEmpty) {
        return 0;
      }

      final circles = await getAll(accountDb, pubkey);
      if (circles.isEmpty) {
        return 0;
      }

      final ids = circles.map((c) => c.id).toList();
      
      await accountDb.writeAsync((accountDb) {
        accountDb.circleISARs.deleteAll(ids);
      });

      LogUtil.v(() => 'Deleted ${ids.length} circles for pubkey $pubkey');
      return ids.length;
    } catch (e) {
      LogUtil.e(() => 'Failed to delete all circles: $e');
      return 0;
    }
  }
}
