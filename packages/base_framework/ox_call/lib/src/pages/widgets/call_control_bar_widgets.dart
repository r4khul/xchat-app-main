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
            label: isMuted ? Localized.text('ox_chat.call_mic_off') : Localized.text('ox_chat.call_mic_on'),
            onTap: () {},
          );
        }
        return isMuted
            ? CallControlButton.inactive(
          icon: Icons.mic_off,
          label: Localized.text('ox_chat.call_mic_off'),
          onTap: controller.toggleMute,
        )
            : CallControlButton.active(
          icon: Icons.mic,
          label: Localized.text('ox_chat.call_mic_on'),
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
            label: isSpeakerOn ? Localized.text('ox_chat.call_speaker') : Localized.text('ox_chat.call_speaker_off'),
            onTap: () {},
          );
        }
        return isSpeakerOn
            ? CallControlButton.active(
          icon: Icons.volume_up,
          label: Localized.text('ox_chat.call_speaker'),
          onTap: controller.toggleSpeaker,
        )
            : CallControlButton.inactive(
          icon: Icons.volume_off,
          label: Localized.text('ox_chat.call_speaker'),
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
            label: isCameraOn ? Localized.text('ox_chat.call_camera_on') : Localized.text('ox_chat.call_camera_off'),
            onTap: () {},
          );
        }
        return isCameraOn
            ? CallControlButton.active(
          icon: Icons.videocam,
          label: Localized.text('ox_chat.call_camera_on'),
          onTap: controller.toggleCamera,
        )
            : CallControlButton.inactive(
          icon: Icons.videocam_off,
          label: Localized.text('ox_chat.call_camera_off'),
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
    required this.label,
    required this.isOutgoingRinging,
  });

  final CallPageController controller;
  final String? label;
  final bool disabled;
  final bool isOutgoingRinging;

  @override
  Widget build(BuildContext context) {
    if (disabled) {
      return CallControlButton.inactive(
        icon: Icons.call_end,
        label: label,
        onTap: () {},
      );
    }
    return CallControlButton.danger(
      icon: Icons.call_end,
      label: label,
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
        label: isConnecting ? Localized.text('ox_chat.call_connecting') : Localized.text('ox_chat.call_accept'),
        onTap: () {},
      );
    }
    return CallControlButton.success(
      icon: Icons.call,
      label: Localized.text('ox_chat.call_accept'),
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
        label: isConnecting ? Localized.text('ox_chat.call_connecting') : Localized.text('ox_chat.call_decline'),
        onTap: () {},
      );
    }
    return CallControlButton.danger(
      icon: Icons.call_end,
      label: Localized.text('ox_chat.call_decline'),
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
    return CallControlButton.inactive(
      icon: Icons.cameraswitch,
      onTap: disabled ? () {} : controller.switchCamera,
    );
  }
}