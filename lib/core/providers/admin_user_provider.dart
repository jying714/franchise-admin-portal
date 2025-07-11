import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import 'package:franchise_admin_portal/core/services/firestore_service.dart';

class AdminUserProvider extends ChangeNotifier {
  admin_user.User? _user;
  admin_user.User? get user => _user;

  set user(admin_user.User? value) {
    _user = value;
    notifyListeners();
  }

  bool get isHqOwner => user?.isHqOwner == true;
  bool get isHqManager => user?.isHqManager == true;
  bool get isOwner => user?.isOwner == true;
  bool get isManager => user?.isManager == true;
  bool get isAdmin => user?.isAdmin == true;
  bool get isStaff => user?.isStaff == true;
  bool get isCustomer => user?.isCustomer == true;
  bool get isDeveloper => user?.isDeveloper == true;

  bool get isHqUser => isHqOwner || isHqManager;
  bool get isFranchiseUser => isOwner || isManager;

  StreamSubscription? _sub;
  bool _loading = false;
  bool get loading => _loading;

  Object? _lastError;
  Object? get lastError => _lastError;

  void listenToAdminUser(FirestoreService firestoreService, String? uid) {
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

    _sub = firestoreService.adminUserStream(uid).listen(
      (userDoc) {
        _user = userDoc;
        _loading = false;
        notifyListeners();
      },
      onError: (error) {
        _lastError = error;
        _loading = false;
        notifyListeners();
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
