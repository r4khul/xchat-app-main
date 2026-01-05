import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:chatcore/chat-core.dart';
import 'package:ox_chat/message_handler/custom_message_utils.dart';
import 'package:ox_common/business_interface/ox_chat/call_message_type.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_localizable/ox_localizable.dart';

import '../manager/chat_page_config.dart';

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

  bool get hasDuration {
    final duration = CallMessageEx(message).callDuration;
    return duration != null && duration > 0;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = textColorOf(context);
    final iconBgColor = iconBgColorOf(context);
    final iconColor = iconColorOf(context);
    final statusText = this.statusText;
    return Container(
      padding: EdgeInsets.only(
        top: 4.px,
        bottom: 4.px,
        left: 2,
        right: 12.px,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 40.px,
            width: 40.px,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(20.px),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20.px,
              color: iconColor,
            ),
          ),
          SizedBox(width: 12.px),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CLText.titleMedium(
                titleText,
                customColor: textColor,
              ),
              if (statusText.isNotEmpty) ...[
                SizedBox(height: 2.px),
                CLText.titleSmall(
                  statusText,
                  customColor: textColor?.withValues(alpha: 0.7),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color? textColorOf(BuildContext context) {
    final theme = ChatPageConfig().pageTheme(context);
    return message.isMe
        ? theme.sentMessageBodyTextStyle.color
        : theme.receivedMessageBodyTextStyle.color;
  }

  Color? iconBgColorOf(BuildContext context) {
    return message.isMe
        ? ColorToken.white.of(context).withValues(alpha: 0.8)
        : ColorToken.onSecondaryContainer.of(context).withValues(alpha: 0.1);
  }

  Color? iconColorOf(BuildContext context) {
    if (hasDuration) {
      return message.isMe
          ? ColorToken.black.of(context)
          : textColorOf(context);
    } else {
      return Colors.red[700];
    }
  }

  IconData? get icon {
    final callType = CallMessageEx(message).callType;
    switch (callType) {
      case CallMessageType.audio:
        return message.isMe
            ? CupertinoIcons.phone_fill_arrow_up_right
            : CupertinoIcons.phone_fill_arrow_down_left;
      case CallMessageType.video:
        return Icons.videocam;
      default:
        return null;
    }
  }

  String get titleText {
    final callType = CallMessageEx(message).callType;
    switch (callType) {
      case CallMessageType.audio:
        return Localized.text('ox_chat.voice_call');
      case CallMessageType.video:
        return Localized.text('ox_chat.video_call');
      default:
        return '';
    }
  }

  String get statusText {
    if (hasDuration) {
      final durationText = _formatDuration();
      return Localized.text('ox_chat.call_duration')
          .replaceAll(r'${duration}', durationText);
    } else {
      final state = CallMessageEx(message).callState;
      switch (state) {
        case CallMessageState.reject:
          return isMe
              ? Localized.text('ox_chat.call_rejected_by_other')
              : Localized.text('ox_chat.call_rejected');
        case CallMessageState.cancel:
          return Localized.text('ox_chat.call_canceled');
        case CallMessageState.timeout:
          return Localized.text('ox_chat.call_timeout');
        case CallMessageState.inCalling:
          return isMe
              ? Localized.text('ox_chat.call_busy')
              : Localized.text('ox_chat.call_busy_not_answered');
        case CallMessageState.disconnect:
        case CallMessageState.offer:
        case CallMessageState.answer:
        default:
          return '';
      }
    }
  }

  String _formatDuration() {
    final durationMs = CallMessageEx(message).callDuration;
    if (durationMs is! int) return '';

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


