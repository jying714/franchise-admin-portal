import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../packages/shared_core/lib/src/core/providers/franchise_feature_provider.dart';

///
/// 🔒 FeatureGateBanner
///
/// A premium gating wrapper that overlays a semi-transparent lock banner
/// over its child when the required feature or subfeature is not available.
///
/// Use this when:
/// - ✅ You want to **educate** or **upsell** locked features.
/// - ✅ You want to **visually indicate** restricted sections during onboarding.
/// - ✅ You want the layout to remain consistent, but clearly restricted.
///
/// Avoid this when:
/// - ❌ The gated content could break layout if visible but unusable.
/// - ❌ You require total exclusion (use `FeatureGate` with `hidden` style instead).
///
/// ---
///
/// Example:
/// ```dart
/// FeatureGateBanner(
///   module: 'inventory',
///   feature: 'liveTracking',
///   lockedMessage: 'Upgrade to enable inventory tracking',
///   onTapUpgrade: () => context.pushNamed('/platform/plans'),
///   child: InventorySectionCard(),
/// )
/// ```
class FeatureGateBanner extends StatelessWidget {
  final String module;
  final String? feature;
  final bool requireEnabled;

  /// Optional custom locked message (defaults to generic).
  final String? lockedMessage;

  /// Optional upgrade button callback
  final VoidCallback? onTapUpgrade;

  /// Optional banner background color
  final Color bannerColor;

  /// Optional lock icon to override default
  final IconData lockIcon;

  /// Widget to show when access is allowed
  final Widget child;

  const FeatureGateBanner({
    Key? key,
    required this.module,
    this.feature,
    this.requireEnabled = true,
    this.lockedMessage,
    this.onTapUpgrade,
    this.bannerColor = const Color(0xAA000000),
    this.lockIcon = Icons.lock_outline,
    required this.child,
  }) : super(key: key);

  bool _isPermitted(FranchiseFeatureProvider provider) {
    if (!provider.hasFeature(module)) return false;
    if (!requireEnabled) return true;
    if (feature != null) {
      return provider.isSubfeatureEnabled(module, feature!);
    }
    return provider.isModuleEnabled(module);
  }

  @override
  Widget build(BuildContext context) {
    final featureProvider = context.watch<FranchiseFeatureProvider>();

    if (!featureProvider.isInitialized) {
      return const SizedBox.shrink();
    }

    final isAllowed = _isPermitted(featureProvider);

    if (isAllowed) return child;

    return Stack(
      children: [
        Opacity(opacity: 0.35, child: child),
        Positioned.fill(
          child: Container(
            color: bannerColor,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(lockIcon, size: 36, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  lockedMessage ?? 'This feature is unavailable in your plan.',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                if (onTapUpgrade != null) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: onTapUpgrade,
                    child: const Text('Upgrade'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
