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
                      Text(
                        'Configuration UI will appear here '
                        '(live preview, draft fields, Save).',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DesignTokens.secondaryTextColor,
                            ),
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
}
