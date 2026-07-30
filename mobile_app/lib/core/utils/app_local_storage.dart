// mobile_app/lib/core/utils/app_local_storage.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_core/shared_core.dart' as shared;

class AppLocalStorage implements shared.LocalStorage {
  static final AppLocalStorage _instance = AppLocalStorage._();
  factory AppLocalStorage() => _instance;
  AppLocalStorage._();

  SharedPreferences? _prefs;

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<void> setString(String key, String value) async {
    await _ensurePrefs();
    await _prefs!.setString(key, value);
  }

  @override
  String? getString(String key) {
    if (_prefs == null) return null;
    return _prefs!.getString(key);
  }

  /// Ensures prefs are loaded (cold start safe). Prefer this for deferred prompts.
  Future<String?> getStringAsync(String key) async {
    await _ensurePrefs();
    return _prefs!.getString(key);
  }

  Future<void> setStringList(String key, List<String> value) async {
    await _ensurePrefs();
    await _prefs!.setStringList(key, value);
  }

  Future<List<String>> getStringListAsync(String key) async {
    await _ensurePrefs();
    return _prefs!.getStringList(key) ?? const <String>[];
  }

  @override
  Future<void> remove(String key) async {
    await _ensurePrefs();
    await _prefs!.remove(key);
  }
}
