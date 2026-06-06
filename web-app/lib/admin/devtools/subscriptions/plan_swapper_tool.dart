import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;

class PlanSwapperTool extends StatefulWidget {
  const PlanSwapperTool({super.key});

  @override
  State<PlanSwapperTool> createState() => _PlanSwapperToolState();
}

class _PlanSwapperToolState extends State<PlanSwapperTool> {
  shared.FranchiseSubscription? _selectedSub;
  shared.PlatformPlan? _selectedPlan;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final subscriptionService =
        Provider.of<shared.FranchiseSubscriptionService>(
      context,
      listen: false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.planSwapperTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        StreamBuilder<List<shared.FranchiseSubscription>>(
          stream: subscriptionService.watchAllFranchiseSubscriptions(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }

            final subs = snapshot.data!;
            return DropdownButtonFormField<shared.FranchiseSubscription>(
              value: _selectedSub,
              decoration: InputDecoration(
                labelText: loc.selectFranchise,
                border: const OutlineInputBorder(),
              ),
              items: subs
                  .map((sub) => DropdownMenuItem<shared.FranchiseSubscription>(
                        value: sub,
                        child: Text('${sub.franchiseId} (${sub.status})'),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedSub = val),
            );
          },
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<shared.PlatformPlan>>(
          future: subscriptionService.getAllPlatformPlans(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }

            final plans = snapshot.data!;
            return DropdownButtonFormField<shared.PlatformPlan>(
              value: _selectedPlan,
              decoration: InputDecoration(
                labelText: loc.selectPlan,
                border: const OutlineInputBorder(),
              ),
              items: plans
                  .map((plan) => DropdownMenuItem<shared.PlatformPlan>(
                        value: plan,
                        child: Text(
                            '${plan.name} (${plan.billingInterval}, \$${plan.price})'),
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
      ],
    );
  }

  Future<void> _handleSwap() async {
    if (_selectedSub == null || _selectedPlan == null) return;

    setState(() => _saving = true);
    final loc = AppLocalizations.of(context)!;

    try {
      final service = Provider.of<shared.FranchiseSubscriptionService>(
        context,
        listen: false,
      );

      await service.subscribeFranchiseToPlan(
        franchiseId: _selectedSub!.franchiseId,
        plan: _selectedPlan!,
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.genericSavedSuccess),
      ));

      setState(() {
        _selectedSub = null;
        _selectedPlan = null;
      });
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to swap plan: $e',
        stack: stack.toString(),
        source: 'PlanSwapperTool',
        severity: 'error',
        contextData: {
          'franchiseId': _selectedSub?.franchiseId,
          'newPlanId': _selectedPlan?.id,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${loc.subscriptionInjectionFailed}: $e'),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
