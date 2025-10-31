import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../../packages/shared_core/lib/src/core/services/franchise_subscription_service.dart';
import '../../../../../packages/shared_core/lib/src/core/models/platform_plan_model.dart';
import '../../../../../packages/shared_core/lib/src/core/providers/franchise_subscription_provider.dart';
import '../../../../../packages/shared_core/lib/src/core/providers/role_guard.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/tight_section_card.dart';

class ActivePlanBanner extends StatefulWidget {
  const ActivePlanBanner({Key? key}) : super(key: key);

  @override
  State<ActivePlanBanner> createState() => _ActivePlanBannerState();
}

class _ActivePlanBannerState extends State<ActivePlanBanner> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subscriptionNotifier = context.watch<FranchiseSubscriptionNotifier>();

    if (!subscriptionNotifier.hasLoaded) {
      return const LinearProgressIndicator();
    }

    final subscription = subscriptionNotifier.currentSubscription;
    final plan = subscriptionNotifier.activePlatformPlan;

    if (subscription == null || subscription.platformPlanId.isEmpty) {
      return RoleGuard(
        allowedRoles: const ['hq_owner', 'platform_owner', 'developer'],
        child: TightSectionCard(
          title: loc.currentPlatformPlan,
          icon: Icons.verified,
          builder: (context) => Text(
            loc.noActivePlatformPlan,
            style: textTheme.bodyMedium,
          ),
        ),
      );
    }

    final snapshot = subscription.planSnapshot ?? {};
    final name = snapshot['name'] ?? plan?.name ?? loc.unknownPlan;
    final price = snapshot['price'] ?? plan?.price ?? 0;
    final interval =
        snapshot['billingInterval'] ?? plan?.billingInterval ?? 'monthly';
    final features =
        List<String>.from(snapshot['features'] ?? plan?.features ?? []);
    final formattedNextBilling =
        DateFormat.yMMMMd().format(subscription.nextBillingDate);
    final formattedStartDate =
        DateFormat.yMMMMd().format(subscription.startDate);

    return RoleGuard(
      allowedRoles: const ['hq_owner', 'platform_owner', 'developer'],
      child: TightSectionCard(
        title: loc.currentPlatformPlan,
        icon: Icons.verified,
        builder: (context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: Plan name + price + interval + chevron
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$name – \$${price.toStringAsFixed(2)} / $interval',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down),
                    onPressed: () {
                      setState(() => _isExpanded = !_isExpanded);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                loc.nextBillingDate(formattedNextBilling),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: -4,
                children: features.map((f) {
                  return Chip(
                    label: Text(f, style: textTheme.labelSmall),
                    backgroundColor: colorScheme.surfaceVariant,
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  );
                }).toList(),
              ),

              if (_isExpanded) ...[
                const SizedBox(height: 12),
                Divider(
                    thickness: 1, color: colorScheme.outline.withOpacity(0.1)),
                Text(
                  '${loc.subscriptionStartDate(formattedStartDate)}',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${loc.status}: ${subscription.status}',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${loc.autoRenewLabel}: ${subscription.autoRenew ? loc.yes : loc.no}',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${loc.cancelAtPeriodEndLabel}: ${subscription.cancelAtPeriodEnd ? loc.yes : loc.no}',
                  style: textTheme.bodyMedium,
                ),
                if (subscription.hasOverdueInvoice)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      loc.overduePaymentWarning,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (subscription.paymentStatus != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${loc.paymentStatusLabel}: ${subscription.paymentStatus}',
                    style: textTheme.bodyMedium,
                  ),
                ],
                if (subscription.cardLast4 != null &&
                    subscription.cardBrand != null &&
                    subscription.paymentTokenId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${loc.cardOnFileLabel}: ${subscription.cardBrand} •••• ${subscription.cardLast4}',
                    style: textTheme.bodyMedium,
                  ),
                ],
                if (subscription.receiptUrl != null &&
                    subscription.receiptUrl!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      // Ideally you use `url_launcher` to open the receipt
                    },
                    child: Text(
                      loc.viewLastReceipt,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
                if (subscription.gracePeriodEndsAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${loc.gracePeriodEndsAtLabel}: ${DateFormat.yMMMMd().format(subscription.gracePeriodEndsAt!)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
