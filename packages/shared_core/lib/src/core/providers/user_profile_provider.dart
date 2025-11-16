// packages/shared_core/lib/src/core/providers/user_profile_provider.dart
// PURE DART INTERFACE ONLY

import '../models/user.dart' as admin_user;

abstract class UserProfileProvider {
  admin_user.User? get user;
  bool get loading;
  Object? get lastError;

  Future<void> loadUser();
  void listenToUser(String? uid);
  void clear();
  void reload();
  void dispose();
}
