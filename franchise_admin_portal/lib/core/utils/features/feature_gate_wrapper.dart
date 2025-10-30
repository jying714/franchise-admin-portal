import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/utils/features/feature_gate.dart';

///
/// 🧱 FeatureGateWrapper
///
/// Lightweight wrapper for gating a widget with configurable fallback style,
/// using the full FeatureGate behind the scenes.
///
/// Great for centralized usage when dynamically toggling fallback types.
///
class FeatureGateWrapper extends StatelessWidget {
  final String module;
  final String? feature;
  final bool requireEnabled;
  final FeatureFallbackStyle fallbackStyle;
  final String? tooltipMessage;
  final String? lockedMessage;
  final VoidCallback? onTapUpgrade;
  final Widget child;

  const FeatureGateWrapper({
    Key? key,
    required this.module,
    this.feature,
    this.requireEnabled = true,
    this.fallbackStyle = FeatureFallbackStyle.hidden,
    this.tooltipMessage,
    this.lockedMessage,
    this.onTapUpgrade,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      module: module,
      feature: feature,
      requireEnabled: requireEnabled,
      fallbackStyle: fallbackStyle,
      tooltipMessage: tooltipMessage,
      lockedMessage: lockedMessage,
      onTapUpgrade: onTapUpgrade,
      child: child,
    );
  }
}
