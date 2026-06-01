import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';

class DashboardSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final WidgetBuilder builder;
  final String? franchiseId;
  final String? brandId;
  final bool developerOnly;
  final bool showFuturePlaceholders;

  const DashboardSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.builder,
    this.franchiseId,
    this.brandId,
    this.developerOnly = false,
    this.showFuturePlaceholders = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final user = context
        .watch<shared.AdminUserProvider>()
        .user; // Fixed ambiguous read + shared prefix

    final isDeveloper = user?.isDeveloper == true;

    if (developerOnly && !isDeveloper) return const SizedBox.shrink();

    final brandColor = brandId != null
        ? BrandingConfig.brandColorFor(brandId!)
        : BrandingConfig.brandRed;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
      ),
      elevation: 0,
      color: brandColor.withValues(alpha: 0.04), // Fixed deprecated withOpacity
      shadowColor: brandColor,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.paddingLg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 200,
            maxHeight: 320,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: brandColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: brandColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Builder(
                    builder: (context) {
                      try {
                        return builder(context);
                      } catch (e, st) {
                        shared.ErrorLogger.log(
                          message: 'Error building section $title: $e',
                          stack: st.toString(),
                          source: 'DashboardSectionCard',
                          severity: 'error',
                          contextData: {
                            'franchiseId': franchiseId,
                            'sectionTitle': title,
                          },
                        );

                        return Text(
                          loc.errorLoadingSection ?? 'Error loading section',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.error,
                                  ),
                        );
                      }
                    },
                  ),
                ),
              ),
              if (showFuturePlaceholders) ...[
                const SizedBox(height: 12),
                _FeaturePlaceholder(
                    label: loc.featureComingSoonCashFlow ??
                        'Cash flow coming soon'),
                _FeaturePlaceholder(
                    label: loc.featureComingSoonRevenueTrends ??
                        'Revenue trends coming soon'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePlaceholder extends StatelessWidget {
  final String label;

  const _FeaturePlaceholder({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
            color:
                color.withValues(alpha: 0.25)), // Fixed deprecated withOpacity
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}
