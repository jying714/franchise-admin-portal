// mobile_app/lib/core/utils/app_local_storage.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_core/src/core/utils/local_storage.dart';

class AppLocalStorage implements LocalStorage {
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

  @override
  Future<void> remove(String key) async {
    await _ensurePrefs();
    await _prefs!.remove(key);
  }
}
