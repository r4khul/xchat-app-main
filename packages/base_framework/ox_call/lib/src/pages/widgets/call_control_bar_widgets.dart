part of 'call_control_bar.dart';

/// Mute button that handles its own state and actions.
class _MuteButton extends StatelessWidget {
  const _MuteButton({
    required this.controller,
    required this.disabled,
  });

  final CallPageController controller;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
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
    );
  }
}

/// Speaker button that handles its own state and actions.
class _SpeakerButton extends StatelessWidget {
  const _SpeakerButton({
    required this.controller,
    required this.disabled,
  });

  final CallPageController controller;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
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
    );
  }
}

/// Camera button that handles its own state and actions.
class _CameraButton extends StatelessWidget {
  const _CameraButton({
    required this.controller,
    required this.disabled,
  });

  final CallPageController controller;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
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
    );
  }
}

/// Hang up button that handles its own actions.
class _HangUpButton extends StatelessWidget {
  const _HangUpButton({
    required this.controller,
    required this.disabled,
    required this.isOutgoingRinging,
  });

  final CallPageController controller;
  final bool disabled;
  final bool isOutgoingRinging;

  @override
  Widget build(BuildContext context) {
    if (disabled) {
      return CallControlButton.inactive(
        icon: Icons.call_end,
        label: isOutgoingRinging ? 'Cancel' : 'Hang Up',
        onTap: () {},
      );
    }
    return CallControlButton.danger(
      icon: Icons.call_end,
      label: isOutgoingRinging ? 'Cancel' : 'Hang Up',
      onTap: controller.hangUp,
    );
  }
}

/// Accept button for incoming calls.
class _AcceptButton extends StatelessWidget {
  const _AcceptButton({
    required this.controller,
    required this.disabled,
    required this.isConnecting,
  });

  final CallPageController controller;
  final bool disabled;
  final bool isConnecting;

  @override
  Widget build(BuildContext context) {
    if (disabled) {
      return CallControlButton.inactive(
        icon: Icons.call,
        label: isConnecting ? 'Connecting...' : 'Accept',
        onTap: () {},
      );
    }
    return CallControlButton.success(
      icon: Icons.call,
      label: 'Accept',
      onTap: controller.accept,
    );
  }
}

/// Decline button for incoming calls.
class _DeclineButton extends StatelessWidget {
  const _DeclineButton({
    required this.controller,
    required this.disabled,
    required this.isConnecting,
  });

  final CallPageController controller;
  final bool disabled;
  final bool isConnecting;

  @override
  Widget build(BuildContext context) {
    if (disabled) {
      return CallControlButton.inactive(
        icon: Icons.call_end,
        label: isConnecting ? 'Connecting...' : 'Decline',
        onTap: () {},
      );
    }
    return CallControlButton.danger(
      icon: Icons.call_end,
      label: 'Decline',
      onTap: controller.reject,
    );
  }
}

/// Switch camera button.
class _SwitchCameraButton extends StatelessWidget {
  const _SwitchCameraButton({
    required this.controller,
    required this.disabled,
  });

  final CallPageController controller;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return CallControlButton.icon(
      icon: Icons.cameraswitch,
      label: '',
      onTap: disabled ? () {} : controller.switchCamera,
    );
  }
}

/// Portrait mode button (placeholder).
class _PortraitModeButton extends StatelessWidget {
  const _PortraitModeButton();

  @override
  Widget build(BuildContext context) {
    return CallControlButton.icon(
      icon: Icons.person_outline,
      label: '',
      onTap: () {
        // TODO: Implement portrait mode
      },
    );
  }
}