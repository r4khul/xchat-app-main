import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/avatar.dart';
import 'package:ox_call/src/models/call_state.dart';
import 'call_page_controller.dart';

/// Content area that automatically renders voice or video call UI.
///
/// The page doesn't need to know whether it's a voice or video call.
class CallContentArea extends StatelessWidget {
  const CallContentArea({
    super.key,
    required this.controller,
  });

  final CallPageController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.session$,
      builder: (context, session, _) {
        // Video call: show video content when connected
        if (controller.isVideoCall && controller.isConnected) {
          return _VideoCallContent(controller: controller);
        }
        // Voice call or video call before connected: show user info
        return _VoiceCallContent(controller: controller);
      },
    );
  }
}

/// Voice call content - shows user avatar and status.
class _VoiceCallContent extends StatelessWidget {
  const _VoiceCallContent({required this.controller});

  final CallPageController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2C2C2E),
            Color(0xFF1C1C1E),
          ],
        ),
      ),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildUserInfo(),
          SizedBox(height: 40.px),
          _buildStatusText(),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return ValueListenableBuilder<UserDBISAR?>(
      valueListenable: controller.remoteUser$,
      builder: (context, remoteUser, _) {
        final userName =
            remoteUser?.name ?? remoteUser?.shortEncodedPubkey ?? 'Unknown';

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OXUserAvatar(
              user: remoteUser,
              size: 120.px,
            ),
            SizedBox(height: 16.px),
            CLText.headlineSmall(
              userName,
              customColor: Colors.white,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusText() {
    return ValueListenableBuilder(
      valueListenable: controller.session$,
      builder: (context, session, _) {
        final statusText = _getStatusText(session);
        if (statusText.isEmpty) return const SizedBox.shrink();

        return CLText.bodyLarge(
          statusText,
          customColor: Colors.white.withValues(alpha: 0.6),
        );
      },
    );
  }

  String _getStatusText(dynamic session) {
    final callTypeText = controller.isVideoCall ? 'video' : 'voice';

    switch (session.state) {
      case CallState.initiating:
      case CallState.ringing:
        if (controller.isIncoming) {
          return 'invites you to $callTypeText call..';
        } else {
          return 'Awaiting response......';
        }
      case CallState.connecting:
        return 'Connecting...';
      case CallState.connected:
        return '';
      case CallState.reconnecting:
        return 'Reconnecting...';
      case CallState.ended:
        return 'Call ended';
      default:
        return '';
    }
  }
}

/// Video call content - shows remote video full screen with local PiP.
class _VideoCallContent extends StatefulWidget {
  const _VideoCallContent({required this.controller});

  final CallPageController controller;

  @override
  State<_VideoCallContent> createState() => _VideoCallContentState();
}

class _VideoCallContentState extends State<_VideoCallContent> {
  // Local video position (draggable)
  Offset _localVideoPosition = Offset.zero;
  final double _localVideoWidth = 100;
  final double _localVideoHeight = 150;

  @override
  void initState() {
    super.initState();
    // Initialize position to top-right corner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final screenSize = MediaQuery.of(context).size;
        setState(() {
          _localVideoPosition = Offset(
            screenSize.width - _localVideoWidth.px - 16.px,
            MediaQuery.of(context).padding.top + 60.px,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.controller.toggleControlsVisibility,
      child: Stack(
        children: [
          // Remote video (full screen)
          Positioned.fill(
            child: RTCVideoView(
              widget.controller.remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),

          // Local video (draggable PiP)
          _buildLocalVideoPiP(),

          // User info overlay (when remote video not ready)
          _buildUserInfoOverlay(),
        ],
      ),
    );
  }

  Widget _buildLocalVideoPiP() {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.controller.isCameraOn$,
      builder: (context, isCameraOn, _) {
        if (!isCameraOn) return const SizedBox.shrink();

        return Positioned(
          left: _localVideoPosition.dx,
          top: _localVideoPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _localVideoPosition += details.delta;
                // Clamp to screen bounds
                final screenSize = MediaQuery.of(context).size;
                final padding = MediaQuery.of(context).padding;
                _localVideoPosition = Offset(
                  _localVideoPosition.dx.clamp(
                    16.px,
                    screenSize.width - _localVideoWidth.px - 16.px,
                  ),
                  _localVideoPosition.dy.clamp(
                    padding.top + 16.px,
                    screenSize.height -
                        _localVideoHeight.px -
                        padding.bottom -
                        200.px,
                  ),
                );
              });
            },
            child: Container(
              width: _localVideoWidth.px,
              height: _localVideoHeight.px,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.px),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: RTCVideoView(
                widget.controller.localRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfoOverlay() {
    // Show user info overlay when waiting for remote video
    return ValueListenableBuilder<UserDBISAR?>(
      valueListenable: widget.controller.remoteUser$,
      builder: (context, remoteUser, _) {
        // Check if remote stream is ready by checking renderer
        final hasRemoteVideo =
            widget.controller.remoteRenderer.srcObject != null;
        if (hasRemoteVideo) return const SizedBox.shrink();

        final userName =
            remoteUser?.name ?? remoteUser?.shortEncodedPubkey ?? 'Unknown';

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(top: 120.px),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OXUserAvatar(
                  user: remoteUser,
                  size: 80.px,
                ),
                SizedBox(height: 12.px),
                CLText.titleLarge(
                  userName,
                  customColor: Colors.white,
                ),
                SizedBox(height: 8.px),
                CLText.bodyMedium(
                  'Connecting...',
                  customColor: Colors.white.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}