import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import 'package:franchise_admin_portal/core/models/franchise_info.dart';

class FranchiseProvider extends ChangeNotifier {
  VoidCallback? onFranchiseChanged;
  String _franchiseId = 'unknown';
  bool _loading = true;
  admin_user.User? _adminUser;

  String get franchiseId {
    print('[FranchiseProvider] franchiseId getter: $_franchiseId');
    return _franchiseId.isEmpty ? 'unknown' : _franchiseId;
  }

  bool get loading => _loading;
  bool get isFranchiseSelected =>
      _franchiseId != 'unknown' && _franchiseId.isNotEmpty;
  admin_user.User? get adminUser => _adminUser;
  bool get isDeveloper => _adminUser?.isDeveloper ?? false;

  bool get hasValidFranchise =>
      _franchiseId.isNotEmpty && _franchiseId != 'unknown';

  FranchiseProvider() {
    _loadFranchiseId();
  }

  /// Set the logged-in admin user context
  void setAdminUser(admin_user.User? user) {
    _adminUser = user;
    notifyListeners();
  }

  /// Load franchiseId from local storage (used at boot or cold start)
  Future<void> _loadFranchiseId() async {
    _loading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('selectedFranchiseId');
    if (id != null && id.isNotEmpty) {
      _franchiseId = id;
    } else {
      _franchiseId = 'unknown';
    }
    _loading = false;
    notifyListeners();
  }

  /// Lock access unless explicitly allowed or user is developer
  Future<void> setFranchiseId(String id) async {
    print(
        '[FranchiseProvider] setFranchiseId called: new id="$id" (was "$_franchiseId")');
    if (id.isEmpty) return;
    if (_franchiseId != id) {
      _franchiseId = id;
      notifyListeners();
      if (onFranchiseChanged != null) onFranchiseChanged!();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedFranchiseId', id);
    }
  }

  /// Use this at login to override franchiseId based on defaultFranchise
  Future<void> setInitialFranchiseId(String id) async {
    print('[FranchiseProvider] setInitialFranchiseId called: id="$id"');

    if (_franchiseId == id) {
      print(
          '[FranchiseProvider] setInitialFranchiseId: No change (already "$id"), skipping update.');
      return;
    }

    _franchiseId = id;

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('selectedFranchiseId');

    if (existing != id) {
      await prefs.setString('selectedFranchiseId', id);
      print(
          '[FranchiseProvider] setInitialFranchiseId: Saved to SharedPreferences: "$id"');
    } else {
      print(
          '[FranchiseProvider] setInitialFranchiseId: Already persisted, skipping write.');
    }

    notifyListeners();
    print(
        '[FranchiseProvider] setInitialFranchiseId: Notified listeners. Current franchiseId="$id"');
  }

  Future<void> clear() async {
    print(
        '[FranchiseProvider] clear() called: franchiseId and adminUser set to null/unknown');

    _franchiseId = 'unknown';
    _adminUser = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedFranchiseId');
  }

  List<FranchiseInfo> _allFranchises = [];

  // Public getter for the franchise picker
  List<FranchiseInfo> get allFranchises => List.unmodifiable(_allFranchises);

  // Optionally, expose a way to set them (you might fetch from Firestore/API)
  void setAllFranchises(List<FranchiseInfo> franchises) {
    _allFranchises = franchises;
    notifyListeners();
  }

  Future<void> initializeWithUser(admin_user.User user) async {
    _adminUser = user;
    final prefs = await SharedPreferences.getInstance();

    // ✅ If _franchiseId already initialized, don't override
    if (_franchiseId != null &&
        _franchiseId != 'unknown' &&
        _franchiseId!.isNotEmpty) {
      print(
          '[FranchiseProvider] initializeWithUser: Skipped — already set to $_franchiseId');
      _loading = false;
      notifyListeners();
      return;
    }

    final storedId = prefs.getString('selectedFranchiseId');
    if (storedId != null && storedId.isNotEmpty) {
      _franchiseId = storedId;
      print(
          '[FranchiseProvider] initializeWithUser: Loaded from SharedPreferences: $_franchiseId');
    } else if (user.defaultFranchise != null &&
        user.defaultFranchise!.isNotEmpty) {
      _franchiseId = user.defaultFranchise!;
      await prefs.setString('selectedFranchiseId', _franchiseId);
      print(
          '[FranchiseProvider] initializeWithUser: Set from user.defaultFranchise: $_franchiseId');
    } else {
      _franchiseId = 'unknown';
      print(
          '[FranchiseProvider] initializeWithUser: No valid source, defaulting to "unknown"');
    }

    _loading = false;
    notifyListeners();

    print(
        '[FranchiseProvider] Initialized franchiseId=$_franchiseId for user=${user.email}');
    print(
        '[FranchiseProvider] Final state: franchiseId=$_franchiseId, user roles=${user.roles}');
  }

  /// Filtered viewable franchises based on current user access
  List<FranchiseInfo> get viewableFranchises {
    if (_adminUser == null) return [];

    // Platform Owner and Developer can see all
    if (_adminUser!.isPlatformOwner || _adminUser!.isDeveloper) {
      return _allFranchises;
    }

    // Everyone else is filtered to their allowed franchise IDs
    final allowedIds = _adminUser!.franchiseIds;
    return _allFranchises.where((f) => allowedIds.contains(f.id)).toList();
  }

  void clearFranchiseContext() {
    _franchiseId = '';
    _allFranchises = [];
    _adminUser = null;
    notifyListeners();
  }
}
