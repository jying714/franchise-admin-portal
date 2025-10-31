import 'package:flutter/widgets.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart' as admin_user;
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'franchise_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

class UserProfileNotifier extends ChangeNotifier {
  admin_user.User? _user;
  admin_user.User? get user => _user;
  FranchiseProvider? _lastFranchiseProvider;
  StreamSubscription? _sub;

  bool _loading = false;
  bool get loading => _loading;

  Object? _lastError;
  Object? get lastError => _lastError;

  FirestoreService? _lastFirestoreService;
  String? _lastUid;

  Future<void> loadUser() async {
    if (Firebase.apps.isEmpty) {
      final msg = '[UserProfileNotifier] loadUser: Firebase not initialized!';
      debugPrint(msg);
      await ErrorLogger.log(
        message:
            'UserProfileNotifier.loadUser called before Firebase initialized',
        source: 'UserProfileNotifier',
        severity: 'fatal',
        screen: 'UserProfileNotifier',
        contextData: {
          'phase': 'loadUser',
          'hint': 'Firebase.apps.isEmpty',
          'widget': runtimeType.toString(),
        },
      );
      return;
    }
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      listenToUser(
        FirestoreService(),
        firebaseUser.uid,
      );
    } else {
      debugPrint('[UserProfileNotifier] loadUser: firebaseUser is null');
      // You may want to log this as a warning as well if it's unexpected:
      await ErrorLogger.log(
        message: 'loadUser called but firebaseUser is null',
        source: 'UserProfileNotifier',
        severity: 'warning',
        screen: 'UserProfileNotifier',
      );
    }
  }

  void listenToUser(FirestoreService firestoreService, String? uid,
      [FranchiseProvider? franchiseProvider]) {
    print('[UserProfileNotifier] listenToUser called for uid=$uid');
    _lastFirestoreService = firestoreService;
    _lastUid = uid;
    _lastFranchiseProvider = franchiseProvider;

    // Cancel existing subscription if any.
    _sub?.cancel();

    if (uid == null) {
      print('[UserProfileNotifier] Skipping listen: missing uid.');
      _user = null;
      _loading = false;
      _lastError = null;

      if (franchiseProvider != null) {
        franchiseProvider.clearFranchiseContext(); // ✅ Clear franchise state
      }

      _lastFranchiseProvider = null; // ✅ Only clear when uid is null
      _deferNotifyListeners();
      return;
    }
    print(
        '[UserProfileNotifier] Attempting to subscribe: uid=$uid, firestoreService=$firestoreService');
    _loading = true;
    _lastError = null;
    _deferNotifyListeners();

    print(
        '[UserProfileNotifier] Subscribing to delayedUserStream for uid=$uid');

    _sub = delayedUserStream(firestoreService, uid).listen(
      (u) {
        _user = u;
        _loading = false;
        _lastError = null;
        _deferNotifyListeners();

        if (u != null && franchiseProvider != null) {
          franchiseProvider.initializeWithUser(u);
        }
      },
      onError: (err, stack) async {
        print('[UserProfileNotifier] ERROR: $err\nStack: $stack');
        _loading = false;
        _lastError = err;
        _deferNotifyListeners();

        final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
        ErrorLogger.log(
          message: err.toString(),
          source: 'UserProfileNotifier.listenToUser',
          screen: 'HomeWrapper',
          stack: stack?.toString(),
          severity: 'error',
          contextData: {
            'userProfileLoading': true,
            'uid': uid,
            'userId': firebaseUser?.uid,
            'errorType': err.runtimeType.toString(),
          },
        );
        _lastFirestoreService = firestoreService;
        _lastUid = uid;
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
    if (_lastFirestoreService != null &&
        _lastUid != null &&
        _lastFranchiseProvider != null) {
      listenToUser(_lastFirestoreService!, _lastUid, _lastFranchiseProvider!);
    }
  }

  Object? get error => lastError;
  bool get isLoading => loading;
}
