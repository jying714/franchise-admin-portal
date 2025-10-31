import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/src/core/models/franchise_subscription_model.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/src/core/providers/admin_user_provider.dart';

class FranchiseSubscriptionSummary extends StatelessWidget {
  final FranchiseSubscription subscription;

  const FranchiseSubscriptionSummary({
    super.key,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = context.read<AdminUserProvider>().user;

    // ðŸ” Access Control
    final isDevOrOwner =
        (user?.isDeveloper ?? false) || (user?.isPlatformOwner ?? false);
    if (!isDevOrOwner) return const SizedBox.shrink();

    try {
      final planFeatures =
          subscription.planSnapshot?['features'] as List<dynamic>? ?? [];
      final planName =
          subscription.planSnapshot?['name'] ?? subscription.platformPlanId;
      final billingInterval = subscription.billingInterval ?? 'monthly';

      final trialEndsSoon = subscription.isTrial &&
          subscription.trialEndsAt != null &&
          subscription.trialEndsAt!.difference(DateTime.now()).inDays <= 3;

      final isPendingCancel = subscription.cancelAtPeriodEnd == true;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: DesignTokens.adminCardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Franchise ID + Plan Name
              Row(
                children: [
                  Icon(Icons.business, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${loc.franchiseIdLabel}: ${subscription.franchiseId}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (isDevOrOwner)
                    Chip(
                      label: Text(loc.translateStatus(subscription.status)),
                      backgroundColor:
                          AppConfig.statusColor(subscription.status, theme),
                      labelStyle: theme.textTheme.labelSmall
                          ?.copyWith(color: colorScheme.onPrimary),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              /// Plan Details
              Text(
                '$planName â€¢ ${loc.perLabel(billingInterval)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (subscription.discountPercent > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${loc.discountLabel}: ${subscription.discountPercent}%',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: colorScheme.secondary),
                  ),
                ),

              if (subscription.customQuoteDetails != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${loc.customQuote}: ${subscription.customQuoteDetails}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: colorScheme.tertiary),
                  ),
                ),

              const SizedBox(height: 8),

              /// Dates + Trial info
              Text(
                '${loc.nextBillingLabel}: ${AppConfig.formatDate(subscription.nextBillingDate)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${loc.startDateLabel}: ${AppConfig.formatDate(subscription.startDate)}',
                style: theme.textTheme.bodySmall,
              ),

              if (subscription.isTrial && subscription.trialEndsAt != null)
                Text(
                  '${loc.trialEndsLabel}: ${AppConfig.formatDate(subscription.trialEndsAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: trialEndsSoon
                        ? colorScheme.error
                        : colorScheme.secondary,
                  ),
                ),

              if (isPendingCancel)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_outlined,
                          size: 16, color: colorScheme.error),
                      const SizedBox(width: 4),
                      Text(
                        loc.planCancelsAtPeriodEnd,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: colorScheme.error),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              /// Feature Set Preview
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: planFeatures
                    .map((feature) => Chip(
                          label: Text(
                              AppConfig.featureDisplayName(feature.toString())),
                          backgroundColor: colorScheme.primaryContainer,
                          labelStyle: theme.textTheme.labelSmall,
                        ))
                    .toList(),
              ),

              const SizedBox(height: 10),
              Text(
                loc.featureComingSoon(loc.subscriptionBillingInsights),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: colorScheme.outline),
              ),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'franchise_subscription_summary_render_error',
        source: 'FranchiseSubscriptionSummary',
        screen: 'franchise_subscription_list_screen',
        severity: 'error',
        contextData: {'exception': e.toString()},
        stack: stack.toString(),
      );
      return const SizedBox.shrink();
    }
  }
}


