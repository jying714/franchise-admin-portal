import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_portal/core/providers/franchise_feature_provider.dart';

/// Defines how `FeatureGuardWrapper` handles feature-gated content.
enum FeatureFallbackStyle {
  /// Completely removes the widget from the tree (same as FeatureGuard).
  hidden,

  /// Displays the widget with reduced opacity and disables interaction.
  /// Useful for education or upsell nudging.
  dimmed,
}

///
/// 🧱 FeatureGuardWrapper
///
/// A flexible wrapper that conditionally hides or disables its child based on
/// a platform feature toggle (and optionally a nested subfeature).
///
/// Use this when:
/// - ✅ You want to **educate** the user about a locked feature.
/// - ✅ You want to **upsell** with a disabled UI (dimmed).
/// - ✅ You want to gracefully **gate** non-critical widgets.
///
/// Avoid this when:
/// - ❌ The gated content would break layout or flow when visible but disabled.
/// - ❌ You want to fully eliminate logic branches (use FeatureGuard instead).
///
/// Example:
/// ```dart
/// FeatureGuardWrapper(
///   module: 'nutrition',
///   fallbackStyle: FeatureFallbackStyle.dimmed,
///   tooltipMessage: 'Upgrade your plan to access nutrition tracking.',
///   child: NutritionEditor(),
/// )
/// ```
///
class FeatureGuardWrapper extends StatelessWidget {
  final String module;
  final String? feature;
  final bool requireEnabled;

  /// Choose between `.hidden` or `.dimmed` fallback behavior.
  final FeatureFallbackStyle fallbackStyle;

  /// Optional tooltip or hover text shown over dimmed content.
  final String? tooltipMessage;

  /// Widget to render if the feature is available/enabled.
  final Widget child;

  const FeatureGuardWrapper({
    Key? key,
    required this.module,
    this.feature,
    this.requireEnabled = true,
    this.fallbackStyle = FeatureFallbackStyle.hidden,
    this.tooltipMessage,
    required this.child,
  }) : super(key: key);

  bool _isPermitted(FranchiseFeatureProvider featureProvider) {
    if (!featureProvider.hasFeature(module)) return false;
    if (!requireEnabled) return true;
    if (feature != null) {
      return featureProvider.isSubfeatureEnabled(module, feature!);
    }
    return featureProvider.isModuleEnabled(module);
  }

  @override
  Widget build(BuildContext context) {
    final featureProvider = context.watch<FranchiseFeatureProvider>();

    if (!featureProvider.isInitialized) {
      return const SizedBox.shrink();
    }

    final isAllowed = _isPermitted(featureProvider);

    // ✅ Feature is active → show as-is
    if (isAllowed) return child;

    // ❌ Feature blocked → determine fallback behavior
    switch (fallbackStyle) {
      case FeatureFallbackStyle.hidden:
        return const SizedBox.shrink();

      case FeatureFallbackStyle.dimmed:
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
    }
  }
}
