// lib/core/utils/onboarding_navigation_utils.dart
//
// Navigation utilities for the Onboarding flow.
// Keeps routing keys, arguments, and normalization consistent.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show VisibleForTesting;
import '../../../../packages/shared_core/lib/src/core/models/onboarding_validation_issue.dart';

/// Canonical argument keys used across onboarding routes.
class OnboardingNavKeys {
  OnboardingNavKeys._();

  static const section = 'section';
  static const sectionKey = 'sectionKey';
  static const focusItemId = 'focusItemId';
  static const locator = 'locator';
  static const focusFields = 'focusFields';
  static const legacyItemId = 'itemId';
  static const legacyIngredientId = 'ingredientId';
  static const createMode = 'createMode';
  static const highlight = 'highlight';
  static const severity = 'severity';
  static const message = 'message';
}

/// Human-readable section labels shown in UI.
class OnboardingSections {
  OnboardingSections._();

  static const features = 'Features';
  static const ingredientTypes = 'Ingredient Types';
  static const ingredients = 'Ingredients';
  static const categories = 'Categories';
  static const menuItems = 'Menu Items';
  static const reviewPublish = 'Review & Publish';

  static const all = <String>[
    features,
    ingredientTypes,
    ingredients,
    categories,
    menuItems,
    reviewPublish,
  ];
}

/// Mapping between human-facing names/aliases and internal dashboard keys.
const Map<String, String> _sectionKeyMap = {
  // Internal routing keys
  'onboardingmenu': 'onboardingMenu',
  'onboardingfeaturesetup': 'onboarding_feature_setup',
  'onboardingingredienttypes': 'onboardingIngredientTypes',
  'onboardingingredients': 'onboardingIngredients',
  'onboardingcategories': 'onboardingCategories',
  'onboardingmenuitems': 'onboardingMenuItems',
  'onboardingreview': 'onboardingReview',

  // Aliases
  'features': 'onboarding_feature_setup',
  'feature setup': 'onboarding_feature_setup',
  'ingredienttypes': 'onboardingIngredientTypes',
  'ingredient types': 'onboardingIngredientTypes',
  'ingredients': 'onboardingIngredients',
  'categories': 'onboardingCategories',
  'menuitems': 'onboardingMenuItems',
  'menu items': 'onboardingMenuItems',
  'review': 'onboardingReview',
  'review&publish': 'onboardingReview',
  'overview': 'onboardingMenu',
};

String _dashboardSectionRoute(String sectionKey) =>
    '/dashboard?section=$sectionKey';

/// Container for parsed onboarding navigation context.
class OnboardingNavContext {
  final String? section;
  final String? sectionKey;
  final String? focusItemId;
  final String? locator;
  final List<String> focusFields;
  final bool? createMode;
  final bool? highlight;
  final String? severity;
  final String? message;

  const OnboardingNavContext({
    this.section,
    this.sectionKey,
    this.focusItemId,
    this.locator,
    this.focusFields = const [],
    this.createMode,
    this.highlight,
    this.severity,
    this.message,
  });

  Map<String, dynamic> toArgs() {
    final map = <String, dynamic>{};

    if (_isNonEmpty(section)) map[OnboardingNavKeys.section] = section;
    if (_isNonEmpty(sectionKey)) map[OnboardingNavKeys.sectionKey] = sectionKey;

    if (_isNonEmpty(focusItemId)) {
      map[OnboardingNavKeys.focusItemId] = focusItemId;
      if (section == OnboardingSections.ingredients) {
        map[OnboardingNavKeys.legacyIngredientId] = focusItemId;
      } else {
        map[OnboardingNavKeys.legacyItemId] = focusItemId;
      }
    }

    if (_isNonEmpty(locator)) {
      map[OnboardingNavKeys.locator] = locator;
    }

    if (focusFields.isNotEmpty) {
      map[OnboardingNavKeys.focusFields] = List<String>.from(focusFields);
    }

    if (createMode != null) {
      map[OnboardingNavKeys.createMode] = createMode;
    }

    if (highlight != null) {
      map[OnboardingNavKeys.highlight] = highlight;
    }

    if (_isNonEmpty(severity)) map[OnboardingNavKeys.severity] = severity;
    if (_isNonEmpty(message)) map[OnboardingNavKeys.message] = message;

    return map;
  }
}

class OnboardingNavigationUtils {
  /// Build navigation arguments from section and issue.
  static Map<String, dynamic> buildOnboardingNavArgs({
    required String section,
    required OnboardingValidationIssue issue,
  }) {
    final normalizedSection = _normalizeSection(section);
    final sectionKey = _sectionKeyMap[normalizedSection] ?? normalizedSection;

    final ctx = OnboardingNavContext(
      section: normalizedSection,
      sectionKey: sectionKey,
      focusItemId: _pickFocusItemId(issue),
      locator: _pickLocator(issue),
      focusFields: List<String>.from(issue.affectedFields),
      createMode: _deriveCreateMode(issue),
      highlight: true,
      severity: _stringifySeverity(issue.severity),
      message: _emptyToNull(issue.message),
    );

    final args = ctx.toArgs();

    if (!_isNonEmpty(args[OnboardingNavKeys.legacyItemId]) &&
        !_isNonEmpty(args[OnboardingNavKeys.legacyIngredientId]) &&
        _isNonEmpty(ctx.focusItemId)) {
      args[OnboardingNavKeys.legacyItemId] = ctx.focusItemId;
    }

    if (!_isNonEmpty(ctx.focusItemId) && ctx.createMode != true) {
      args[OnboardingNavKeys.highlight] = false;
    }

    debugPrint(
      '[OnboardingNavigationUtils] buildOnboardingNavArgs → section="$section" normalized="$normalizedSection" args=$args',
    );

    return Map<String, dynamic>.unmodifiable(args);
  }

  /// Resolve a dashboard route from a raw section name or key.
  static String resolveRoute(String section, OnboardingValidationIssue? issue) {
    final normalizedSection = _normalizeSection(section);
    debugPrint(
        '[OnboardingNavigationUtils] resolveRoute: input="$section" normalized="$normalizedSection"');

    switch (normalizedSection) {
      case 'onboardingMenu':
        return _dashboardSectionRoute('onboardingMenu');
      case 'onboarding_feature_setup':
        return _dashboardSectionRoute('onboarding_feature_setup');
      case 'onboardingIngredientTypes':
        return _dashboardSectionRoute('onboardingIngredientTypes');
      case 'onboardingIngredients':
        return _dashboardSectionRoute('onboardingIngredients');
      case 'onboardingCategories':
        return _dashboardSectionRoute('onboardingCategories');
      case 'onboardingMenuItems':
        return _dashboardSectionRoute('onboardingMenuItems');
      case 'onboardingReview':
        return _dashboardSectionRoute('onboardingReview');
      default:
        debugPrint(
            '[OnboardingNavigationUtils][WARN] No mapping for normalizedSection="$normalizedSection"');
        return '';
    }
  }

  /// Public wrapper to normalize a section string for routing.
  /// Converts human-friendly names (e.g., "Ingredients") to
  /// dashboard routing keys (e.g., "onboardingIngredients").
  /// Safe to call from any UI or provider code before calling resolveRoute().
  static String normalizeForRouting(String section) {
    return _normalizeSection(section);
  }
}

/// --- Internal helpers ---
String _normalizeSection(String section) {
  final trimmedLower = section.trim().toLowerCase();
  return _sectionKeyMap[trimmedLower] ?? section.trim();
}

String? _pickFocusItemId(OnboardingValidationIssue issue) =>
    _emptyToNull(issue.itemId);

String? _pickLocator(OnboardingValidationIssue issue) =>
    _emptyToNull(issue.itemLocator);

bool _deriveCreateMode(OnboardingValidationIssue issue) {
  if (_isNonEmpty(issue.itemId)) return false;
  final label = _emptyToNull(issue.actionLabel)?.toLowerCase() ?? '';
  return label.contains('add') ||
      label.contains('create') ||
      label.contains('new');
}

String? _emptyToNull(String? v) {
  if (v == null) return null;
  final s = v.trim();
  return s.isEmpty ? null : s;
}

bool _isNonEmpty(Object? v) {
  if (v == null) return false;
  if (v is String) return v.trim().isNotEmpty;
  return true;
}

String? _stringifySeverity(OnboardingIssueSeverity? s) {
  switch (s) {
    case OnboardingIssueSeverity.critical:
      return 'critical';
    case OnboardingIssueSeverity.warning:
      return 'warning';
    case OnboardingIssueSeverity.info:
      return 'info';
    default:
      return null;
  }
}
