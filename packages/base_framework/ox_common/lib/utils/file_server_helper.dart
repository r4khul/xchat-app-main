import 'package:flutter/widgets.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/model/file_server_model.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/repository/file_server_repository.dart';

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
  /// - When selected url is empty -> returns [defaultFileServerGroup].
  /// - When selected url matches a custom server -> returns a single-item list.
  /// - When selected url is not found (e.g. deleted) -> fallback to default
  ///   group and persist selection to empty string.
  static Future<List<FileServerModel>> currentUploadCandidates() async {
    final circle = LoginManager.instance.currentCircle;
    final url = circle?.selectedFileServerUrl;
    if (isDefaultFileServerGroupSelected(url)) {
      return defaultFileServerGroup;
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
      return defaultFileServerGroup;
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