import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  error,
  warning,
}

class CallLogger {
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  static void _log(LogLevel level, String message, [dynamic error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();
    final logMessage = '[CallManager][$levelStr][$timestamp] $message';

    if (kDebugMode) {
      switch (level) {
        case LogLevel.debug:
          debugPrint(logMessage);
          break;
        case LogLevel.info:
          print(logMessage);
          break;
        case LogLevel.warning:
          print('⚠️ $logMessage');
          if (error != null) print('Error: $error');
          break;
        case LogLevel.error:
          print('❌ $logMessage');
          if (error != null) print('Error: $error');
          if (stackTrace != null) print('Stack: $stackTrace');
          break;
      }
    }
  }
}