import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FranchiseProvider extends ChangeNotifier {
  String? _franchiseId;

  String? get franchiseId => _franchiseId;

  FranchiseProvider() {
    _loadFranchiseId();
  }

  // Load from local storage on startup
  Future<void> _loadFranchiseId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('selectedFranchiseId');
    if (id != null && _franchiseId != id) {
      _franchiseId = id;
      notifyListeners();
    }
  }

  void setFranchiseId(String? id) async {
    if (_franchiseId != id) {
      _franchiseId = id;
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

  void clear() async {
    _franchiseId = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedFranchiseId');
  }
}
