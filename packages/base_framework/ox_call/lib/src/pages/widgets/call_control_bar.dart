import 'package:flutter/material.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_call/src/models/call_state.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'call_page_controller.dart';
import 'call_control_button.dart';

part 'call_control_bar_widgets.dart';

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
    return ValueListenableBuilder(
      valueListenable: controller.isConnected$,
      builder: (context, isConnected, _) {
        // Incoming call ringing: show accept/decline
        if (!isConnected && controller.isIncoming) {
          return _IncomingCallControls(
            controller: controller,
          );
        }

        // Video call: two-row layout
        if (controller.isVideoCall) {
          return _VideoCallControls(controller: controller);
        }

        // Voice call: single-row layout
        return _VoiceCallControls(controller: controller);
      },
    );
  }
}

/// Controls for incoming call (Decline / Accept).
class _IncomingCallControls extends StatelessWidget {
  const _IncomingCallControls({
    required this.controller,
  });

  final CallPageController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.callState$,
      builder: (context, state, _) => ValueListenableBuilder<bool>(
        valueListenable: controller.actionInProgress$,
        builder: (context, inProgress, __) {
          final disabled = inProgress || state == CallState.ended;
          final isConnecting = state == CallState.connecting;
          return SafeArea(
            child: _buildButtonRow(disabled, isConnecting),
          );
        },
      ),
    );
  }

  Widget _buildButtonRow(bool disabled, bool isConnecting) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.px),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _DeclineButton(
            controller: controller,
            disabled: disabled,
            isConnecting: isConnecting,
          ),
          SizedBox(width: 80.px),
          _AcceptButton(
            controller: controller,
            disabled: disabled,
            isConnecting: isConnecting,
          ),
        ],
      ),
    );
  }
}

/// Controls for voice call (single row: Mic / Hang Up / Speaker).
class _VoiceCallControls extends StatelessWidget {
  const _VoiceCallControls({required this.controller});

  final CallPageController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.callState$,
      builder: (context, state, _) => ValueListenableBuilder(
        valueListenable: controller.actionInProgress$,
        builder: (context, inProgress, _) {
          final isOutgoingRinging =
              !controller.isIncoming && state == CallState.ringing;
          final disabled = inProgress || state == CallState.ended;
          return SafeArea(
            child: _buildButtonRow(disabled, isOutgoingRinging),
          );
        },
      ),
    );
  }

  Widget _buildButtonRow(bool disabled, bool isOutgoingRinging) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.px),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MuteButton(controller: controller, disabled: disabled),
          SizedBox(width: 40.px),
          _HangUpButton(
            controller: controller,
            disabled: disabled,
            label: isOutgoingRinging ? Localized.text('ox_chat.call_cancel') : Localized.text('ox_chat.call_hang_up'),
            isOutgoingRinging: isOutgoingRinging,
          ),
          SizedBox(width: 40.px),
          _SpeakerButton(controller: controller, disabled: disabled),
        ],
      ),
    );
  }
}

class _VideoCallControls extends StatelessWidget {
  const _VideoCallControls({required this.controller});

  final CallPageController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.callState$,
      builder: (context, state, _) => ValueListenableBuilder(
        valueListenable: controller.actionInProgress$,
        builder: (context, inProgress, _) {
          final isOutgoingRinging =
              !controller.isIncoming && state == CallState.ringing;
          final disabled = inProgress || state == CallState.ended;
          return _buildContainer(disabled, isOutgoingRinging);
        },
      ),
    );
  }

  Widget _buildContainer(bool disabled, bool isOutgoingRinging) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.px),
      decoration: _buildGradientDecoration(),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFirstRow(disabled),
            SizedBox(height: 24.px),
            _buildSecondRow(disabled, isOutgoingRinging),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildGradientDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.6),
        ],
      ),
    );
  }

  Widget _buildFirstRow(bool disabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _MuteButton(controller: controller, disabled: disabled),
        _SpeakerButton(controller: controller, disabled: disabled),
        _CameraButton(controller: controller, disabled: disabled),
      ],
    );
  }

  Widget _buildSecondRow(bool disabled, bool isOutgoingRinging) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        CallControlButton.placeholder(),
        _HangUpButton(
          controller: controller,
          disabled: disabled,
          label: null,
          isOutgoingRinging: isOutgoingRinging,
        ),
        _SwitchCameraButton(controller: controller, disabled: disabled),
      ],
    );
  }
}