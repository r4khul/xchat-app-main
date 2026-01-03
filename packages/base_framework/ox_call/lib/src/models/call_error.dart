enum CallErrorType {
  permissionDenied,
  deviceOccupied,
  audioRouteFailed,
  networkUnavailable,
  networkTimeout,
  natUdpBlocked,
  turnUnavailable,
  peerOffline,
  inviteExpired,
  stateConflict,
  replayOrOutOfOrder,
  sdpSetupFailed,
  codecIncompatible,
  iceFailed,
  dtlsFailed,
  backgroundRestricted,
  callKitFailed,
  audioSessionInterrupted,
  unknown,
}

class CallError {
  final CallErrorType type;
  final String message;
  final dynamic originalError;

  CallError({
    required this.type,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'CallError(type: $type, message: $message)';
}