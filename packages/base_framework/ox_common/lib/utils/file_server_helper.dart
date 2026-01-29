import 'package:flutter/widgets.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/model/file_server_model.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/repository/file_server_repository.dart';
import 'package:ox_common/log_util.dart';

class FileServerHelper {
  FileServerHelper._();

  static List<FileServerModel> get defaultFileServerGroup =>
      [
        FileServerModel(
          id: 0,
          type: FileServerType.nip96,
          name: 'pomf2.lain.la',
          url: 'https://pomf2.lain.la',
        ),
        FileServerModel(
          id: 0,
          type: FileServerType.blossom,
          name: 'blossom.lostr.space',
          url: 'https://blossom.lostr.space',
        ),
      ];

  static bool isDefaultFileServerGroupSelected(String? selectedUrl) =>
      selectedUrl == null || selectedUrl.isEmpty;


  /// Get current upload candidates according to current circle selection.
  ///
  /// - When selected url is empty -> returns [defaultFileServerGroup] with S3 server prepended if available.
  /// - When selected url matches a custom server -> returns a single-item list.
  /// - When selected url is not found (e.g. deleted) -> fallback to default
  ///   group and persist selection to empty string.
  static Future<List<FileServerModel>> currentUploadCandidates() async {
    final circle = LoginManager.instance.currentCircle;
    final url = circle?.selectedFileServerUrl;
    
    // Get S3 config from current circle if available
    FileServerModel? s3FileServer;
    if (circle != null) {
      try {
        final circleDB = await Account.sharedInstance.getCircleById(circle.id);
        if (circleDB != null && circleDB.s3ConfigJson != null && circleDB.s3ConfigJson!.isNotEmpty) {
          final s3Config = await S3ConfigUtils.loadS3ConfigFromCircleDB(circle.id);
          if (s3Config != null) {
            final url = S3ConfigUtils.getS3FileServerUrl(s3Config);
            s3FileServer = FileServerModel(
              id: 0, // Will be used as default server
              type: FileServerType.minio,
              name: circleDB.tenantName ?? circle.name,
              url: url,
              accessKey: s3Config.accessKeyId,
              secretKey: s3Config.secretAccessKey,
              bucketName: s3Config.bucket,
              pathPrefix: s3Config.pathPrefix,
              region: s3Config.region,
              sessionToken: s3Config.sessionToken,
              expiration: s3Config.expiration,
            );
          }
        }
      } catch (e) {
        LogUtil.w(() => 'Failed to load S3 config for current circle: $e');
      }
    }
    
    if (isDefaultFileServerGroupSelected(url)) {
      // Return default group with S3 server prepended if available
      final candidates = <FileServerModel>[];
      if (s3FileServer != null) {
        candidates.add(s3FileServer);
      }
      candidates.addAll(defaultFileServerGroup);
      return candidates;
    }

    final repo = FileServerRepository(DBISAR.sharedInstance.isar);
    final list = await repo.watchAll().first;
    FileServerModel? matched;
    try {
      matched = list.firstWhere((e) => e.url == url);
    } catch (_) {
      matched = null;
    }

    if (matched == null) {
      // Fallback: revert to default group selection.
      if (circle != null) {
        await circle.updateSelectedFileServerUrl('');
      }
      // Return default group with S3 server prepended if available
      final candidates = <FileServerModel>[];
      if (s3FileServer != null) {
        candidates.add(s3FileServer);
      }
      candidates.addAll(defaultFileServerGroup);
      return candidates;
    }
    return [matched];
  }

  static Future<bool> ensureFileServerConfigured(
      BuildContext context, {
        VoidCallback? onGoToSettings,
      }) async {
    return (await currentUploadCandidates()).isNotEmpty;
  }
}