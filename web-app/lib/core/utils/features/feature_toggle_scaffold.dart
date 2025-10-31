// 🔧 Feature Toggle Registration Scaffold
// Used in onboarding_feature_setup_screen.dart or devtools

import 'package:flutter/material.dart';
import '../../../../../packages/shared_core/lib/src/core/utils/features/enum_platform_features.dart';
import 'package:franchise_admin_portal/core/utils/features/feature_gate.dart';

class FeatureToggleScaffold extends StatelessWidget {
  final Map<String, bool> currentState;
  final void Function(String module, bool value) onToggle;

  const FeatureToggleScaffold({
    Key? key,
    required this.currentState,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: PlatformFeature.values.map((feature) {
        final key = feature.key;
        final displayName = key.replaceAll('_', ' ').toUpperCase();

        return SwitchListTile.adaptive(
          value: currentState[key] ?? false,
          title: Text(displayName),
          subtitle: Text('Feature module: $key'),
          onChanged: (value) => onToggle(key, value),
        );
      }).toList(),
    );
  }
}
