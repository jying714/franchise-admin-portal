import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';

// Only import dart:io and path_provider if not on web
// ignore: uri_does_not_exist
import 'dart:io' if (dart.library.io) 'dart:io';
// ignore: uri_does_not_exist
import 'package:path_provider/path_provider.dart'
    if (dart.library.io) 'package:path_provider/path_provider.dart';

class LogUtils {
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

  static File? _logFile;

  /// Initializes the log file location (call once, e.g., in main())
  static Future<void> init() async {
    if (kIsWeb) return; // Skip file logging on web
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/app_log.txt';
    _logFile = File(path);
  }

  /// Writes a message to the file (appends with timestamp)
  static Future<void> logToFile(String message) async {
    if (kIsWeb) return; // No-op on web
    if (_logFile == null) await init();
    final timestamp = DateTime.now().toIso8601String();
    await _logFile?.writeAsString('[$timestamp] $message\n',
        mode: FileMode.append);
  }

  /// Info log
  static void i(String message) {
    _logger.i(message);
    logToFile(message);
  }

  /// Error log
  static void e(String message, [dynamic error, StackTrace? stack]) {
    _logger.e(message, error: error, stackTrace: stack);
    logToFile('ERROR: $message\n${error ?? ''}\n${stack ?? ''}');
  }

  /// Debug log
  static void d(String message) {
    _logger.d(message);
    logToFile('DEBUG: $message');
  }

  /// Warning log
  static void w(String message) {
    _logger.w(message);
    logToFile('WARNING: $message');
  }

  /// Trace log
  static void t(String message) {
    _logger.t(message);
    logToFile('TRACE: $message');
  }

  /// Log exception
  static void logException(dynamic error, StackTrace? stack,
      {String? context}) {
    final msg = context != null ? '[$context] $error' : '$error';
    e(msg, error, stack);
  }
}
