enum CallState {
  idle,
  initiating,
  ringing,
  connecting,
  connected,
  reconnecting,
  ended,
  failed,
}

enum CallType {
  audio,
  video,
}

enum CallDirection {
  incoming,
  outgoing,
}

enum CallEndReason {
  hangup,
  reject,
  timeout,
  busy,
  networkError,
  permissionDenied,
  unknown,
}