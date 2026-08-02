// web-app/lib/admin/hq_owner/screens/website_settings_panel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:url_launcher/url_launcher.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// Restaurant settings → Website tab (hq-restaurant-settings-v1 S3).
/// Live: storefront URL + QR. Content fields are local draft stubs until storefront doc save.
class WebsiteSettingsPanel extends StatefulWidget {
  const WebsiteSettingsPanel({super.key});

  @override
  State<WebsiteSettingsPanel> createState() => _WebsiteSettingsPanelState();
}

class _WebsiteSettingsPanelState extends State<WebsiteSettingsPanel> {
  static const storefrontOrigin = 'https://franchise-storefront.web.app';

  final _heroUrl = TextEditingController();
  final _headline = TextEditingController();
  final _subheadline = TextEditingController();
  final _story = TextEditingController();
  final _photoUrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _syncedFranchiseId;
  String? _loadError;

  @override
  void dispose() {
    _heroUrl.dispose();
    _headline.dispose();
    _subheadline.dispose();
    _story.dispose();
    _photoUrl.dispose();
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
          .doc('storefront')
          .get();
      final data = snap.data() ?? {};
      _heroUrl.text = (data['heroImageUrl'] ?? '').toString();
      _headline.text = (data['heroHeadline'] ?? '').toString();
      _subheadline.text = (data['heroSubheadline'] ?? '').toString();
      _photoUrl.text = (data['storefrontPhotoUrl'] ?? '').toString();
      _story.text = (data['storyBody'] ?? '').toString();
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
          .collection('config')
          .doc('storefront')
          .set({
        'heroImageUrl': _heroUrl.text.trim(),
        'heroHeadline': _headline.text.trim(),
        'heroSubheadline': _subheadline.text.trim(),
        'storefrontPhotoUrl': _photoUrl.text.trim(),
        'storyBody': _story.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Website content saved')),
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

  static String urlFor(String franchiseId) =>
      '$storefrontOrigin/f/$franchiseId';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: true);
    final franchiseId = fp.franchiseId;
    final canLink = franchiseId.isNotEmpty &&
        franchiseId != 'unknown' &&
        franchiseId != 'test';
    final url = canLink ? urlFor(franchiseId) : null;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: EdgeInsets.all(DesignTokens.paddingLg),
      children: [
        Text(
          'Public storefront',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: DesignTokens.adminCardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canLink
                            ? 'Share this link or QR for online ordering.'
                            : 'Select a franchise to get the storefront link.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (url != null)
                        SelectableText(
                          url,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: DesignTokens.primaryColor,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: url == null
                                ? null
                                : () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: url),
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Storefront link copied'),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy link'),
                          ),
                          TextButton.icon(
                            onPressed: url == null
                                ? null
                                : () async {
                                    final ok = await launchUrl(
                                      Uri.parse(url),
                                      webOnlyWindowName: '_blank',
                                    );
                                    if (!ok && context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Could not open storefront'),
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Open'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (url != null) ...[
                  const SizedBox(width: 12),
                  QrImageView(
                    data: url,
                    version: QrVersions.auto,
                    size: 96,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Site content',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Stored at franchises/{id}/config/storefront for customer_web.',
          style: theme.textTheme.bodySmall?.copyWith(
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
        const SizedBox(height: 12),
        TextField(
          controller: _heroUrl,
          decoration: const InputDecoration(
            labelText: 'Hero image URL',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _headline,
          decoration: const InputDecoration(
            labelText: 'Hero headline',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _subheadline,
          decoration: const InputDecoration(
            labelText: 'Hero subheadline',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _photoUrl,
          decoration: const InputDecoration(
            labelText: 'Storefront photo URL',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _story,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Our story',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: (!canLink || _saving) ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined, size: 18),
          label: Text(_saving ? 'Saving…' : 'Save website content'),
          style: FilledButton.styleFrom(
            backgroundColor: DesignTokens.primaryColor,
            foregroundColor: DesignTokens.foregroundColor,
          ),
        ),
      ],
    );
  }
}
