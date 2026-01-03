part of 'call_manager.dart';

/// Extension for managing offer timeout timers.
extension CallManagerTimer on CallManager {

  static const int _offerTimeoutSeconds = 30;

  void _startOfferTimer(String sessionId) {
    _cancelOfferTimer(sessionId);

    _offerTimers[sessionId] = Timer(Duration(seconds: _offerTimeoutSeconds), () {
      CallLogger.warning('Offer timeout: sessionId=$sessionId');
      _endCall(sessionId, CallEndReason.timeout);
    });
  }

  void _cancelOfferTimer(String sessionId) {
    _offerTimers[sessionId]?.cancel();
    _offerTimers.remove(sessionId);
  }
}