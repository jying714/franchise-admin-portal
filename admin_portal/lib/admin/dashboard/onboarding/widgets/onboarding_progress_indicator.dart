// File: lib/admin/dashboard/onboarding/widgets/onboarding_progress_indicator.dart

import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// A polished, responsive onboarding progress indicator for stepper-based flows.
/// - Shows the current step number, total steps, and an optional custom label.
/// - Styled to match Franchise Admin Portal's onboarding screens.
class OnboardingProgressIndicator extends StatelessWidget {
  /// The 1-based index of the current step (e.g., 2 for "Step 2 of 6").
  final int currentStep;

  /// The total number of steps in the onboarding flow.
  final int totalSteps;

  /// Optional: Custom label to display (e.g., "Step 2 of 6" or "Menu Setup").
  /// If null, displays "Step X of Y".
  final String? stepLabel;

  /// Optional: List of step names for labeled indicator display.
  /// If provided, highlights the current step name.
  final List<String>? stepNames;

  const OnboardingProgressIndicator({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabel,
    this.stepNames,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveStepLabel = stepLabel ?? 'Step $currentStep of $totalSteps';

    final showStepNames = stepNames != null && stepNames!.length == totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Numeric progress row ("Step 3 of 6")
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Progress circle (primary color, animated)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$currentStep',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  fontFamily: DesignTokens.fontFamily,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Step label ("Step X of Y")
            Text(
              effectiveStepLabel,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                fontFamily: DesignTokens.fontFamily,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 10),
            // Progress bar, if enough width
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: LinearProgressIndicator(
                  value: currentStep / totalSteps,
                  backgroundColor: colorScheme.surface.withOpacity(0.21),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                ),
              ),
            ),
          ],
        ),
        // Optional: Step name row (e.g. ["Features", "Ingredient Types", ...])
        if (showStepNames) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stepNames!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 18),
              itemBuilder: (context, i) {
                final isCurrent = (i + 1) == currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? colorScheme.primary.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    stepNames![i],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.67),
                      letterSpacing: 0.15,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
