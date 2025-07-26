import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_feature_provider.dart';

/// A flexible widget that only shows [child] if the feature is available
/// and optionally enabled (usage opt-in).
///
/// Use for gating sections, screens, or UI elements like buttons.
///
/// Example:
/// ```dart
/// FeatureGuard(
///   module: 'inventory',
///   requireEnabled: true,
///   fallback: Text('Upgrade to unlock inventory'),
///   child: InventoryDashboard(),
/// )
/// ```
class FeatureGuard extends StatelessWidget {
  /// The top-level module key (required)
  final String module;

  /// Optional subfeature key within the module
  final String? feature;

  /// Whether the feature must also be **enabled** by the franchisee (not just in plan)
  final bool requireEnabled;

  /// Widget to render if feature is not available/enabled
  final Widget fallback;

  /// Widget to render if the feature is permitted
  final Widget child;

  const FeatureGuard({
    Key? key,
    required this.module,
    this.feature,
    this.requireEnabled = true,
    required this.fallback,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final featureProvider = context.watch<FranchiseFeatureProvider>();

    if (!featureProvider.isInitialized) {
      return const SizedBox.shrink(); // or CircularProgressIndicator()
    }

    final isGranted = featureProvider.hasFeature(module);

    if (!isGranted) return fallback;

    if (!requireEnabled) return child;

    if (feature != null) {
      final isSubfeatureActive =
          featureProvider.isSubfeatureEnabled(module, feature!);
      return isSubfeatureActive ? child : fallback;
    }

    final isModuleActive = featureProvider.isModuleEnabled(module);
    return isModuleActive ? child : fallback;
  }
}
