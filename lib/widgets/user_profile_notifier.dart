import 'package:flutter/widgets.dart';
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

    // Always cancel existing subscription if any.
    _sub?.cancel();

    // Robust guard: Only start if both uid and franchiseId are valid.
    if (uid == null || franchiseId == 'unknown') {
      print(
          '[UserProfileNotifier] Skipping listen: missing uid or franchiseId.');
      _user = null;
      _loading = false;
      _lastError = null;
      _deferNotifyListeners();
      return;
    }

    _loading = true;
    _lastError = null;
    _deferNotifyListeners();

    _sub = delayedUserStream(firestoreService, uid, franchiseId).listen(
      (u) {
        print('[UserProfileNotifier] Received user: ${u?.email}');
        _user = u;
        _loading = false;
        _lastError = null;
        _deferNotifyListeners();
      },
      onError: (err, stack) async {
        print('[UserProfileNotifier] ERROR: $err\nStack: $stack');
        _loading = false;
        _lastError = err;
        _deferNotifyListeners();

        final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
        // Only log if franchiseId is valid
        if (franchiseId != 'unknown') {
          await firestoreService.logError(
            franchiseId,
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
              'franchiseId': franchiseId,
            },
          );
        } else {
          print(
              '[UserProfileNotifier] Skipped error logging: franchiseId is unknown');
        }
      },
    );
  }

  void clear() {
    print('[UserProfileNotifier] clear() called');
    _sub?.cancel();
    _user = null;
    _loading = false;
    _lastError = null;
    _deferNotifyListeners();
  }

  @override
  void dispose() {
    print('[UserProfileNotifier] dispose() called');
    _sub?.cancel();
    super.dispose();
  }

  void _deferNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
