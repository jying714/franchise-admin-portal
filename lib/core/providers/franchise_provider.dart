import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;

class FranchiseProvider extends ChangeNotifier {
  VoidCallback? onFranchiseChanged;
  String _franchiseId = 'unknown';
  bool _loading = true;
  admin_user.User? _adminUser;

  String get franchiseId => _franchiseId.isEmpty ? 'unknown' : _franchiseId;
  bool get loading => _loading;
  bool get isFranchiseSelected => _franchiseId != 'unknown';
  admin_user.User? get adminUser => _adminUser;
  bool get isDeveloper => _adminUser?.isDeveloper ?? false;

  FranchiseProvider() {
    _loadFranchiseId();
  }

  /// Set the logged-in admin user context
  void setAdminUser(admin_user.User user) {
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
    _franchiseId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFranchiseId', id);
    notifyListeners();
  }

  Future<void> clear() async {
    _franchiseId = 'unknown';
    _adminUser = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedFranchiseId');
  }
}
