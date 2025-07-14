import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

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
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final user = Provider.of<AdminUserProvider>(context).user;

    final isDeveloper = user?.isDeveloper == true;

    // Guard if developerOnly is true
    if (developerOnly && !isDeveloper) return const SizedBox.shrink();

    final brandColor = brandId != null
        ? BrandingConfig.brandColorFor(brandId!)
        : BrandingConfig.brandRed;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
      ),
      elevation: 0,
      color: brandColor.withOpacity(0.04),
      shadowColor: brandColor,
      child: Padding(
          padding: const EdgeInsets.all(DesignTokens.paddingLg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                minHeight: 200,
                maxHeight: 320), // You may want to tweak maxHeight!
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

                // ---- Key Fix: Scrollable main card content ----
                Expanded(
                  child: SingleChildScrollView(
                    child: Builder(
                      builder: (context) {
                        try {
                          return builder(context);
                        } catch (e, st) {
                          final fs = Provider.of<FirestoreService>(context,
                              listen: false);
                          ErrorLogger.log(
                            message: 'Error building section $title: $e',
                            stack: st.toString(),
                            source: 'DashboardSectionCard',
                            screen: title,
                            severity: 'error',
                            contextData: {
                              'franchiseId': franchiseId,
                              'sectionTitle': title,
                            },
                          );

                          return Text(
                            loc.errorLoadingSection,
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
                // ---- end Key Fix ----

                if (showFuturePlaceholders) ...[
                  const SizedBox(height: 12),
                  _FeaturePlaceholder(label: loc.featureComingSoonCashFlow),
                  _FeaturePlaceholder(
                      label: loc.featureComingSoonRevenueTrends),
                ],
              ],
            ),
          )),
    );
  }
}

class _FeaturePlaceholder extends StatelessWidget {
  final String label;
  const _FeaturePlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.25)),
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
