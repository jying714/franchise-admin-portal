import 'package:shared_preferences/shared_preferences.dart';

/// Station-local printer host. Prefs win; dart-define is fallback.
class PosPrinterConfig {
  static const _prefsKey = 'pos_printer_host';
  static const _nameKey = 'pos_ticket_store_name';

  static String? _cached;
  static String? _cachedName;

  static String get compileTimeHost =>
      const String.fromEnvironment('POS_PRINTER_HOST', defaultValue: '').trim();

  static String get host {
    final saved = _cached?.trim() ?? '';
    if (saved.isNotEmpty) return saved;
    return compileTimeHost;
  }

  static String get storeName => _cachedName?.trim() ?? '';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getString(_prefsKey);
    _cachedName = prefs.getString(_nameKey);
  }

  static Future<void> saveName(String value) async {
    _cachedName = value.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_cachedName == null || _cachedName!.isEmpty) {
      await prefs.remove(_nameKey);
    } else {
      await prefs.setString(_nameKey, _cachedName!);
    }
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
