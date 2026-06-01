// web-app/lib/core/utils/features/feature_gate_wrapper.dart

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

/// FeatureGateWrapper
///
/// Lightweight wrapper for gating a widget with configurable fallback style.
class FeatureGateWrapper extends StatelessWidget {
  final String module;
  final String? feature;
  final bool requireEnabled;
  final shared.FeatureFallbackStyle fallbackStyle;
  final String? tooltipMessage;
  final String? lockedMessage;
  final VoidCallback? onTapUpgrade;
  final Widget child;

  const FeatureGateWrapper({
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

  @override
  Widget build(BuildContext context) {
    return shared.FeatureGate(
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
