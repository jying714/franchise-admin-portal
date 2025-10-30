import 'package:flutter/material.dart';
import 'package:admin_portal/config/app_config.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:admin_portal/core/models/dashboard_section.dart';
import 'package:admin_portal/core/providers/admin_user_provider.dart';
import 'package:provider/provider.dart';
import 'package:admin_portal/core/models/platform_plan_model.dart';
import 'package:admin_portal/core/services/franchise_subscription_service.dart';

class PlatformPlansSection extends StatefulWidget {
  const PlatformPlansSection({super.key});

  @override
  State<PlatformPlansSection> createState() => _PlatformPlansSectionState();
}

class _PlatformPlansSectionState extends State<PlatformPlansSection> {
  late Future<List<PlatformPlan>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _plansFuture = _loadPlans();
  }

  Future<List<PlatformPlan>> _loadPlans() async {
    try {
      final service = FranchiseSubscriptionService();
      return await service.getPlatformPlans();
    } catch (e, stack) {
      ErrorLogger.log(
        message: "platform_plans_load_error",
        stack: stack.toString(),
        source: 'PlatformPlansSection',
        screen: 'platform_plans_section',
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

    if (!(user?.isDeveloper ?? false) &&
        !(user?.isAdmin ?? false) &&
        !(user?.isHqOwner ?? false)) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<PlatformPlan>>(
      future: _plansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final plans = snapshot.data ?? [];

        if (plans.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(loc.noPlansAvailable),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.platformPlansTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...plans
                .map((plan) => _buildPlanCard(plan, loc, theme, user))
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildPlanCard(
      PlatformPlan plan, AppLocalizations loc, ThemeData theme, user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: plan.active
          ? theme.colorScheme.surface
          : theme.colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(plan.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: plan.active
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    )),
                const Spacer(),
                if (user?.isDeveloper == true || user?.isAdmin == true) ...[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: loc.editPlan,
                    onPressed: () {
                      // TODO: implement plan edit dialog
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: loc.deletePlan,
                    onPressed: () {
                      // TODO: implement delete confirmation
                    },
                  ),
                ],
                if (plan.isCustom)
                  Chip(
                    label: Text(loc.customPlan),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  ),
                if (!plan.active)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Chip(
                      label: Text(loc.inactive),
                      backgroundColor: theme.colorScheme.errorContainer,
                    ),
                  )
              ],
            ),
            const SizedBox(height: 8),
            Text('\$${plan.price.toStringAsFixed(2)} / ${loc.perMonth}',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: plan.features
                  .map((feature) => Chip(
                        label: Text(AppConfig.featureDisplayName(feature)),
                        backgroundColor: theme.colorScheme.primaryContainer,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            // 🔮 Future: Button to view subscribers / switch UI / plan analytics
            Text(loc.featurePlanComingSoon,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}
