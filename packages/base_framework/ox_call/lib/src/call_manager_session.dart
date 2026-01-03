part of 'call_manager.dart';

extension CallManagerSession on CallManager {
  CallSession? _getSession(String sessionId) {
    return _activeSessions[sessionId];
  }

  void _addSession(String sessionId, CallSession session) {
    _activeSessions[sessionId] = session;
  }

  void _removeSession(String sessionId) {
    _activeSessions.remove(sessionId);
  }

  bool _hasActiveSessions() {
    return _activeSessions.isNotEmpty;
  }

  List<CallSession> _getAllSessions() {
    return _activeSessions.values.toList();
  }

  void _updateSession(String sessionId, {required CallState state}) {
    final session = _getSession(sessionId);
    if (session == null) return;

    session.state = state;
    
    // Cancel offer timer when connection starts or succeeds
    if (state == CallState.connecting || state == CallState.connected) {
      _cancelOfferTimer(sessionId);
    }
    
    _notifyStateChange(session);
  }

  void _notifyStateChange(CallSession session) {
    for (final callback in _stateCallbacks) {
      callback(session);
    }
  }

  String _generateSessionId() {
    return generate64RandomHexChars();
  }

  /// Mark a session as ended to filter out-of-order messages.
  void _markSessionAsEnded(String sessionId) {
    _endedSessions.add(sessionId);
  }

  /// Check if a session was already ended.
  /// Returns true if the session ID is in the ended sessions set.
  bool _isSessionEnded(String sessionId) {
    return _endedSessions.contains(sessionId);
  }
}