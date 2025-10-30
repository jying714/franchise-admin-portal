import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_portal/core/providers/franchise_feature_provider.dart';

/// A flexible widget that only shows [child] if the specified feature/module is
/// available in the franchise plan, and optionally also enabled by the franchisee.
///
/// Priority:
/// - If [requireEnabled] == false → show [child] if module exists in plan.
/// - If [requireEnabled] == true:
///   - If [feature] is provided → check subfeature enabled.
///   - Else → check module enabled.
///
/// Use this guard in onboarding flows, developer tools, and screen sections.
///
/// Example:
/// ```dart
/// FeatureGuard(
///   module: 'inventory',
///   feature: 'liveTracking',
///   requireEnabled: true,
///   loading: CircularProgressIndicator(),
///   fallback: Text('Upgrade to unlock inventory tracking'),
///   child: InventoryManager(),
/// )
/// ```
class FeatureGuard extends StatelessWidget {
  /// The top-level module key (e.g., "inventory", "nutrition")
  final String module;

  /// Optional subfeature key within the module (e.g., "liveTracking")
  final String? feature;

  /// Whether the feature must be enabled (e.g., franchise toggle) or just present in the plan
  final bool requireEnabled;

  /// Widget shown while `FranchiseFeatureProvider` is not yet ready
  final Widget? loading;

  /// Widget to show if the feature is not granted/enabled
  final Widget fallback;

  /// Widget to show if the feature is allowed
  final Widget child;

  const FeatureGuard({
    Key? key,
    required this.module,
    this.feature,
    this.requireEnabled = true,
    this.loading,
    required this.fallback,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final featureProvider = context.watch<FranchiseFeatureProvider>();

    if (!featureProvider.isInitialized) {
      return loading ?? const SizedBox.shrink();
    }

    final isGranted = featureProvider.hasFeature(module);

    if (!isGranted) {
      assert(() {
        debugPrint('⚠️ FeatureGuard: Module "$module" not found in plan.');
        return true;
      }());
      return fallback;
    }

    if (!requireEnabled) {
      return child;
    }

    if (feature != null) {
      final isSubfeatureActive =
          featureProvider.isSubfeatureEnabled(module, feature!);
      return isSubfeatureActive ? child : fallback;
    }

    final isModuleActive = featureProvider.isModuleEnabled(module);
    return isModuleActive ? child : fallback;
  }
}
