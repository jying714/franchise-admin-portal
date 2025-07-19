import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/platform_plan_model.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class PlatformPlanCard extends StatelessWidget {
  final PlatformPlan plan;
  final bool isSelected;
  final VoidCallback onSubscribe;

  const PlatformPlanCard({
    Key? key,
    required this.plan,
    required this.isSelected,
    required this.onSubscribe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: plan.active
          ? colorScheme.surface
          : colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Custom Label
            Row(
              children: [
                Text(
                  plan.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: plan.active
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const Spacer(),
                if (plan.isCustom)
                  Chip(
                    label: Text(loc.customPlan),
                    backgroundColor: colorScheme.secondaryContainer,
                  ),
                if (!plan.active)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Chip(
                      label: Text(loc.inactive),
                      backgroundColor: colorScheme.errorContainer,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            if (plan.description.isNotEmpty)
              Text(
                plan.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),

            const SizedBox(height: 14),

            // Price
            Text(
              '\$${plan.price.toStringAsFixed(2)} / ${plan.billingInterval}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),

            const SizedBox(height: 14),

            // Features
            if (plan.includedFeatures.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: plan.includedFeatures
                    .map((feature) => Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: colorScheme.secondary, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                feature,
                                style: textTheme.bodySmall,
                              ),
                            )
                          ],
                        ))
                    .toList(),
              ),

            const SizedBox(height: 20),

            // Subscribe button or Current Plan label
            Align(
              alignment: Alignment.centerRight,
              child: isSelected
                  ? Chip(
                      label: Text(loc.currentPlan),
                      backgroundColor: colorScheme.secondaryContainer,
                      labelStyle: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        try {
                          onSubscribe();
                        } catch (e, stack) {
                          ErrorLogger.log(
                            message: 'Plan subscribe error',
                            stack: stack.toString(),
                            source: 'PlatformPlanCard',
                            screen: 'platform_plan_card',
                            severity: 'error',
                            contextData: {'exception': e.toString()},
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.genericErrorOccurred),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: Text(loc.subscribe),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
