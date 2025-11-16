// web_app/lib/core/utils/log_utils.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_core/src/core/utils/log_utils_core.dart';

class LogUtils {
  static File? _logFile;

  static Future<void> init() async {
    if (kIsWeb) return;

    LogUtilsCore.logHandler = (message) async {
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
  static void i(String message) => LogUtilsCore.i(message);
  static void e(String message, [dynamic error, StackTrace? stack]) =>
      LogUtilsCore.e(message, error, stack);
  static void d(String message) => LogUtilsCore.d(message);
  static void w(String message) => LogUtilsCore.w(message);
  static void t(String message) => LogUtilsCore.t(message);
  static void logException(dynamic error, StackTrace? stack,
          {String? context}) =>
      LogUtilsCore.logException(error, stack, context: context);
}
