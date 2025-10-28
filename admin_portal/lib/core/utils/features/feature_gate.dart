import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_feature_provider.dart';
import 'package:franchise_admin_portal/core/utils/features/feature_lock_overlay.dart';

/// Defines how the fallback content should behave if the feature is not granted or enabled.
enum FeatureFallbackStyle {
  /// Completely hides the widget from the layout.
  hidden,

  /// Shows the widget dimmed and disabled.
  dimmed,

  /// Displays the widget with a centered lock overlay for upsell/education.
  lockedBanner,
}

///
/// 🚪 FeatureGate
///
/// Centralized feature-gating widget supporting `.hidden`, `.dimmed`, and `.lockedBanner` styles.
///
/// ✅ Use for:
/// - Gating optional sections, cards, tabs, fields, or advanced inputs.
/// - Educating or upselling on locked features.
///
/// ❌ Avoid when:
/// - You need backend-level access control (this is UI-only).
/// - You want zero layout impact (use `hidden` only).
///
class FeatureGate extends StatelessWidget {
  final String module;
  final String? feature;
  final bool requireEnabled;
  final FeatureFallbackStyle fallbackStyle;

  final String? tooltipMessage; // for dimmed
  final String? lockedMessage; // for lockedBanner
  final VoidCallback? onTapUpgrade; // for lockedBanner

  final Widget? loading;
  final Widget child;

  const FeatureGate({
    Key? key,
    required this.module,
    this.feature,
    this.requireEnabled = true,
    this.fallbackStyle = FeatureFallbackStyle.hidden,
    this.tooltipMessage,
    this.lockedMessage,
    this.onTapUpgrade,
    this.loading,
    required this.child,
  }) : super(key: key);

  bool _isPermitted(FranchiseFeatureProvider provider) {
    if (!provider.hasFeature(module)) return false;
    if (!requireEnabled) return true;
    if (feature != null) return provider.isSubfeatureEnabled(module, feature!);
    return provider.isModuleEnabled(module);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FranchiseFeatureProvider>();

    if (!provider.isInitialized) {
      return loading ?? const SizedBox.shrink();
    }

    final isAllowed = _isPermitted(provider);
    if (isAllowed) return child;

    switch (fallbackStyle) {
      case FeatureFallbackStyle.hidden:
        return const SizedBox.shrink();

      case FeatureFallbackStyle.dimmed:
        return Tooltip(
          message:
              tooltipMessage ?? 'This feature is not available in your plan.',
          child: IgnorePointer(
            ignoring: true,
            child: Opacity(opacity: 0.4, child: child),
          ),
        );

      case FeatureFallbackStyle.lockedBanner:
        return Stack(
          children: [
            Opacity(opacity: 0.35, child: child),
            FeatureLockOverlay(
              lockedMessage: lockedMessage,
              onTapUpgrade: onTapUpgrade,
            ),
          ],
        );
    }
  }
}
