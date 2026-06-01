// web-app/lib/core/utils/features/feature_guard_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'feature_gate_banner.dart'; // Local import for FeatureGateBanner

///
/// FeatureGuardWrapper
///
/// A flexible wrapper that conditionally hides or disables its child based on
/// a platform feature toggle.
///
class FeatureGuardWrapper extends StatelessWidget {
  final String module;
  final String? feature;
  final bool requireEnabled;
  final shared.FeatureFallbackStyle fallbackStyle;
  final String? tooltipMessage;
  final String? lockedMessage;
  final VoidCallback? onTapUpgrade;
  final Widget child;

  const FeatureGuardWrapper({
    super.key,
    required this.module,
    this.feature,
    this.requireEnabled = true,
    this.fallbackStyle = shared.FeatureFallbackStyle.hidden,
    this.tooltipMessage,
    this.lockedMessage,
    this.onTapUpgrade,
    required this.child,
  });

  bool _isPermitted(shared.FranchiseFeatureProvider featureProvider) {
    if (!featureProvider.hasFeature(module)) return false;
    if (!requireEnabled) return true;
    if (feature != null) {
      return featureProvider.isSubfeatureEnabled(module, feature!);
    }
    return featureProvider.isModuleEnabled(module);
  }

  @override
  Widget build(BuildContext context) {
    final featureProvider = context.watch<shared.FranchiseFeatureProvider>();

    if (!featureProvider.isInitialized) {
      return const SizedBox.shrink();
    }

    final isAllowed = _isPermitted(featureProvider);

    if (isAllowed) return child;

    // Feature blocked → determine fallback behavior
    switch (fallbackStyle) {
      case shared.FeatureFallbackStyle.hidden:
        return const SizedBox.shrink();

      case shared.FeatureFallbackStyle.dimmed:
        return Tooltip(
          message:
              tooltipMessage ?? 'This feature is unavailable for your plan.',
          child: IgnorePointer(
            ignoring: true,
            child: Opacity(
              opacity: 0.4,
              child: child,
            ),
          ),
        );

      case shared.FeatureFallbackStyle.lockedBanner:
        return FeatureGateBanner(
          module: module,
          feature: feature,
          lockedMessage: lockedMessage ?? tooltipMessage,
          onTapUpgrade: onTapUpgrade,
          child: child,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
