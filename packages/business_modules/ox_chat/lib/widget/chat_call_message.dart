import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:chatcore/chat-core.dart';
import 'package:ox_chat/message_handler/custom_message_utils.dart';
import 'package:ox_common/business_interface/ox_chat/call_message_type.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_localizable/ox_localizable.dart';

extension CallMessageEx on types.CustomMessage {
  String get callText => metadata?[CustomMessageEx.metaContentKey]?['text'] ?? '';
  CallMessageType? get callType => CallMessageTypeEx.fromValue(metadata?[CustomMessageEx.metaContentKey]?['type']);
  CallMessageState? get callState => metadata?[CustomMessageEx.metaContentKey]?['state'];
  int? get callDuration {
    final duration = metadata?[CustomMessageEx.metaContentKey]?['duration'];
    if (duration is int) return duration;
    if (duration is String) return int.tryParse(duration);
    return null;
  }
}

class ChatCallMessage extends StatelessWidget {
  const ChatCallMessage({
    required this.message,
    required this.isMe,
  });

  final types.CustomMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final callType = CallMessageEx(message).callType;
    final state = CallMessageEx(message).callState;
    final duration = CallMessageEx(message).callDuration;

    if (callType == null) {
      return const SizedBox();
    }

    final isVideoCall = callType == CallMessageType.video;
    final hasDuration = duration != null && duration > 0;

    Color backgroundColor;
    Color borderColor;
    Color textColor;
    Color iconColor;
    String statusText;

    if (hasDuration) {
      backgroundColor = Colors.green.withValues(alpha: 0.1);
      borderColor = Colors.green;
      textColor = Colors.green;
      iconColor = Colors.green;
      final durationText = _formatDuration(duration);
      statusText = Localized.text('ox_chat.call_duration')
          .replaceAll(r'${duration}', durationText);
    } else {
      switch (state) {
        case CallMessageState.reject:
          backgroundColor = Colors.red.withValues(alpha: 0.1);
          borderColor = Colors.red;
          textColor = Colors.red;
          iconColor = Colors.red;
          statusText = isMe
              ? Localized.text('ox_chat.call_rejected_by_other')
              : Localized.text('ox_chat.call_rejected');
          break;
        case CallMessageState.cancel:
          backgroundColor = Colors.orange.withValues(alpha: 0.1);
          borderColor = Colors.orange;
          textColor = Colors.orange;
          iconColor = Colors.orange;
          statusText = Localized.text('ox_chat.call_canceled');
          break;
        case CallMessageState.timeout:
          backgroundColor = Colors.grey.withValues(alpha: 0.1);
          borderColor = Colors.grey;
          textColor = Colors.grey;
          iconColor = Colors.grey;
          statusText = Localized.text('ox_chat.call_timeout');
          break;
        case CallMessageState.inCalling:
          backgroundColor = Colors.grey.withValues(alpha: 0.1);
          borderColor = Colors.grey;
          textColor = Colors.grey;
          iconColor = Colors.grey;
          statusText = Localized.text('ox_chat.call_busy');
          break;
        case CallMessageState.disconnect:
        case CallMessageState.offer:
        case CallMessageState.answer:
        default:
          return SizedBox();
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.px, vertical: 8.px),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.px),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVideoCall ? Icons.videocam : Icons.phone,
            size: 20.px,
            color: iconColor,
          ),
          SizedBox(width: 8.px),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CLText.labelMedium(
                isVideoCall
                    ? Localized.text('ox_chat.video_call')
                    : Localized.text('ox_chat.voice_call'),
                customColor: textColor,
              ),
              if (statusText.isNotEmpty) ...[
                SizedBox(height: 2.px),
                CLText.labelSmall(
                  statusText,
                  customColor: textColor,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int durationMs) {
    final duration = Duration(milliseconds: durationMs);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}


