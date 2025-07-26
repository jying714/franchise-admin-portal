import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class RemovePlatformFeaturesForm extends StatefulWidget {
  const RemovePlatformFeaturesForm({super.key});

  @override
  State<RemovePlatformFeaturesForm> createState() =>
      _RemovePlatformFeaturesFormState();
}

class _RemovePlatformFeaturesFormState
    extends State<RemovePlatformFeaturesForm> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<String> _featureKeys = [];
  String? _selectedFeatureKey;
  String? _statusMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFeatureKeys();
  }

  Future<void> _loadFeatureKeys() async {
    try {
      final snapshot = await _db.collection('platform_features').get();
      final keys = snapshot.docs.map((doc) => doc.id).toList();

      setState(() => _featureKeys = keys);
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Failed to fetch platform_features for deletion',
        stack: st.toString(),
        screen: 'RemovePlatformFeaturesForm',
        source: 'remove_platform_features_form.dart',
        severity: 'warning',
      );
    }
  }

  Future<void> _deleteFeature() async {
    final loc = AppLocalizations.of(context)!;

    if (_selectedFeatureKey == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      await _db
          .collection('platform_features')
          .doc(_selectedFeatureKey)
          .delete();

      setState(() {
        _featureKeys.remove(_selectedFeatureKey);
        _selectedFeatureKey = null;
        _statusMessage = loc.devtoolsDeleteSuccess;
      });
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Failed to delete platform_feature',
        stack: st.toString(),
        screen: 'RemovePlatformFeaturesForm',
        source: 'remove_platform_features_form.dart',
        contextData: {'featureKey': _selectedFeatureKey},
        severity: 'error',
      );

      setState(() => _statusMessage = loc.devtoolsDeleteError);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.devtoolsDeletePlatformFeaturesTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedFeatureKey,
                items: _featureKeys
                    .map((id) => DropdownMenuItem(
                          value: id,
                          child: Text(id),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedFeatureKey = value),
                decoration: InputDecoration(
                  labelText: loc.devtoolsSelectFeature,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.delete_outline),
              onPressed: _selectedFeatureKey == null || _isLoading
                  ? null
                  : _deleteFeature,
              label: Text(
                _isLoading ? loc.deleting : loc.delete,
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ),
        if (_statusMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _statusMessage!,
            style: TextStyle(
              color: _statusMessage == loc.devtoolsDeleteSuccess
                  ? Colors.green
                  : theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
