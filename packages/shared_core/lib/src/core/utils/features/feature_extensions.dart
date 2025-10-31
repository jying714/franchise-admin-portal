import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/franchise_feature_provider.dart';

extension FeatureContextExtension on BuildContext {
  /// Shorthand for checking top-level feature availability
  bool hasFeature(String module) {
    final provider = read<FranchiseFeatureProvider>();
    return provider.hasFeature(module);
  }

  /// Shorthand for checking if a feature is fully enabled
  bool isFeatureEnabled(String module) {
    final provider = read<FranchiseFeatureProvider>();
    return provider.isModuleEnabled(module);
  }

  /// Shorthand for checking if a subfeature is enabled
  bool isSubFeatureEnabled(String module, String feature) {
    final provider = read<FranchiseFeatureProvider>();
    return provider.isSubfeatureEnabled(module, feature);
  }

  /// Return a readable instance without triggering rebuilds
  T read<T>() => Provider.of<T>(this, listen: false);
}
