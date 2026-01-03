import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_call/src/call_manager.dart';
import 'package:ox_call/src/services/call_service.dart';
import 'package:ox_call/src/utils/call_logger.dart';

class CallIntegrationHelper with LoginManagerObserver {
  CallIntegrationHelper._();

  static final CallIntegrationHelper _instance = CallIntegrationHelper._();
  static CallIntegrationHelper get instance => _instance;

  bool _initialized = false;
  bool _registered = false;

  /// Register as LoginManager observer. Call this in module setup.
  void register() {
    if (_registered) return;
    LoginManager.instance.addObserver(this);
    _registered = true;

    // If already logged into a circle, initialize immediately
    if (LoginManager.instance.isLoginCircle) {
      _initializeCallManager();
    }
  }

  /// Unregister from LoginManager observer.
  void unregister() {
    if (!_registered) return;
    LoginManager.instance.removeObserver(this);
    _registered = false;
  }

  @override
  void onCircleChange(bool isSuccess, LoginFailure? failure) {
    if (isSuccess) {
      _initializeCallManager();
    }
  }

  @override
  void onLogout() {
    _cleanupCallManager();
  }

  Future<void> _initializeCallManager() async {
    if (_initialized) return;

    try {
      final pubkey = LoginManager.instance.currentPubkey;
      if (pubkey.isNotEmpty) {
        await CallManager().initialize();
        CallService.instance.initialize();
        _initialized = true;
      }
    } catch (e) {
      CallLogger.error('Failed to initialize CallManager: $e');
    }
  }

  Future<void> _cleanupCallManager() async {
    if (!_initialized) return;

    try {
      final activeSessions = CallManager().getActiveSessions();
      for (final session in activeSessions) {
        await CallManager().endCall(session.sessionId);
      }
      CallService.instance.cleanup();
      _initialized = false;
    } catch (e) {
      CallLogger.error('Failed to cleanup CallManager: $e');
    }
  }
}