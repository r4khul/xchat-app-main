import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:chatcore/chat-core.dart';

class PingResult {
  final bool reachable;
  final int timeMs;
  final double? successRate;

  const PingResult._({
    required this.reachable,
    required this.timeMs,
    required this.successRate,
  });

  factory PingResult.success({
    required int timeMs,
    double successRate = 1.0,
  }) {
    return PingResult._(
      reachable: true,
      timeMs: timeMs,
      successRate: successRate,
    );
  }

  factory PingResult.failure() {
    return const PingResult._(
      reachable: false,
      timeMs: 0,
      successRate: 0,
    );
  }

  @override
  String toString() {
    return 'PingResult(reachable=$reachable, timeMs=$timeMs, successRate=$successRate)';
  }
}

class PingHelper {
  static Duration get _timeoutDuration => const Duration(seconds: 2);
  static Duration get _singlePingTimeout => const Duration(milliseconds: 500);

  static Future<bool> reachable(Uri uri) async {
    try {
      final ws = await WebSocket.connect(uri.toString())
        .timeout(
          _timeoutDuration,
          onTimeout: () async {
            throw Exception('reachable timeout');
          },
        );
      ws.close();
      return true;
    } catch (e) {
      LogUtils.e(() => 'reachable error: $e');
      return false;
    }
  }

  static Future<PingResult> relayLatency({
    required Uri uri,
    int count = 3,
    Duration interval = const Duration(milliseconds: 200),
  }) async {
    return _runAttempts(
      attempt: () => _nostrPingViaPingPong(uri),
      count: count,
      interval: interval,
    );
  }

  static Future<PingResult> _runAttempts({
    required Future<int?> Function() attempt,
    required int count,
    required Duration interval,
  }) async {
    int successCount = 0;
    final times = <int>[];

    for (int i = 0; i < count; i++) {
      final ms = await attempt();
      if (ms != null) {
        successCount++;
        times.add(ms);
      }
      if (i < count - 1) {
        await Future.delayed(interval);
      }
    }

    final rate = successCount / count;
    final avg = times.isNotEmpty
        ? times.reduce((a, b) => a + b) / times.length
        : null;

    if (successCount > 0 && avg != null) {
      return PingResult.success(
        timeMs: avg.round(),
        successRate: rate,
      );
    } else {
      return PingResult.failure();
    }
  }

  static Future<int?> _nostrPingViaPingPong(Uri uri) async {
    return Connect.sharedInstance.testRelayLatency(
      uri.toString(),
      timeout: _singlePingTimeout,
    );
  }
}