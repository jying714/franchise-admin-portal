import 'package:shared_preferences/shared_preferences.dart';

/// Station-local printer host. Prefs win; dart-define is fallback.
class PosPrinterConfig {
  static const _prefsKey = 'pos_printer_host';

  static String? _cached;

  static String get compileTimeHost =>
      const String.fromEnvironment('POS_PRINTER_HOST', defaultValue: '').trim();

  static String get host {
    final saved = _cached?.trim() ?? '';
    if (saved.isNotEmpty) return saved;
    return compileTimeHost;
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getString(_prefsKey);
  }

  static Future<void> save(String value) async {
    _cached = value.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_cached == null || _cached!.isEmpty) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, _cached!);
    }
  }
}
