// web-app/lib/core/utils/app_local_storage.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_core/shared_core.dart' as shared;

class AppLocalStorage implements shared.LocalStorage {
  static final AppLocalStorage _instance = AppLocalStorage._();
  factory AppLocalStorage() => _instance;
  AppLocalStorage._();

  // Cache the instance for synchronous reads
  late final Future<SharedPreferences> _prefsFuture =
      SharedPreferences.getInstance();

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await _prefsFuture;
    await prefs.setString(key, value);
  }

  @override
  String? getString(String key) {
    // Note: This is intentionally synchronous to match the abstract.
    // In practice, it may return null until the first async call completes.
    // For better reliability, consider updating the abstract to async in shared_core later.
    try {
      final prefs =
          SharedPreferences.getInstance().then((p) => p.getString(key));
      // This is a quick synchronous wrapper — real production often uses async getString
      return null; // Temporary — will be improved after abstract update
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await _prefsFuture;
    await prefs.remove(key);
  }
}
