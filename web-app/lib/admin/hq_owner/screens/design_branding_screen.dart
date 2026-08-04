import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/screens/hq_onboarding_shell_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// HQ Owner — Design & Branding screen (v1.1).
///
/// Slice: docs/slices/hq-design-branding-v1.md (Decision 8).
/// Opened from Owner HQ Live Branding card via Navigator.push + MaterialPageRoute.
/// Back pops to the dashboard. Save merges branding to franchise + config/ui_config.
///
/// Draft fields drive live preview; Save persists and refreshes DesignTokens path.
class DesignBrandingScreen extends StatefulWidget {
  /// When true (HQ onboarding shell), no route back; Save marks progress and can continue.
  final bool embeddedInOnboarding;

  /// When true (Restaurant settings → Brand tab), no AppBar; onboarding chrome hidden.
  final bool embeddedInSettingsShell;

  const DesignBrandingScreen({
    super.key,
    this.embeddedInOnboarding = false,
    this.embeddedInSettingsShell = false,
  });

  @override
  State<DesignBrandingScreen> createState() => _DesignBrandingScreenState();
}

class _DesignBrandingScreenState extends State<DesignBrandingScreen> {
  bool _saving = false;
  late final TextEditingController _appNameController;
  late final TextEditingController _logoUrlController;
  late final TextEditingController _primaryHexController;
  late final TextEditingController _secondaryHexController;
  bool _uploadingLogo = false;

  /// FranchiseId drafts were last synced from (re-sync when picker changes).
  String? _syncedFranchiseId;

  Future<void> _uploadLogo() async {
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    final franchiseId = fp.currentFranchiseId;
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No franchise selected')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read image bytes')),
      );
      return;
    }

    setState(() => _uploadingLogo = true);
    try {
      final ext = (file.extension ?? 'png').toLowerCase();
      final path =
          'franchises/$franchiseId/branding/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = FirebaseStorage.instance.ref().child(path);
      final contentType = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      final url = await ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        _logoUrlController.text = url;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo uploaded — click Save to persist')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  String _normalizeHex(String raw) {
    var h = raw.trim();
    if (h.isEmpty) return h;
    if (!h.startsWith('#')) h = '#$h';
    return h.toUpperCase();
  }

  bool _isValidHex(String h) {
    final n = _normalizeHex(h);
    return RegExp(r'^#[0-9A-F]{6}$').hasMatch(n);
  }

  Color? _colorFromHex(String raw) {
    final n = _normalizeHex(raw);
    if (!_isValidHex(n)) return null;
    final v = int.tryParse(n.substring(1), radix: 16);
    if (v == null) return null;
    return Color(0xFF000000 | v);
  }

  Future<void> _saveBranding() async {
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    final franchiseId = fp.currentFranchiseId;
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No franchise selected')),
      );
      return;
    }

    final appName = _appNameController.text.trim();
    final logoUrl = _logoUrlController.text.trim();
    final primary = _normalizeHex(_primaryHexController.text);
    final secondary = _normalizeHex(_secondaryHexController.text);

    if (!_isValidHex(primary) || !_isValidHex(secondary)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primary and secondary must be #RRGGBB')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'primaryColorHex': primary,
        'secondaryColorHex': secondary,
        if (appName.isNotEmpty) 'appName': appName,
        if (logoUrl.isNotEmpty) 'logoUrl': logoUrl,
      };

      final uiConfigPayload = <String, dynamic>{
        ...payload,
        if (appName.isNotEmpty) 'currentAppName': appName,
        if (logoUrl.isNotEmpty) 'logoMain': logoUrl,
      };

      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final rootRef = db.collection('franchises').doc(franchiseId);
      final uiRef = rootRef.collection('config').doc('ui_config');
      batch.set(rootRef, payload, SetOptions(merge: true));
      batch.set(uiRef, uiConfigPayload, SetOptions(merge: true));
      await batch.commit();

      // Refresh in-memory live path (DesignTokens reads FranchiseProvider)
      final merged = Map<String, dynamic>.from(fp.currentBranding)
        ..addAll(payload);
      fp.setBrandingFromFranchiseDoc(merged);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Branding saved')),
      );

      if (widget.embeddedInOnboarding) {
        try {
          await Provider.of<shared.OnboardingProgressProvider>(context,
                  listen: false)
              .markStepComplete('onboarding_design_branding');
        } catch (e, st) {
          shared.ErrorLogger.log(
            message: 'Failed to mark onboarding_design_branding complete',
            stack: st.toString(),
            source: 'design_branding_screen.dart',
          );
        }
      }
    } catch (e, st) {
      shared.ErrorLogger.log(
        message: 'Design & Branding save failed',
        stack: st.toString(),
        source: 'design_branding_screen.dart',
        contextData: {'franchiseId': franchiseId, 'error': e.toString()},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fp = Provider.of<shared.FranchiseProvider>(context);
    final franchiseId = fp.franchiseId;
    final isFirstSync = _syncedFranchiseId == null;
    if (_syncedFranchiseId == franchiseId) return;
    _syncedFranchiseId = franchiseId;
    // initState already populated controllers for the initial franchise
    if (isFirstSync) return;
    _resetDraftsToLive();
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
      // HQ-only route keeps AppBar + Back. Onboarding embed: title in body only.
      appBar: (widget.embeddedInOnboarding || widget.embeddedInSettingsShell)
          ? null
          : AppBar(
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
              if (widget.embeddedInOnboarding) ...[
                Text(
                  'Step 2: Design & Branding',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: DesignTokens.textColor,
                      ),
                ),
                SizedBox(height: DesignTokens.adminCardSpacing),
              ],
              Text(
                hasFranchise
                    ? 'Franchise: ${DesignTokens.currentAppName} ($franchiseId)'
                    : 'Franchise: not selected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                            color: _colorFromHex(draftPrimaryHex) ??
                                DesignTokens.primaryColor,
                            label: 'Primary',
                            hex: draftPrimaryHex.isEmpty
                                ? franchiseProvider.currentPrimaryColorHex
                                : draftPrimaryHex,
                          ),
                          const SizedBox(width: 16),
                          _swatchColumn(
                            context,
                            color: _colorFromHex(draftSecondaryHex) ??
                                DesignTokens.secondaryColor,
                            label: 'Secondary',
                            hex: draftSecondaryHex.isEmpty
                                ? franchiseProvider.currentSecondaryColorHex
                                : draftSecondaryHex,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Draft fields (Save writes franchise + config/ui_config)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                          helperText: 'Paste a URL or upload below',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: (_uploadingLogo || !hasFranchise)
                            ? null
                            : _uploadLogo,
                        icon: _uploadingLogo
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file, size: 18),
                        label: Text(
                          _uploadingLogo ? 'Uploading…' : 'Upload logo',
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
                            onPressed: _saving ? null : _saveBranding,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_outlined, size: 18),
                            label: Text(_saving ? 'Saving…' : 'Save'),
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
                          if (widget.embeddedInOnboarding) ...[
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: () {
                                final hqShell = context.findAncestorStateOfType<
                                    HqOnboardingShellScreenState>();
                                hqShell?.switchToSection(
                                    'onboarding_menu_foundation');
                              },
                              icon: const Icon(Icons.arrow_forward, size: 18),
                              label: const Text('Continue to Foundation'),
                              style: FilledButton.styleFrom(
                                backgroundColor: DesignTokens.primaryColor,
                                foregroundColor: DesignTokens.foregroundColor,
                              ),
                            ),
                          ],
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
              size: 22, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            'No logo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          hex,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
