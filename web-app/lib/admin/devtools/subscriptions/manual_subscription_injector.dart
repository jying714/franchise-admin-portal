import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;

class ManualSubscriptionInjector extends StatefulWidget {
  const ManualSubscriptionInjector({super.key});

  @override
  State<ManualSubscriptionInjector> createState() =>
      _ManualSubscriptionInjectorState();
}

class _ManualSubscriptionInjectorState
    extends State<ManualSubscriptionInjector> {
  String? selectedFranchiseId;
  shared.PlatformPlan? selectedPlan;
  String status = 'active';
  bool isSubmitting = false;

  late Future<List<shared.PlatformPlan>> platformPlansFuture;

  @override
  void initState() {
    super.initState();
    platformPlansFuture = Provider.of<shared.FranchiseSubscriptionService>(
      context,
      listen: false,
    ).getPlatformPlans();
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;

    if (selectedFranchiseId == null || selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.pleaseSelectFranchiseAndPlan),
      ));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final service = Provider.of<shared.FranchiseSubscriptionService>(
        context,
        listen: false,
      );

      await service.subscribeFranchiseToPlan(
        franchiseId: selectedFranchiseId!,
        plan: selectedPlan!,
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.subscriptionInjectionSuccess),
      ));
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Manual Subscription Injection Failed',
        stack: stack.toString(),
        source: 'ManualSubscriptionInjector',
        severity: 'error',
        contextData: {
          'franchiseId': selectedFranchiseId,
          'planId': selectedPlan?.id,
          'error': e.toString(),
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${loc.subscriptionInjectionFailed}: $e'),
      ));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final franchises =
        context.watch<shared.FranchiseProvider>().viewableFranchises ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.manualSubscriptionInjectorTitle,
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedFranchiseId,
          decoration: InputDecoration(labelText: loc.selectFranchise),
          items: franchises.map((f) {
            return DropdownMenuItem<String>(
              value: f.id,
              child: Text('${f.name} (${f.id})'),
            );
          }).toList(),
          onChanged: (val) => setState(() => selectedFranchiseId = val),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<shared.PlatformPlan>>(
          future: platformPlansFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }
            final plans = snapshot.data ?? [];
            return DropdownButtonFormField<shared.PlatformPlan>(
              value: selectedPlan,
              decoration: InputDecoration(labelText: loc.selectPlan),
              items: plans.map((plan) {
                return DropdownMenuItem<shared.PlatformPlan>(
                  value: plan,
                  child: Text(
                      '${plan.name} (${plan.billingInterval}, \$${plan.price})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedPlan = val),
            );
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: status,
          decoration: InputDecoration(labelText: loc.selectStatus),
          items: ['active', 'trial', 'paused']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) => setState(() => status = val ?? 'active'),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(loc.injectSubscription),
          onPressed: isSubmitting ? null : _submit,
        ),
      ],
    );
  }
}
