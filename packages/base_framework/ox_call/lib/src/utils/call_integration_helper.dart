import 'package:chatcore/chat-core.dart';
import 'package:ox_call/src/call_manager.dart';
import 'package:ox_call/src/utils/call_logger.dart';

class CallIntegrationHelper {
  static Future<void> initializeAfterLogin() async {
    try {
      if (Contacts.sharedInstance.pubkey.isNotEmpty) {
        await CallManager().initialize();
        CallLogger.info('CallManager initialized after login');
      } else {
        CallLogger.warning('Cannot initialize CallManager: user not logged in');
      }
    } catch (e) {
      CallLogger.error('Failed to initialize CallManager after login: $e');
    }
  }

  static Future<void> cleanupOnLogout() async {
    try {
      final activeSessions = CallManager().getActiveSessions();
      for (final session in activeSessions) {
        await CallManager().endCall(session.sessionId);
      }
      CallLogger.info('CallManager cleaned up on logout');
    } catch (e) {
      CallLogger.error('Failed to cleanup CallManager on logout: $e');
    }
  }
}