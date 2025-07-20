import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:franchise_admin_portal/core/models/platform_plan_model.dart';
import 'package:franchise_admin_portal/core/providers/franchise_subscription_provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/widgets/role_guard.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/tight_section_card.dart';

class ActivePlanBanner extends StatelessWidget {
  const ActivePlanBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subscriptionNotifier = context.watch<FranchiseSubscriptionNotifier>();
    if (!subscriptionNotifier.hasLoaded) {
      debugPrint('[ActivePlanBanner] Waiting for subscription to load...');
      return const LinearProgressIndicator();
    }
    final subscription = subscriptionNotifier.currentSubscription;

    debugPrint('[ActivePlanBanner] Build called');
    if (subscription == null) {
      debugPrint('[ActivePlanBanner] No current subscription found.');
    } else {
      debugPrint('[ActivePlanBanner] Subscription found: '
          'planId=${subscription.platformPlanId}, '
          'billingInterval=${subscription.billingInterval}');
    }

    return RoleGuard(
      allowedRoles: const ['hq_owner', 'platform_owner', 'developer'],
      child: TightSectionCard(
        title: loc.currentPlatformPlan,
        icon: Icons.verified,
        builder: (context) {
          if (subscription == null || subscription.platformPlanId.isEmpty) {
            debugPrint('[ActivePlanBanner] subscription null or planId empty');
            return Text(
              loc.noActivePlatformPlan,
              style: textTheme.bodyMedium,
            );
          }

          final planSnapshot = subscription.planSnapshot;
          debugPrint('[ActivePlanBanner] Snapshot: $planSnapshot');

          if (planSnapshot != null && planSnapshot.isNotEmpty) {
            final name = planSnapshot['name'] ?? 'Unnamed Plan';
            final interval = subscription.billingInterval ?? 'monthly';
            final features = List<String>.from(planSnapshot['features'] ?? []);
            final formattedDate =
                DateFormat.yMMMMd().format(subscription.nextBillingDate);

            debugPrint('[ActivePlanBanner] Rendering from snapshot: $name');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name – $interval',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.nextBillingDate(formattedDate),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                    );
                  }).toList(),
                ),
              ],
            );
          }

          // Fallback to Firestore fetch
          debugPrint(
              '[ActivePlanBanner] Snapshot missing. Fetching plan from Firestore for ID: ${subscription.platformPlanId}');

          return FutureBuilder<PlatformPlan?>(
            future: _fetchPlan(subscription.platformPlanId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                debugPrint('[ActivePlanBanner] Waiting for Firestore fetch...');
                return const LinearProgressIndicator();
              }

              if (snapshot.hasError || !snapshot.hasData) {
                debugPrint('[ActivePlanBanner] Fetch error or no data');
                ErrorLogger.log(
                  message: 'Failed to fetch platform plan',
                  source: 'ActivePlanBanner',
                  screen: 'available_platform_plans_screen',
                  severity: 'warning',
                  contextData: {
                    'error': snapshot.error.toString(),
                    'planId': subscription.platformPlanId
                  },
                );
                return Text(
                  loc.errorLoadingPlan,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                );
              }

              final plan = snapshot.data!;
              final formattedDate =
                  DateFormat.yMMMMd().format(subscription.nextBillingDate);

              debugPrint(
                  '[ActivePlanBanner] Successfully fetched plan: ${plan.name}');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${plan.name} – ${subscription.billingInterval ?? plan.billingInterval}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.nextBillingDate(formattedDate),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: -4,
                    children: plan.includedFeatures.map((f) {
                      return Chip(
                        label: Text(f, style: textTheme.labelSmall),
                        backgroundColor: colorScheme.surfaceVariant,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<PlatformPlan?> _fetchPlan(String planId) async {
    try {
      debugPrint(
          '[ActivePlanBanner] Calling FirestoreService.getPlatformPlanById($planId)');
      return await FirestoreService.getPlatformPlanById(planId);
    } catch (e, stack) {
      debugPrint('[ActivePlanBanner] Exception in _fetchPlan: $e');
      ErrorLogger.log(
        message: 'Error fetching plan by ID: $planId',
        stack: stack.toString(),
        source: 'ActivePlanBanner',
        screen: 'available_platform_plans_screen',
        severity: 'error',
        contextData: {'exception': e.toString()},
      );
      return null;
    }
  }
}
