import 'package:flutter/foundation.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_call/src/models/call_state.dart';

class CallSession {
  final String sessionId;

  /// The private group ID for signaling context.
  /// All participants in this call share the same privateGroupId.
  final String privateGroupId;

  /// The local user's pubkey (current user).
  final String localPubkey;

  /// The remote user's pubkey (the other party in the call).
  final String remotePubkey;

  /// All participant pubkeys (for multi-party calls).
  final List<String> participantPubkeys;

  final CallType callType;
  final CallDirection direction;
  CallState state;
  int startTime;
  int? endTime;
  CallEndReason? endReason;
  int? duration;

  /// Remote SDP offer (stored for incoming calls until accepted).
  final String? remoteSdp;

  CallSession({
    required this.sessionId,
    required this.privateGroupId,
    required this.localPubkey,
    required this.remotePubkey,
    required this.participantPubkeys,
    required this.callType,
    required this.direction,
    required this.state,
    required this.startTime,
    this.endTime,
    this.endReason,
    this.duration,
    this.remoteSdp,
  });

  /// Get the remote user info (lazily loaded).
  ValueNotifier<UserDBISAR?> get remoteUser$ {
    return Account.sharedInstance.getUserNotifier(remotePubkey);
  }

  /// Get the local user info (lazily loaded).
  ValueNotifier<UserDBISAR?> get localUser$ {
    return Account.sharedInstance.getUserNotifier(localPubkey);
  }
}