import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:chatcore/chat-core.dart';
import 'package:nostr_core_dart/nostr.dart' show SignalingState;
import 'package:ox_common/login/login_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ox_call/src/models/call_state.dart';
import 'package:ox_call/src/models/call_error.dart';
import 'package:ox_call/src/models/call_session.dart';
import 'package:ox_call/src/models/call_device_info.dart';
import 'package:ox_call/src/utils/call_logger.dart';
import 'package:ox_call/src/utils/ice_server_config.dart';
import 'package:ox_call/src/utils/background_keep_alive.dart';
import 'package:ox_call/src/device_manager.dart';

typedef CallStateCallback = void Function(CallSession session);
typedef CallErrorCallback = void Function(CallSession session, CallError error);
typedef RemoteStreamCallback = void Function(String sessionId, MediaStream stream);

class CallManager {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  static const int _offerTimeoutSeconds = 30;

  final Map<String, CallSession> _activeSessions = {};
  final Map<String, RTCPeerConnection?> _peerConnections = {};
  final Map<String, MediaStream?> _localStreams = {};
  final Map<String, MediaStream?> _remoteStreams = {};
  final Map<String, Timer?> _offerTimers = {};

  CallStateCallback? onCallStateChanged;
  CallErrorCallback? onCallError;
  RemoteStreamCallback? onRemoteStreamReady;

  bool _initialized = false;
  final BackgroundKeepAlive _backgroundKeepAlive = BackgroundKeepAlive();

  Future<void> initialize() async {
    if (_initialized) return;
    _setupSignalingListener();
    _initialized = true;
    CallLogger.info('CallManager initialized');
  }

  void _setupSignalingListener() {
    Contacts.sharedInstance.onCallStateChange = (
      String friend,
      SignalingState state,
      String data,
      String? offerId,
    ) {
      _handleSignalingMessage(friend, state, data, offerId);
    };
  }

  /// Start a call
  ///
  /// [calleePubkey] - The primary callee's public key
  /// [callType] - Audio or video call
  /// [additionalParticipants] - Additional participants for group calls
  ///
  /// Note: Current implementation uses point-to-point connection.
  /// For true multi-party calls, each participant needs a separate RTCPeerConnection.
  /// ICE candidates are sent to all participants, but only one connection is established.
  Future<void> startCall({
    required String calleePubkey,
    required CallType callType,
    List<String>? additionalParticipants,
  }) async {
    final sessionId = _generateSessionId();
    final offerId = sessionId;
    final participants = [
      Account.sharedInstance.currentPubkey,
      calleePubkey,
      ...?additionalParticipants,
    ];

    final session = CallSession(
      sessionId: sessionId,
      offerId: offerId,
      callerPubkey: Account.sharedInstance.currentPubkey,
      calleePubkey: calleePubkey,
      participants: participants,
      callType: callType,
      direction: CallDirection.outgoing,
      state: CallState.initiating,
      startTime: DateTime.now().millisecondsSinceEpoch,
    );

    _activeSessions[sessionId] = session;
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
      });

      await Contacts.sharedInstance.sendOffer(calleePubkey, offerJson);

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
    final session = _findSessionByOfferId(offerId);
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

    // Cancel the timeout timer
    _cancelOfferTimer(session.sessionId);

    try {
      if (!await _requestPermissions(session.callType)) {
        await rejectCall(offerId, 'permissionDenied');
        return;
      }

      // Get media stream FIRST before creating PeerConnection
      CallLogger.debug('Getting user media for call type: ${session.callType}');
      final localStream = await _getUserMedia(session.callType);
      _localStreams[session.sessionId] = localStream;
      CallLogger.debug('Got local stream with ${localStream.getTracks().length} tracks');

      // Then create PeerConnection
      final peerConnection = await _createPeerConnection(session.sessionId);
      _peerConnections[session.sessionId] = peerConnection;

      // Add tracks to PeerConnection
      for (final track in localStream.getTracks()) {
        await peerConnection.addTrack(track, localStream);
      }
      CallLogger.debug('Added ${localStream.getTracks().length} tracks to PeerConnection');

      // Set remote description from stored SDP
      await peerConnection.setRemoteDescription(
        RTCSessionDescription(session.remoteSdp!, 'offer'),
      );

      // Create and send answer
      final answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);

      final answerSdp = answer.sdp ?? '';
      final answerJson = jsonEncode({
        'sdp': answerSdp,
        'type': answer.type,
      });

      await Contacts.sharedInstance.sendAnswer(offerId, session.callerPubkey, answerJson);

      await _backgroundKeepAlive.configureForCall();
      await _backgroundKeepAlive.activate();

      _updateSession(session.sessionId, state: CallState.connecting);
      CallLogger.info('Answer sent: offerId=$offerId');
    } catch (e) {
      CallLogger.error('Failed to accept call: $e');
      await _handleError(session.sessionId, CallErrorType.unknown, 'Failed to accept call: $e', e);
    }
  }

  Future<void> rejectCall(String offerId, [String? reason]) async {
    final session = _findSessionByOfferId(offerId);
    if (session == null) {
      CallLogger.error('Session not found for offerId: $offerId');
      return;
    }

    CallLogger.info('Rejecting call: sessionId=${session.sessionId}');

    final disconnectContent = jsonEncode({'reason': reason ?? 'reject'});
    await Contacts.sharedInstance.sendDisconnect(
      offerId,
      session.callerPubkey,
      disconnectContent,
    );

    await _endCall(session.sessionId, CallEndReason.reject);
  }

  Future<void> endCall(String sessionId) async {
    CallLogger.info('Ending call: sessionId=$sessionId');

    final session = _activeSessions[sessionId];
    if (session == null) return;

    final disconnectContent = jsonEncode({'reason': 'hangUp'});
    await Contacts.sharedInstance.sendDisconnect(
      session.offerId,
      session.direction == CallDirection.outgoing
          ? session.calleePubkey
          : session.callerPubkey,
      disconnectContent,
    );

    await _endCall(sessionId, CallEndReason.hangup);
  }

  Future<void> _endCall(String sessionId, CallEndReason reason) async {
    final session = _activeSessions[sessionId];
    if (session == null) return;

    _cancelOfferTimer(sessionId);

    final endTime = DateTime.now().millisecondsSinceEpoch;
    final duration = endTime - session.startTime;

    // Update session state
    session.state = CallState.ended;
    session.endTime = endTime;
    session.endReason = reason;
    session.duration = duration;

    _notifyStateChange(session);

    await _cleanupSession(sessionId);
    _activeSessions.remove(sessionId);

    if (_activeSessions.isEmpty) {
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
      if (_activeSessions.isNotEmpty) {
        CallLogger.warning('Already in a call, rejecting incoming call');
        final disconnectContent = jsonEncode({'reason': 'inCalling'});
        await Contacts.sharedInstance.sendDisconnect(offerId, caller, disconnectContent);
        return;
      }

      // Create session in ringing state, store the remote SDP for later use
      final session = CallSession(
        sessionId: sessionId,
        offerId: offerId,
        callerPubkey: caller,
        calleePubkey: Account.sharedInstance.currentPubkey,
        participants: [caller, Account.sharedInstance.currentPubkey],
        callType: callType,
        direction: CallDirection.incoming,
        state: CallState.ringing,
        startTime: DateTime.now().millisecondsSinceEpoch,
        remoteSdp: sdp,
      );

      _activeSessions[sessionId] = session;
      _notifyStateChange(session);

      // Start timeout timer for incoming call
      _startOfferTimer(sessionId);

      CallLogger.info('Incoming call ringing: offerId=$offerId, waiting for user to accept');
    } catch (e) {
      CallLogger.error('Failed to handle offer: $e');
      final disconnectContent = jsonEncode({'reason': 'error'});
      await Contacts.sharedInstance.sendDisconnect(offerId, caller, disconnectContent);
    }
  }

  Future<void> _handleAnswer(String callee, String data, String? offerId) async {
    if (offerId == null) return;

    final session = _findSessionByOfferId(offerId);
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

    final session = _findSessionByOfferId(offerId);
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

    final session = _findSessionByOfferId(offerId);
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

  Future<RTCPeerConnection> _createPeerConnection(String sessionId) async {
    final circle = LoginManager.instance.currentCircle;
    if (circle == null) {
      throw 'No active circle for creating peer connection';
    }

    final iceServerConfig = await IceServerConfig.load()
        ?? IceServerConfig.defaultPublicConfig(circle);

    final iceServers = iceServerConfig.toRTCIceServers();
    CallLogger.debug('Creating PeerConnection with ${iceServers.length} ICE servers: $iceServers');

    final configuration = <String, dynamic>{
      'iceServers': iceServers,
    };

    final peerConnection = await createPeerConnection(configuration);
    CallLogger.debug('PeerConnection created successfully');

    peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      _sendIceCandidate(sessionId, candidate);
    };

    peerConnection.onConnectionState = (RTCPeerConnectionState state) {
      _handleConnectionStateChange(sessionId, state);
    };

    peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
      _handleIceConnectionStateChange(sessionId, state);
    };

    peerConnection.onAddStream = (MediaStream stream) {
      _handleRemoteStream(sessionId, stream);
    };

    peerConnection.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _handleRemoteStream(sessionId, event.streams[0]);
      }
    };

    return peerConnection;
  }

  Future<void> _sendIceCandidate(String sessionId, RTCIceCandidate candidate) async {
    final session = _activeSessions[sessionId];
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
        session.offerId,
        targetPubkey,
        candidateJson,
      );

      CallLogger.debug('ICE candidate sent: sessionId=$sessionId, to=$targetPubkey');

      for (final participant in session.participants) {
        if (participant != targetPubkey && participant != Account.sharedInstance.currentPubkey) {
          await Contacts.sharedInstance.sendCandidate(
            session.offerId,
            participant,
            candidateJson,
          );
          CallLogger.debug('ICE candidate sent to additional participant: $participant');
        }
      }
    } catch (e) {
      CallLogger.error('Failed to send ICE candidate: $e');
    }
  }

  void _handleConnectionStateChange(String sessionId, RTCPeerConnectionState state) {
    CallLogger.debug('Connection state changed: sessionId=$sessionId, state=$state');

    final session = _activeSessions[sessionId];
    if (session == null) return;

    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _updateSession(sessionId, state: CallState.connected);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        if (session.state != CallState.ended) {
          _endCall(sessionId, CallEndReason.networkError);
        }
        break;
      default:
        break;
    }
  }

  void _handleIceConnectionStateChange(String sessionId, RTCIceConnectionState state) {
    CallLogger.debug('ICE connection state changed: sessionId=$sessionId, state=$state');

    final session = _activeSessions[sessionId];
    if (session == null) return;

    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
      case RTCIceConnectionState.RTCIceConnectionStateCompleted:
        if (session.state == CallState.connecting) {
          _updateSession(sessionId, state: CallState.connected);
        }
        break;
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        _handleError(sessionId, CallErrorType.iceFailed, 'ICE connection failed', null);
        break;
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        if (session.state == CallState.connected) {
          _updateSession(sessionId, state: CallState.reconnecting);
        }
        break;
      default:
        break;
    }
  }

  void _handleRemoteStream(String sessionId, MediaStream stream) {
    CallLogger.info('Remote stream received: sessionId=$sessionId');
    _remoteStreams[sessionId] = stream;
    onRemoteStreamReady?.call(sessionId, stream);
  }

  Future<MediaStream> _getUserMedia(CallType callType) async {
    final constraints = <String, dynamic>{
      'audio': true,
      'video': callType == CallType.video
          ? {
              'facingMode': 'user',
            }
          : false,
    };

    return await navigator.mediaDevices.getUserMedia(constraints);
  }

  Future<bool> _requestPermissions(CallType callType) async {
    final permissions = callType == CallType.video
        ? [Permission.camera, Permission.microphone]
        : [Permission.microphone];

    final statuses = await permissions.request();
    final allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      CallLogger.error('Permissions not granted: $statuses');
    }

    return allGranted;
  }

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

  void _updateSession(String sessionId, {required CallState state}) {
    final session = _activeSessions[sessionId];
    if (session == null) return;

    session.state = state;
    _notifyStateChange(session);
  }

  void _notifyStateChange(CallSession session) {
    onCallStateChanged?.call(session);
  }

  Future<void> _handleError(String sessionId, CallErrorType type, String message, dynamic originalError) async {
    final session = _activeSessions[sessionId];
    if (session == null) return;

    final error = CallError(
      type: type,
      message: message,
      originalError: originalError,
    );

    CallLogger.error('Call error: sessionId=$sessionId, error=$error');

    onCallError?.call(session, error);

    if (session.state != CallState.ended) {
      await _endCall(sessionId, CallEndReason.unknown);
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

  CallSession? getSession(String sessionId) {
    return _activeSessions[sessionId];
  }

  MediaStream? getLocalStream(String sessionId) {
    return _localStreams[sessionId];
  }

  MediaStream? getRemoteStream(String sessionId) {
    return _remoteStreams[sessionId];
  }

  List<CallSession> getActiveSessions() {
    return _activeSessions.values.toList();
  }

  Future<void> switchCamera(String sessionId) async {
    final localStream = _localStreams[sessionId];
    if (localStream == null) {
      CallLogger.warning('Local stream not found for camera switch: sessionId=$sessionId');
      return;
    }

    await DeviceManager().switchCamera(sessionId, localStream);
  }

  Future<void> setMuted(String sessionId, bool muted) async {
    final localStream = _localStreams[sessionId];
    if (localStream == null) {
      CallLogger.warning('Local stream not found for mute: sessionId=$sessionId');
      return;
    }

    await DeviceManager().setMuted(sessionId, localStream, muted);
  }

  Future<void> setVideoEnabled(String sessionId, bool enabled) async {
    final localStream = _localStreams[sessionId];
    if (localStream == null) {
      CallLogger.warning('Local stream not found for video toggle: sessionId=$sessionId');
      return;
    }

    await DeviceManager().setVideoEnabled(sessionId, localStream, enabled);
  }

  Future<void> setAudioInputDevice(String sessionId, String deviceId) async {
    final localStream = _localStreams[sessionId];
    if (localStream == null) {
      CallLogger.warning('Local stream not found for audio input device: sessionId=$sessionId');
      return;
    }

    await DeviceManager().setAudioInputDevice(sessionId, localStream, deviceId);
  }

  Future<void> setAudioOutputDevice(String deviceId) async {
    await DeviceManager().setAudioOutputDevice(deviceId);
  }

  Future<List<CallDeviceInfo>> getAudioInputDevices() async {
    return await DeviceManager().getAudioInputDevices();
  }

  Future<List<CallDeviceInfo>> getAudioOutputDevices() async {
    return await DeviceManager().getAudioOutputDevices();
  }

  Future<List<CallDeviceInfo>> getVideoInputDevices() async {
    return await DeviceManager().getVideoInputDevices();
  }
}