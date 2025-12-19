part of 'call_manager.dart';

/// Extension for handling call errors.
extension CallManagerError on CallManager {
  Future<void> _handleError(String sessionId, CallErrorType type, String message, dynamic originalError) async {
    final session = _activeSessions[sessionId];
    if (session == null) return;

    final error = CallError(
      type: type,
      message: message,
      originalError: originalError,
    );

    CallLogger.error('Call error: sessionId=$sessionId, error=$error');

    for (final callback in _errorCallbacks) {
      callback(session, error);
    }

    if (session.state != CallState.ended) {
      await _endCall(sessionId, CallEndReason.unknown);
    }
  }
}