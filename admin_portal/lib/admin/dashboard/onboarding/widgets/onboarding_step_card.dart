import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/config/design_tokens.dart';

class OnboardingStepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String subtitle;
  final bool completed;
  final VoidCallback onTap;

  const OnboardingStepCard({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    print(
        '[OnboardingStepCard] building: title="$title", subtitle="$subtitle", completed=$completed');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: colorScheme.surface,
        elevation: 1,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepNumberBadge(context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                completed
                    ? Icon(Icons.check_circle_rounded,
                        color: colorScheme.primary, size: 24)
                    : Icon(Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepNumberBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 16,
      backgroundColor: completed
          ? colorScheme.primary.withOpacity(0.85)
          : colorScheme.surfaceVariant,
      child: Text(
        '$stepNumber',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color:
              completed ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
