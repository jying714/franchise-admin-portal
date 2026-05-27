import 'package:flutter/foundation.dart';

/// Minimal but functional AnalyticsService stub.
/// Logs to console in debug; ready to be replaced with FirebaseAnalytics or similar.
class AnalyticsService {
  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      print('[Analytics] Event: $name ${parameters ?? {}}');
    }
    // TODO: Wire to real analytics provider
  }

  void logMenuItemAddedToCart(String itemId, String category, int quantity) {
    logEvent('menu_item_added_to_cart', parameters: {
      'item_id': itemId,
      'category': category,
      'quantity': quantity,
    });
  }

  void setUserProperty(String name, String value) {
    if (kDebugMode) {
      print('[Analytics] User Property: $name = $value');
    }
  }
}
