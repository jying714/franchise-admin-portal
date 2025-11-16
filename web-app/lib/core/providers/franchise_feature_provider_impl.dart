// web_app/lib/core/providers/franchise_feature_provider_impl.dart

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class FranchiseFeatureProviderImpl extends ChangeNotifier
    implements FranchiseFeatureProvider {
  final FranchiseFeatureService _service;
  String _franchiseId;
  @override
  String get currentFranchiseId => _franchiseId;

  final Set<String> _availableFeatures = {};
  FeatureState _featureMetadata =
      FeatureState(modules: {}, liveSnapshotEnabled: false);
  bool _liveSnapshotEnabled = false;
  bool _isInitialized = false;

  FranchiseFeatureProviderImpl({
    required FranchiseFeatureService service,
    required String franchiseId,
  })  : _service = service,
        _franchiseId = franchiseId;

  @override
  Set<String> get allGrantedFeatures => _availableFeatures;

  @override
  FeatureState get featureMetadata => _featureMetadata;

  @override
  bool get liveSnapshotEnabled => _liveSnapshotEnabled;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> loadLiveSnapshotFlag(String franchiseId) async {
    try {
      _liveSnapshotEnabled = await _service.isLiveSnapshotEnabled(franchiseId);
      notifyListeners();
    } catch (e, st) {
      ErrorLogger.log(
        message: 'Failed to load liveSnapshotEnabled flag',
        stack: st.toString(),
        source: 'FranchiseFeatureProviderImpl.loadLiveSnapshotFlag',
        contextData: {'franchiseId': franchiseId},
      );
    }
  }

  @override
  void setLiveSnapshotEnabled(bool value) {
    if (_featureMetadata.liveSnapshotEnabled == value) return;

    _featureMetadata = FeatureState(
      modules: _featureMetadata.modules,
      liveSnapshotEnabled: value,
    );
    _liveSnapshotEnabled = value;
    notifyListeners();

    _service.updateLiveSnapshotFlag(_franchiseId, value).catchError((e, st) {
      ErrorLogger.log(
        message: 'Failed to persist liveSnapshotEnabled change',
        stack: st.toString(),
        source: 'FranchiseFeatureProviderImpl.setLiveSnapshotEnabled',
        contextData: {
          'franchiseId': _franchiseId,
          'attemptedValue': value,
        },
      );
    });
  }

  @override
  Future<void> initialize() async {
    final granted =
        await _service.getGrantedFeaturesFromSubscription(_franchiseId);
    final metadata = await _service.getFeatureMetadata(_franchiseId);

    _availableFeatures
      ..clear()
      ..addAll(granted);

    final updated = <String, FeatureModule>{};
    for (final entry in (metadata?.modules ?? {}).entries) {
      updated[entry.key] = entry.value;
    }

    for (final granted in _availableFeatures) {
      updated.putIfAbsent(
          granted, () => FeatureModule(enabled: false, features: {}));
    }

    _featureMetadata = FeatureState(
      modules: updated,
      liveSnapshotEnabled:
          metadata?.liveSnapshotEnabled ?? _featureMetadata.liveSnapshotEnabled,
    );
    _liveSnapshotEnabled = _featureMetadata.liveSnapshotEnabled;
    _isInitialized = true;
    notifyListeners();
  }

  @override
  bool hasFeature(String key) => _availableFeatures.contains(key);

  @override
  bool isModuleEnabled(String moduleKey) {
    if (!hasFeature(moduleKey)) return false;
    return _featureMetadata.modules[moduleKey]?.enabled ?? false;
  }

  @override
  bool isSubfeatureEnabled(String moduleKey, String featureKey) {
    if (!isModuleEnabled(moduleKey)) return false;
    return _featureMetadata.modules[moduleKey]?.features[featureKey] ?? false;
  }

  @override
  FeatureModule? getModule(String moduleKey) =>
      _featureMetadata.modules[moduleKey];

  @override
  bool isModuleLocked(String moduleKey) => !hasFeature(moduleKey);

  @override
  bool isSubfeatureAvailableButDisabled(String moduleKey, String featureKey) {
    return hasFeature(moduleKey) &&
        (_featureMetadata.modules[moduleKey]?.features[featureKey] == false);
  }

  @override
  void setModuleEnabled(String moduleKey, bool enabled) {
    final existing = _featureMetadata.modules[moduleKey];
    _featureMetadata.modules[moduleKey] =
        (existing ?? FeatureModule(enabled: false, features: {}))
            .copyWith(enabled: enabled);
    notifyListeners();
  }

  @override
  void toggleSubfeature(String moduleKey, String featureKey, bool enabled) {
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

  @override
  void setFeatureMetadata(FeatureState metadata) {
    _featureMetadata = FeatureState(
      modules: metadata.modules,
      liveSnapshotEnabled:
          metadata.liveSnapshotEnabled ?? _featureMetadata.liveSnapshotEnabled,
    );
    _liveSnapshotEnabled = _featureMetadata.liveSnapshotEnabled;
    notifyListeners();
  }

  @override
  void clearAll() {
    _featureMetadata = FeatureState(modules: {}, liveSnapshotEnabled: false);
    _liveSnapshotEnabled = false;
    _availableFeatures.clear();
    _isInitialized = false;
    notifyListeners();
  }

  @override
  void setFranchiseId(String newId) {
    if (newId.isNotEmpty && newId != _franchiseId) {
      _franchiseId = newId;
      _isInitialized = false;
      Future.microtask(() => initialize());
    }
  }

  @override
  Future<bool> persistToFirestore() async {
    return await _service.saveFeatureMetadata(
      franchiseId: _franchiseId,
      metadata: _featureMetadata,
    );
  }

  @override
  Map<String, bool> getSubfeatures(String moduleKey) {
    return _featureMetadata.modules[moduleKey]?.features ?? {};
  }

  @override
  List<String> get enabledModuleKeys => _featureMetadata.modules.entries
      .where((e) => e.value.enabled)
      .map((e) => e.key)
      .toList();

  @override
  Future<List<OnboardingValidationIssue>> validate() async {
    final issues = <OnboardingValidationIssue>[];
    try {
      if (!enabledModuleKeys.contains('menu_management')) {
        issues.add(OnboardingValidationIssue(
          section: 'Features',
          itemId: '',
          itemDisplayName: '',
          severity: OnboardingIssueSeverity.critical,
          code: 'MISSING_MENU_MANAGEMENT_FEATURE',
          message:
              "Menu Management feature must be enabled to continue onboarding.",
          affectedFields: ['menu_management'],
          isBlocking: true,
          fixRoute: '/onboarding/feature_setup',
          resolutionHint: "Enable the Menu Management feature.",
          actionLabel: "Fix Now",
          icon: Icons.build_outlined,
          detectedAt: DateTime.now(),
          contextData: {'enabledFeatures': enabledModuleKeys},
        ));
      }
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'franchise_feature_validate_failed',
        stack: stack.toString(),
        source: 'FranchiseFeatureProviderImpl.validate',
        contextData: {},
      );
    }
    return issues;
  }
}
