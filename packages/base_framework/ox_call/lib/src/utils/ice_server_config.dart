import 'dart:convert';
import 'package:ox_cache_manager/ox_cache_manager.dart';
import 'package:ox_common/utils/storage_key_tool.dart';
import 'package:ox_call/src/utils/call_logger.dart';

class IceServerConfig {
  final List<IceServer> servers;

  IceServerConfig({required this.servers});

  List<Map<String, dynamic>> toRTCIceServers() {
    return servers.map((server) {
      final urls = server.urls is String
          ? [server.urls as String]
          : (server.urls as List).cast<String>();

      final serverMap = <String, dynamic>{
        'urls': urls,
      };

      if (server.username != null) {
        serverMap['username'] = server.username;
      }

      if (server.credential != null) {
        serverMap['credential'] = server.credential;
      }

      return serverMap;
    }).toList();
  }

  static Future<IceServerConfig> load() async {
    try {
      final iceServerJson = await OXCacheManager.defaultOXCacheManager.getData(
        StorageSettingKey.KEY_ICE_SERVER.name,
        defaultValue: '',
      );

      if (iceServerJson.isEmpty) {
        CallLogger.warning('ICE server config is empty, using default STUN');
        return IceServerConfig(
          servers: [
            IceServer(urls: 'stun:stun.l.google.com:19302'),
          ],
        );
      }

      final configData = jsonDecode(iceServerJson) as Map<String, dynamic>;
      final serversData = configData['servers'] as List<dynamic>?;

      if (serversData == null || serversData.isEmpty) {
        CallLogger.warning('ICE server config has no servers, using default STUN');
        return IceServerConfig(
          servers: [
            IceServer(urls: 'stun:stun.l.google.com:19302'),
          ],
        );
      }

      final servers = serversData
          .map((serverData) => IceServer.fromJson(serverData as Map<String, dynamic>))
          .toList();

      CallLogger.info('Loaded ${servers.length} ICE servers');
      return IceServerConfig(servers: servers);
    } catch (e) {
      CallLogger.error('Failed to load ICE server config: $e');
      return IceServerConfig(
        servers: [
          IceServer(urls: 'stun:stun.l.google.com:19302'),
        ],
      );
    }
  }
}

class IceServer {
  final dynamic urls;
  final String? username;
  final String? credential;

  IceServer({
    required this.urls,
    this.username,
    this.credential,
  });

  factory IceServer.fromJson(Map<String, dynamic> json) {
    return IceServer(
      urls: json['urls'],
      username: json['username'] as String?,
      credential: json['credential'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'urls': urls,
      if (username != null) 'username': username,
      if (credential != null) 'credential': credential,
    };
  }
}