import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/franchise_subscription_model.dart';
import 'package:franchise_admin_portal/core/models/platform_plan_model.dart';
import 'package:franchise_admin_portal/core/services/franchise_subscription_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class PlanSwapperTool extends StatefulWidget {
  const PlanSwapperTool({super.key});

  @override
  State<PlanSwapperTool> createState() => _PlanSwapperToolState();
}

class _PlanSwapperToolState extends State<PlanSwapperTool> {
  final _subscriptionService = FranchiseSubscriptionService();
  FranchiseSubscription? _selectedSub;
  PlatformPlan? _selectedPlan;
  bool _saving = false;

  Future<void> _handleSwap() async {
    if (_selectedSub == null || _selectedPlan == null) return;

    setState(() => _saving = true);
    final loc = AppLocalizations.of(context)!;

    try {
      await _subscriptionService.subscribeFranchiseToPlan(
        franchiseId: _selectedSub!.franchiseId,
        plan: _selectedPlan!,
      );

      await ErrorLogger.log(
        message: 'Plan manually swapped by developer',
        source: 'PlanSwapperTool',
        screen: 'subscription_dev_tools_screen',
        contextData: {
          'franchiseId': _selectedSub!.franchiseId,
          'newPlanId': _selectedPlan!.id,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.genericSavedSuccess)),
        );
      }

      setState(() {
        _selectedSub = null;
        _selectedPlan = null;
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to swap plan: $e',
        source: 'PlanSwapperTool',
        screen: 'subscription_dev_tools_screen',
        stack: stack.toString(),
        severity: 'error',
      );
    }

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.planSwapperTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        StreamBuilder<List<FranchiseSubscription>>(
          stream: _subscriptionService.watchAllFranchiseSubscriptions(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }

            final subs = snapshot.data!;
            return DropdownButtonFormField<FranchiseSubscription>(
              value: subs.any((sub) => sub.id == _selectedSub?.id)
                  ? _selectedSub
                  : null,
              decoration: InputDecoration(
                labelText: loc.selectFranchise,
                border: const OutlineInputBorder(),
              ),
              items: subs
                  .map((sub) => DropdownMenuItem<FranchiseSubscription>(
                        value: sub,
                        child: Text('${sub.franchiseId} (${sub.status})'),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedSub = val),
            );
          },
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<PlatformPlan>>(
          future: _subscriptionService.getAllPlatformPlans(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }

            final plans = snapshot.data!;
            return DropdownButtonFormField<PlatformPlan>(
              value: plans.any((p) => p.id == _selectedPlan?.id)
                  ? _selectedPlan
                  : null,
              decoration: InputDecoration(
                labelText: loc.selectPlan,
                border: const OutlineInputBorder(),
              ),
              items: plans
                  .map((plan) => DropdownMenuItem(
                        value: plan,
                        child: Text('${plan.name} (${plan.billingInterval})'),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedPlan = val),
            );
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.swap_horiz),
          label: Text(loc.swap),
          onPressed: _saving ? null : _handleSwap,
        ),
        const SizedBox(height: 20),
        if (_selectedSub != null)
          Text('${loc.franchiseIdLabel}: ${_selectedSub!.franchiseId}'),
        // 💡 Future: Show before/after plan snapshot diff or audit trail
      ],
    );
  }
}
