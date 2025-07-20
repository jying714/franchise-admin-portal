import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:franchise_admin_portal/core/models/platform_plan_model.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/core/providers/platform_plan_selection_provider.dart';
import 'package:franchise_admin_portal/core/services/franchise_onboarding_service.dart';
import 'package:franchise_admin_portal/core/providers/franchise_subscription_provider.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/active_plan_banner.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/platform_plan_tile.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';

class AvailablePlatformPlansScreen extends StatefulWidget {
  const AvailablePlatformPlansScreen({super.key});

  @override
  State<AvailablePlatformPlansScreen> createState() =>
      _AvailablePlatformPlansScreenState();
}

class _AvailablePlatformPlansScreenState
    extends State<AvailablePlatformPlansScreen> {
  late Future<List<PlatformPlan>> _plansFuture;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _plansFuture = _loadPlans();
  }

  Future<List<PlatformPlan>> _loadPlans() async {
    try {
      final plans = await FirestoreService.getPlatformPlans();
      debugPrint(
          '[DEBUG][AvailablePlatformPlansScreen] Loaded plans: ${plans.length}');
      for (final p in plans) {
        debugPrint('[DEBUG] Plan: ${p.name}, active: ${p.active}');
      }
      return plans;
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'platform_plans_load_error',
        stack: stack.toString(),
        source: 'AvailablePlatformPlansScreen',
        screen: 'available_platform_plans_screen',
        severity: 'error',
      );
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    if (franchiseId == 'unknown' || franchiseId.isEmpty) {
      debugPrint('[AvailablePlatformPlansScreen] franchiseId is still unknown');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = context.watch<AdminUserProvider>().user;
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final planProvider = context.watch<PlatformPlanSelectionProvider>();
    final currentPlanId = planProvider.currentSubscription?.platformPlanId;

    if (!(user?.isHqOwner ?? false) && !(user?.isHqManager ?? false)) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.platformPlansTitle)),
        body: Center(child: Text(loc.unauthorizedAccessMessage)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.platformPlansTitle)),
      body: FutureBuilder<List<PlatformPlan>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final allPlans = snapshot.data ?? [];
          final filteredPlans =
              allPlans.where((plan) => plan.id != currentPlanId).toList();

          final subscriptionNotifier =
              context.watch<FranchiseSubscriptionNotifier>();
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
                          final franchiseId = context
                              .read<AdminUserProvider>()
                              .user
                              ?.defaultFranchise;
                          if (franchiseId != null) {
                            await FranchiseOnboardingService()
                                .markOnboardingComplete(franchiseId);
                            context
                                .read<FranchiseSubscriptionNotifier>()
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
    );
  }
}
