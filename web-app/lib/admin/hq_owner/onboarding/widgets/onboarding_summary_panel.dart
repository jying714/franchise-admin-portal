import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// Minimal HQ onboarding summary placeholder (MVP).
class OnboardingSummaryPanel extends StatelessWidget {
  const OnboardingSummaryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              'Step progress is shown on the HQ dashboard and in the shell sidebar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DesignTokens.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
