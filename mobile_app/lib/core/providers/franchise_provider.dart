import 'package:flutter/material.dart';
import 'package:franchise_mobile_app/core/utils/app_local_storage.dart';
import 'package:shared_core/src/core/models/franchise_info.dart';
import 'package:shared_core/src/core/services/firestore_service.dart';

/// Simple ChangeNotifier for managing the current franchise context in the mobile customer app.
/// Persists the selection using local storage.
/// 
/// Usage:
/// - Provide at root in main.dart
/// - Consume with Provider.of<FranchiseProvider>(context) or Consumer
class FranchiseProvider extends ChangeNotifier {
  static const String _storageKey = 'selectedFranchiseId';

  String _currentFranchiseId = 'unknown';
  bool _isLoading = true;

  final AppLocalStorage _storage = AppLocalStorage();

  String get currentFranchiseId => _currentFranchiseId;
  bool get isLoading => _isLoading;
  bool get hasValidFranchise => _currentFranchiseId != 'unknown' && _currentFranchiseId.isNotEmpty;

  FranchiseProvider() {
    _loadFranchiseId();
  }

  Future<void> _loadFranchiseId() async {
    _isLoading = true;
    notifyListeners();

    try {
      final storedId = await _storage.getString(_storageKey);
      _currentFranchiseId = (storedId != null && storedId.isNotEmpty) ? storedId : 'unknown';
    } catch (e) {
      _currentFranchiseId = 'unknown';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Set the current franchise. Persists to storage and notifies listeners.
  Future<void> setCurrentFranchiseId(String franchiseId) async {
    if (franchiseId.isEmpty || franchiseId == _currentFranchiseId) return;

    _currentFranchiseId = franchiseId;
    await _storage.setString(_storageKey, franchiseId);
    notifyListeners();
  }

  Future<void> clearFranchise() async {
    _currentFranchiseId = 'unknown';
    await _storage.remove(_storageKey);
    notifyListeners();
  }

  /// Initialize from user profile (e.g. after login). Falls back to stored or 'unknown'.
  Future<void> initializeFromUser({String? defaultFranchiseId}) async {
    if (_currentFranchiseId != 'unknown' && _currentFranchiseId.isNotEmpty) {
      return;
    }

    if (defaultFranchiseId != null && defaultFranchiseId.isNotEmpty) {
      await setCurrentFranchiseId(defaultFranchiseId);
      return;
    }

    // Reload from storage
    await _loadFranchiseId();
  }

  FranchiseInfo? _currentFranchiseDetails;

  FranchiseInfo? get currentFranchiseDetails => _currentFranchiseDetails;

  /// Basic dynamic branding getters (MVP)
  String get restaurantName => _currentFranchiseDetails?.name ?? 'Doughboys Pizzeria';
  String? get logoUrl => _currentFranchiseDetails?.logoUrl;
  Color get primaryColor {
    // For MVP, return a default or parse if you add 'primaryColor' hex to FranchiseInfo later
    return Colors.deepOrange; // fallback brand color
  }

  /// Load full FranchiseInfo for branding + display in selector.
  /// Call after setting franchiseId (e.g. after login or switch).
  Future<void> loadCurrentFranchiseDetails(FirestoreService firestore) async {
    if (_currentFranchiseId == 'unknown' || _currentFranchiseId.isEmpty) {
      _currentFranchiseDetails = null;
      notifyListeners();
      return;
    }

    try {
      final list = await firestore.getFranchisesByIds([_currentFranchiseId]);
      if (list.isNotEmpty) {
        _currentFranchiseDetails = list.first;
      } else {
        _currentFranchiseDetails = FranchiseInfo(id: _currentFranchiseId, name: 'Unknown Restaurant');
      }
    } catch (_) {
      _currentFranchiseDetails = FranchiseInfo(id: _currentFranchiseId, name: 'Unknown Restaurant');
    }
    notifyListeners();
  }

}
