// web-app/lib/admin/hq_owner/screens/contact_settings_panel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// Restaurant settings → Contact tab (hq-restaurant-settings-v1 S4).
/// Persists public contact fields on franchises/{id} (merge).
class ContactSettingsPanel extends StatefulWidget {
  const ContactSettingsPanel({super.key});

  @override
  State<ContactSettingsPanel> createState() => _ContactSettingsPanelState();
}

class _ContactSettingsPanelState extends State<ContactSettingsPanel> {
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _mapUrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _syncedFranchiseId;
  String? _loadError;

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _mapUrl.dispose();
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
          .get();
      final data = snap.data() ?? {};
      // Prefer explicit public* keys; fall back to common legacy keys.
      _address.text = (data['publicAddress'] ??
              data['address'] ??
              data['franchiseAddress'] ??
              '')
          .toString();
      _phone.text =
          (data['publicPhone'] ?? data['phone'] ?? data['franchisePhone'] ?? '')
              .toString();
      _email.text = (data['publicEmail'] ?? data['email'] ?? '').toString();
      _mapUrl.text = (data['mapEmbedUrl'] ?? data['mapUrl'] ?? '').toString();
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

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .set({
        'publicAddress': _address.text.trim(),
        'publicPhone': _phone.text.trim(),
        'publicEmail': _email.text.trim(),
        'mapEmbedUrl': _mapUrl.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact saved')),
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
          hasFranchise
              ? 'Public contact for website footer, contact page, and receipts.'
              : 'Select a franchise to edit contact.',
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
        TextField(
          controller: _address,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Public address',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          decoration: const InputDecoration(
            labelText: 'Public phone',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Public email',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _mapUrl,
          decoration: const InputDecoration(
            labelText: 'Map embed or Google Maps URL',
            border: OutlineInputBorder(),
            isDense: true,
            helperText: 'Used on customer website contact / location section',
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
          label: Text(_saving ? 'Saving…' : 'Save contact'),
          style: FilledButton.styleFrom(
            backgroundColor: DesignTokens.primaryColor,
            foregroundColor: DesignTokens.foregroundColor,
          ),
        ),
      ],
    );
  }
}
