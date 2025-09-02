import 'dart:async';
import 'dart:math';
import 'dart:ui';

class CLRetryer {
  CLRetryer({
    this.maxAttempts = 6,
    this.jitterLowMs = 100,
    this.jitterHighMs = 499,
  }) : assert(maxAttempts > 0),
        assert(jitterLowMs >= 0),
        assert(jitterHighMs >= jitterLowMs);

  final int maxAttempts;
  final int jitterLowMs;
  final int jitterHighMs;

  int _attempt = 0;
  Timer? _timer;

  /// Schedules [action] using exponential backoff + jitter.
  /// If max attempts reached, this is a no-op.
  void schedule(VoidCallback action) {
    if (_attempt >= maxAttempts) {
      return;
    }
    _attempt += 1; // 1-based
    final seconds = 1 << _attempt; // 2,4,8,16,32,64...
    final jitter = (jitterHighMs == jitterLowMs)
        ? jitterLowMs
        : (jitterLowMs + Random().nextInt(jitterHighMs - jitterLowMs + 1));
    final delay = Duration(seconds: seconds, milliseconds: jitter);

    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void reset() {
    _attempt = 0;
    _timer?.cancel();
    _timer = null;
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  int get attempt => _attempt;

  bool get hasPending => _timer != null;
}
