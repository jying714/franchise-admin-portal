// mobile_app/lib/core/utils/app_local_storage.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_core/src/core/utils/local_storage.dart';

class AppLocalStorage implements LocalStorage {
  static final AppLocalStorage _instance = AppLocalStorage._();
  factory AppLocalStorage() => _instance;
  AppLocalStorage._();

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
