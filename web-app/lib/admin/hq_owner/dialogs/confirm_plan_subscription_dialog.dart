import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';

class ConfirmPlanSubscriptionDialog extends StatelessWidget {
  final shared.PlatformPlan plan;
  final String franchiseId;

  const ConfirmPlanSubscriptionDialog({
    super.key,
    required this.plan,
    required this.franchiseId,
  });

  static Future<void> show({
    required BuildContext context,
    required shared.PlatformPlan plan,
    required String franchiseId,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ConfirmPlanSubscriptionDialog(
        plan: plan,
        franchiseId: franchiseId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.dialogBorderRadius),
      ),
      elevation: DesignTokens.adminDialogElevation,
      title: Text(loc.confirmPlanSubscriptionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(plan.description ?? ''),
          const SizedBox(height: 16),
          Text('${loc.billingIntervalLabel}: ${plan.billingInterval}'),
          Text(
              '${loc.priceLabel}: ${plan.price.toStringAsFixed(2)} ${plan.currency}'),
          const SizedBox(height: 16),
          Text(loc.confirmPlanSubscriptionPrompt),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
          ),
          onPressed: () async {
            Navigator.of(context).pop(); // Close dialog immediately

            try {
              final service = Provider.of<shared.FranchiseSubscriptionService>(
                context,
                listen: false,
              );

              await service.subscribeFranchiseToPlan(
                franchiseId: franchiseId,
                plan: plan,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.subscriptionSuccessMessage)),
              );
            } catch (e, st) {
              shared.ErrorLogger.log(
                message: 'Subscription failed: $e',
                stack: st.toString(),
                source: 'ConfirmPlanSubscriptionDialog',
                severity: 'error',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.genericErrorOccurred),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
          },
          child: Text(loc.confirm),
        ),
      ],
    );
  }
}
