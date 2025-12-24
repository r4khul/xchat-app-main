import 'package:flutter/material.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_call/src/models/call_state.dart';
import 'call_page_controller.dart';
import 'call_control_button.dart';

/// Control bar that automatically shows appropriate buttons based on call state.
///
/// - Incoming ringing: Decline / Accept
/// - Voice call (outgoing/connected): Mic / Hang Up / Speaker
/// - Video call (outgoing/connected): Two rows of buttons
class CallControlBar extends StatelessWidget {
  const CallControlBar({
    super.key,
    required this.controller,
  });

  final CallPageController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CallState>(
      valueListenable: controller.callState$,
      builder: (context, state, _) => ValueListenableBuilder<bool>(
        valueListenable: controller.actionInProgress$,
        builder: (context, inProgress, __) {
          final bool disabled = inProgress || state == CallState.connecting;
        // Incoming call ringing: show accept/decline
          if (state == CallState.ringing && controller.isIncoming) {
            return _IncomingCallControls(
              controller: controller,
              disabled: disabled,
              isConnecting: state == CallState.connecting,
            );
          }

        // Video call: two-row layout
          if (controller.isVideoCall) {
            return _VideoCallControls(controller: controller, disabled: disabled);
          }

        // Voice call: single-row layout
          return _VoiceCallControls(controller: controller, disabled: disabled);
        },
      ),
    );
  }
}

/// Controls for incoming call (Decline / Accept).
class _IncomingCallControls extends StatelessWidget {
  const _IncomingCallControls({
    required this.controller,
    required this.disabled,
    required this.isConnecting,
  });

  final CallPageController controller;
  final bool disabled;
  final bool isConnecting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.px),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          disabled
              ? CallControlButton.inactive(
                  icon: Icons.call_end,
                  label: isConnecting ? 'Connecting...' : 'Decline',
                  onTap: () {},
                )
              : CallControlButton.danger(
                  icon: Icons.call_end,
                  label: 'Decline',
                  onTap: controller.reject,
                ),
          SizedBox(width: 80.px),
          disabled
              ? CallControlButton.inactive(
                  icon: Icons.call,
                  label: isConnecting ? 'Connecting...' : 'Accept',
                  onTap: () {},
                )
              : CallControlButton.success(
                  icon: Icons.call,
                  label: 'Accept',
                  onTap: controller.accept,
                ),
        ],
      ),
    );
  }
}

/// Controls for voice call (single row: Mic / Hang Up / Speaker).
class _VoiceCallControls extends StatelessWidget {
  const _VoiceCallControls({required this.controller, required this.disabled});

  final CallPageController controller;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final isOutgoingRinging =
        !controller.isIncoming && controller.isRinging;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.px),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mute button
          ValueListenableBuilder<bool>(
            valueListenable: controller.isMuted$,
            builder: (context, isMuted, _) {
              if (disabled) {
                return CallControlButton.inactive(
                  icon: isMuted ? Icons.mic_off : Icons.mic,
                  label: isMuted ? 'Mic Off' : 'Mic On',
                  onTap: () {},
                );
              }
              return isMuted
                  ? CallControlButton.inactive(
                      icon: Icons.mic_off,
                      label: 'Mic Off',
                      onTap: controller.toggleMute,
                    )
                  : CallControlButton.active(
                      icon: Icons.mic,
                      label: 'Mic On',
                      onTap: controller.toggleMute,
                    );
            },
          ),
          SizedBox(width: 40.px),

          // Hang up / Cancel
          disabled
              ? CallControlButton.inactive(
                  icon: Icons.call_end,
                  label: isOutgoingRinging ? 'Cancel' : 'Hang Up',
                  onTap: () {},
                )
              : CallControlButton.danger(
                  icon: Icons.call_end,
                  label: isOutgoingRinging ? 'Cancel' : 'Hang Up',
                  onTap: controller.hangUp,
                ),
          SizedBox(width: 40.px),

          // Speaker
          ValueListenableBuilder<bool>(
            valueListenable: controller.isSpeakerOn$,
            builder: (context, isSpeakerOn, _) {
              if (disabled) {
                return CallControlButton.inactive(
                  icon: isSpeakerOn ? Icons.volume_up : Icons.volume_mute,
                  label: isSpeakerOn ? 'Speaker' : 'Speaker Off',
                  onTap: () {},
                );
              }
              return isSpeakerOn
                  ? CallControlButton.active(
                      icon: Icons.volume_up,
                      label: 'Speaker',
                      onTap: controller.toggleSpeaker,
                    )
                  : CallControlButton.inactive(
                      icon: Icons.volume_off,
                      label: 'Speaker',
                      onTap: controller.toggleSpeaker,
                    );
            },
          ),
        ],
      ),
    );
  }
}

/// Controls for video call (two rows).
/// Row 1: Mic / Speaker / Camera
/// Row 2: Portrait Mode / Hang Up / Switch Camera
class _VideoCallControls extends StatelessWidget {
  const _VideoCallControls({required this.controller, required this.disabled});

  final CallPageController controller;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final isOutgoingRinging =
        !controller.isIncoming && controller.isRinging;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40.px, vertical: 16.px),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // First row: Mic / Speaker / Camera
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mute button
              ValueListenableBuilder<bool>(
                valueListenable: controller.isMuted$,
                builder: (context, isMuted, _) {
              if (disabled) {
                return CallControlButton.inactive(
                  icon: isMuted ? Icons.mic_off : Icons.mic,
                  label: isMuted ? 'Mic Off' : 'Mic On',
                  onTap: () {},
                );
              }
              return isMuted
                      ? CallControlButton.inactive(
                          icon: Icons.mic_off,
                          label: 'Mic Off',
                          onTap: controller.toggleMute,
                        )
                      : CallControlButton.active(
                          icon: Icons.mic,
                          label: 'Mic On',
                          onTap: controller.toggleMute,
                        );
                },
              ),
              SizedBox(width: 40.px),

              // Speaker
              ValueListenableBuilder<bool>(
                valueListenable: controller.isSpeakerOn$,
                builder: (context, isSpeakerOn, _) {
                  if (disabled) {
                    return CallControlButton.inactive(
                      icon: isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      label: isSpeakerOn ? 'Speaker' : 'Speaker',
                      onTap: () {},
                    );
                  }
                  return isSpeakerOn
                      ? CallControlButton.active(
                          icon: Icons.volume_up,
                          label: 'Speaker',
                          onTap: controller.toggleSpeaker,
                        )
                      : CallControlButton.inactive(
                          icon: Icons.volume_off,
                          label: 'Speaker',
                          onTap: controller.toggleSpeaker,
                        );
                },
              ),
              SizedBox(width: 40.px),

              // Camera toggle
              ValueListenableBuilder<bool>(
                valueListenable: controller.isCameraOn$,
                builder: (context, isCameraOn, _) {
                  if (disabled) {
                    return CallControlButton.inactive(
                      icon: isCameraOn ? Icons.videocam : Icons.videocam_off,
                      label: isCameraOn ? 'Camera On' : 'Camera Off',
                      onTap: () {},
                    );
                  }
                  return isCameraOn
                      ? CallControlButton.active(
                          icon: Icons.videocam,
                          label: 'Camera On',
                          onTap: controller.toggleCamera,
                        )
                      : CallControlButton.inactive(
                          icon: Icons.videocam_off,
                          label: 'Camera Off',
                          onTap: controller.toggleCamera,
                        );
                },
              ),
            ],
          ),

          SizedBox(height: 24.px),

          // Second row: Portrait Mode / Hang Up / Switch Camera
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Portrait mode (placeholder)
              CallControlButton.icon(
                icon: Icons.person_outline,
                label: '',
                onTap: () {
                  // TODO: Implement portrait mode
                },
              ),
              SizedBox(width: 56.px),

              // Hang up / Cancel
              disabled
                  ? CallControlButton.inactive(
                      icon: Icons.call_end,
                      label: isOutgoingRinging ? 'Cancel' : 'Hang Up',
                      onTap: () {},
                    )
                  : CallControlButton.danger(
                      icon: Icons.call_end,
                      label: isOutgoingRinging ? 'Cancel' : 'Hang Up',
                      onTap: controller.hangUp,
                    ),
              SizedBox(width: 56.px),

              // Switch camera
              CallControlButton.icon(
                icon: Icons.cameraswitch,
                label: '',
                onTap: disabled ? () {} : controller.switchCamera,
              ),
            ],
          ),
        ],
      ),
    );
  }
}