import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/avatar.dart';
import 'package:ox_call/src/call_manager.dart';
import 'package:ox_call/src/services/call_service.dart';
import 'package:ox_call/src/models/call_state.dart';
import 'package:ox_call/src/models/call_session.dart';

class CallInProgressPage extends StatefulWidget {
  final CallSession session;

  const CallInProgressPage({
    super.key,
    required this.session,
  });

  @override
  State<CallInProgressPage> createState() => _CallInProgressPageState();
}

class _CallInProgressPageState extends State<CallInProgressPage> {
  late CallSession _session;
  Timer? _durationTimer;
  int _callDuration = 0;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _hasPopped = false;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _initRenderers();
    _setupListeners();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _updateStreams();
  }

  void _updateStreams() {
    final localStream = CallManager().getLocalStream(_session.sessionId);
    final remoteStream = CallManager().getRemoteStream(_session.sessionId);

    if (localStream != null) {
      _localRenderer.srcObject = localStream;
    }
    if (remoteStream != null) {
      _remoteRenderer.srcObject = remoteStream;
    }
  }

  void _setupListeners() {
    // Listen to session changes from CallService
    CallService.instance.currentSession$.addListener(_onSessionChanged);

    // Listen to remote stream changes
    CallService.instance.remoteStream$.addListener(_onRemoteStreamChanged);

    // Listen to remote user info changes
    _session.remoteUser$.addListener(_onRemoteUserChanged);
  }

  void _onSessionChanged() {
    final session = CallService.instance.currentSession$.value;
    if (session == null || session.sessionId != _session.sessionId) return;

    setState(() {
      _session = session;
    });

    if (session.state == CallState.connected) {
      _startDurationTimer();
      _updateStreams();
    }

    if (session.state == CallState.ended && !_hasPopped) {
      _stopDurationTimer();
      _hasPopped = true;
      // Pop back after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _onRemoteStreamChanged() {
    final stream = CallService.instance.remoteStream$.value;
    if (stream != null && mounted) {
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
    }
  }

  void _onRemoteUserChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleMute() async {
    await CallManager().setMuted(_session.sessionId, !_isMuted);
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  Future<void> _toggleVideo() async {
    await CallManager().setVideoEnabled(_session.sessionId, !_isVideoEnabled);
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
  }

  Future<void> _switchCamera() async {
    await CallManager().switchCamera(_session.sessionId);
  }

  Future<void> _endCall() async {
    await CallManager().endCall(_session.sessionId);
  }

  Future<void> _acceptCall() async {
    await CallManager().acceptCall(_session.offerId);
  }

  Future<void> _rejectCall() async {
    await CallManager().rejectCall(_session.offerId);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _stopDurationTimer();
    CallService.instance.currentSession$.removeListener(_onSessionChanged);
    CallService.instance.remoteStream$.removeListener(_onRemoteStreamChanged);
    _session.remoteUser$.removeListener(_onRemoteUserChanged);
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideoCall = _session.callType == CallType.video;
    final isIncoming = _session.direction == CallDirection.incoming;
    final isRinging = _session.state == CallState.ringing;

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Stack(
          children: [
            // Video views (only for video calls)
            if (isVideoCall) ...[
              // Remote video (full screen)
              Positioned.fill(
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
              // Local video (picture-in-picture)
              Positioned(
                top: 16.px,
                right: 16.px,
                width: 100.px,
                height: 150.px,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.px),
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            ],

            // Audio call UI or overlay for video
            if (!isVideoCall || _session.state != CallState.connected)
              _buildAudioCallUI(),

            // Controls at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 40.px,
              child: isRinging && isIncoming
                  ? _buildIncomingCallControls()
                  : _buildCallControls(isVideoCall),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioCallUI() {
    final remoteUser = _session.remoteUser$.value;
    final userName = remoteUser?.name ?? remoteUser?.shortEncodedPubkey ?? 'Unknown';

    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OXUserAvatar(
              user: remoteUser,
              size: 100.px,
            ),
            SizedBox(height: 24.px),
            CLText.titleLarge(
              userName,
              customColor: Colors.white,
            ),
            SizedBox(height: 12.px),
            CLText.bodyMedium(
              _getStateText(),
              customColor: Colors.white70,
            ),
            if (_session.state == CallState.connected) ...[
              SizedBox(height: 8.px),
              CLText.titleMedium(
                _formatDuration(_callDuration),
                customColor: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStateText() {
    switch (_session.state) {
      case CallState.initiating:
        return 'Initiating...';
      case CallState.ringing:
        return _session.direction == CallDirection.incoming
            ? 'Incoming call'
            : 'Ringing...';
      case CallState.connecting:
        return 'Connecting...';
      case CallState.connected:
        return _session.callType == CallType.video ? 'Video Call' : 'Voice Call';
      case CallState.reconnecting:
        return 'Reconnecting...';
      case CallState.ended:
        return 'Call ended';
      default:
        return '';
    }
  }

  Widget _buildIncomingCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reject button
        _buildControlButton(
          icon: Icons.call_end,
          color: Colors.red,
          onTap: _rejectCall,
          label: 'Decline',
        ),
        SizedBox(width: 60.px),
        // Accept button
        _buildControlButton(
          icon: Icons.call,
          color: Colors.green,
          onTap: _acceptCall,
          label: 'Accept',
        ),
      ],
    );
  }

  Widget _buildCallControls(bool isVideoCall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mute button
        _buildControlButton(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          color: _isMuted ? Colors.red : Colors.white24,
          onTap: _toggleMute,
        ),
        SizedBox(width: 24.px),

        // Video toggle (only for video calls)
        if (isVideoCall) ...[
          _buildControlButton(
            icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            color: _isVideoEnabled ? Colors.white24 : Colors.red,
            onTap: _toggleVideo,
          ),
          SizedBox(width: 24.px),
        ],

        // End call button
        _buildControlButton(
          icon: Icons.call_end,
          color: Colors.red,
          size: 64.px,
          onTap: _endCall,
        ),

        // Camera switch (only for video calls)
        if (isVideoCall) ...[
          SizedBox(width: 24.px),
          _buildControlButton(
            icon: Icons.cameraswitch,
            color: Colors.white24,
            onTap: _switchCamera,
          ),
        ],
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 56,
    String? label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
        if (label != null) ...[
          SizedBox(height: 8.px),
          CLText.bodySmall(label, customColor: Colors.white70),
        ],
      ],
    );
  }
}