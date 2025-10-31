// 📁 File: lib/admin/owner/screens/full_platform_plans_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import '../../../../../packages/shared_core/lib/src/core/providers/admin_user_provider.dart';
import '../../../../../packages/shared_core/lib/src/core/models/platform_plan_model.dart';
import '../../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import '../../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';
import '../../../../../packages/shared_core/lib/src/core/services/franchise_subscription_service.dart';

class FullPlatformPlansScreen extends StatefulWidget {
  const FullPlatformPlansScreen({super.key});

  @override
  State<FullPlatformPlansScreen> createState() =>
      _FullPlatformPlansScreenState();
}

class _FullPlatformPlansScreenState extends State<FullPlatformPlansScreen> {
  late Future<List<PlatformPlan>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _plansFuture = _loadPlans();
  }

  Future<List<PlatformPlan>> _loadPlans() async {
    try {
      return await FranchiseSubscriptionService().getPlatformPlans();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'load_platform_plans_failed',
        stack: stack.toString(),
        source: 'FullPlatformPlansScreen',
        screen: 'full_platform_plans_screen',
        severity: 'error',
        contextData: {'exception': e.toString()},
      );
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AdminUserProvider>().user;
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // 🔐 Developer-only access
    if (!(user?.isDeveloper ?? false) && !(user?.isPlatformOwner ?? false)) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.platformPlansTitle)),
        body: Center(child: Text(loc.unauthorizedAccessMessage)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.platformPlansTitle),
      ),
      body: FutureBuilder<List<PlatformPlan>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final plans = snapshot.data ?? [];

          if (plans.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child:
                  Text(loc.noPlansAvailable, style: theme.textTheme.bodyMedium),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Card(
                elevation: DesignTokens.adminCardElevation,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                color: plan.active
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: plan.active
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                            ),
                          ),
                          const Spacer(),
                          if (plan.isCustom)
                            Chip(
                              label: Text(loc.customPlan),
                              backgroundColor:
                                  theme.colorScheme.secondaryContainer,
                            ),
                          if (!plan.active)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Chip(
                                label: Text(loc.inactive),
                                backgroundColor:
                                    theme.colorScheme.errorContainer,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${plan.price.toStringAsFixed(2)} / ${loc.perMonth}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: plan.features
                            .map(
                              (feature) => Chip(
                                label:
                                    Text(AppConfig.featureDisplayName(feature)),
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        loc.featureComingSoon(loc.platformPlansTitle),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
