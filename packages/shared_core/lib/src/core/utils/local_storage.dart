// shared_core/lib/src/core/utils/local_storage.dart
abstract class LocalStorage {
  Future<void> setString(String key, String value);
  String? getString(String key);
  Future<void> remove(String key);
}
