import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/src/core/services/firestore_service.dart';
import 'package:shared_core/src/core/models/platform_plan_model.dart';
import 'package:shared_core/src/core/providers/franchise_provider.dart';
import 'package:shared_core/src/core/services/franchise_subscription_service.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

class ManualSubscriptionInjector extends StatefulWidget {
  const ManualSubscriptionInjector({super.key});

  @override
  State<ManualSubscriptionInjector> createState() =>
      _ManualSubscriptionInjectorState();
}

class _ManualSubscriptionInjectorState
    extends State<ManualSubscriptionInjector> {
  String? selectedFranchiseId;
  PlatformPlan? selectedPlan;
  String status = 'active'; // active | trial | paused
  bool isSubmitting = false;

  late Future<List<PlatformPlan>> platformPlansFuture;

  @override
  void initState() {
    super.initState();
    platformPlansFuture = FranchiseSubscriptionService().getPlatformPlans();
  }

  Future<void> _submit(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (selectedFranchiseId == null || selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.pleaseSelectFranchiseAndPlan),
        backgroundColor: colorScheme.error,
      ));
      return;
    }

    setState(() => isSubmitting = true);
    final service = FranchiseSubscriptionService();

    try {
      await service.subscribeFranchiseToPlan(
        franchiseId: selectedFranchiseId!,
        plan: selectedPlan!,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.subscriptionInjectionSuccess),
        backgroundColor: colorScheme.primary,
      ));
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Manual Subscription Injection Failed',
        stack: stack.toString(),
        source: 'ManualSubscriptionInjector',
        screen: 'manual_subscription_injector.dart',
        severity: 'error',
        contextData: {
          'franchiseId': selectedFranchiseId,
          'planId': selectedPlan?.id,
          'error': e.toString(),
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${loc.subscriptionInjectionFailed}: $e'),
        backgroundColor: colorScheme.error,
      ));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final franchiseProvider = context.watch<FranchiseProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final franchises = franchiseProvider.viewableFranchises ?? [];

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
        FutureBuilder<List<PlatformPlan>>(
          future: platformPlansFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }
            final plans = snapshot.data ?? [];
            return DropdownButtonFormField<PlatformPlan>(
              value: selectedPlan,
              decoration: InputDecoration(labelText: loc.selectPlan),
              items: plans.map((plan) {
                return DropdownMenuItem<PlatformPlan>(
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
          onPressed: isSubmitting ? null : () => _submit(context),
        ),
        const SizedBox(height: 20),
        // ðŸ’¡ Future: support custom startDate or backdating UI here
      ],
    );
  }
}


