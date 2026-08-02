// web-app/lib/admin/hq_owner/screens/station_settings_panel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// Restaurant settings → Station / POS (hq-restaurant-settings-v1 S7).
/// Path: franchises/{id}/config/pos
class StationSettingsPanel extends StatefulWidget {
  const StationSettingsPanel({super.key});

  @override
  State<StationSettingsPanel> createState() => _StationSettingsPanelState();
}

class _StationSettingsPanelState extends State<StationSettingsPanel> {
  final _largeOrderAmount = TextEditingController(text: '150');
  final _largeOrderItemCount = TextEditingController(text: '20');
  final _maxSplitTenders = TextEditingController(text: '3');
  final _pinTimeoutMinutes = TextEditingController(text: '15');
  final _defaultPrepMinutes = TextEditingController(text: '30');

  bool _largeOrderApprovalRequired = true;
  bool _autoPrintOnPaid = true;
  bool _autoPrintOnAccept = true;

  bool _loading = true;
  bool _saving = false;
  String? _syncedFranchiseId;
  String? _loadError;

  @override
  void dispose() {
    _largeOrderAmount.dispose();
    _largeOrderItemCount.dispose();
    _maxSplitTenders.dispose();
    _pinTimeoutMinutes.dispose();
    _defaultPrepMinutes.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id =
        Provider.of<shared.FranchiseProvider>(context).franchiseId.trim();
    if (id.isEmpty || id == 'unknown') return;
    if (_syncedFranchiseId == id) return;
    _syncedFranchiseId = id;
    _load(id);
  }

  Future<void> _load(String franchiseId) async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('config')
          .doc('pos')
          .get();
      final data = snap.data();
      if (data != null) {
        if (data['largeOrderAmount'] != null) {
          _largeOrderAmount.text = '${data['largeOrderAmount']}';
        }
        if (data['largeOrderItemCount'] != null) {
          _largeOrderItemCount.text = '${data['largeOrderItemCount']}';
        }
        if (data['maxSplitTenders'] != null) {
          _maxSplitTenders.text = '${data['maxSplitTenders']}';
        }
        if (data['pinTimeoutMinutes'] != null) {
          _pinTimeoutMinutes.text = '${data['pinTimeoutMinutes']}';
        }
        if (data['defaultPrepMinutes'] != null) {
          _defaultPrepMinutes.text = '${data['defaultPrepMinutes']}';
        }
        _largeOrderApprovalRequired =
            data['largeOrderApprovalRequired'] as bool? ?? true;
        _autoPrintOnPaid = data['autoPrintOnPaid'] as bool? ?? true;
        _autoPrintOnAccept = data['autoPrintOnAccept'] as bool? ?? true;
      }
    } catch (e) {
      _loadError = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    final franchiseId = fp.franchiseId.trim();
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No franchise selected')),
      );
      return;
    }

    final amount = double.tryParse(_largeOrderAmount.text.trim());
    final itemCount = int.tryParse(_largeOrderItemCount.text.trim());
    final splits = int.tryParse(_maxSplitTenders.text.trim());
    final pinMin = int.tryParse(_pinTimeoutMinutes.text.trim());
    final prep = int.tryParse(_defaultPrepMinutes.text.trim());

    if (amount == null ||
        amount < 0 ||
        itemCount == null ||
        itemCount < 0 ||
        splits == null ||
        splits < 1 ||
        pinMin == null ||
        pinMin < 1 ||
        prep == null ||
        prep < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check numeric fields')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('config')
          .doc('pos')
          .set({
        'largeOrderAmount': amount,
        'largeOrderItemCount': itemCount,
        'largeOrderApprovalRequired': _largeOrderApprovalRequired,
        'maxSplitTenders': splits,
        'pinTimeoutMinutes': pinMin,
        'defaultPrepMinutes': prep,
        'autoPrintOnPaid': _autoPrintOnPaid,
        'autoPrintOnAccept': _autoPrintOnAccept,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Station settings saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: true);
    final hasFranchise =
        fp.franchiseId.isNotEmpty && fp.franchiseId != 'unknown';

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: EdgeInsets.all(DesignTokens.paddingLg),
      children: [
        Text(
          'Thin POS station rules (Decision 14). POS app should read config/pos.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (_loadError != null) ...[
          const SizedBox(height: 8),
          Text(
            'Load warning: $_loadError',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Large orders',
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _largeOrderAmount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Amount threshold (\$)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _largeOrderItemCount,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Item-count threshold',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Require manager approval over threshold'),
          value: _largeOrderApprovalRequired,
          onChanged: (v) => setState(() => _largeOrderApprovalRequired = v),
        ),
        const SizedBox(height: 12),
        Text(
          'Payments & session',
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _maxSplitTenders,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Max split tenders',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pinTimeoutMinutes,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'PIN session timeout (minutes)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _defaultPrepMinutes,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Default prep / promised time (minutes)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Printing',
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto-print on paid'),
          value: _autoPrintOnPaid,
          onChanged: (v) => setState(() => _autoPrintOnPaid = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto-print on accept / send to kitchen'),
          value: _autoPrintOnAccept,
          onChanged: (v) => setState(() => _autoPrintOnAccept = v),
        ),
        const SizedBox(height: 8),
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: ListTile(
            leading: const Icon(Icons.print_disabled_outlined),
            title: const Text('Printer routing by category'),
            subtitle: const Text(
                'Coming soon — configure printers in a later station epic'),
            enabled: false,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: const ListTile(
            leading: Icon(Icons.more_horiz),
            title: Text('Tip prompts (POS only)'),
            subtitle: Text('Coming soon — not used on customer website'),
            enabled: false,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: (!hasFranchise || _saving) ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined, size: 18),
          label: Text(_saving ? 'Saving…' : 'Save station settings'),
          style: FilledButton.styleFrom(
            backgroundColor: DesignTokens.primaryColor,
            foregroundColor: DesignTokens.foregroundColor,
          ),
        ),
      ],
    );
  }
}
