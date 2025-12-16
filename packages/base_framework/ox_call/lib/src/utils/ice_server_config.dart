import 'package:chatcore/chat-core.dart';
import 'package:isar/isar.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_call/src/models/iceserver_db_isar.dart';
import 'package:ox_call/src/utils/call_logger.dart';
import 'package:ox_common/login/login_models.dart';

class IceServerConfig {
  final List<ICEServerDBISAR> servers;

  IceServerConfig({required this.servers});

  List<Map<String, dynamic>> toRTCIceServers() {
    return servers.map((server) {
      return <String, dynamic>{
        'urls': server.url,
        if (server.username != null)
          'username': server.username,
        if (server.credential != null)
          'credential': server.credential,
      };
    }).toList();
  }

  static Future<IceServerConfig?> load() async {
    try {
      final currentCircleId = LoginManager.instance.currentCircle?.id;
      if (currentCircleId == null) {
        CallLogger.warning('No active circle');
        return null;
      }

      final isar = DBISAR.sharedInstance.isar;
      final servers = isar.iCEServerDBISARs
          .where()
          .circleIdEqualTo(currentCircleId)
          .findAll();

      if (servers.isEmpty) {
        CallLogger.warning('ICE server list empty for circle $currentCircleId');
        return null;
      }

      CallLogger.info('Loaded ${servers.length} ICE servers');
      return IceServerConfig(servers: servers);
    } catch (e) {
      CallLogger.error('Failed to load ICE server config: $e');
      return null;
    }
  }

  static Future<void> save(IceServerConfig config) async {
    final currentCircleId = LoginManager.instance.currentCircle?.id;
    if (currentCircleId == null) {
      CallLogger.warning('No active circle, skip saving ICE servers');
      return;
    }

    final isar = DBISAR.sharedInstance.isar;
    await isar.writeAsync((isar) async {
      // Clean old records for this circle
      isar.iCEServerDBISARs
          .where()
          .circleIdEqualTo(currentCircleId)
          .deleteAll();

      // set auto increment id
      final servers = config.servers.map((server) {
        server.id = isar.iCEServerDBISARs.autoIncrement();
        return server;
      }).toList();

      // Insert new records
      isar.iCEServerDBISARs.putAll(servers);
    });
  }

  static IceServerConfig defaultPublicConfig(Circle circle) => IceServerConfig(
    servers: [
      ICEServerDBISAR(
        circleId: circle.id,
        url: 'stun:stun.l.google.com:19302',
      ),
    ],
  );
}