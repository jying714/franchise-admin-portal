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
class DesignBrandingScreen extends StatelessWidget {
  const DesignBrandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: true);
    final franchiseId = franchiseProvider.franchiseId;
    final hasFranchise = franchiseId.isNotEmpty && franchiseId != 'unknown';

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
                      Text(
                        DesignTokens.currentAppName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: DesignTokens.primaryColor,
                                ),
                      ),
                      const SizedBox(height: 12),
                      // Logo with fallback
                      if (DesignTokens.currentLogoUrl != null &&
                          DesignTokens.currentLogoUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.adminCardRadius),
                          child: Image.network(
                            DesignTokens.currentLogoUrl!,
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
                      // Color swatches + hex labels (hex from FranchiseProvider instance)
                      Row(
                        children: [
                          _swatchColumn(
                            context,
                            color: DesignTokens.primaryColor,
                            label: 'Primary',
                            hex: franchiseProvider.currentPrimaryColorHex,
                          ),
                          const SizedBox(width: 16),
                          _swatchColumn(
                            context,
                            color: DesignTokens.secondaryColor,
                            label: 'Secondary',
                            hex: franchiseProvider.currentSecondaryColorHex,
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
}
