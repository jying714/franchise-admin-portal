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

  FirestoreService? _lastFirestoreService;
  String? _lastUid;

  void listenToUser(FirestoreService firestoreService, String? uid) {
    print('[UserProfileNotifier] listenToUser called for uid=$uid');

    // Always cancel existing subscription if any.
    _sub?.cancel();

    // Robust guard: Only start if uid is valid.
    if (uid == null) {
      print('[UserProfileNotifier] Skipping listen: missing uid.');
      _user = null;
      _loading = false;
      _lastError = null;
      _deferNotifyListeners();
      return;
    }

    _loading = true;
    _lastError = null;
    _deferNotifyListeners();

    _sub = delayedUserStream(firestoreService, uid).listen(
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
        // No franchiseId context; pass empty string or remove as needed.
        await firestoreService.logError(
          '', // No franchise context in franchise-agnostic flow
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

  void reload() {
    if (_lastFirestoreService != null && _lastUid != null) {
      listenToUser(_lastFirestoreService!, _lastUid);
    }
  }

  Object? get error => lastError;
  bool get isLoading => loading;
}
