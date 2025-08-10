// lib/core/utils/onboarding_navigation_utils.dart

import 'package:franchise_admin_portal/core/models/onboarding_validation_issue.dart';

/// Builds a unified argument map for deep-linking from onboarding issue lists.
/// Ensures all screens get consistent keys for scroll/highlight and context.
Map<String, dynamic> buildOnboardingNavArgs({
  required String section,
  required OnboardingValidationIssue issue,
}) {
  final Map<String, dynamic> args = {};

  // Always pass section for context
  args['section'] = section;

  // Main scroll/highlight target
  if (issue.itemId.isNotEmpty) {
    args['focusItemId'] = issue.itemId;

    // Backward compatibility for older screens
    if (section == 'Ingredients') {
      args['ingredientId'] = issue.itemId;
    } else {
      args['itemId'] = issue.itemId;
    }
  } else if (issue.itemLocator != null && issue.itemLocator!.isNotEmpty) {
    // Fallback to locator if no ID
    args['focusItemId'] = issue.itemLocator;
  }

  // Pass locator if present
  if (issue.itemLocator != null && issue.itemLocator!.isNotEmpty) {
    args['locator'] = issue.itemLocator;
  }

  // Pass affected fields
  if (issue.affectedFields.isNotEmpty) {
    args['focusFields'] = issue.affectedFields;
  }

  // Special creation mode
  if (issue.itemId.isEmpty &&
      (issue.actionLabel ?? '').toLowerCase().contains('add')) {
    args['createMode'] = true;
  }

  return args;
}
