// web_app/lib/core/providers/user_profile_notifier_impl.dart

import 'package:flutter/widgets.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

class UserProfileNotifier extends ChangeNotifier
    implements UserProfileProvider {
  admin_user.User? _user;
  @override
  admin_user.User? get user => _user;

  bool _loading = false;
  @override
  bool get loading => _loading;

  Object? _lastError;
  @override
  Object? get lastError => _lastError;

  FirestoreService? _firestoreService;
  String? _lastUid;
  StreamSubscription? _sub;

  @override
  Future<void> loadUser() async {
    if (Firebase.apps.isEmpty) {
      debugPrint('[UserProfileNotifier] Firebase not initialized');
      return;
    }

    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      listenToUser(firebaseUser.uid);
    }
  }

  @override
  void listenToUser(String? uid) {
    _sub?.cancel();
    _lastUid = uid;

    if (uid == null) {
      _user = null;
      _loading = false;
      _lastError = null;
      _deferNotify();
      return;
    }

    _loading = true;
    _lastError = null;
    _deferNotify();

    _firestoreService ??= FirestoreServiceImpl(); // ← Use impl

    _sub = delayedUserStream(_firestoreService!, uid).listen(
      (u) {
        _user = u;
        _loading = false;
        _lastError = null;
        _deferNotify();
      },
      onError: (err, stack) {
        _loading = false;
        _lastError = err;
        _deferNotify();
        ErrorLogger.log(
          message: err.toString(),
          source: 'UserProfileNotifier.listenToUser',
          stack: stack?.toString(),
          severity: 'error',
        );
      },
    );
  }

  @override
  void clear() {
    _sub?.cancel();
    _user = null;
    _loading = false;
    _lastError = null;
    _deferNotify();
  }

  @override
  void reload() {
    if (_firestoreService != null && _lastUid != null) {
      listenToUser(_lastUid);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _deferNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  // === HELPER: delayedUserStream ===
  Stream<admin_user.User?> delayedUserStream(
      FirestoreService firestore, String uid) {
    return firestore.userStream(uid).asyncMap((u) async {
      await Future.delayed(const Duration(milliseconds: 100)); // debounce
      return u;
    });
  }
}
