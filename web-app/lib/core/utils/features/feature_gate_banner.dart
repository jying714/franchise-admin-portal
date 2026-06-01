// web_app/lib/core/utils/features/feature_gate_banner.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

///
/// FeatureGateBanner
///
/// A premium gating wrapper that overlays a semi-transparent lock banner
/// over its child when the required feature or subfeature is not available.
///
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
    super.key, // Fixed: use super parameter
    required this.module,
    this.feature,
    this.requireEnabled = true,
    this.lockedMessage,
    this.onTapUpgrade,
    this.bannerColor = const Color(0xAA000000),
    this.lockIcon = Icons.lock_outline,
    required this.child,
  });

  bool _isPermitted(shared.FranchiseFeatureProvider provider) {
    if (!provider.hasFeature(module)) return false;
    if (!requireEnabled) return true;
    if (feature != null) {
      return provider.isSubfeatureEnabled(module, feature!);
    }
    return provider.isModuleEnabled(module);
  }

  @override
  Widget build(BuildContext context) {
    final featureProvider = context.watch<shared.FranchiseFeatureProvider>();

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
