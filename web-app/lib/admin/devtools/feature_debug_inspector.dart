import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/src/core/utils/features/enum_platform_features.dart';
import 'package:shared_core/src/core/providers/franchise_provider.dart';
import 'package:shared_core/src/core/providers/franchise_feature_provider.dart';

class FeatureDebugInspector extends StatefulWidget {
  const FeatureDebugInspector({super.key});

  @override
  State<FeatureDebugInspector> createState() => _FeatureDebugInspectorState();
}

class _FeatureDebugInspectorState extends State<FeatureDebugInspector> {
  bool _showOnlyInactive = false;

  @override
  Widget build(BuildContext context) {
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    final featureProvider = context.watch<FranchiseFeatureProvider>();

    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      return const Center(child: Text('âš ï¸ No franchise selected.'));
    }

    if (!featureProvider.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final features = PlatformFeature.values.where((f) {
      final key = f.key;
      final isAvailable = featureProvider.hasFeature(key);
      final isEnabled = featureProvider.isModuleEnabled(key);
      final isActive = isAvailable && isEnabled;
      return !_showOnlyInactive || !isActive;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ðŸ§© Feature Debug Inspector',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('Franchise ID: $franchiseId'),
            const Spacer(),
            FilterChip(
              label: const Text('Show only inactive'),
              selected: _showOnlyInactive,
              onSelected: (val) => setState(() => _showOnlyInactive = val),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: features.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final feature = features[index];
              final key = feature.key;

              final isAvailable = featureProvider.hasFeature(key);
              final isEnabled = featureProvider.isModuleEnabled(key);
              final isActive = isAvailable && isEnabled;
              final subfeatures = featureProvider.getSubfeatures(key);

              return ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(key),
                subtitle: Text(
                  'Available: ${_yesNo(isAvailable)}  â€¢  Enabled: ${_yesNo(isEnabled)}  â€¢  Active: ${_yesNo(isActive)}',
                ),
                trailing: Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  color: isActive ? Colors.green : Colors.redAccent,
                ),
                children: [
                  if (subfeatures.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('  âŸ¶ No subfeatures',
                          style: TextStyle(fontSize: 13)),
                    )
                  else
                    ...subfeatures.entries.map(
                      (entry) => ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.only(left: 32, right: 16),
                        title: Text(entry.key),
                        trailing: Icon(
                          entry.value
                              ? Icons.toggle_on
                              : Icons.toggle_off_outlined,
                          color: entry.value ? Colors.green : Colors.grey,
                          size: 28,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _yesNo(bool val) => val ? 'âœ…' : 'âŒ';
}


