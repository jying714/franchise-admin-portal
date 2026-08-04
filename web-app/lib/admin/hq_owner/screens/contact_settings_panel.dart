// web-app/lib/admin/hq_owner/screens/contact_settings_panel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// Restaurant settings → Contact tab.
/// Persists structured address map + public phone/email/map on franchises/{id}.
class ContactSettingsPanel extends StatefulWidget {
  const ContactSettingsPanel({super.key});

  @override
  State<ContactSettingsPanel> createState() => _ContactSettingsPanelState();
}

class _ContactSettingsPanelState extends State<ContactSettingsPanel>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _street = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _mapUrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _syncedFranchiseId;
  String? _loadError;

  @override
  void dispose() {
    _street.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
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

  void _applyAddressMap(Map<String, dynamic> addr) {
    _street.text = (addr['street'] ?? '').toString();
    _city.text = (addr['city'] ?? '').toString();
    _state.text = (addr['state'] ?? '').toString();
    _zip.text = (addr['zip'] ?? addr['postalCode'] ?? '').toString();
  }

  Future<void> _load(String franchiseId) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .get();
      if (!mounted) return;

      final data = snap.data() ?? {};
      final rawAddress = data['address'];
      if (rawAddress is Map) {
        _applyAddressMap(Map<String, dynamic>.from(rawAddress));
      } else {
        _street.text = '';
        _city.text = '';
        _state.text = '';
        _zip.text = '';
      }

      _phone.text =
          '${data['publicPhone'] ?? data['contactPhone'] ?? data['phone'] ?? data['franchisePhone'] ?? ''}';
      _email.text =
          '${data['publicEmail'] ?? data['contactEmail'] ?? data['email'] ?? ''}';
      _mapUrl.text = '${data['mapEmbedUrl'] ?? data['mapUrl'] ?? ''}';
    } catch (e) {
      if (!mounted) return;
      _loadError = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!mounted) return;

    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    final franchiseId = fp.franchiseId.trim();
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No franchise selected')),
      );
      return;
    }

    // Capture before any await / setState so dispose cannot race reads.
    final street = _street.text.trim();
    final city = _city.text.trim();
    final state = _state.text.trim();
    final zip = _zip.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final mapUrl = _mapUrl.text.trim();

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .set({
        'address': {
          'street': street,
          'city': city,
          'state': state,
          'zip': zip,
        },
        'publicPhone': phone,
        'publicEmail': email,
        'contactPhone': phone,
        'contactEmail': email,
        'mapEmbedUrl': mapUrl,
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
    super.build(context);
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
              ? 'Public contact for website footer, contact page, and receipts. Address is stored as street / city / state / zip on the franchise document.'
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
          controller: _street,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Street',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _city,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'City',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _state,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _zip,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ZIP',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
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
