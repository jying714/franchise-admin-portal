import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// HQ Owner — Design & Branding screen (v1 shell).
///
/// Slice: docs/slices/hq-design-branding-v1.md (Decision 8).
/// Opened from Owner HQ Live Branding card via Navigator.push + MaterialPageRoute.
/// Back pops to the dashboard. No Firestore writes in v1.
///
/// S1: scaffold + AppBar + placeholder only.
/// Later steps fill preview, draft fields, and Save snackbar.
class DesignBrandingScreen extends StatefulWidget {
  const DesignBrandingScreen({super.key});

  @override
  State<DesignBrandingScreen> createState() => _DesignBrandingScreenState();
}

class _DesignBrandingScreenState extends State<DesignBrandingScreen> {
  late final TextEditingController _appNameController;
  late final TextEditingController _logoUrlController;
  late final TextEditingController _primaryHexController;
  late final TextEditingController _secondaryHexController;

  @override
  void initState() {
    super.initState();
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    _appNameController =
        TextEditingController(text: DesignTokens.currentAppName);
    _logoUrlController =
        TextEditingController(text: DesignTokens.currentLogoUrl ?? '');
    _primaryHexController =
        TextEditingController(text: fp.currentPrimaryColorHex);
    _secondaryHexController =
        TextEditingController(text: fp.currentSecondaryColorHex);

    // Rebuild preview when any draft field changes
    void listener() => setState(() {});
    _appNameController.addListener(listener);
    _logoUrlController.addListener(listener);
    _primaryHexController.addListener(listener);
    _secondaryHexController.addListener(listener);
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _logoUrlController.dispose();
    _primaryHexController.dispose();
    _secondaryHexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: true);
    final franchiseId = franchiseProvider.franchiseId;
    final hasFranchise = franchiseId.isNotEmpty && franchiseId != 'unknown';

    // Draft values used by the live preview (local only — no Firestore)
    final draftName = _appNameController.text.trim().isEmpty
        ? DesignTokens.currentAppName
        : _appNameController.text.trim();
    final draftLogoUrl = _logoUrlController.text.trim();
    final draftPrimaryHex = _primaryHexController.text.trim();
    final draftSecondaryHex = _secondaryHexController.text.trim();

    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      appBar: AppBar(
        elevation: DesignTokens.appBarElevation,
        backgroundColor: DesignTokens.appBarBackgroundColor,
        foregroundColor: DesignTokens.appBarForegroundColor,
        iconTheme: IconThemeData(color: DesignTokens.appBarIconColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Design & Branding'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(DesignTokens.paddingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Franchise context (minimal for shell; S3 can polish)
              Text(
                hasFranchise
                    ? 'Franchise: $franchiseId'
                    : 'Franchise: not selected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DesignTokens.secondaryTextColor,
                    ),
              ),
              SizedBox(height: DesignTokens.adminCardSpacing),
              Card(
                elevation: DesignTokens.adminCardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.adminCardRadius),
                ),
                child: Padding(
                  padding: EdgeInsets.all(DesignTokens.paddingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            color: DesignTokens.primaryColor,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Design & Branding',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Live Preview (S4) — reads only existing DesignTokens + FranchiseProvider instance getters
                      // Live Preview driven by local draft state (v1 — no write)
                      Text(
                        draftName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: DesignTokens.primaryColor,
                                ),
                      ),
                      const SizedBox(height: 12),
                      if (draftLogoUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.adminCardRadius),
                          child: Image.network(
                            draftLogoUrl,
                            width: 120,
                            height: 60,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                _logoFallback(context),
                          ),
                        )
                      else
                        _logoFallback(context),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _swatchColumn(
                            context,
                            color: DesignTokens.primaryColor,
                            label: 'Primary',
                            hex: draftPrimaryHex.isEmpty
                                ? franchiseProvider.currentPrimaryColorHex
                                : draftPrimaryHex,
                          ),
                          const SizedBox(width: 16),
                          _swatchColumn(
                            context,
                            color: DesignTokens.secondaryColor,
                            label: 'Secondary',
                            hex: draftSecondaryHex.isEmpty
                                ? franchiseProvider.currentSecondaryColorHex
                                : draftSecondaryHex,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Draft (local only — Save not wired yet)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: DesignTokens.secondaryTextColor,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _appNameController,
                        decoration: const InputDecoration(
                          labelText: 'App name',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _logoUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Logo URL',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _primaryHexController,
                        decoration: const InputDecoration(
                          labelText: 'Primary hex',
                          border: OutlineInputBorder(),
                          isDense: true,
                          hintText: '#RRGGBB',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _secondaryHexController,
                        decoration: const InputDecoration(
                          labelText: 'Secondary hex',
                          border: OutlineInputBorder(),
                          isDense: true,
                          hintText: '#RRGGBB',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Save not wired yet'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.save_outlined, size: 18),
                            label: const Text('Save'),
                            style: FilledButton.styleFrom(
                              backgroundColor: DesignTokens.primaryColor,
                              foregroundColor: DesignTokens.foregroundColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _resetDraftsToLive,
                            icon: const Icon(Icons.restart_alt, size: 18),
                            label: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoFallback(BuildContext context) {
    return Container(
      width: 120,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: DesignTokens.cardBorderColor),
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined,
              size: 22, color: DesignTokens.secondaryTextColor),
          const SizedBox(height: 4),
          Text(
            'No logo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.secondaryTextColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _swatchColumn(
    BuildContext context, {
    required Color color,
    required String label,
    required String hex,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: DesignTokens.cardBorderColor, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DesignTokens.secondaryTextColor,
              ),
        ),
        Text(
          hex,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DesignTokens.secondaryTextColor,
                fontFamily: 'monospace',
              ),
        ),
      ],
    );
  }

  void _resetDraftsToLive() {
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    setState(() {
      _appNameController.text = DesignTokens.currentAppName;
      _logoUrlController.text = DesignTokens.currentLogoUrl ?? '';
      _primaryHexController.text = fp.currentPrimaryColorHex;
      _secondaryHexController.text = fp.currentSecondaryColorHex;
    });
  }
}
