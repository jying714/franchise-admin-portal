import 'package:flutter/foundation.dart';

/// A provider to hold and expose the current user's franchiseId
/// This should be set after loading the user profile from Firestore.
class FranchiseProvider extends ChangeNotifier {
  String? _franchiseId;

  /// Returns the currently set franchiseId, or null if not set.
  String? get franchiseId => _franchiseId;

  /// Set the franchiseId and notify listeners if changed.
  void setFranchiseId(String? id) {
    if (_franchiseId != id) {
      _franchiseId = id;
      notifyListeners();
    }
  }

  /// Clear franchiseId (e.g. on sign out)
  void clear() {
    _franchiseId = null;
    notifyListeners();
  }
}
