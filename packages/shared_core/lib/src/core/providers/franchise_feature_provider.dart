// packages/shared_core/lib/src/core/providers/franchise_feature_provider.dart
// PURE DART INTERFACE ONLY

import '../models/feature_metadata.dart' show FeatureState;
import '../models/feature_module.dart';
import '../models/onboarding_validation_issue.dart';

abstract class FranchiseFeatureProvider {
  String get currentFranchiseId;
  Set<String> get allGrantedFeatures;
  FeatureState get featureMetadata;
  bool get liveSnapshotEnabled;
  bool get isInitialized;

  Future<void> loadLiveSnapshotFlag(String franchiseId);
  void setLiveSnapshotEnabled(bool value);
  Future<void> initialize();
  bool hasFeature(String key);
  bool isModuleEnabled(String moduleKey);
  bool isSubfeatureEnabled(String moduleKey, String featureKey);
  FeatureModule? getModule(String moduleKey);
  bool isModuleLocked(String moduleKey);
  bool isSubfeatureAvailableButDisabled(String moduleKey, String featureKey);
  void setModuleEnabled(String moduleKey, bool enabled);
  void toggleSubfeature(String moduleKey, String featureKey, bool enabled);
  void setFeatureMetadata(FeatureState metadata);
  void clearAll();
  void setFranchiseId(String newId);
  Future<bool> persistToFirestore();
  Map<String, bool> getSubfeatures(String moduleKey);
  List<String> get enabledModuleKeys;
  Future<List<OnboardingValidationIssue>> validate();
}
