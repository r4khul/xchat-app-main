import 'package:isar/isar.dart';
import 'package:ox_common/log_util.dart';
import 'login_models.dart';
import 'circle_isar.dart';

class CircleRepository {
  CircleRepository._();
  
  static Future<CircleISAR?> create(Isar accountDb, Circle circle) async {
    try {
      final isar = circle.toISAR();

      // Check if circle with same ID already exists
      final existing = await getById(accountDb, circle.id);
      if (existing != null) {
        LogUtil.w(() => 'Circle with id ${circle.id} already exists');
        return null;
      }

      // Assign auto-increment ID
      if (isar.id == 0) {
        isar.id = accountDb.circleISARs.autoIncrement();
      }

      await accountDb.writeAsync((accountDb) {
        accountDb.circleISARs.put(isar);
      });

      LogUtil.v(() => 'Circle created: ${circle.id}');
      return isar;
    } catch (e) {
      LogUtil.e(() => 'Failed to create circle: $e');
      return null;
    }
  }

  static Future<CircleISAR?> getById(Isar accountDb, String circleId) async {
    try {
      // Since circleId has unique index, we can query directly
      final circle = accountDb.circleISARs
          .where()
          .circleIdEqualTo(circleId)
          .findFirst();
      
      return circle;
    } catch (e) {
      LogUtil.e(() => 'Failed to get circle by id: $e');
      return null;
    }
  }

  static Future<List<CircleISAR>> getAll(Isar accountDb) async {
    try {
      return accountDb.circleISARs
          .where()
          .findAll();
    } catch (e) {
      LogUtil.e(() => 'Failed to get all circles: $e');
      return [];
    }
  }

  static Future<bool> update(Isar accountDb, Circle circle) async {
    // Extract all values from Circle object FIRST to avoid capturing the Circle object
    // (which contains Isar db that cannot be sent across isolates)
    final circleId = circle.id;
    final name = circle.name;
    final relayUrl = circle.relayUrl;
    final type = circle.type;
    final invitationCode = circle.invitationCode;
    final category = circle.category;
    final groupId = circle.groupId;
    final circleOwnerPubkey = circle.ownerPubkey ?? '';
    
    try {
      final existing = await getById(accountDb, circleId);
      final existingId = existing?.id;
      if (existingId == null) {
        LogUtil.e(() => 'Circle with id $circleId not found in database');
        return false;
      }

      LogUtil.v(() => 'Updating circle $circleId with existingId: $existingId, name: $name');

      await accountDb.writeAsync((accountDb) {
        // Get the existing object again inside the closure to avoid capturing it
        final circleToUpdate = accountDb.circleISARs.get(existingId);
        if (circleToUpdate == null) {
          // Don't use LogUtil here as it might capture variables from outer scope
          throw Exception('Circle with id $existingId not found in writeAsync closure');
        }
        
        circleToUpdate.name = name;
        circleToUpdate.relayUrl = relayUrl;
        circleToUpdate.type = type;
        circleToUpdate.invitationCode = invitationCode;
        circleToUpdate.category = category;
        circleToUpdate.groupId = groupId;
        circleToUpdate.pubkey = circleOwnerPubkey;
        accountDb.circleISARs.put(circleToUpdate);
      });

      // Verify the update was successful by reading back the value
      final updated = await getById(accountDb, circleId);
      if (updated == null || updated.name != name) {
        LogUtil.e(() => 'Circle update verification failed: expected name "$name", got "${updated?.name ?? "null"}"');
        return false;
      }

      LogUtil.v(() => 'Circle updated successfully: $circleId -> $name');
      return true;
    } catch (e, stackTrace) {
      LogUtil.e(() => 'Failed to update circle: $e');
      LogUtil.e(() => 'Stack trace: $stackTrace');
      return false;
    }
  }

  /// Update invitation code for a circle
  static Future<bool> updateInvitationCode(Isar accountDb, String circleId, String invitationCode) async {
    try {
      final existing = await getById(accountDb, circleId);
      if (existing == null) {
        LogUtil.w(() => 'Circle with id $circleId not found');
        return false;
      }

      existing.invitationCode = invitationCode;

      await accountDb.writeAsync((accountDb) {
        accountDb.circleISARs.put(existing);
      });

      LogUtil.v(() => 'Invitation code updated for circle: $circleId');
      return true;
    } catch (e) {
      LogUtil.e(() => 'Failed to update invitation code: $e');
      return false;
    }
  }

  static Future<bool> delete(Isar accountDb, String circleId) async {
    try {
      final existing = await getById(accountDb, circleId);
      if (existing == null) {
        LogUtil.w(() => 'Circle with id $circleId not found');
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

  static Future<int> deleteAll(Isar accountDb) async {
    try {
      final circles = await getAll(accountDb);
      if (circles.isEmpty) {
        return 0;
      }

      final ids = circles.map((c) => c.id).toList();
      
      await accountDb.writeAsync((accountDb) {
        accountDb.circleISARs.deleteAll(ids);
      });

      LogUtil.v(() => 'Deleted ${ids.length} circles');
      return ids.length;
    } catch (e) {
      LogUtil.e(() => 'Failed to delete all circles: $e');
      return 0;
    }
  }
}
