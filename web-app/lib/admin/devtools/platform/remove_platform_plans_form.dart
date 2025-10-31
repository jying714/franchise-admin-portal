import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

class RemovePlatformPlansForm extends StatefulWidget {
  const RemovePlatformPlansForm({super.key});

  @override
  State<RemovePlatformPlansForm> createState() =>
      _RemovePlatformPlansFormState();
}

class _RemovePlatformPlansFormState extends State<RemovePlatformPlansForm> {
  late final FirebaseFirestore _db;
  List<String> _planIds = [];
  String? _selectedPlanId;
  String? _statusMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _db = FirebaseFirestore.instance;
    _loadPlanIds();
  }

  Future<void> _loadPlanIds() async {
    try {
      final snapshot = await _db.collection('platform_plans').get();
      final ids = snapshot.docs.map((doc) => doc.id).toList();

      setState(() => _planIds = ids);
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Failed to fetch platform_plans for deletion',
        stack: st.toString(),
        screen: 'RemovePlatformPlansForm',
        source: 'remove_platform_plans_form.dart',
        severity: 'warning',
      );
    }
  }

  Future<void> _deletePlan() async {
    final loc = AppLocalizations.of(context)!;

    if (_selectedPlanId == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      await _db.collection('platform_plans').doc(_selectedPlanId).delete();

      setState(() {
        _planIds.remove(_selectedPlanId);
        _selectedPlanId = null;
        _statusMessage = loc.devtoolsDeleteSuccess;
      });
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Failed to delete platform_plan',
        stack: st.toString(),
        screen: 'RemovePlatformPlansForm',
        source: 'remove_platform_plans_form.dart',
        contextData: {'planId': _selectedPlanId},
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
          loc.devtoolsDeletePlatformPlansTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPlanId,
                items: _planIds
                    .map((id) => DropdownMenuItem(
                          value: id,
                          child: Text(id),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedPlanId = value),
                decoration: InputDecoration(
                  labelText: loc.devtoolsSelectPlan,
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
              onPressed:
                  _selectedPlanId == null || _isLoading ? null : _deletePlan,
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


