import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

/// Minimal HQ onboarding summary placeholder (MVP).
class OnboardingSummaryPanel extends StatelessWidget {
  const OnboardingSummaryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = Provider.of<shared.OnboardingProgressProvider>(context);
    const keys = <String>[
      'onboarding_feature_setup',
      'onboarding_menu_foundation',
      'onboardingMenuItems',
      'onboardingReview',
    ];
    final completed =
        keys.where((String key) => progress.isStepComplete(key)).length;
    return Card(
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Onboarding summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$completed/4 steps complete',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
