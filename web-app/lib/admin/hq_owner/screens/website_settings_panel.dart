// web-app/lib/admin/hq_owner/screens/website_settings_panel.dart
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

  @override
  void dispose() {
    _heroUrl.dispose();
    _headline.dispose();
    _subheadline.dispose();
    _story.dispose();
    _photoUrl.dispose();
    super.dispose();
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
          'Site content (draft — save in a later phase)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fields map to config/storefront when persistence lands.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
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
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Storefront content save lands when config/storefront is wired',
                ),
              ),
            );
          },
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('Save website content (soon)'),
        ),
      ],
    );
  }
}
