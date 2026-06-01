// web-app/lib/core/utils/log_utils.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

class LogUtils {
  static File? _logFile;

  static Future<void> init() async {
    if (kIsWeb) return;

    shared.LogUtilsCore.logHandler = (message) async {
      if (_logFile == null) {
        final dir = await getApplicationDocumentsDirectory();
        _logFile = File('${dir.path}/app_log.txt');
      }
      final timestamp = DateTime.now().toIso8601String();
      await _logFile?.writeAsString('[$timestamp] $message\n',
          mode: FileMode.append);
    };
  }

  // Proxy all methods
  static void i(String message) => shared.LogUtilsCore.i(message);
  static void e(String message, [dynamic error, StackTrace? stack]) =>
      shared.LogUtilsCore.e(message, error, stack);
  static void d(String message) => shared.LogUtilsCore.d(message);
  static void w(String message) => shared.LogUtilsCore.w(message);
  static void t(String message) => shared.LogUtilsCore.t(message);
  static void logException(dynamic error, StackTrace? stack,
          {String? context}) =>
      shared.LogUtilsCore.logException(error, stack, context: context);
}
