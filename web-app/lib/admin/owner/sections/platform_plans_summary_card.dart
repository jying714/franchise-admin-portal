// ðŸ“ Path: lib/admin/owner/sections/platform_plans_summary_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/src/core/services/firestore_service.dart';
import 'package:shared_core/src/core/models/platform_plan_model.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/src/core/providers/admin_user_provider.dart';
import 'package:shared_core/src/core/services/franchise_subscription_service.dart';

class PlatformPlansSummaryCard extends StatelessWidget {
  const PlatformPlansSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AdminUserProvider>().user;
    if (!(user?.isPlatformOwner ?? false) && !(user?.isDeveloper ?? false)) {
      return const SizedBox.shrink();
    }

    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<List<PlatformPlan>>(
      future: FranchiseSubscriptionService().getPlatformPlans(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          ErrorLogger.log(
            message: 'platform_plans_summary_card_error',
            source: 'PlatformPlansSummaryCard',
            screen: 'platform_owner_dashboard',
            severity: 'error',
            contextData: {'error': snapshot.error.toString()},
          );
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(loc.genericErrorOccurred,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.error)),
          );
        }

        final plans = snapshot.data ?? [];
        final activePlans = plans.where((p) => p.active).toList();

        return Card(
          elevation: DesignTokens.adminCardElevation,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.payment, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Text(loc.platformPlansTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/platform/plans'),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(loc.viewAll),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (activePlans.isEmpty)
                  Text(loc.noPlansAvailable,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.secondary,
                      ))
                else
                  ...activePlans.take(3).map((plan) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: colorScheme.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  '${plan.name} â€¢ \$${plan.price.toStringAsFixed(2)} / ${loc.perMonth}',
                                  style: theme.textTheme.bodyMedium),
                            ),
                          ],
                        ),
                      )),
                const SizedBox(height: 8),
                Text(loc.featureComingSoon('Plan analytics'),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: colorScheme.outline)),
              ],
            ),
          ),
        );
      },
    );
  }
}


