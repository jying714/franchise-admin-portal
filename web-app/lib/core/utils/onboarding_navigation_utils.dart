// web-app/lib/core/utils/onboarding_navigation_utils.dart
//
// Navigation utilities for the Onboarding flow (updated for 4-Step structure).

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

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

/// Human-readable section labels shown in UI (updated for 4 steps).
class OnboardingSections {
  OnboardingSections._();

  static const features = 'Features';
  static const coreMenuFoundation = 'Core Menu Foundation';
  static const menuItems = 'Menu Items';
  static const reviewPublish = 'Review & Publish';

  static const all = <String>[
    features,
    coreMenuFoundation,
    menuItems,
    reviewPublish,
  ];
}

/// Mapping between human-facing names/aliases and internal dashboard keys (4-step).
const Map<String, String> _sectionKeyMap = {
  // Internal registry keys
  'onboardingmenu': 'onboardingMenu',
  'onboarding_feature_setup': 'onboarding_feature_setup',
  'onboarding_menu_foundation': 'onboarding_menu_foundation',
  'onboardingmenuitems': 'onboardingMenuItems',
  'onboardingreview': 'onboardingReview',

  // Human / alias variants
  'features': 'onboarding_feature_setup',
  'feature setup': 'onboarding_feature_setup',
  'core menu foundation': 'onboarding_menu_foundation',
  'foundation': 'onboarding_menu_foundation',
  'menu foundation': 'onboarding_menu_foundation',
  'menuitems': 'onboardingMenuItems',
  'menu items': 'onboardingMenuItems',
  'review': 'onboardingReview',
  'review & publish': 'onboardingReview',
  'overview': 'onboardingMenu',
};

String _dashboardSectionRoute(String sectionKey) =>
    '/dashboard?section=$sectionKey';

/// Container for parsed onboarding navigation context (unchanged).
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
      if (section == OnboardingSections.menuItems) {
        map[OnboardingNavKeys.legacyItemId] = focusItemId;
      } else if (section?.toLowerCase().contains('ingredient') == true) {
        map[OnboardingNavKeys.legacyIngredientId] = focusItemId;
      }
    }

    if (_isNonEmpty(locator)) map[OnboardingNavKeys.locator] = locator;
    if (focusFields.isNotEmpty)
      map[OnboardingNavKeys.focusFields] = List<String>.from(focusFields);
    if (createMode != null) map[OnboardingNavKeys.createMode] = createMode;
    if (highlight != null) map[OnboardingNavKeys.highlight] = highlight;
    if (_isNonEmpty(severity)) map[OnboardingNavKeys.severity] = severity;
    if (_isNonEmpty(message)) map[OnboardingNavKeys.message] = message;

    return map;
  }
}

class OnboardingNavigationUtils {
  /// Build navigation arguments from section and issue.
  static Map<String, dynamic> buildOnboardingNavArgs({
    required String section,
    required shared.OnboardingValidationIssue issue,
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

  /// Resolve a dashboard route from a raw section name or key (updated for 4 steps).
  static String resolveRoute(
      String section, shared.OnboardingValidationIssue? issue) {
    final normalized = _normalizeSection(section);
    debugPrint(
        '[OnboardingNavigationUtils] resolveRoute: input="$section" → normalized="$normalized"');

    if (normalized.contains('feature') || normalized.contains('setup')) {
      return _dashboardSectionRoute('onboarding_feature_setup');
    }
    if (normalized.contains('foundation') || normalized.contains('core menu')) {
      return _dashboardSectionRoute('onboarding_menu_foundation');
    }
    if (normalized.contains('menuitem') || normalized.contains('items')) {
      return _dashboardSectionRoute('onboardingMenuItems');
    }
    if (normalized.contains('review')) {
      return _dashboardSectionRoute('onboardingReview');
    }
    if (normalized.contains('menu') || normalized.contains('overview')) {
      return _dashboardSectionRoute('onboardingMenu');
    }

    debugPrint('[WARN] No mapping for $normalized - falling back');
    return '/dashboard?section=$normalized';
  }

  static String normalizeForRouting(String section) {
    return _normalizeSection(section);
  }
}

/// --- Internal helpers ---
String _normalizeSection(String section) {
  String s =
      section.trim().toLowerCase().replaceAll('_', '').replaceAll(' ', '');
  return _sectionKeyMap[s] ?? section.trim();
}

String? _pickFocusItemId(shared.OnboardingValidationIssue issue) =>
    _emptyToNull(issue.itemId);

String? _pickLocator(shared.OnboardingValidationIssue issue) =>
    _emptyToNull(issue.itemLocator);

bool _deriveCreateMode(shared.OnboardingValidationIssue issue) {
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

String? _stringifySeverity(shared.OnboardingIssueSeverity? s) {
  switch (s) {
    case shared.OnboardingIssueSeverity.critical:
      return 'critical';
    case shared.OnboardingIssueSeverity.warning:
      return 'warning';
    case shared.OnboardingIssueSeverity.info:
      return 'info';
    default:
      return null;
  }
}
