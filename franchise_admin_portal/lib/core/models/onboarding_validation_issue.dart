// File: lib/core/models/onboarding_validation_issue.dart

import 'package:flutter/material.dart';

/// Represents a single validation issue found during onboarding review.
/// Used by all onboarding providers (ingredient types, ingredients, categories, menu items, etc.)
/// and surfaced in the review/publish screen.
class OnboardingValidationIssue {
  /// The onboarding section or domain where this issue was found.
  /// Example values: 'Features', 'Ingredient Types', 'Ingredients', 'Categories', 'Menu Items'
  final String section;

  /// The unique ID of the affected item, if applicable (ingredientId, typeId, categoryId, menuItemId, etc).
  /// Empty if the issue is at the section or global level.
  final String itemId;

  /// Human-friendly display name for the affected item (e.g. 'Mozzarella Cheese', 'Deluxe Pizza').
  /// Used for error details and UI highlighting.
  final String itemDisplayName;

  /// The criticality/severity of the issue:
  /// 'critical' = blocks publish, 'warning' = advisory but not blocking, 'info' = for completeness.
  final OnboardingIssueSeverity severity;

  /// A unique error/warning code for analytics or programmatic handling (e.g., 'MISSING_TYPE', 'DUPLICATE_NAME').
  final String code;

  /// Human-readable, localized message explaining the problem.
  /// Example: "Ingredient 'Mozzarella Cheese' has no assigned type."
  final String message;

  /// Which field(s) are missing/invalid (e.g. 'type', 'sizePrices').
  /// Used for auto-focus or deep linking in forms.
  final List<String> affectedFields;

  /// If true, this issue must be resolved before allowing publish.
  final bool isBlocking;

  /// The route or onboarding step key this issue is associated with (for navigation).
  /// Example: '/onboarding/ingredients', '/onboarding/menu_items'
  final String fixRoute;

  /// (Optional) The index, list position, or deep reference to auto-scroll/highlight in the UI.
  /// Example: row index, group name, or JSON path.
  final String? itemLocator;

  /// Localized tooltip or guidance for how to resolve the issue (can be empty).
  final String? resolutionHint;

  /// Optional quick-fix action label, e.g. 'Fix Now', 'Auto-Assign', 'Go to Step'.
  final String? actionLabel;

  /// Optional icon to represent the issue type (for UI/status table).
  final IconData? icon;

  /// Optional time the issue was detected (useful for audit trail/history).
  final DateTime? detectedAt;

  /// Optionally, extra context for debugging/logging (raw object, Firestore path, etc).
  final Map<String, dynamic>? contextData;

  /// (Optional) Whether the issue was auto-fixed or acknowledged (for warning/info issues).
  final bool acknowledged;

  // Constructor
  const OnboardingValidationIssue({
    required this.section,
    required this.itemId,
    required this.itemDisplayName,
    required this.severity,
    required this.code,
    required this.message,
    required this.affectedFields,
    required this.isBlocking,
    required this.fixRoute,
    this.itemLocator,
    this.resolutionHint,
    this.actionLabel,
    this.icon,
    this.detectedAt,
    this.contextData,
    this.acknowledged = false,
  });
}

/// Enum for strict typing of issue severity.
/// All logic and UI should respect these tiers.
enum OnboardingIssueSeverity {
  critical, // blocks publish
  warning, // shown, but doesn't block publish
  info, // surfaced for user awareness only
}
