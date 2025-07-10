import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FranchiseProvider extends ChangeNotifier {
  String _franchiseId = 'unknown';
  bool _loading = true; // <--- add this

  String get franchiseId => _franchiseId;
  bool get isFranchiseSelected =>
      _franchiseId != null && _franchiseId != 'unknown';
  bool get loading => _loading; // <--- and this

  FranchiseProvider() {
    _loadFranchiseId();
  }

  // Load from local storage on startup
  Future<void> _loadFranchiseId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('selectedFranchiseId');
    if (id != null && _franchiseId != id) {
      _franchiseId = id;
    }
    _loading = false; // <--- mark done loading
    notifyListeners();
  }

  Future<void> setFranchiseId(String? id) async {
    final value = id ?? 'unknown';
    if (_franchiseId != value) {
      _franchiseId = value;
      notifyListeners();
      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      if (id != null) {
        await prefs.setString('selectedFranchiseId', id);
      } else {
        await prefs.remove('selectedFranchiseId');
      }
    }
  }

  Future<void> clear() async {
    _franchiseId = 'unknown';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedFranchiseId');
  }
}
