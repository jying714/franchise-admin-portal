// packages/shared_core/lib/src/core/services/franchise_feature_service.dart

import '../models/feature_metadata.dart' show FeatureState;

abstract class FranchiseFeatureService {
  /// Get the list of all features granted by the current active subscription plan
  Future<List<String>> getGrantedFeaturesFromSubscription(String franchiseId);

  /// Load the feature metadata config for onboarding/use
  Future<FeatureState?> getFeatureMetadata(String franchiseId);

  /// Save the feature metadata (if valid)
  Future<bool> saveFeatureMetadata({
    required String franchiseId,
    required FeatureState metadata,
  });

  /// Save a single module toggle
  Future<void> updateModuleEnabled(
      String franchiseId, String moduleKey, bool enabled);

  /// Save toggles inside a module
  Future<void> updateModuleFeatures(
      String franchiseId, String moduleKey, Map<String, bool> updates);

  /// Remove a full module (e.g., inventory)
  Future<void> removeModule(String franchiseId, String moduleKey);

  /// Remove one subfeature from module
  Future<void> removeFeature(
      String franchiseId, String moduleKey, String featureKey);

  /// Legacy flat flags (optional legacy devtool support)
  Future<Map<String, bool>> getFlatFeatureFlags(String franchiseId);

  Future<void> saveFlatFeatureFlags(
      String franchiseId, Map<String, bool> flags);

  /// Schema validator for metadata enforcement
  List<String> validateFeatureMetadata({
    required List<String> grantedFeatures,
    required FeatureState metadata,
  });

  Future<bool> isLiveSnapshotEnabled(String franchiseId);

  /// Toggle the liveSnapshotEnabled flag in Firestore
  Future<void> updateLiveSnapshotFlag(String franchiseId, bool enabled);
}
