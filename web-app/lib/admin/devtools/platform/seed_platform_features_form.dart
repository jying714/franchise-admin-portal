import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';

class SeedPlatformFeaturesForm extends StatefulWidget {
  const SeedPlatformFeaturesForm({super.key});

  @override
  State<SeedPlatformFeaturesForm> createState() =>
      _SeedPlatformFeaturesFormState();
}

class _SeedPlatformFeaturesFormState extends State<SeedPlatformFeaturesForm> {
  final _keyController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _moduleController = TextEditingController();

  bool _deprecated = false;
  bool _developerOnly = false;
  bool _isSaving = false;
  String? _statusMessage;

  final List<Map<String, dynamic>> _featuresToSeed = [];

  void _addFeature() {
    final key = _keyController.text.trim();
    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final module = _moduleController.text.trim();

    if (key.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.devtoolsValidationMissingFields)),
      );
      return;
    }

    setState(() {
      _featuresToSeed.add({
        'key': key,
        'name': name,
        'description': description,
        'module': module,
        'deprecated': _deprecated,
        'developerOnly': _developerOnly,
      });
      _keyController.clear();
      _nameController.clear();
      _descController.clear();
      _moduleController.clear();
      _deprecated = false;
      _developerOnly = false;
    });
  }

  Future<void> _submitFeatures() async {
    final loc = AppLocalizations.of(context)!;

    if (_featuresToSeed.isEmpty) {
      setState(() => _statusMessage = loc.devtoolsValidationEmptyFeatureList);
      return;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      final ref = FirebaseFirestore.instance.collection('platform_features');

      for (final f in _featuresToSeed) {
        final key = f['key'];
        if (key == null || key.toString().isEmpty) continue;
        batch.set(ref.doc(key), f);
      }

      await batch.commit();
      setState(() {
        _featuresToSeed.clear();
        _statusMessage = loc.devtoolsSeedSuccess;
      });
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Failed to seed platform_features',
        stack: st.toString(),
        source: 'SeedPlatformFeaturesForm',
        screen: 'seed_platform_features_form',
        severity: 'error',
      );
      setState(() => _statusMessage = loc.devtoolsSeedError);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _moduleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.seedPlatformFeaturesTitle,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(loc.seedPlatformFeaturesDescription,
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),

        // ─── Horizontal Row 1 ────────────────────────────────────────
        Row(children: [
          Expanded(
            child: TextField(
              controller: _keyController,
              decoration: InputDecoration(labelText: loc.devtoolsFieldKey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: loc.devtoolsFieldName),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // ─── Horizontal Row 2 ────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _deprecated,
                  onChanged: (val) =>
                      setState(() => _deprecated = val ?? false),
                ),
                Text(loc.devtoolsFieldDeprecated),
              ],
            ),
            const SizedBox(width: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _developerOnly,
                  onChanged: (val) =>
                      setState(() => _developerOnly = val ?? false),
                ),
                Text(loc.devtoolsFieldDeveloperOnly),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ─── Multiline Description ──────────────────────────────────
        TextField(
          controller: _descController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: loc.devtoolsFieldDescription,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(loc.devtoolsAddFeature),
              onPressed: _addFeature,
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(loc.uploadViaJson),
              onPressed: () {
                // TODO: Open JSON upload dialog
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ─── List of Features ───────────────────────────────────────
        if (_featuresToSeed.isNotEmpty) ...[
          Text(
            loc.devtoolsFeaturesToSeed,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._featuresToSeed.map((f) => Text('- ${f['key']} → ${f['name']}')),
          const SizedBox(height: 12),
        ],

        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _submitFeatures,
              icon: const Icon(Icons.save),
              label: Text(_isSaving ? loc.saving : loc.seed),
            ),
            const SizedBox(width: 16),
            if (_statusMessage != null)
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage == loc.devtoolsSeedSuccess
                      ? Colors.green
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
