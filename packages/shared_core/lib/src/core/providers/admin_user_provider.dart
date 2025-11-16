import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart' as admin_user;
import '../services/firestore_service.dart';
import 'franchise_provider.dart';
import '../models/franchise_info.dart';

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

  void listenToAdminUser(
    FirestoreService firestoreService,
    String? uid,
    FranchiseProvider franchiseProvider,
  ) {
    _sub?.cancel();
    _loading = true;
    _lastError = null;
    notifyListeners();

    if (uid == null) {
      _user = null;
      _loading = false;
      franchiseProvider.clearFranchiseContext(); // Ensure state is reset
      notifyListeners();
      return;
    }

    _sub = firestoreService.userStream(uid).listen(
      (userDoc) async {
        _user = userDoc;

        // ✅ Inject the user into FranchiseProvider so it can compute viewableFranchises
        franchiseProvider.setAdminUser(_user);

        // ✅ Fetch allowed franchises immediately after user loads
        try {
          List<FranchiseInfo> fList;

          if (_user?.isPlatformOwner == true || _user?.isDeveloper == true) {
            fList = await firestoreService.getAllFranchises(); // 🧠 must exist
          } else {
            fList = await firestoreService
                .getFranchisesByIds(_user?.franchiseIds ?? []);
          }

          franchiseProvider.setAllFranchises(fList);
          print(
              '[AdminUserProvider] Loaded ${fList.length} franchises for user.');
        } catch (e, st) {
          print('[AdminUserProvider] Failed to fetch franchise list: $e\n$st');
        }

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
