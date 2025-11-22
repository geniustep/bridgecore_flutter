import 'package:flutter/foundation.dart';

/// Logger for BridgeCore SDK
class BridgeCoreLogger {
  static bool _enabled = false;
  static LogLevel _level = LogLevel.info;

  /// Enable or disable logging
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Set log level
  static void setLevel(LogLevel level) {
    _level = level;
  }

  /// Log debug message
  static void debug(String message, [Map<String, dynamic>? data]) {
    if (!_enabled || _level.index > LogLevel.debug.index) return;
    _log('DEBUG', message, data);
  }

  /// Log info message
  static void info(String message, [Map<String, dynamic>? data]) {
    if (!_enabled || _level.index > LogLevel.info.index) return;
    _log('INFO', message, data);
  }

  /// Log warning message
  static void warning(String message, [Map<String, dynamic>? data]) {
    if (!_enabled || _level.index > LogLevel.warning.index) return;
    _log('WARNING', message, data);
  }

  /// Log error message
  static void error(String message,
      [Map<String, dynamic>? data, dynamic error]) {
    if (!_enabled || _level.index > LogLevel.error.index) return;
    _log('ERROR', message, data, error);
  }

  static void _log(String level, String message,
      [Map<String, dynamic>? data, dynamic error]) {
    final timestamp = DateTime.now().toIso8601String();
    final prefix = '[BridgeCore][$timestamp][$level]';

    if (data != null || error != null) {
      debugPrint('$prefix $message');
      if (data != null) {
        debugPrint('$prefix Data: $data');
      }
      if (error != null) {
        debugPrint('$prefix Error: $error');
      }
    } else {
      debugPrint('$prefix $message');
    }
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
}
