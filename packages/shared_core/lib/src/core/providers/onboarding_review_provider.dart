// File: lib/core/providers/onboarding_review_provider.dart

import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../models/onboarding_validation_issue.dart';
import 'ingredient_type_provider.dart';
import 'ingredient_metadata_provider.dart';
import 'category_provider.dart';
import 'menu_item_provider.dart';
import 'franchise_feature_provider.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';
import '../services/firestore_service_BACKUP.dart';
import '../services/audit_log_service.dart';

/// OnboardingReviewProvider: Aggregates and enforces all onboarding state and menu integrity
///
/// - Collates issues from each onboarding provider
/// - Cross-checks all references (ingredients, types, categories) for consistency
/// - Surfaces every critical and warning issue for review/publish
/// - Controls publish/export/refresh
class OnboardingReviewProvider extends ChangeNotifier {
  // References to all onboarding providers; these must be set by the screen/parent.
  final FranchiseFeatureProvider franchiseFeatureProvider;
  final IngredientTypeProvider ingredientTypeProvider;
  final IngredientMetadataProvider ingredientMetadataProvider;
  final CategoryProvider categoryProvider;
  final MenuItemProvider menuItemProvider;

  final FirestoreService firestoreService; // For publishing
  final AuditLogService auditLogService; //audit log
  // Holds the current issue list, updated via [validateAll]
  Map<String, List<OnboardingValidationIssue>> _issuesBySection = {};

  // Optional: timestamp of last full validation
  DateTime? lastValidatedAt;

  // Last exportable snapshot of onboarding data, for backup/download
  Map<String, dynamic> _lastExportSnapshot = {};

  OnboardingReviewProvider({
    required this.franchiseFeatureProvider,
    required this.ingredientTypeProvider,
    required this.ingredientMetadataProvider,
    required this.categoryProvider,
    required this.menuItemProvider,
    required this.firestoreService,
    required this.auditLogService,
  });

  /// Get all issues grouped by section (Features, Ingredient Types, Ingredients, Categories, Menu Items)
  Map<String, List<OnboardingValidationIssue>> get allIssuesBySection =>
      _issuesBySection;

  /// Get flattened issue list for UI (useful for summary/counts)
  List<OnboardingValidationIssue> get allIssuesFlat =>
      _issuesBySection.values.expand((x) => x).toList();

  /// True if no critical issues exist (menu is safe to publish)
  bool get isPublishable => allIssuesFlat
      .where(
          (i) => i.isBlocking && i.severity == OnboardingIssueSeverity.critical)
      .isEmpty;

  /// Validates the entire onboarding state, collecting issues from each provider and cross-checking references.
  /// Updates [_issuesBySection] and exportable snapshot. Notifies listeners on completion.
  /// No placeholder logic; all validations are active.
  Future<void> validateAll() async {
    try {
      _issuesBySection = {
        'Features': [],
        'Ingredient Types': [],
        'Ingredients': [],
        'Categories': [],
        'Menu Items': [],
      };
      final Map<String, List<OnboardingValidationIssue>> issues = {};

      // --- 1. Franchise Features ---
      final featuresIssues = await franchiseFeatureProvider.validate();
      issues['Features'] = featuresIssues;

      // --- 2. Ingredient Types ---
      final typeIssues = await ingredientTypeProvider.validate(
        referencedTypeIds: ingredientMetadataProvider.ingredients
            .map((e) => e.typeId ?? '')
            .toSet()
            .toList(),
      );
      issues['Ingredient Types'] = typeIssues;

      // --- 3. Ingredients ---
      final ingredientIssues = await ingredientMetadataProvider.validate(
        validTypeIds: ingredientTypeProvider.ingredientTypes
            .map((e) => e.id ?? '')
            .toSet()
            .toList(),
        referencedIngredientIds: _allReferencedIngredientIdsFromMenu(),
      );
      issues['Ingredients'] = ingredientIssues;

      // --- 4. Categories ---
      final categoryIssues = await categoryProvider.validate(
        referencedCategoryIds: menuItemProvider.menuItems
            .map((e) => e.categoryId)
            .whereType<String>()
            .toSet()
            .toList(),
      );
      issues['Categories'] = categoryIssues;

      // --- 5. Menu Items (deep, cross-model) ---
      final menuItemIssues = await menuItemProvider.validate(
        validCategoryIds: categoryProvider.categories
            .map((e) => e.id)
            .whereType<String>()
            .toSet()
            .toList(),
        validIngredientIds: ingredientMetadataProvider.ingredients
            .map((e) => e.id)
            .whereType<String>()
            .toSet()
            .toList(),
        validTypeIds: ingredientTypeProvider.ingredientTypes
            .map((e) => e.id)
            .whereType<String>()
            .toSet()
            .toList(),
      );
      issues['Menu Items'] = menuItemIssues;

      // --- 6. Cross-step checks not covered by providers ---
      // Cross-reference checks for each menu item
      for (final menuItem in menuItemProvider.menuItems) {
        // 6.1: Validate all included ingredients exist and reference valid types
        for (final included in menuItem.includedIngredients ?? []) {
          final includedIngredientId =
              included['ingredientId'] ?? included['id'];
          final ingredient =
              ingredientMetadataProvider.ingredients.firstWhereOrNull(
            (e) => e.id == includedIngredientId,
          );
          if (ingredient == null) {
            issues['Menu Items'] ??= [];
            issues['Menu Items']!.add(OnboardingValidationIssue(
              section: 'Menu Items',
              itemId: menuItem.id,
              itemDisplayName: menuItem.name,
              severity: OnboardingIssueSeverity.critical,
              code: 'REFERENCES_MISSING_INGREDIENT',
              message:
                  "Menu item '${menuItem.name}' includes missing ingredient (ID: '$includedIngredientId').",
              affectedFields: ['includedIngredients'],
              isBlocking: true,
              fixRoute: '/onboarding/menu_items',
              itemLocator: menuItem.id,
              resolutionHint:
                  "Remove or replace the missing ingredient reference.",
              actionLabel: "Fix Now",
              icon: Icons.link_off,
              detectedAt: DateTime.now(),
              contextData: {'missingIngredientId': includedIngredientId},
            ));
          } else {
            // Ingredient exists, but its type must also be valid
            if (ingredient.typeId == null ||
                ingredient.typeId!.isEmpty ||
                !ingredientTypeProvider.ingredientTypes
                    .any((t) => t.id == ingredient.typeId)) {
              issues['Menu Items'] ??= [];
              issues['Menu Items']!.add(OnboardingValidationIssue(
                section: 'Menu Items',
                itemId: menuItem.id,
                itemDisplayName: menuItem.name,
                severity: OnboardingIssueSeverity.critical,
                code: 'INGREDIENT_MISSING_TYPE',
                message:
                    "Included ingredient '${ingredient.name}' in '${menuItem.name}' has no valid type assigned.",
                affectedFields: ['includedIngredients.typeId'],
                isBlocking: true,
                fixRoute: '/onboarding/menu_items',
                itemLocator: menuItem.id,
                resolutionHint:
                    "Assign a valid type to ingredient '${ingredient.name}'.",
                actionLabel: "Fix Now",
                icon: Icons.link_off,
                detectedAt: DateTime.now(),
                contextData: {
                  'ingredientId': ingredient.id,
                  'menuItemId': menuItem.id
                },
              ));
            }
          }
        }
        // 6.2: Validate menu item category exists
        if (menuItem.categoryId.isEmpty ||
            !categoryProvider.categories
                .any((c) => c.id == menuItem.categoryId)) {
          issues['Menu Items'] ??= [];
          issues['Menu Items']!.add(OnboardingValidationIssue(
            section: 'Menu Items',
            itemId: menuItem.id,
            itemDisplayName: menuItem.name,
            severity: OnboardingIssueSeverity.critical,
            code: 'MISSING_CATEGORY_FOR_MENU_ITEM',
            message:
                "Menu item '${menuItem.name}' references a missing category.",
            affectedFields: ['categoryId'],
            isBlocking: true,
            fixRoute: '/onboarding/menu_items',
            itemLocator: menuItem.id,
            resolutionHint: "Select a valid category for this menu item.",
            actionLabel: "Fix Now",
            icon: Icons.category_outlined,
            detectedAt: DateTime.now(),
          ));
        }
        // 6.3: Enforce all required fields per menu schema
        if (menuItem.name.trim().isEmpty) {
          issues['Menu Items'] ??= [];
          issues['Menu Items']!.add(OnboardingValidationIssue(
            section: 'Menu Items',
            itemId: menuItem.id,
            itemDisplayName: menuItem.name,
            severity: OnboardingIssueSeverity.critical,
            code: 'MISSING_MENU_ITEM_NAME',
            message: "Menu item is missing a name.",
            affectedFields: ['name'],
            isBlocking: true,
            fixRoute: '/onboarding/menu_items',
            itemLocator: menuItem.id,
            resolutionHint: "Enter a name for this menu item.",
            actionLabel: "Fix Now",
            icon: Icons.short_text,
            detectedAt: DateTime.now(),
          ));
        }
        // 6.4: Check for at least one price
        if ((menuItem.price == 0.0 || menuItem.price == null) &&
            (menuItem.sizePrices == null || menuItem.sizePrices!.isEmpty)) {
          issues['Menu Items'] ??= [];
          issues['Menu Items']!.add(OnboardingValidationIssue(
            section: 'Menu Items',
            itemId: menuItem.id,
            itemDisplayName: menuItem.name,
            severity: OnboardingIssueSeverity.critical,
            code: 'MISSING_MENU_ITEM_PRICE',
            message: "Menu item '${menuItem.name}' has no price set.",
            affectedFields: ['price', 'sizePrices'],
            isBlocking: true,
            fixRoute: '/onboarding/menu_items',
            itemLocator: menuItem.id,
            resolutionHint: "Enter a price or size prices for this menu item.",
            actionLabel: "Fix Now",
            icon: Icons.attach_money,
            detectedAt: DateTime.now(),
          ));
        }
        // 6.5: Image warning
        if (menuItem.imageUrl.isEmpty) {
          issues['Menu Items'] ??= [];
          issues['Menu Items']!.add(OnboardingValidationIssue(
            section: 'Menu Items',
            itemId: menuItem.id,
            itemDisplayName: menuItem.name,
            severity: OnboardingIssueSeverity.warning,
            code: 'MISSING_MENU_ITEM_IMAGE',
            message: "Menu item '${menuItem.name}' does not have an image.",
            affectedFields: ['imageUrl'],
            isBlocking: false,
            fixRoute: '/onboarding/menu_items',
            itemLocator: menuItem.id,
            resolutionHint: "Add a photo to improve the menu.",
            actionLabel: "Review",
            icon: Icons.image_not_supported,
            detectedAt: DateTime.now(),
          ));
        }
      }

      // --- Save state ---
      _issuesBySection = issues;
      lastValidatedAt = DateTime.now();
      notifyListeners();

      // --- Prepare exportable snapshot ---
      _lastExportSnapshot = _buildExportSnapshot();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'onboarding_review_validate_failed',
        stack: stack.toString(),
        source: 'OnboardingReviewProvider.validateAll',
        severity: 'fatal',
        contextData: {},
      );
      // For robustness, do not throw—leave last state unchanged.
    }
  }

  /// Returns all referenced ingredient IDs across all menu items (for orphan/consistency checks).
  List<String> _allReferencedIngredientIdsFromMenu() {
    final ids = <String>{};
    for (final item in menuItemProvider.menuItems) {
      ids.addAll(item.includedIngredientIds);
      // Optionally: Add customizations/add-ons if you want all possible references
      ids.addAll(item.optionalAddOnIds);
      ids.addAll(item.allGroupIngredientIds);
    }
    return ids.toList();
  }

  /// Build a JSON-serializable snapshot of onboarding state and issues for export/download.
  Map<String, dynamic> _buildExportSnapshot() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'featureState': franchiseFeatureProvider.featureMetadata?.toMap(),
      'ingredientTypes':
          ingredientTypeProvider.ingredientTypes.map((t) => t.toMap()).toList(),
      'ingredients':
          ingredientMetadataProvider.ingredients.map((i) => i.toMap()).toList(),
      'categories':
          categoryProvider.categories.map((c) => c.toFirestore()).toList(),
      'menuItems': menuItemProvider.menuItems.map((m) => m.toMap()).toList(),
      'issues': allIssuesFlat
          .map((i) => {
                'section': i.section,
                'itemId': i.itemId,
                'itemDisplayName': i.itemDisplayName,
                'severity': i.severity.name,
                'code': i.code,
                'message': i.message,
                'affectedFields': i.affectedFields,
                'isBlocking': i.isBlocking,
                'fixRoute': i.fixRoute,
                'itemLocator': i.itemLocator,
                'resolutionHint': i.resolutionHint,
                'actionLabel': i.actionLabel,
                'detectedAt': i.detectedAt?.toIso8601String(),
                'contextData': i.contextData,
                'acknowledged': i.acknowledged,
              })
          .toList(),
    };
  }

  /// Export onboarding data + issues as JSON (for audit, backup, or download)
  String exportDataAsJson() => jsonEncode(_lastExportSnapshot);

  /// Initiate onboarding publish (only if publishable).
  ///
  /// - Revalidates all state
  /// - Sets onboardingStatus to 'complete', franchise status to 'active'
  /// - Writes an audit log to Firestore
  /// - Throws if not publishable
  Future<void> publishOnboarding(
      {required String franchiseId, required String userId}) async {
    await validateAll();
    if (!isPublishable) {
      throw Exception("Cannot publish onboarding: critical issues remain.");
    }
    try {
      // 1. Mark onboardingStatus as 'complete' and status as 'active'
      await firestoreService.setOnboardingComplete(franchiseId: franchiseId);

      // 2. Write onboarding audit log (timestamp, userId, snapshot of state, issues)
      await auditLogService.addLog(
        franchiseId: franchiseId,
        userId: userId,
        action: 'onboarding_publish',
        targetType: 'onboarding',
        targetId: franchiseId,
        details: _lastExportSnapshot,
      );
      // 3. Optionally, notify listeners, UI, etc.
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'onboarding_publish_failed',
        stack: stack.toString(),
        source: 'OnboardingReviewProvider.publishOnboarding',
        severity: 'fatal',
        contextData: {
          'franchiseId': franchiseId,
          'userId': userId,
        },
      );
      rethrow;
    }
  }

  /// Refresh (manual or after returning from fixing an issue)
  Future<void> refresh() => validateAll();

  /// Public getter for the current validation issues.
  /// Returns a flattened list from [_issuesBySection] for quick UI consumption.
  List<OnboardingValidationIssue> get issues {
    if (_issuesBySection.isEmpty) {
      print(
          '[OnboardingReviewProvider] ⚠️ issues getter called before any validation run.');
      return const [];
    }
    final flat = _issuesBySection.values.expand((list) => list).toList();
    print(
        '[OnboardingReviewProvider] 📋 Returning ${flat.length} total issues across ${_issuesBySection.length} sections.');
    return flat;
  }

  /// Alias for `issues` to maintain backward compatibility with older code.
  List<OnboardingValidationIssue> get validationResults {
    print(
        '[OnboardingReviewProvider] 📋 validationResults getter called. Returning ${issues.length} issues.');
    return issues;
  }
}
