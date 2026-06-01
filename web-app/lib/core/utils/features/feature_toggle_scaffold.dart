// web-app/lib/core/utils/features/feature_toggle_scaffold.dart

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

class FeatureToggleScaffold extends StatelessWidget {
  final Map<String, bool> currentState;
  final void Function(String module, bool value) onToggle;

  const FeatureToggleScaffold({
    super.key,
    required this.currentState,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: shared.PlatformFeature.values.map((feature) {
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
