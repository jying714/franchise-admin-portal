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

  void listenToUser(
      FirestoreService firestoreService, String? uid, String franchiseId) {
    print(
        '[UserProfileNotifier] listenToUser called for uid=$uid, franchiseId=$franchiseId');
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

    _sub = delayedUserStream(firestoreService, uid, franchiseId).listen(
      (u) {
        print('[UserProfileNotifier] Received user: ${u?.email}');
        _user = u;
        _loading = false;
        _lastError = null;
        notifyListeners();
      },
      onError: (err, stack) async {
        print('[UserProfileNotifier] ERROR: $err\nStack: $stack');
        _loading = false;
        _lastError = err;
        notifyListeners();

        final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
        await firestoreService.logError(
          franchiseId, // <-- provide actual franchise ID here
          message: err.toString(), // Pass message as positional argument
          source: 'UserProfileNotifier.listenToUser',
          userId: firebaseUser?.uid,
          screen: 'HomeWrapper',
          stackTrace: stack?.toString(),
          errorType: err.runtimeType.toString(),
          severity: 'error',
          contextData: {
            'userProfileLoading': true,
            'uid': uid,
            'franchiseId': franchiseId,
          },
        );
      },
    );
  }

  void clear() {
    print('[UserProfileNotifier] clear() called');
    _sub?.cancel();
    _user = null;
    _loading = false;
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    print('[UserProfileNotifier] dispose() called');
    _sub?.cancel();
    super.dispose();
  }
}
