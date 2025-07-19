// 📁 Path: lib/admin/hq_owner/screens/available_platform_plans_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:franchise_admin_portal/core/models/platform_plan_model.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:franchise_admin_portal/admin/hq_owner/dialogs/confirm_plan_subscription_dialog.dart';
import 'package:franchise_admin_portal/core/providers/platform_plan_selection_provider.dart';
import 'package:franchise_admin_portal/core/services/franchise_onboarding_service.dart';

class AvailablePlatformPlansScreen extends StatefulWidget {
  const AvailablePlatformPlansScreen({super.key});

  @override
  State<AvailablePlatformPlansScreen> createState() =>
      _AvailablePlatformPlansScreenState();
}

class _AvailablePlatformPlansScreenState
    extends State<AvailablePlatformPlansScreen> {
  late Future<List<PlatformPlan>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _plansFuture = _loadPlans();
  }

  Future<List<PlatformPlan>> _loadPlans() async {
    try {
      final plans = await FirestoreService.getPlatformPlans();
      print(
          '[DEBUG][AvailablePlatformPlansScreen] Loaded plans: ${plans.length}');
      for (final p in plans) {
        print('[DEBUG] Plan: ${p.name}, active: ${p.active}');
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
    final user = context.watch<AdminUserProvider>().user;
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final planProvider = context.watch<PlatformPlanSelectionProvider>();

    if (!(user?.isHqOwner ?? false) && !(user?.isHqManager ?? false)) {
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
                  borderRadius: BorderRadius.circular(14),
                ),
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
                      Text(
                        plan.description,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: plan.includedFeatures.map((f) {
                          return Chip(
                            label: Text(f, style: theme.textTheme.labelSmall),
                            backgroundColor: theme.colorScheme.primaryContainer
                                .withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: plan.active
                              ? () async {
                                  final franchiseId = user?.defaultFranchise;
                                  if (franchiseId == null ||
                                      franchiseId.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text(loc.genericErrorOccurred)),
                                    );
                                    return;
                                  }

                                  planProvider.selectPlan(plan);
                                  await planProvider.subscribeToPlan(
                                    context: context,
                                    franchiseId: franchiseId,
                                    onSuccess: () async {
                                      await FranchiseOnboardingService()
                                          .markOnboardingComplete(franchiseId);

                                      // Role-aware redirect
                                      final roles = user?.roles ?? [];

                                      if (roles.contains('hq_owner')) {
                                        Navigator.of(context)
                                            .pushReplacementNamed(
                                                '/hq-owner/dashboard');
                                      } else if (roles.contains('admin')) {
                                        Navigator.of(context)
                                            .pushReplacementNamed(
                                                '/admin/dashboard');
                                      } else {
                                        Navigator.of(context)
                                            .pushReplacementNamed('/');
                                      }
                                    },
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(loc.selectThisPlan),
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
