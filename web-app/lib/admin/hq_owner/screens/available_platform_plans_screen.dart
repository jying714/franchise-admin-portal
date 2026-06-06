import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/admin/hq_owner/widgets/active_plan_banner.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/platform_plan_tile.dart';
import 'package:franchise_admin_portal/widgets/admin/role_guard_widget.dart';

class AvailablePlatformPlansScreen extends StatefulWidget {
  const AvailablePlatformPlansScreen({super.key});

  @override
  State<AvailablePlatformPlansScreen> createState() =>
      _AvailablePlatformPlansScreenState();
}

class _AvailablePlatformPlansScreenState
    extends State<AvailablePlatformPlansScreen> {
  late Future<List<shared.PlatformPlan>> _plansFuture;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _plansFuture = _loadPlans();
  }

  Future<List<shared.PlatformPlan>> _loadPlans() async {
    try {
      final plans = await Provider.of<shared.FranchiseSubscriptionService>(
              context,
              listen: false)
          .getPlatformPlans();
      debugPrint(
          '[DEBUG][AvailablePlatformPlansScreen] Loaded plans: ${plans.length}');
      for (final p in plans) {
        debugPrint('[DEBUG] Plan: ${p.name}, active: ${p.active}');
      }
      return plans;
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'platform_plans_load_error',
        stack: stack.toString(),
        source: 'AvailablePlatformPlansScreen',
        severity: 'error',
      );
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final franchiseId = context.watch<shared.FranchiseProvider>().franchiseId;
    if (franchiseId == 'unknown' || franchiseId.isEmpty) {
      debugPrint('[AvailablePlatformPlansScreen] franchiseId is still unknown');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return RoleGuard(
      allowedRoles: const [
        'hq_owner',
        'hq_manager',
        'developer',
        'platform_owner'
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(loc.platformPlansTitle)),
        body: FutureBuilder<List<shared.PlatformPlan>>(
          future: _plansFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final allPlans = snapshot.data ?? [];
            final planProvider =
                context.watch<shared.PlatformPlanSelectionProvider>();
            final subscriptionNotifier =
                context.watch<shared.FranchiseSubscriptionProvider>();
            final subscription = subscriptionNotifier.currentSubscription;

            final currentPlanId =
                planProvider.currentSubscription?.platformPlanId;
            final filteredPlans = allPlans.where((plan) {
              return plan.id != currentPlanId &&
                  plan.id != subscription?.platformPlanId;
            }).toList();

            if (!subscriptionNotifier.hasLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: ActivePlanBanner(),
                ),
                if (filteredPlans.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      loc.noPlansAvailable,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredPlans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final plan = filteredPlans[index];
                        return PlatformPlanTile(
                          plan: plan,
                          isExpanded: _expandedIndex == index,
                          onExpand: () {
                            setState(() {
                              _expandedIndex =
                                  _expandedIndex == index ? null : index;
                            });
                          },
                          onPlanUpdated: () async {
                            final franchiseId =
                                Provider.of<shared.AdminUserProvider>(context,
                                        listen: false)
                                    .user
                                    ?.defaultFranchise;
                            if (franchiseId != null) {
                              await Provider.of<
                                          shared.FranchiseOnboardingService>(
                                      context,
                                      listen: false)
                                  .markOnboardingComplete(franchiseId);
                              Provider.of<shared.FranchiseSubscriptionProvider>(
                                      context,
                                      listen: false)
                                  .updateFranchiseId(franchiseId);
                            }
                            setState(() => _expandedIndex = null);
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
