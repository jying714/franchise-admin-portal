import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class UserProfileNotifier extends ChangeNotifier {
  admin_user.User? _user;
  admin_user.User? get user => _user;

  StreamSubscription? _sub;

  bool _loading = false;
  bool get loading => _loading;

  Object? _lastError;
  Object? get lastError => _lastError;

  void listenToUser(FirestoreService firestoreService, String? uid) {
    _sub?.cancel();
    _loading = true;
    _lastError = null;
    notifyListeners();

    if (uid == null) {
      _user = null;
      _loading = false;
      notifyListeners();
      return;
    }

    _sub = delayedUserStream(firestoreService, uid).listen(
      (u) {
        _user = u;
        _loading = false;
        _lastError = null;
        notifyListeners();
      },
      onError: (err, stack) async {
        _loading = false;
        _lastError = err;
        notifyListeners();

        // --- Firestore error caching ---
        final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
        await firestoreService.logError(
          message: err.toString(),
          source: 'UserProfileNotifier.listenToUser',
          userId: firebaseUser?.uid,
          screen: 'HomeWrapper',
          stackTrace: stack?.toString(),
          errorType: err.runtimeType.toString(),
          severity: 'error',
          contextData: {
            'userProfileLoading': true,
            'uid': uid,
          },
        );
      },
    );
  }

  void clear() {
    _sub?.cancel();
    _user = null;
    _loading = false;
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
