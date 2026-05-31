import 'package:flutter/widgets.dart';
import 'dart:async';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class UserProfileNotifier extends ChangeNotifier
    implements shared.UserProfileProvider {
  shared.User? _user;
  @override
  shared.User? get user => _user;

  bool _loading = false;
  @override
  bool get loading => _loading;

  Object? _lastError;
  @override
  Object? get lastError => _lastError;

  shared.FirestoreService? _firestoreService;
  String? _lastUid;
  StreamSubscription? _sub;

  @override
  Future<void> loadUser() async {
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

    _firestoreService ??= shared.FirestoreServiceImpl();

    _sub = _delayedUserStream(_firestoreService!, uid).listen(
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
        shared.ErrorLogger.log(
          message: err.toString(),
          source: 'UserProfileNotifier.listenToUser',
          stack: stack?.toString(),
          severity: 'error',
        );
      },
    );
  }

  Stream<shared.User?> _delayedUserStream(
      shared.FirestoreService firestore, String uid) {
    return firestore.userStream(uid).asyncMap((u) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return u;
    });
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
}
