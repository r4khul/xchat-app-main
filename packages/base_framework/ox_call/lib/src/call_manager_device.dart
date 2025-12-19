part of 'call_manager.dart';

/// Extension for managing device controls (camera, microphone, audio devices).
extension CallManagerDevice on CallManager {
  Future<void> switchCamera(String sessionId) async {
    final localStream = _localStreams[sessionId];
    if (localStream == null) {
      CallLogger.warning('Local stream not found for camera switch: sessionId=$sessionId');
      return;
    }

    await DeviceManager().switchCamera(sessionId, localStream);
  }

  Future<void> setMuted(String sessionId, bool muted) async {
    final localStream = _localStreams[sessionId];
    if (localStream == null) {
      CallLogger.warning('Local stream not found for mute: sessionId=$sessionId');
      return;
    }

    await DeviceManager().setMuted(sessionId, localStream, muted);
  }

  Future<void> setVideoEnabled(String sessionId, bool enabled) async {
    final localStream = _localStreams[sessionId];
    if (localStream == null) {
      CallLogger.warning('Local stream not found for video toggle: sessionId=$sessionId');
      return;
    }

    await DeviceManager().setVideoEnabled(sessionId, localStream, enabled);
  }

  Future<void> setAudioInputDevice(String sessionId, String deviceId) async {
    final localStream = _localStreams[sessionId];
    if (localStream == null) {
      CallLogger.warning('Local stream not found for audio input device: sessionId=$sessionId');
      return;
    }

    await DeviceManager().setAudioInputDevice(sessionId, localStream, deviceId);
  }

  Future<void> setAudioOutputDevice(String deviceId) async {
    await DeviceManager().setAudioOutputDevice(deviceId);
  }

  Future<List<CallDeviceInfo>> getAudioInputDevices() async {
    return await DeviceManager().getAudioInputDevices();
  }

  Future<List<CallDeviceInfo>> getAudioOutputDevices() async {
    return await DeviceManager().getAudioOutputDevices();
  }

  Future<List<CallDeviceInfo>> getVideoInputDevices() async {
    return await DeviceManager().getVideoInputDevices();
  }
}