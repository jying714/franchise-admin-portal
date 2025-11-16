// web_app/lib/core/providers/onboarding_review_provider_impl.dart

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'dart:convert';
import 'package:collection/collection.dart';

class OnboardingReviewProviderImpl extends ChangeNotifier
    implements OnboardingReviewProvider {
  final FranchiseFeatureProvider _franchiseFeatureProvider;
  final IngredientTypeProvider _ingredientTypeProvider;
  final IngredientMetadataProvider _ingredientMetadataProvider;
  final CategoryProvider _categoryProvider;
  final MenuItemProvider _menuItemProvider;
  final FirestoreService _firestoreService;
  final AuditLogService _auditLogService;

  Map<String, List<OnboardingValidationIssue>> _issuesBySection = {};
  DateTime? _lastValidatedAt;
  Map<String, dynamic> _lastExportSnapshot = {};

  OnboardingReviewProviderImpl({
    required FranchiseFeatureProvider franchiseFeatureProvider,
    required IngredientTypeProvider ingredientTypeProvider,
    required IngredientMetadataProvider ingredientMetadataProvider,
    required CategoryProvider categoryProvider,
    required MenuItemProvider menuItemProvider,
    required FirestoreService firestoreService,
    required AuditLogService auditLogService,
  })  : _franchiseFeatureProvider = franchiseFeatureProvider,
        _ingredientTypeProvider = ingredientTypeProvider,
        _ingredientMetadataProvider = ingredientMetadataProvider,
        _categoryProvider = categoryProvider,
        _menuItemProvider = menuItemProvider,
        _firestoreService = firestoreService,
        _auditLogService = auditLogService;

  @override
  Map<String, List<OnboardingValidationIssue>> get allIssuesBySection =>
      _issuesBySection;

  @override
  List<OnboardingValidationIssue> get allIssuesFlat =>
      _issuesBySection.values.expand((x) => x).toList();

  @override
  bool get isPublishable => allIssuesFlat
      .where(
          (i) => i.isBlocking && i.severity == OnboardingIssueSeverity.critical)
      .isEmpty;

  @override
  DateTime? get lastValidatedAt => _lastValidatedAt;

  @override
  Map<String, dynamic> get lastExportSnapshot => _lastExportSnapshot;

  @override
  Future<void> validateAll() async {
    try {
      _issuesBySection = {
        'Features': [],
        'Ingredient Types': [],
        'Ingredients': [],
        'Categories': [],
        'Menu Items': [],
      };

      // 1. Franchise Features
      final featuresIssues = await _franchiseFeatureProvider.validate();
      _issuesBySection['Features'] = featuresIssues;

      // 2. Ingredient Types
      final typeIssues = await _ingredientTypeProvider.validate(
        referencedTypeIds: _ingredientMetadataProvider.ingredients
            .map((e) => e.typeId ?? '')
            .toSet()
            .toList(),
      );
      _issuesBySection['Ingredient Types'] = typeIssues;

      // 3. Ingredients
      final ingredientIssues = await _ingredientMetadataProvider.validate(
        validTypeIds: _ingredientTypeProvider.ingredientTypes
            .map((e) => e.id ?? '')
            .toSet()
            .toList(),
        referencedIngredientIds: _allReferencedIngredientIdsFromMenu(),
      );
      _issuesBySection['Ingredients'] = ingredientIssues;

      // 4. Categories
      final categoryIssues = await _categoryProvider.validate(
        referencedCategoryIds: _menuItemProvider.menuItems
            .map((e) => e.categoryId)
            .whereType<String>()
            .toSet()
            .toList(),
      );
      _issuesBySection['Categories'] = categoryIssues;

      // 5. Menu Items
      final menuItemIssues = await _menuItemProvider.validate(
        validCategoryIds: _categoryProvider.categories
            .map((e) => e.id)
            .whereType<String>()
            .toSet()
            .toList(),
        validIngredientIds: _ingredientMetadataProvider.ingredients
            .map((e) => e.id)
            .whereType<String>()
            .toSet()
            .toList(),
        validTypeIds: _ingredientTypeProvider.ingredientTypes
            .map((e) => e.id)
            .whereType<String>()
            .toSet()
            .toList(),
      );
      _issuesBySection['Menu Items'] = menuItemIssues;

      // 6. Cross-checks
      for (final menuItem in _menuItemProvider.menuItems) {
        for (final included in menuItem.includedIngredients ?? []) {
          final ingredientId = included['ingredientId'] ?? included['id'];
          final ingredient = _ingredientMetadataProvider.ingredients
              .firstWhereOrNull((e) => e.id == ingredientId);

          if (ingredient == null) {
            _issuesBySection['Menu Items']!.add(OnboardingValidationIssue(
              section: 'Menu Items',
              itemId: menuItem.id,
              itemDisplayName: menuItem.name,
              severity: OnboardingIssueSeverity.critical,
              code: 'REFERENCES_MISSING_INGREDIENT',
              message:
                  "Menu item '${menuItem.name}' includes missing ingredient (ID: '$ingredientId').",
              affectedFields: ['includedIngredients'],
              isBlocking: true,
              fixRoute: '/onboarding/menu_items',
              itemLocator: menuItem.id,
              resolutionHint:
                  "Remove or replace the missing ingredient reference.",
              actionLabel: "Fix Now",
              icon: Icons.link_off,
              detectedAt: DateTime.now(),
              contextData: {'missingIngredientId': ingredientId},
            ));
          } else if (ingredient.typeId == null ||
              !ingredient.typeId!.isNotEmpty ||
              !_ingredientTypeProvider.ingredientTypes
                  .any((t) => t.id == ingredient.typeId)) {
            _issuesBySection['Menu Items']!.add(OnboardingValidationIssue(
              section: 'Menu Items',
              itemId: menuItem.id,
              itemDisplayName: menuItem.name,
              severity: OnboardingIssueSeverity.critical,
              code: 'INGREDIENT_MISSING_TYPE',
              message:
                  "Included ingredient '${ingredient.name}' in '${menuItem.name}' has no valid type.",
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

        if (menuItem.categoryId.isEmpty ||
            !_categoryProvider.categories
                .any((c) => c.id == menuItem.categoryId)) {
          _issuesBySection['Menu Items']!.add(OnboardingValidationIssue(
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
            resolutionHint: "Select a valid category.",
            actionLabel: "Fix Now",
            icon: Icons.category_outlined,
            detectedAt: DateTime.now(),
          ));
        }

        if (menuItem.name.trim().isEmpty) {
          _issuesBySection['Menu Items']!.add(OnboardingValidationIssue(
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
            resolutionHint: "Enter a name.",
            actionLabel: "Fix Now",
            icon: Icons.short_text,
            detectedAt: DateTime.now(),
          ));
        }

        if ((menuItem.price == 0.0 || menuItem.price == null) &&
            (menuItem.sizePrices == null || menuItem.sizePrices!.isEmpty)) {
          _issuesBySection['Menu Items']!.add(OnboardingValidationIssue(
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
            resolutionHint: "Enter a price or size prices.",
            actionLabel: "Fix Now",
            icon: Icons.attach_money,
            detectedAt: DateTime.now(),
          ));
        }

        if (menuItem.imageUrl.isEmpty) {
          _issuesBySection['Menu Items']!.add(OnboardingValidationIssue(
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
            resolutionHint: "Add a photo.",
            actionLabel: "Review",
            icon: Icons.image_not_supported,
            detectedAt: DateTime.now(),
          ));
        }
      }

      _lastValidatedAt = DateTime.now();
      _lastExportSnapshot = _buildExportSnapshot();
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'onboarding_review_validate_failed',
        stack: stack.toString(),
        source: 'OnboardingReviewProviderImpl.validateAll',
        severity: 'fatal',
        contextData: {},
      );
    }
  }

  List<String> _allReferencedIngredientIdsFromMenu() {
    final ids = <String>{};
    for (final item in _menuItemProvider.menuItems) {
      ids.addAll(item.includedIngredientIds);
      ids.addAll(item.optionalAddOnIds);
      ids.addAll(item.allGroupIngredientIds);
    }
    return ids.toList();
  }

  Map<String, dynamic> _buildExportSnapshot() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'featureState': _franchiseFeatureProvider.featureMetadata?.toMap(),
      'ingredientTypes': _ingredientTypeProvider.ingredientTypes
          .map((t) => t.toMap())
          .toList(),
      'ingredients': _ingredientMetadataProvider.ingredients
          .map((i) => i.toMap())
          .toList(),
      'categories':
          _categoryProvider.categories.map((c) => c.toFirestore()).toList(),
      'menuItems': _menuItemProvider.menuItems.map((m) => m.toMap()).toList(),
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

  @override
  String exportDataAsJson() => jsonEncode(_lastExportSnapshot);

  @override
  Future<void> publishOnboarding(
      {required String franchiseId, required String userId}) async {
    await validateAll();
    if (!isPublishable) {
      throw Exception("Cannot publish onboarding: critical issues remain.");
    }
    try {
      await _firestoreService.setOnboardingComplete(franchiseId: franchiseId);
      await _auditLogService.addLog(
        franchiseId: franchiseId,
        userId: userId,
        action: 'onboarding_publish',
        targetType: 'onboarding',
        targetId: franchiseId,
        details: _lastExportSnapshot,
      );
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'onboarding_publish_failed',
        stack: stack.toString(),
        source: 'OnboardingReviewProviderImpl.publishOnboarding',
        severity: 'fatal',
        contextData: {'franchiseId': franchiseId, 'userId': userId},
      );
      rethrow;
    }
  }

  @override
  Future<void> refresh() => validateAll();

  @override
  List<OnboardingValidationIssue> get issues {
    return _issuesBySection.values.expand((list) => list).toList();
  }

  @override
  List<OnboardingValidationIssue> get validationResults => issues;
}
