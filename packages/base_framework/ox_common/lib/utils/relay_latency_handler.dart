import 'dart:async';
import 'package:chatcore/chat-core.dart';
import 'package:flutter/cupertino.dart';
import 'package:ox_common/network/ping_helper.dart';

enum RelayNetworkStatus {
  offline,
  excellent,
  normal,
  poor,
}

extension PingResultRelayStatusX on PingResult {
  RelayNetworkStatus get relayStatus {
    if (!reachable) return RelayNetworkStatus.offline;

    final int latency = timeMs;

    if (latency <= 200) {
      return RelayNetworkStatus.excellent;
    }

    if (latency <= 500) {
      return RelayNetworkStatus.normal;
    }

    return RelayNetworkStatus.poor;
  }

  Color get relayStatusColor {
    switch (relayStatus) {
      case RelayNetworkStatus.excellent:
        return CupertinoColors.systemGreen;
      case RelayNetworkStatus.normal:
        return CupertinoColors.systemYellow;
      case RelayNetworkStatus.poor:
        return CupertinoColors.systemRed;
      case RelayNetworkStatus.offline:
        return CupertinoColors.systemGrey;
    }
  }
}

/// RelayLatencyHandler encapsulates latency measurement of a relay (WebSocket) URL.
/// It follows the workflow:
/// 1. Fast retry (every 5s) until a valid latency (>0) is obtained.
/// 2. After success, refresh periodically (1min when collapsed, 5s when expanded).
/// External callers only interact via simple APIs, complying with the Law of Demeter.
class RelayLatencyHandler {
  RelayLatencyHandler({required ValueNotifier<bool> isExpanded$})
      : _isExpanded$ = isExpanded$ {
    _isExpanded$.addListener(_restartRegularTimer);
    _startRegularTimer();
  }

  // Expansion status of the UI, influences regular refresh interval
  final ValueNotifier<bool> _isExpanded$;

  // Map of ping result notifiers, one per relay URL
  final Map<String, ValueNotifier<PingResult>> _resultMap = {};

  // Currently measured relay
  String? _currentRelay;

  // Timers
  Timer? _initialTimer;
  Timer? _regularTimer;

  // Constants
  static const Duration _fastRetry = Duration(seconds: 5);
  static const Duration _regularCollapsed = Duration(minutes: 1);
  static const Duration _regularExpanded = Duration(seconds: 5);

  /// Get ping result notifier for a relay URL.
  ValueNotifier<PingResult> getPingResultNotifier(String relayUrl) {
    return _resultMap.putIfAbsent(
      relayUrl,
      () => ValueNotifier<PingResult>(
        PingResult.failure(),
      ),
    );
  }

  /// Switch to another relay to measure. Fast-retry will start automatically.
  void switchRelay(String relayUrl) {
    if (_currentRelay == relayUrl) return;

    _currentRelay = relayUrl;

    // Ensure notifier exists and reset to offline before measuring
    getPingResultNotifier(relayUrl).value = PingResult.failure();

    _cancelTimers();

    _attemptFastRetry();
  }

  /// Dispose resources.
  void dispose() {
    _isExpanded$.removeListener(_restartRegularTimer);
    _cancelTimers();
  }

  /* ----------------------------- Internal ----------------------------- */

  void _attemptFastRetry() async {
    if (_currentRelay == null) return;
    final success = await _measureOnce(_currentRelay!);
    if (!success) {
      _initialTimer = Timer(_fastRetry, _attemptFastRetry);
    } else {
      _initialTimer = null;
      _startRegularTimer();
    }
  }

  Future<bool> _measureOnce(String relayUrl) async {
    final uri = Uri.tryParse(relayUrl);
    if (uri == null) return false;

    PingResult result = await PingHelper.relayLatency(uri: uri);
    LogUtils.i(() => 'RelayLatency result: $result');

    getPingResultNotifier(relayUrl).value = result;
    return result.reachable;
  }

  void _startRegularTimer() {
    _regularTimer?.cancel();

    Future<void> scheduleNext() async {
      if (_currentRelay != null) {
        await _measureOnce(_currentRelay!);
      }

      // final interval = _isExpanded$.value ? _regularExpanded : _regularCollapsed;
      //
      // _regularTimer = Timer(interval, () {
      //   scheduleNext();
      // });
    }

    scheduleNext();
  }

  void _restartRegularTimer() {
    if (_regularTimer != null) {
      _startRegularTimer();
    }
  }

  void _cancelTimers() {
    _initialTimer?.cancel();
    _regularTimer?.cancel();
    _initialTimer = null;
    _regularTimer = null;
  }
} 