import 'package:audio_session/audio_session.dart';
import 'package:ox_call/src/utils/call_logger.dart';

class BackgroundKeepAlive {
  static final BackgroundKeepAlive _instance = BackgroundKeepAlive._internal();
  factory BackgroundKeepAlive() => _instance;
  BackgroundKeepAlive._internal();

  AudioSession? _audioSession;
  bool _isConfigured = false;

  Future<void> configureForCall() async {
    if (_isConfigured) return;

    try {
      _audioSession = await AudioSession.instance;
      await _audioSession!.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth
          | AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.audibilityEnforced,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));

      _isConfigured = true;
      CallLogger.info('Audio session configured for call');
    } catch (e) {
      CallLogger.error('Failed to configure audio session: $e');
      rethrow;
    }
  }

  Future<void> activate() async {
    if (!_isConfigured) {
      await configureForCall();
    }

    try {
      await _audioSession?.setActive(true);
      CallLogger.info('Audio session activated');
    } catch (e) {
      CallLogger.error('Failed to activate audio session: $e');
    }
  }

  Future<void> deactivate() async {
    try {
      await _audioSession?.setActive(false);
      CallLogger.info('Audio session deactivated');
    } catch (e) {
      CallLogger.error('Failed to deactivate audio session: $e');
    }
  }

  void dispose() {
    _audioSession = null;
    _isConfigured = false;
  }
}