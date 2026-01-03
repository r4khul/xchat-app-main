part of 'call_manager.dart';

/// Extension for managing offer timeout timers.
extension CallManagerTimer on CallManager {

  static const int _offerTimeoutSeconds = 30;

  void _startOfferTimer(String sessionId) {
    _cancelOfferTimer(sessionId);

    _offerTimers[sessionId] = Timer(Duration(seconds: _offerTimeoutSeconds), () {
      CallLogger.warning('Offer timeout: sessionId=$sessionId');
      
      // Check if session is still in ringing state before ending the call
      final session = _getSession(sessionId);
      if (session == null) {
        CallLogger.debug('Session not found for offer timeout: sessionId=$sessionId');
        return;
      }
      
      if (session.state != CallState.ringing) {
        CallLogger.debug('Offer timeout ignored: session is not in ringing state, current state=${session.state}');
        return;
      }
      
      _endCall(sessionId, CallEndReason.timeout);
    });
  }

  void _cancelOfferTimer(String sessionId) {
    _offerTimers[sessionId]?.cancel();
    _offerTimers.remove(sessionId);
  }
}