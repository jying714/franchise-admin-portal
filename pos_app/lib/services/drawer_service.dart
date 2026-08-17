import 'package:flutter/foundation.dart';

/// Mock cash drawer for pilot.
/// Real kick (ESC/POS drawer pin / vendor SDK) when hardware arrives.
class DrawerService {
  const DrawerService();

  /// Open drawer. Never throws into payment / refund paths.
  Future<bool> openDrawer({String? reason}) async {
    try {
      final label = reason == null || reason.isEmpty ? 'kick' : reason;
      // ignore: avoid_print
      print('[POS] cash drawer (mock) — $label');
      debugPrint('[POS] cash drawer (mock) — $label');
      return true;
    } catch (e, st) {
      debugPrint('[POS] cash drawer mock failed: $e\n$st');
      return false;
    }
  }
}
