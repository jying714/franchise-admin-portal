import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class LogUtils {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      lineLength: 100, // Width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      dateTimeFormat:
          DateTimeFormat.onlyTimeAndSinceStart, // Shows time & uptime
    ),
  );

  static File? _logFile;

  /// Initializes the log file location (call once, e.g., in main())
  static Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/app_log.txt';
    _logFile = File(path);
  }

  /// Writes a message to the file (appends with timestamp)
  static Future<void> logToFile(String message) async {
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

  /// Error log, with proper named parameters
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

  /// Trace log (formerly verbose)
  static void t(String message) {
    _logger.t(message);
    logToFile('TRACE: $message');
  }

  /// Convenience: Log any exception with stack trace
  static void logException(dynamic error, StackTrace? stack,
      {String? context}) {
    final msg = context != null ? '[$context] $error' : '$error';
    e(msg, error, stack);
  }
}
