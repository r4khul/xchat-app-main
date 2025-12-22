import 'package:flutter/foundation.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_call/src/models/call_state.dart';
import 'package:ox_call/src/models/call_target.dart';

class CallSession {
  final String sessionId;

  /// The caller target (who initiated the call).
  final CallTarget callerTarget;

  /// The callee target (who receives the call).
  final CallTarget calleeTarget;

  final List<CallTarget> participants;
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
    required this.callerTarget,
    required this.calleeTarget,
    required this.participants,
    required this.callType,
    required this.direction,
    required this.state,
    required this.startTime,
    this.endTime,
    this.endReason,
    this.duration,
    this.remoteSdp,
  })  : callerUser$ = callerTarget.user$,
        calleeUser$ = calleeTarget.user$;

  /// Convenience getter for caller pubkey.
  String get callerPubkey => callerTarget.pubkey;

  /// Convenience getter for callee pubkey.
  String get calleePubkey => calleeTarget.pubkey;

  /// Get the private group ID for this call session.
  /// Uses the callee's privateGroupId as the signaling context.
  String get privateGroupId => calleeTarget.privateGroupId;

  /// Get the remote target based on call direction.
  CallTarget get remoteTarget =>
      direction == CallDirection.outgoing ? calleeTarget : callerTarget;

  /// Get the local target based on call direction.
  CallTarget get localTarget =>
      direction == CallDirection.outgoing ? callerTarget : calleeTarget;

  /// Get the remote user based on call direction.
  ValueNotifier<UserDBISAR?> get remoteUser$ =>
      direction == CallDirection.outgoing ? calleeUser$ : callerUser$;

  /// Get the local user based on call direction.
  ValueNotifier<UserDBISAR?> get localUser$ =>
      direction == CallDirection.outgoing ? callerUser$ : calleeUser$;

  /// Get participant pubkeys for backward compatibility.
  List<String> get participantPubkeys =>
      participants.map((t) => t.pubkey).toList();
}