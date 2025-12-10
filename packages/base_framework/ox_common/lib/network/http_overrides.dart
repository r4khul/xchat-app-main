import 'dart:async';
import 'dart:io';
import 'package:ox_common/log_util.dart';
import 'package:tor/tor.dart';
import 'package:socks5_proxy/socks.dart';

import 'tor_network_helper.dart';

class OXHttpOverrides extends HttpOverrides {
  bool Function()? torUsageResolver;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context)
      ..badCertificateCallback = badCertificateHandler
      ..connectionFactory = (uri, proxyHost, proxyPort) async {
        ProxySettings? proxy = await getProxySetting(uri, context);
        final socket = createSocket(uri: uri, proxy: proxy, context: context);
        return ConnectionTask.fromSocket(socket, () async => (await socket).close().ignore());
      };
    return client;
  }

  bool badCertificateHandler(X509Certificate cert, String host, int port) => true;

  Future<ProxySettings?> getProxySetting(Uri uri, SecurityContext? context) async {
    final isTorUsage = torUsageResolver?.call() ?? false;
    final isOnionUrl = TorNetworkHelper.isOnionUrl(uri.toString());
    if (isTorUsage || isOnionUrl) {
      LogUtil.d('[OXHttpOverrides] Using Tor proxy');
      return getTorProxy(context);
    }
    LogUtil.d('[OXHttpOverrides] Using direct');
    return null;
  }

  Future<ProxySettings> getTorProxy(SecurityContext? context) async {
    await TorNetworkHelper.initializeWaiting;
    return ProxySettings(
      TorNetworkHelper.torProxyHost,
      TorNetworkHelper.torProxyPort,
      context: context,
    );
  }

  ProxySettings? getSystemProxy(SecurityContext? context) {
    final systemProxy = Tor.instance.currentSystemProxy();
    if (systemProxy == null) return null;

    return ProxySettings(
      InternetAddress(systemProxy.address),
      systemProxy.port,
      context: context,
    );
  }

  Future<Socket> createSocket({
    required Uri uri,
    required ProxySettings? proxy,
    SecurityContext? context,
  }) async {
    final isSecure = uri.scheme == 'https';
    final port = portWith(uri: uri);

    if (proxy != null) {
      final client = await SocksTCPClient.connect(
        [proxy],
        InternetAddress(uri.host, type: InternetAddressType.unix),
        port,
      );

      // Secure connection after establishing Socks connection
      if (isSecure) {
        return client.secure(
          uri.host,
          context: context,
          onBadCertificate: (cer) => badCertificateHandler(cer, uri.host, port),
        );
      }

      return client;
    }

    if (isSecure) {
      return SecureSocket.connect(
        uri.host,
        port,
        context: context,
        onBadCertificate: (cer) => badCertificateHandler(cer, uri.host, port),
      );
    }

    return Socket.connect(uri.host, port);
  }

  int portWith({required Uri uri}) {
    final isSecure = uri.scheme == 'https' || uri.scheme == 'wss';
    var uriPort = uri.port;
    if (uriPort == 0) {
      uriPort = isSecure ? 443 : 80;
    }
    return uriPort;
  }
}