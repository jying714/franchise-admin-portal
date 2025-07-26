import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/feature_metadata.dart'
    show FeatureState;
import 'package:franchise_admin_portal/core/models/feature_module.dart';
import 'package:franchise_admin_portal/core/services/franchise_feature_service.dart';
import 'package:franchise_admin_portal/core/constants/feature_metadata.dart'
    as config;

class FranchiseFeatureProvider with ChangeNotifier {
  final FranchiseFeatureService _service;
  String _franchiseId;
  String get currentFranchiseId => _franchiseId;

  FranchiseFeatureProvider({
    required FranchiseFeatureService service,
    required String franchiseId,
  })  : _service = service,
        _franchiseId = franchiseId;

  /// ✅ Features granted by the subscription
  final Set<String> _availableFeatures = {};

  /// ✅ Structured metadata (what the user has opted to enable)
  FeatureState _featureMetadata = FeatureState(modules: {});

  /// ⏳ Initialization state
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Set<String> get allGrantedFeatures => _availableFeatures;

  FeatureState get featureMetadata => _featureMetadata;

  /// Loads both subscription and Firestore feature metadata
  Future<void> initialize() async {
    final granted =
        await _service.getGrantedFeaturesFromSubscription(_franchiseId);
    final metadata = await _service.getFeatureMetadata(_franchiseId);
    debugPrint(
        '[FeatureProvider] initialize() called for franchiseId: $_franchiseId');
    debugPrint('[FeatureProvider] granted: $granted');
    debugPrint('[FeatureProvider] metadata keys: ${metadata?.modules.keys}');
    _availableFeatures
      ..clear()
      ..addAll(granted);

    // Inject default disabled modules if missing
    final updated = <String, FeatureModule>{};
    for (final entry in (metadata?.modules ?? {}).entries) {
      updated[entry.key] = entry.value;
    }

    for (final granted in _availableFeatures) {
      updated.putIfAbsent(
        granted,
        () => FeatureModule(enabled: false, features: {}),
      );
    }

    _featureMetadata = FeatureState(modules: updated);

    _isInitialized = true;
    notifyListeners();
  }

  // -------------------------
  // 🔍 Feature Checks
  // -------------------------

  bool hasFeature(String key) => _availableFeatures.contains(key);

  /// True if the module is granted by plan and enabled
  bool isModuleEnabled(String moduleKey) {
    if (!hasFeature(moduleKey)) return false;
    return _featureMetadata.modules[moduleKey]?.enabled ?? false;
  }

  /// True if the subfeature is granted and explicitly enabled
  bool isSubfeatureEnabled(String moduleKey, String featureKey) {
    if (!isModuleEnabled(moduleKey)) return false;
    return _featureMetadata.modules[moduleKey]?.features[featureKey] ?? false;
  }

  /// Exposed safely for UI
  FeatureModule? getModule(String moduleKey) {
    return _featureMetadata.modules[moduleKey];
  }

  /// Indicates if module is unavailable due to plan tier
  bool isModuleLocked(String moduleKey) => !hasFeature(moduleKey);

  /// Indicates if subfeature is plan-granted but not enabled yet
  bool isSubfeatureAvailableButDisabled(String moduleKey, String featureKey) {
    return hasFeature(moduleKey) &&
        (_featureMetadata.modules[moduleKey]?.features[featureKey] == false);
  }

  // -------------------------
  // 🛠️ Runtime Updaters
  // -------------------------

  void setModuleEnabled(String moduleKey, bool enabled) {
    final existing = _featureMetadata.modules[moduleKey];
    _featureMetadata.modules[moduleKey] =
        (existing ?? FeatureModule(enabled: false, features: {}))
            .copyWith(enabled: enabled);
    notifyListeners();
  }

  void toggleSubfeature(String moduleKey, String featureKey, bool enabled) {
    debugPrint('[FeatureProvider] Toggling $moduleKey.$featureKey -> $enabled');

    if (featureKey == 'enabled') {
      setModuleEnabled(moduleKey, enabled);
      return;
    }

    final existing = _featureMetadata.modules[moduleKey];
    if (existing != null) {
      existing.features[featureKey] = enabled;
    } else {
      _featureMetadata.modules[moduleKey] =
          FeatureModule(enabled: true, features: {featureKey: enabled});
    }
    notifyListeners();
  }

  void setFeatureMetadata(FeatureState metadata) {
    _featureMetadata = metadata;
    notifyListeners();
  }

  void clearAll() {
    _featureMetadata = FeatureState(modules: {});
    _availableFeatures.clear();
    _isInitialized = false;
    notifyListeners();
  }

  void setFranchiseId(String newId) {
    if (newId.isNotEmpty && newId != _franchiseId) {
      debugPrint('[FeatureProvider] setFranchiseId: $newId');
      _franchiseId = newId;
      _isInitialized = false;

      Future.microtask(
          () => initialize()); // ✅ Now re-fetches with correct franchiseId
    }
  }

  /// Optional: persist to Firestore
  /// Attempts to save the feature metadata to Firestore.
  /// Returns true if the save succeeded (i.e., validated and persisted).
  Future<bool> persistToFirestore() async {
    return await _service.saveFeatureMetadata(
      franchiseId: _franchiseId,
      metadata: _featureMetadata,
    );
  }
}
