import 'package:flutter/material.dart';

///
/// 🔐 FeatureLockOverlay
///
/// A flexible widget that overlays a centered lock icon, message, and optional
/// upgrade button over a blurred or dimmed background.
///
/// Use this as the **visual overlay component** inside:
/// - `FeatureGateBanner` (section overlays)
/// - `FeatureGateModal` (coming soon)
/// - Any dimmed card or locked list tile
///
/// ---
///
/// ✅ Use when:
/// - You want a **consistent visual style** for locked features.
/// - You're gating a **card**, **container**, or **section** with meaningful content.
///
/// ❌ Avoid when:
/// - You're gating small elements (e.g. toggle switch only).
/// - You want full invisibility (`FeatureFallbackStyle.hidden` is better).
///
class FeatureLockOverlay extends StatelessWidget {
  final String? lockedMessage;
  final VoidCallback? onTapUpgrade;
  final Color backgroundColor;
  final IconData lockIcon;

  const FeatureLockOverlay({
    Key? key,
    this.lockedMessage,
    this.onTapUpgrade,
    this.backgroundColor = const Color(0xAA000000),
    this.lockIcon = Icons.lock_outline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: backgroundColor,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }
}
