import 'package:ox_call/src/models/call_state.dart';

class CallSession {
  final String sessionId;
  final String offerId;
  final String callerPubkey;
  final String calleePubkey;
  final List<String> participants;
  final CallType callType;
  final CallDirection direction;
  final CallState state;
  final int startTime;
  final int? endTime;
  final CallEndReason? endReason;
  final int? duration;

  CallSession({
    required this.sessionId,
    required this.offerId,
    required this.callerPubkey,
    required this.calleePubkey,
    required this.participants,
    required this.callType,
    required this.direction,
    required this.state,
    required this.startTime,
    this.endTime,
    this.endReason,
    this.duration,
  });

  CallSession copyWith({
    String? sessionId,
    String? offerId,
    String? callerPubkey,
    String? calleePubkey,
    List<String>? participants,
    CallType? callType,
    CallDirection? direction,
    CallState? state,
    int? startTime,
    int? endTime,
    CallEndReason? endReason,
    int? duration,
  }) {
    return CallSession(
      sessionId: sessionId ?? this.sessionId,
      offerId: offerId ?? this.offerId,
      callerPubkey: callerPubkey ?? this.callerPubkey,
      calleePubkey: calleePubkey ?? this.calleePubkey,
      participants: participants ?? this.participants,
      callType: callType ?? this.callType,
      direction: direction ?? this.direction,
      state: state ?? this.state,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      endReason: endReason ?? this.endReason,
      duration: duration ?? this.duration,
    );
  }
}