// shared_core/lib/src/core/utils/error_logger.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Pure Dart error logger with Firestore persistence + smart severity
class ErrorLogger {
  /// Custom logger override (set in main.dart if needed)
  static void Function({
    required String message,
    String? source,
    String? severity,
    String? stack,
    Map<String, dynamic>? contextData,
  })? _customLogger;

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

  /// Smart severity adjustment
  static String _normalizeSeverity(String? severity, String message) {
    final msg = message.toLowerCase();
    if (severity == 'fatal') return 'fatal';

    if (msg.contains('lightweight') ||
        msg.contains('unimplemented') ||
        msg.contains('admin-only') ||
        msg.contains('skipped')) {
      return 'warning';
    }
    if (msg.contains('permission-denied') ||
        msg.contains('failed-precondition') ||
        msg.contains('index')) {
      return 'error';
    }
    return severity?.toLowerCase() ?? 'info';
  }

  /// Public entry point
  static Future<void> log({
    required String message,
    String? source,
    String? severity,
    String? stack,
    Map<String, dynamic>? contextData,
  }) async {
    final finalSeverity = _normalizeSeverity(severity, message);
    final fullContext = {
      if (contextData != null) ...contextData,
      'platform': kIsWeb ? 'web' : 'mobile',
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Call custom logger if set
    _customLogger?.call(
      message: message,
      source: source,
      severity: finalSeverity,
      stack: stack,
      contextData: fullContext,
    );

    // Console output (development friendly)
    print('[$finalSeverity] $source: $message');

    // Persist to Firestore (non-blocking)
    try {
      await FirebaseFirestore.instance.collection('error_logs').add({
        'message': message,
        'source': source ?? 'unknown',
        'severity': finalSeverity,
        'stack': stack ?? '',
        'context': fullContext,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Fallback if Firestore itself fails
      print('[ErrorLogger] Failed to write to error_logs: $e');
    }
  }
}
