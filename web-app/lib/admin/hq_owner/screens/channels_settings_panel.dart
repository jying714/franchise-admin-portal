// web-app/lib/admin/hq_owner/screens/channels_settings_panel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// Restaurant settings → Channels (hq-restaurant-settings-v1 S5).
/// Reads/writes franchises/{id}/config/features (FeatureConfig keys only).
class ChannelsSettingsPanel extends StatefulWidget {
  const ChannelsSettingsPanel({super.key});

  @override
  State<ChannelsSettingsPanel> createState() => _ChannelsSettingsPanelState();
}

class _ChannelsSettingsPanelState extends State<ChannelsSettingsPanel> {
  /// Owner-relevant toggles (existing FeatureConfig field names only).
  static const _specs = <({String key, String label, String? subtitle})>[
    (
      key: 'loyaltyEnabled',
      label: 'Loyalty',
      subtitle: 'Points / rewards on customer apps'
    ),
    (key: 'favoritesEnabled', label: 'Favorites', subtitle: null),
    (
      key: 'scheduledOrdersEnabled',
      label: 'Scheduled orders',
      subtitle: 'Mobile; web may hide until parity'
    ),
    (key: 'trackOrderEnabled', label: 'Track order', subtitle: null),
    (
      key: 'notificationsEnabled',
      label: 'Push notifications',
      subtitle: 'Mobile'
    ),
    (
      key: 'chatSupportEnabled',
      label: 'Chat support',
      subtitle: 'Mobile; web out of current parity wave'
    ),
    (
      key: 'enableGuestMode',
      label: 'Guest mode',
      subtitle: 'Prefer off if cart requires auth'
    ),
    (key: 'forceLogin', label: 'Force login', subtitle: null),
    (key: 'googleAuthEnabled', label: 'Google sign-in', subtitle: null),
    (key: 'appleAuthEnabled', label: 'Apple sign-in', subtitle: null),
    (key: 'facebookAuthEnabled', label: 'Facebook sign-in', subtitle: null),
    (key: 'phoneAuthEnabled', label: 'Phone sign-in', subtitle: null),
    (key: 'inventoryEnabled', label: 'Inventory tracking', subtitle: null),
    (key: 'nutritionEnabled', label: 'Nutrition display', subtitle: null),
    (key: 'languageEnabled', label: 'Language selector', subtitle: null),
  ];

  final Map<String, bool> _values = {};
  bool _loading = true;
  bool _saving = false;
  String? _syncedFranchiseId;
  String? _loadError;

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
          .doc('features')
          .get();
      final data = snap.data() ?? {};
      final defaults = shared.FeatureConfig.instance.asMap;
      for (final s in _specs) {
        final v = data[s.key];
        if (v is bool) {
          _values[s.key] = v;
        } else {
          _values[s.key] = defaults[s.key] ?? false;
        }
      }
    } catch (e) {
      _loadError = '$e';
      final defaults = shared.FeatureConfig.instance.asMap;
      for (final s in _specs) {
        _values[s.key] = defaults[s.key] ?? false;
      }
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
      final payload = <String, dynamic>{
        for (final s in _specs) s.key: _values[s.key] ?? false,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('config')
          .doc('features')
          .set(payload, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Channels saved')),
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
          'Customer & channel features for this franchise.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (_loadError != null) ...[
          const SizedBox(height: 8),
          Text(
            'Load warning: $_loadError — showing defaults',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 8),
        for (final s in _specs)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.label),
            subtitle: s.subtitle != null ? Text(s.subtitle!) : null,
            value: _values[s.key] ?? false,
            onChanged: (v) => setState(() => _values[s.key] = v),
            activeColor: DesignTokens.primaryColor,
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: (!hasFranchise || _saving) ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined, size: 18),
          label: Text(_saving ? 'Saving…' : 'Save channels'),
          style: FilledButton.styleFrom(
            backgroundColor: DesignTokens.primaryColor,
            foregroundColor: DesignTokens.foregroundColor,
          ),
        ),
      ],
    );
  }
}
