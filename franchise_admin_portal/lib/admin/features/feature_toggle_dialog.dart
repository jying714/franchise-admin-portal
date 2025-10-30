import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/feature_config.dart';

class FeatureToggleDialog extends StatefulWidget {
  final VoidCallback? onChanged;
  const FeatureToggleDialog({Key? key, this.onChanged}) : super(key: key);

  @override
  State<FeatureToggleDialog> createState() => _FeatureToggleDialogState();
}

class _FeatureToggleDialogState extends State<FeatureToggleDialog> {
  late Map<String, bool> featureMap;

  @override
  void initState() {
    super.initState();
    featureMap = Map<String, bool>.from(FeatureConfig.instance.asMap);
  }

  Future<void> _save() async {
    // You'll want to save updated toggles to Firestore here, e.g.:
    // await FirestoreService().updateFeatureToggles(featureMap);
    if (widget.onChanged != null) widget.onChanged!();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Feature Toggles'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: featureMap.entries.map((e) {
            return SwitchListTile(
              value: e.value,
              title: Text(e.key),
              onChanged: (v) => setState(() => featureMap[e.key] = v),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
