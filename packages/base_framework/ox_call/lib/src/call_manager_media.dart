part of 'call_manager.dart';

/// Extension for managing media streams and permissions.
extension CallManagerMedia on CallManager {
  Future<MediaStream> getUserMedia(CallType callType) async {
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

  void setLocalStream(MediaStream stream) {
    _localStream = stream;
    // Notify all listeners that local stream is ready
    for (final callback in _localStreamCallbacks) {
      callback(stream);
    }
  }
}