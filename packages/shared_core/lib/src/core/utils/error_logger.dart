// shared_core/lib/src/core/utils/error_logger.dart

/// Pure Dart error logger interface + fallback
/// Apps override via setCustomLogger()
class ErrorLogger {
  /// Default fallback logger (prints to console)
  static void _defaultLog({
    required String message,
    String? source,
    String? severity,
    String? stack,
    Map<String, dynamic>? contextData,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('[ERROR] $message');
    if (source != null) buffer.writeln('  Source: $source');
    if (severity != null) buffer.writeln('  Severity: $severity');
    if (stack != null) buffer.writeln('  Stack: $stack');
    if (contextData != null && contextData.isNotEmpty) {
      buffer.writeln('  Context: $contextData');
    }
    // ignore: avoid_print
    print(buffer.toString());
  }

  /// Custom logger set by app
  static void Function({
    required String message,
    String? source,
    String? severity,
    String? stack,
    Map<String, dynamic>? contextData,
  })? _customLogger;

  /// Set custom logger (called once in main.dart)
  static void setCustomLogger(
    void Function({
      required String message,
      String? source,
      String? severity,
      String? stack,
      Map<String, dynamic>? contextData,
    }) logger,
  ) {
    _customLogger = logger;
  }

  /// Public entry point — safe to call from anywhere
  static void log({
    required String message,
    String? source,
    String? severity,
    String? stack,
    Map<String, dynamic>? contextData,
  }) {
    _customLogger?.call(
      message: message,
      source: source,
      severity: severity,
      stack: stack,
      contextData: contextData,
    );
    _defaultLog(
      message: message,
      source: source,
      severity: severity,
      stack: stack,
      contextData: contextData,
    );
  }
}
