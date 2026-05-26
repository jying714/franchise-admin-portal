import 'package:flutter/foundation.dart';

/// Minimal stub AnalyticsService for menu flow after migration.
/// In production, wire to Firebase Analytics or similar.
class AnalyticsService {
  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      print('[Analytics] $name ${parameters ?? ''}');
    }
  }

  void setUserProperty(String name, String value) {
    if (kDebugMode) {
      print('[Analytics] UserProperty $name = $value');
    }
  }
}