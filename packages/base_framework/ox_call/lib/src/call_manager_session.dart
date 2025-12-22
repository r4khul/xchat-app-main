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
}