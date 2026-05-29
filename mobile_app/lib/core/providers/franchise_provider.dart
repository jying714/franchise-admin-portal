import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/core/utils/app_local_storage.dart';

class FranchiseProvider extends ChangeNotifier {
  static const String _storageKey = 'selectedFranchiseId';

  String _currentFranchiseId = '';
  bool _isLoading = true;
  String? _error;

  final AppLocalStorage _storage = AppLocalStorage();
  shared.FranchiseInfo? _currentFranchiseDetails;

  String get currentFranchiseId => _currentFranchiseId;
  bool get isLoading => _isLoading;
  bool get hasValidFranchise => _currentFranchiseId.isNotEmpty;
  String? get error => _error;

  shared.FranchiseInfo? get currentFranchiseDetails => _currentFranchiseDetails;

  String get restaurantName =>
      _currentFranchiseDetails?.name ?? 'Doughboys Pizzeria';

  FranchiseProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    final storedId = await _storage.getString(_storageKey);
    if (storedId != null && storedId.isNotEmpty) {
      _currentFranchiseId = storedId;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> initializeFromUser(shared.User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final defaultId = user.defaultFranchise ??
          (user.franchiseIds.isNotEmpty ? user.franchiseIds.first : null);

      if (defaultId != null && defaultId.isNotEmpty) {
        await setCurrentFranchiseId(defaultId);
      }
    } catch (e) {
      _error = 'Failed to initialize franchise';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCurrentFranchiseId(String franchiseId) async {
    if (franchiseId.isEmpty || franchiseId == _currentFranchiseId) return;

    _currentFranchiseId = franchiseId;
    await _storage.setString(_storageKey, franchiseId);
    _error = null;
    notifyListeners();
  }

  void clearFranchise() {
    _currentFranchiseId = '';
    _storage.remove(_storageKey);
    _currentFranchiseDetails = null;
    notifyListeners();
  }
}
