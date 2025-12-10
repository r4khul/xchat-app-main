import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tor/proxy_support.dart';
import 'package:tor/tor.dart';

import '../log_util.dart';

class TorNetworkHelper {

  static bool get isTorEnabled => Tor.instance.started && Tor.instance.bootstrapped;
  static Future<bool> get initializeWaiting => _initializeWaitingCmp.future;
  static Completer<bool> _initializeWaitingCmp = Completer();

  static InternetAddress get torProxyHost => InternetAddress.loopbackIPv4;
  static int get torProxyPort => Tor.instance.port;

  static Future<void> initialize() async {
    if (isTorEnabled) return;

    try {
      await Tor.init(enabled: true);
      await _start();
    } catch (e) {
      if (kDebugMode) {
        LogUtil.e('Failed to initialize Tor: $e');
      }
      _initializeWaitingCmp.complete(false);
      rethrow;
    }
  }

  static Future<void> _start() async {
    try {
      await Tor.instance.start();
      _initializeWaitingCmp.complete(true);
    } catch (e) {
      if (kDebugMode) {
        LogUtil.e('Failed to start Tor: $e');
      }
      _initializeWaitingCmp.complete(false);
      rethrow;
    }
  }

  static Future<void> stop() async {
    await Tor.instance.stop();
  }

  static bool isOnionUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.host.toLowerCase().contains('.onion');
  }

  static void updateCustomProxy(String address, int port) {
    Tor.instance.updateCustomProxy(
      ProxyInfo(
        address: address,
        port: port,
        type: ProxyType.socks5,
      ),
    );
  }

  static void clearCustomProxy() {
    Tor.instance.updateCustomProxy(null);
  }
}