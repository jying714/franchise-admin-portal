// packages/shared_core/lib/src/core/utils/log_utils_core.dart

import 'package:logger/logger.dart';

/// =======================
/// LogUtilsCore (PURE DART)
/// =======================
/// Platform-agnostic logging with callbacks.
/// No Flutter, no file system.
/// =======================

typedef LogCallback = void Function(String message);

class LogUtilsCore {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static LogCallback? _onLog;

  /// Set external log handler (file, analytics, etc.)
  static set logHandler(LogCallback? handler) => _onLog = handler;

  static void _emit(String level, String message,
      [dynamic error, StackTrace? stack]) {
    final fullMessage =
        error != null || stack != null ? '$message\n$error\n$stack' : message;

    _onLog?.call('[$level] $fullMessage');
  }

  static void i(String message) {
    _logger.i(message);
    _emit('INFO', message);
  }

  static void e(String message, [dynamic error, StackTrace? stack]) {
    _logger.e(message, error: error, stackTrace: stack);
    _emit('ERROR', message, error, stack);
  }

  static void d(String message) {
    _logger.d(message);
    _emit('DEBUG', message);
  }

  static void w(String message) {
    _logger.w(message);
    _emit('WARN', message);
  }

  static void t(String message) {
    _logger.t(message);
    _emit('TRACE', message);
  }

  static void logException(dynamic error, StackTrace? stack,
      {String? context}) {
    final msg = context != null ? '[$context] $error' : '$error';
    e(msg, error, stack);
  }
}
