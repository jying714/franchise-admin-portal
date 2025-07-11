import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;

class FranchiseProvider extends ChangeNotifier {
  String _franchiseId = 'unknown';
  bool _loading = true;
  admin_user.User? _adminUser;

  String get franchiseId => _franchiseId;
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
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('selectedFranchiseId');
    if (id != null) {
      _franchiseId = id;
    }
    _loading = false;
    notifyListeners();
  }

  /// Lock access unless explicitly allowed or user is developer
  Future<void> setFranchiseId(String? id) async {
    final value = id ?? 'unknown';
    if (_franchiseId != value) {
      print('[FranchiseProvider] setFranchiseId: $value');
      _franchiseId = value;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      if (id != null) {
        await prefs.setString('selectedFranchiseId', id);
      } else {
        await prefs.remove('selectedFranchiseId');
      }
      print('[FranchiseProvider] setFranchiseId: saved to prefs');
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
