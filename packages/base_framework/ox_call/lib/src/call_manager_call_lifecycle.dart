part of 'call_manager.dart';

/// Extension for managing call lifecycle (start, accept, reject, end).
extension CallManagerCallLifecycle on CallManager {
  /// Start a call to a target.
  ///
  /// [target] - The call target (pubkey + privateGroupId)
  /// [callType] - Audio or video call
  /// [additionalParticipants] - Additional participants for group calls
  Future<void> startCall({
    required UserDBISAR target,
    required String privateGroupId,
    required CallType callType,
    List<UserDBISAR>? additionalParticipants,
  }) async {
    final sessionId = _generateSessionId();
    final currentPubkey = Account.sharedInstance.currentPubkey;

    final participantPubkeys = [
      currentPubkey,
      target.pubKey,
      ...?additionalParticipants?.map((t) => t.pubKey),
    ];

    final session = CallSession(
      sessionId: sessionId,
      privateGroupId: privateGroupId,
      localPubkey: currentPubkey,
      remotePubkey: target.pubKey,
      participantPubkeys: participantPubkeys,
      callType: callType,
      direction: CallDirection.outgoing,
      state: CallState.initiating,
      startTime: DateTime.now().millisecondsSinceEpoch,
    );

    _addSession(sessionId, session);
    _notifyStateChange(session);

    try {
      if (!await _requestPermissions(callType)) {
        await _endCall(sessionId, CallEndReason.permissionDenied);
        return;
      }

      final localStream = await _getUserMedia(callType);
      _localStreams[sessionId] = localStream;

      final peerConnection = await _createPeerConnection(sessionId);
      _peerConnections[sessionId] = peerConnection;

      for (final track in localStream.getTracks()) {
        await peerConnection.addTrack(track, localStream);
      }

      final offer = await peerConnection.createOffer();
      await peerConnection.setLocalDescription(offer);

      final offerSdp = offer.sdp ?? '';
      final offerJson = jsonEncode({
        'sdp': offerSdp,
        'type': offer.type,
        'media': callType == CallType.video ? 'video' : 'audio',
        'privateGroupId': privateGroupId,
      });

      CallLogger.debug(
        'Send offer, friendPubkey: ${target.pubKey}, '
        'privateGroupId: $privateGroupId, '
      );
      await Contacts.sharedInstance.sendOffer(
        session.sessionId,
        session.remotePubkey,
        session.privateGroupId,
        offerJson,
      );

      _updateSession(sessionId, state: CallState.ringing);
      _startOfferTimer(sessionId);

      await _backgroundKeepAlive.configureForCall();
      await _backgroundKeepAlive.activate();
    } catch (e) {
      CallLogger.error('Failed to start call: $e');
      await _handleError(sessionId, CallErrorType.unknown, 'Failed to start call: $e', e);
    }
  }

  Future<void> acceptCall(String offerId) async {
    final session = _getSession(offerId);
    if (session == null) {
      CallLogger.error('Session not found for offerId: $offerId');
      return;
    }

    if (session.state != CallState.ringing) {
      CallLogger.error('Cannot accept call in state: ${session.state}');
      return;
    }

    if (session.remoteSdp == null) {
      CallLogger.error('Remote SDP not found for session: ${session.sessionId}');
      await rejectCall(offerId, 'error');
      return;
    }

    CallLogger.info('Accepting call: sessionId=${session.sessionId}');

    _cancelOfferTimer(session.sessionId);

    try {
      if (!await _requestPermissions(session.callType)) {
        await rejectCall(offerId, 'permissionDenied');
        return;
      }

      CallLogger.debug('Getting user media for call type: ${session.callType}');
      final localStream = await _getUserMedia(session.callType);
      _localStreams[session.sessionId] = localStream;
      CallLogger.debug('Got local stream with ${localStream.getTracks().length} tracks');

      final peerConnection = await _createPeerConnection(session.sessionId);
      _peerConnections[session.sessionId] = peerConnection;

      for (final track in localStream.getTracks()) {
        await peerConnection.addTrack(track, localStream);
      }
      CallLogger.debug('Added ${localStream.getTracks().length} tracks to PeerConnection');

      await peerConnection.setRemoteDescription(
        RTCSessionDescription(session.remoteSdp!, 'offer'),
      );

      final answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);

      final answerSdp = answer.sdp ?? '';
      final answerJson = jsonEncode({
        'sdp': answerSdp,
        'type': answer.type,
      });

      await Contacts.sharedInstance.sendAnswer(
        offerId,
        session.remotePubkey,
        session.privateGroupId,
        answerJson,
      );

      await _backgroundKeepAlive.configureForCall();
      await _backgroundKeepAlive.activate();

      _updateSession(session.sessionId, state: CallState.connecting);
      CallLogger.info('Answer sent: offerId=$offerId');
    } catch (e) {
      CallLogger.error('Failed to accept call: $e');
      await _handleError(session.sessionId, CallErrorType.unknown, 'Failed to accept call: $e', e);
    }
  }

  Future<void> rejectCall(String sessionId, [String? reason]) async {
    final session = _getSession(sessionId);
    if (session == null) {
      CallLogger.error('Session not found for offerId: $sessionId');
      return;
    }

    CallLogger.info('Rejecting call: sessionId=${session.sessionId}, privateGroupId: ${session.privateGroupId}');

    final disconnectContent = jsonEncode({'reason': reason ?? 'reject'});
    await Contacts.sharedInstance.sendDisconnect(
      sessionId,
      session.remotePubkey,
      session.privateGroupId,
      disconnectContent,
    );

    await _endCall(session.sessionId, CallEndReason.reject);
  }

  Future<void> endCall(String sessionId) async {
    CallLogger.info('Ending call: sessionId=$sessionId');

    final session = _getSession(sessionId);
    if (session == null) return;

    final disconnectContent = jsonEncode({'reason': 'hangUp'});
    await Contacts.sharedInstance.sendDisconnect(
      session.sessionId,
      session.remotePubkey,
      session.privateGroupId,
      disconnectContent,
    );

    await _endCall(sessionId, CallEndReason.hangup);
  }

  Future<void> _endCall(String sessionId, CallEndReason reason) async {
    final session = _getSession(sessionId);
    if (session == null) return;

    _cancelOfferTimer(sessionId);

    final endTime = DateTime.now().millisecondsSinceEpoch;
    final duration = endTime - session.startTime;

    session.state = CallState.ended;
    session.endTime = endTime;
    session.endReason = reason;
    session.duration = duration;

    _notifyStateChange(session);

    await _cleanupSession(sessionId);
    _removeSession(sessionId);

    if (!_hasActiveSessions()) {
      await _backgroundKeepAlive.deactivate();
    }
  }

  Future<void> _cleanupSession(String sessionId) async {
    _cancelOfferTimer(sessionId);

    final peerConnection = _peerConnections[sessionId];
    if (peerConnection != null) {
      await peerConnection.close();
      _peerConnections.remove(sessionId);
    }

    final localStream = _localStreams[sessionId];
    if (localStream != null) {
      localStream.getTracks().forEach((track) => track.stop());
      _localStreams.remove(sessionId);
    }

    final remoteStream = _remoteStreams[sessionId];
    if (remoteStream != null) {
      remoteStream.getTracks().forEach((track) => track.stop());
      _remoteStreams.remove(sessionId);
    }
  }
}