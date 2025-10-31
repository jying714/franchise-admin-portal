import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

class SeedPlatformPlansForm extends StatefulWidget {
  const SeedPlatformPlansForm({super.key});

  @override
  State<SeedPlatformPlansForm> createState() => _SeedPlatformPlansFormState();
}

class _SeedPlatformPlansFormState extends State<SeedPlatformPlansForm> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _currencyController = TextEditingController(text: 'USD');
  final _intervalController = TextEditingController(text: 'monthly');
  final _versionController = TextEditingController(text: 'v1');
  bool _active = true;
  bool _isCustom = false;
  String? _statusMessage;
  bool _isSaving = false;

  final List<String> _selectedFeatures = [];
  List<String> _availableFeatures = [];
  String? _selectedFeatureToAdd;

  @override
  void initState() {
    super.initState();
    _loadPlatformFeatures();
  }

  Future<void> _loadPlatformFeatures() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('platform_features')
          .get();
      final featureKeys = snap.docs.map((doc) => doc.id).toList();
      setState(() => _availableFeatures = featureKeys);
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Failed to load platform_features',
        stack: st.toString(),
        source: 'SeedPlatformPlansForm',
        screen: 'seed_platform_plans_form',
        severity: 'error',
      );
    }
  }

  Future<void> _handleSubmit() async {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    final planData = {
      'id': _idController.text.trim(),
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'currency': _currencyController.text.trim(),
      'active': _active,
      'isCustom': _isCustom,
      'billingInterval': _intervalController.text.trim(),
      'planVersion': _versionController.text.trim(),
      'features': _selectedFeatures,
    };

    try {
      final docRef = FirebaseFirestore.instance
          .collection('platform_plans')
          .doc(planData['id'] as String?);

      await docRef.set(planData);

      setState(() => _statusMessage = loc.devtoolsSeedSuccess);
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Failed to seed platform_plan',
        stack: st.toString(),
        source: 'SeedPlatformPlansForm',
        screen: 'seed_platform_plans_form',
        severity: 'error',
        contextData: {
          'formData': planData,
          'errorType': e.runtimeType.toString(),
          'errorMessage': e.toString(),
        },
      );

      setState(() => _statusMessage = loc.devtoolsSeedError);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addFeature(String feature) {
    if (!_selectedFeatures.contains(feature)) {
      setState(() {
        _selectedFeatures.add(feature);
        _availableFeatures.remove(feature);
        _selectedFeatureToAdd = null;
      });
    }
  }

  void _removeFeature(String feature) {
    setState(() => _selectedFeatures.remove(feature));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.devtoolsSeedPlatformPlansTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 200,
                child: TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(labelText: 'Plan ID'),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Required' : null,
                ),
              ),
              SizedBox(
                width: 300,
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Required' : null,
                ),
              ),
              SizedBox(
                width: 200,
                child: TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Price'),
                ),
              ),
              SizedBox(
                width: 150,
                child: TextFormField(
                  controller: _currencyController,
                  decoration: InputDecoration(labelText: 'Currency'),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                      value: _active,
                      onChanged: (v) => setState(() => _active = v)),
                  const SizedBox(width: 8),
                  const Text('Active')
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                      value: _isCustom,
                      onChanged: (v) => setState(() => _isCustom = v)),
                  const SizedBox(width: 8),
                  const Text('Custom Plan')
                ],
              ),
              SizedBox(
                width: 180,
                child: TextFormField(
                  controller: _intervalController,
                  decoration: InputDecoration(labelText: 'Billing Interval'),
                ),
              ),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _versionController,
                  decoration: InputDecoration(labelText: 'Version'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descController,
            maxLines: 3,
            decoration: InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              DropdownButton<String>(
                value: _selectedFeatureToAdd,
                hint: const Text('Add Feature'),
                items: _availableFeatures
                    .where((f) => !_selectedFeatures.contains(f))
                    .map((feature) => DropdownMenuItem(
                          value: feature,
                          child: Text(feature),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedFeatureToAdd = value),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _selectedFeatureToAdd == null ||
                        _selectedFeatures.contains(_selectedFeatureToAdd)
                    ? null
                    : () => _addFeature(_selectedFeatureToAdd!),
                child: const Text('+ Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedFeatures
                .map((f) =>
                    Chip(label: Text(f), onDeleted: () => _removeFeature(f)))
                .toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSubmit,
                icon: const Icon(Icons.save),
                label: Text(_isSaving ? loc.saving : loc.seed),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Replace with JSON import/export dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('JSON Upload Placeholder')),
                  );
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload via JSON'),
              ),
              const SizedBox(width: 12),
              if (_statusMessage != null)
                Text(_statusMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    )),
            ],
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _intervalController.dispose();
    _versionController.dispose();
    super.dispose();
  }
}


