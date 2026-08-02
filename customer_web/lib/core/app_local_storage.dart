// customer_web/lib/core/app_local_storage.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_core/shared_core.dart' as shared;

class AppLocalStorage implements shared.LocalStorage {
  static final AppLocalStorage _instance = AppLocalStorage._();
  factory AppLocalStorage() => _instance;
  AppLocalStorage._();

  late final Future<SharedPreferences> _prefsFuture =
      SharedPreferences.getInstance();

  SharedPreferences? _cached;

  Future<SharedPreferences> _prefs() async {
    _cached ??= await _prefsFuture;
    return _cached!;
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await _prefs();
    await prefs.setString(key, value);
  }

  @override
  String? getString(String key) {
    // Abstract is sync; return from cache if available, else null
    // (first read after setString will hit cache after await completes).
    return _cached?.getString(key);
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await _prefs();
    await prefs.remove(key);
  }
}
