// 📁 Path: lib/admin/owner/sections/franchise_subscription_summary_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import '../../../../../packages/shared_core/lib/src/core/models/franchise_subscription_model.dart';
import '../../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:provider/provider.dart';
import '../../../../../packages/shared_core/lib/src/core/providers/admin_user_provider.dart';

class FranchiseSubscriptionSummaryCard extends StatelessWidget {
  const FranchiseSubscriptionSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AdminUserProvider>().user;
    if (!(user?.isPlatformOwner ?? false) && !(user?.isDeveloper ?? false)) {
      return const SizedBox.shrink();
    }

    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<List<FranchiseSubscription>>(
      future: FirestoreService.getFranchiseSubscriptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          ErrorLogger.log(
            message: 'franchise_subscription_summary_error',
            source: 'FranchiseSubscriptionSummaryCard',
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

        final subs = snapshot.data ?? [];
        final activeSubs = subs.where((s) => s.status == 'active').toList();

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
                    Icon(Icons.subscriptions, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Text(loc.franchiseSubscriptionsTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                          context, '/platform/subscriptions'),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(loc.viewAll),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (activeSubs.isEmpty)
                  Text(loc.noSubscriptionsFound,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.secondary,
                      ))
                else
                  ...activeSubs.take(3).map((sub) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: colorScheme.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  'ID: ${sub.franchiseId} • ${sub.platformPlanId}',
                                  style: theme.textTheme.bodyMedium),
                            ),
                          ],
                        ),
                      )),
                const SizedBox(height: 8),
                Text(loc.featureComingSoon('Subscription billing metrics'),
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
