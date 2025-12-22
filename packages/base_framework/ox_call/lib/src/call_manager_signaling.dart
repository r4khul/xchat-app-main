part of 'call_manager.dart';

/// Extension for handling signaling messages (offer, answer, candidate, disconnect).
extension CallManagerSignaling on CallManager {
  void _handleSignalingMessage(
      String friend,
      SignalingState state,
      String data,
      String? offerId,
      ) {
    CallLogger.debug('Received signaling: friend=$friend, state=$state, offerId=$offerId');

    switch (state) {
      case SignalingState.offer:
        _handleOffer(friend, data, offerId);
        break;
      case SignalingState.answer:
        _handleAnswer(friend, data, offerId);
        break;
      case SignalingState.candidate:
        _handleCandidate(friend, data, offerId);
        break;
      case SignalingState.disconnect:
        _handleDisconnect(friend, data, offerId);
        break;
    }
  }

  Future<void> _handleOffer(String caller, String data, String? offerId) async {
    if (offerId == null) return;

    CallLogger.info('Received offer: offerId=$offerId');

    try {
      final offerData = jsonDecode(data) as Map<String, dynamic>;
      final sdp = offerData['sdp'] as String;
      final media = offerData['media'] as String? ?? 'audio';
      final callType = media == 'video' ? CallType.video : CallType.audio;

      final sessionId = offerId;

      // Check if already in a call
      if (_hasActiveSessions()) {
        CallLogger.warning('Already in a call, rejecting incoming call');
        final privateGroupId = _pendingPrivateGroupIds[sessionId] ?? '';
        final disconnectContent = jsonEncode({'reason': 'inCalling'});
        await Contacts.sharedInstance.sendDisconnect(
          sessionId,
          caller,
          privateGroupId,
          disconnectContent,
        );
        return;
      }

      // Get privateGroupId from the signaling context
      // This should be passed through the signaling layer
      final privateGroupId = _extractPrivateGroupId(sessionId, caller) ?? '';

      final currentPubkey = Account.sharedInstance.currentPubkey;
      final callerTarget = CallTarget(pubkey: caller, privateGroupId: privateGroupId);
      final calleeTarget = CallTarget(pubkey: currentPubkey, privateGroupId: privateGroupId);

      final session = CallSession(
        sessionId: sessionId,
        callerTarget: callerTarget,
        calleeTarget: calleeTarget,
        participants: [callerTarget, calleeTarget],
        callType: callType,
        direction: CallDirection.incoming,
        state: CallState.ringing,
        startTime: DateTime.now().millisecondsSinceEpoch,
        remoteSdp: sdp,
      );

      _addSession(sessionId, session);
      _notifyStateChange(session);

      _startOfferTimer(sessionId);

      CallLogger.info('Incoming call ringing: offerId=$offerId, waiting for user to accept');
    } catch (e) {
      CallLogger.error('Failed to handle offer: $e');
      final privateGroupId = _pendingPrivateGroupIds[offerId] ?? '';
      final disconnectContent = jsonEncode({'reason': 'error'});
      await Contacts.sharedInstance.sendDisconnect(
        offerId,
        caller,
        privateGroupId,
        disconnectContent,
      );
    }
  }

  /// Extract privateGroupId from signaling context.
  /// This needs to be implemented based on how the signaling layer passes this information.
  String? _extractPrivateGroupId(String offerId, String remotePubkey) {
    // Check if we have a pending privateGroupId stored
    if (_pendingPrivateGroupIds.containsKey(offerId)) {
      return _pendingPrivateGroupIds[offerId];
    }

    // Try to find from existing sessions
    final existingSession = _getSession(offerId);
    if (existingSession != null) {
      return existingSession.privateGroupId;
    }

    // Default: try to find a private group between current user and remote
    // This is a fallback and may need to be improved based on app requirements
    return _findPrivateGroupWithUser(remotePubkey);
  }

  /// Find a private group ID that contains both current user and the specified user.
  String? _findPrivateGroupWithUser(String userPubkey) {
    // This should be implemented based on how private groups are stored
    // For now, return null and let the signaling layer handle it
    return null;
  }

  /// Register a privateGroupId for an upcoming incoming call.
  /// Call this when you know the privateGroupId before the offer arrives.
  void registerPendingPrivateGroupId(String offerId, String privateGroupId) {
    _pendingPrivateGroupIds[offerId] = privateGroupId;
  }

  Future<void> _handleAnswer(String callee, String data, String? offerId) async {
    if (offerId == null) return;

    final session = _getSession(offerId);
    if (session == null) {
      CallLogger.error('Session not found for offerId: $offerId');
      return;
    }

    CallLogger.info('Received answer: offerId=$offerId');

    try {
      final answerData = jsonDecode(data) as Map<String, dynamic>;
      final sdp = answerData['sdp'] as String;

      final peerConnection = _peerConnections[session.sessionId];
      if (peerConnection == null) {
        CallLogger.error('PeerConnection not found for session: ${session.sessionId}');
        return;
      }

      await peerConnection.setRemoteDescription(
        RTCSessionDescription(sdp, 'answer'),
      );

      _updateSession(session.sessionId, state: CallState.connecting);
      CallLogger.info('Answer processed: offerId=$offerId');
    } catch (e) {
      CallLogger.error('Failed to handle answer: $e');
      await _handleError(session.sessionId, CallErrorType.sdpSetupFailed, 'Failed to handle answer: $e', e);
    }
  }

  Future<void> _handleCandidate(String peer, String data, String? offerId) async {
    if (offerId == null) return;

    final session = _getSession(offerId);
    if (session == null) {
      CallLogger.debug('Session not found for offerId: $offerId (candidate may be late)');
      return;
    }

    try {
      final candidateData = jsonDecode(data) as Map<String, dynamic>;
      final candidate = candidateData['candidate'] as String;
      final sdpMLineIndex = candidateData['sdpMLineIndex'] as int?;
      final sdpMid = candidateData['sdpMid'] as String?;

      final peerConnection = _peerConnections[session.sessionId];
      if (peerConnection == null) {
        CallLogger.debug('PeerConnection not found for session: ${session.sessionId} (candidate may be late)');
        return;
      }

      await peerConnection.addCandidate(
        RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
      );

      CallLogger.debug('ICE candidate added: offerId=$offerId');
    } catch (e) {
      CallLogger.error('Failed to handle candidate: $e');
    }
  }

  Future<void> _handleDisconnect(String peer, String data, String? offerId) async {
    if (offerId == null) return;

    final session = _getSession(offerId);
    if (session == null) {
      CallLogger.debug('Session not found for offerId: $offerId');
      return;
    }

    CallLogger.info('Received disconnect: offerId=$offerId');

    try {
      final disconnectData = jsonDecode(data) as Map<String, dynamic>;
      final reason = disconnectData['reason'] as String? ?? 'unknown';

      CallEndReason endReason;
      switch (reason) {
        case 'hangUp':
          endReason = CallEndReason.hangup;
          break;
        case 'reject':
          endReason = CallEndReason.reject;
          break;
        case 'timeout':
          endReason = CallEndReason.timeout;
          break;
        case 'inCalling':
          endReason = CallEndReason.busy;
          break;
        default:
          endReason = CallEndReason.unknown;
      }

      await _endCall(session.sessionId, endReason);
    } catch (e) {
      CallLogger.error('Failed to handle disconnect: $e');
      await _endCall(session.sessionId, CallEndReason.unknown);
    }
  }

  Future<void> _sendIceCandidate(String sessionId, RTCIceCandidate candidate) async {
    final session = _getSession(sessionId);
    if (session == null) return;

    try {
      final candidateJson = jsonEncode({
        'candidate': candidate.candidate,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'sdpMid': candidate.sdpMid,
      });

      final targetPubkey = session.direction == CallDirection.outgoing
          ? session.calleePubkey
          : session.callerPubkey;

      await Contacts.sharedInstance.sendCandidate(
        session.sessionId,
        targetPubkey,
        session.privateGroupId,
        candidateJson,
      );

      // Send to additional participants
      for (final participant in session.participants) {
        if (participant.pubkey != targetPubkey &&
            participant.pubkey != Account.sharedInstance.currentPubkey) {
          await Contacts.sharedInstance.sendCandidate(
            session.sessionId,
            participant.pubkey,
            participant.privateGroupId,
            candidateJson,
          );
          CallLogger.debug('ICE candidate sent to additional participant: ${participant.pubkey}');
        }
      }
    } catch (e) {
      CallLogger.error('Failed to send ICE candidate: $e');
    }
  }
}