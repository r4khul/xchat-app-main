part of 'call_manager.dart';

/// Extension for managing media streams and permissions.
extension CallManagerMedia on CallManager {
  Future<MediaStream> _getUserMedia(CallType callType) async {
    final constraints = <String, dynamic>{
      'audio': true,
      'video': callType == CallType.video
          ? {
        'facingMode': 'user',
      }
          : false,
    };

    return await navigator.mediaDevices.getUserMedia(constraints);
  }

  Future<bool> _requestPermissions(CallType callType) async {
    final permissions = callType == CallType.video
        ? [Permission.camera, Permission.microphone]
        : [Permission.microphone];

    final statuses = await permissions.request();
    final allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      CallLogger.error('Permissions not granted: $statuses');
    }

    return allGranted;
  }
}