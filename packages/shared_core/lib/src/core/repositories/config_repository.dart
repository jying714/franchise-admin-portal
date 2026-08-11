// packages/shared_core/lib/src/core/repositories/config_repository.dart
//
// Bounded-context repository for franchise/global config surfaces.
// Authority: docs/slices/bounded-context-repos-v1.md (Phase A2)
// Does not replace FirestoreService; call sites migrate gradually.
// Zero behavior change: signatures mirror existing FirestoreService methods.

import '../models/franchise_info.dart'; // adjust path if FranchiseInfo lives elsewhere

abstract class ConfigRepository {
  // --- Feature toggles (A2.1) ---
  Future<Map<String, dynamic>> getGlobalFeatureToggles();

  Future<Map<String, dynamic>> getFranchiseFeatureToggles(String franchiseId);

  Future<void> setFranchiseFeatureToggles(
      String franchiseId, Map<String, dynamic> toggles);

  Stream<Map<String, dynamic>> streamFranchiseFeatureToggles(
      String franchiseId);

  Future<void> updateFeatureToggle(
      String franchiseId, String key, dynamic value);

  // --- Franchise doc config (A2.2) ---
  Future<FranchiseInfo?> getFranchiseInfo(String franchiseId);

  Future<void> saveFranchiseBusinessHours({
    required String franchiseId,
    required List<Map<String, dynamic>> hours,
  });

  Future<List<Map<String, dynamic>>> getFranchiseBusinessHours(
      String franchiseId);
}
