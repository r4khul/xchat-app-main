part of 'call_manager.dart';

/// Extension for managing call sessions and state.
extension CallManagerSession on CallManager {
  void _updateSession(String sessionId, {required CallState state}) {
    final session = _activeSessions[sessionId];
    if (session == null) return;

    session.state = state;
    _notifyStateChange(session);
  }

  void _notifyStateChange(CallSession session) {
    for (final callback in _stateCallbacks) {
      callback(session);
    }
  }

  CallSession? _findSessionByOfferId(String offerId) {
    try {
      return _activeSessions.values.firstWhere(
            (session) => session.offerId == offerId,
      );
    } catch (e) {
      return _activeSessions[offerId];
    }
  }

  String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}