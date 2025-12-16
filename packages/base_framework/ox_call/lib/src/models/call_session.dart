import 'package:flutter/foundation.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_call/src/models/call_state.dart';

class CallSession {
  final String sessionId;
  final String offerId;
  final String callerPubkey;
  final String calleePubkey;
  final List<String> participants;
  final CallType callType;
  final CallDirection direction;
  CallState state;
  int startTime;
  int? endTime;
  CallEndReason? endReason;
  int? duration;

  /// Remote SDP offer (stored for incoming calls until accepted).
  final String? remoteSdp;

  /// ValueNotifier for caller user info, lazily loaded.
  final ValueNotifier<UserDBISAR?> callerUser$;

  /// ValueNotifier for callee user info, lazily loaded.
  final ValueNotifier<UserDBISAR?> calleeUser$;

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
    this.remoteSdp,
  })  : callerUser$ = Account.sharedInstance.getUserNotifier(callerPubkey),
        calleeUser$ = Account.sharedInstance.getUserNotifier(calleePubkey);

  /// Get the remote user based on call direction.
  ValueNotifier<UserDBISAR?> get remoteUser$ =>
      direction == CallDirection.outgoing ? calleeUser$ : callerUser$;

  /// Get the local user based on call direction.
  ValueNotifier<UserDBISAR?> get localUser$ =>
      direction == CallDirection.outgoing ? callerUser$ : calleeUser$;
}