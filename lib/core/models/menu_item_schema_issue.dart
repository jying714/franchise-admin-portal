// lib/core/models/menu_item_schema_issue.dart
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

/// Enum representing the type of schema issue for a MenuItem.
enum MenuItemSchemaIssueType {
  category,
  ingredient,
  ingredientType,
  missingField, // NEW: for core fields like name, price, etc.
  // Expandable: add more types if needed, e.g. modifier, templateRef, etc.
}

/// Represents a missing or invalid reference found during schema validation.
@immutable
class MenuItemSchemaIssue {
  /// The type of schema issue (e.g., category, ingredient, ingredientType).
  final MenuItemSchemaIssueType type;

  /// The missing or invalid value (e.g., a missing id or name).
  final String missingReference;

  /// Optionally, the human-readable label for the reference (for user clarity).
  final String? label;

  /// The menu item field/key where the issue was found (e.g., 'includedIngredients', 'categoryId').
  final String field;

  /// Optionally, the menu item ID this issue is attached to (for onboarding lists).
  final String? menuItemId;

  /// Optionally, context to further help in mapping (e.g., the group label, row number, etc.).
  final String? context;

  /// Severity (optional): warning, error, info, etc.
  final String severity;

  /// Optional: if this issue is resolved by the user (for UI state).
  final bool resolved;

  const MenuItemSchemaIssue({
    required this.type,
    required this.missingReference,
    required this.field,
    this.label,
    this.menuItemId,
    this.context,
    this.severity = 'warning',
    this.resolved = false,
  });

  /// Human-friendly display string for UI use.
  String get displayMessage {
    switch (type) {
      case MenuItemSchemaIssueType.category:
        return "Category reference not found: '${label ?? missingReference}'"
            "${context != null ? ' ($context)' : ''}";
      case MenuItemSchemaIssueType.ingredient:
        return "Ingredient reference not found: '${label ?? missingReference}'"
            "${context != null ? ' ($context)' : ''}";
      case MenuItemSchemaIssueType.ingredientType:
        return "Ingredient type not found: '${label ?? missingReference}'"
            "${context != null ? ' ($context)' : ''}";
      case MenuItemSchemaIssueType.missingField:
        return "Required field missing: ${label ?? field}";
      default:
        return "Unknown schema issue in '$field': '${label ?? missingReference}'";
    }
  }

  /// Clone with resolved state (for UI/repair workflows)
  MenuItemSchemaIssue markResolved([bool isResolved = true]) =>
      MenuItemSchemaIssue(
        type: type,
        missingReference: missingReference,
        label: label,
        field: field,
        menuItemId: menuItemId,
        context: context,
        severity: severity,
        resolved: isResolved,
      );

  /// Utility: Convert issue type enum to string for filtering/logging.
  String get typeKey => describeEnum(type);

  /// For equality/sets.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItemSchemaIssue &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          missingReference == other.missingReference &&
          field == other.field &&
          menuItemId == other.menuItemId &&
          context == other.context;

  @override
  int get hashCode =>
      type.hashCode ^
      missingReference.hashCode ^
      field.hashCode ^
      menuItemId.hashCode ^
      context.hashCode;

  /// Factory for JSON or Map-based creation (optional, for API or export use)
  factory MenuItemSchemaIssue.fromMap(Map<String, dynamic> map) {
    return MenuItemSchemaIssue(
      type: MenuItemSchemaIssueType.values.firstWhere(
          (e) => describeEnum(e) == map['type'],
          orElse: () => MenuItemSchemaIssueType.ingredient),
      missingReference: map['missingReference'] as String,
      label: map['label'] as String?,
      field: map['field'] as String,
      menuItemId: map['menuItemId'] as String?,
      context: map['context'] as String?,
      severity: map['severity'] as String? ?? 'warning',
      resolved: map['resolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': typeKey,
      'missingReference': missingReference,
      'label': label,
      'field': field,
      'menuItemId': menuItemId,
      'context': context,
      'severity': severity,
      'resolved': resolved,
    };
  }

  // ---
  // NOTE: Expand this method as your onboarding grows (e.g., customizations, advanced upcharges, etc.)
  // ---
  /// Detects all missing references for the given menu item and current schema state.
  static List<MenuItemSchemaIssue> detectAllIssues({
    required dynamic menuItem,
    required List categories,
    required List ingredients,
    required List ingredientTypes,
  }) {
    final List<MenuItemSchemaIssue> issues = [];

    // --- CATEGORY CHECK ---
    final categoryId = menuItem.categoryId;
    if (categoryId != null &&
        categories.where((c) => c.id == categoryId).isEmpty) {
      issues.add(MenuItemSchemaIssue(
        type: MenuItemSchemaIssueType.category,
        missingReference: categoryId,
        label: menuItem.category,
        field: 'categoryId',
        menuItemId: menuItem.id,
        severity: 'error',
      ));
    }

    // --- INCLUDED INGREDIENTS CHECK ---
    final included = menuItem.includedIngredients ?? [];
    for (final i in included) {
      final id = i['id'] ?? i['ingredientId'];
      if (id == null || ingredients.where((ing) => ing.id == id).isEmpty) {
        issues.add(MenuItemSchemaIssue(
          type: MenuItemSchemaIssueType.ingredient,
          missingReference: id?.toString() ?? '',
          label: i['name'],
          field: 'includedIngredients',
          menuItemId: menuItem.id,
          context: i['type'] != null ? 'Type: ${i['type']}' : null,
          severity: 'error',
        ));
      } else {
        // Ingredient type check
        final ingredient = ingredients.firstWhereOrNull((ing) => ing.id == id);
        final typeId = i['typeId'] ?? i['type'];
        if (ingredient != null &&
            typeId != null &&
            ingredientTypes.where((t) => t.id == typeId).isEmpty) {
          issues.add(MenuItemSchemaIssue(
            type: MenuItemSchemaIssueType.ingredientType,
            missingReference: typeId,
            label: i['name'],
            field: 'includedIngredients',
            menuItemId: menuItem.id,
            context: 'Ingredient: ${i['name']}',
            severity: 'warning',
          ));
        }
      }
    }

    // --- OPTIONAL ADDONS CHECK ---
    final optionalAddOns = menuItem.optionalAddOns ?? [];
    for (final o in optionalAddOns) {
      final id = o['id'] ?? o['ingredientId'];
      if (id == null || ingredients.where((ing) => ing.id == id).isEmpty) {
        issues.add(MenuItemSchemaIssue(
          type: MenuItemSchemaIssueType.ingredient,
          missingReference: id?.toString() ?? '',
          label: o['name'],
          field: 'optionalAddOns',
          menuItemId: menuItem.id,
          context: o['type'] != null ? 'Type: ${o['type']}' : null,
          severity: 'error',
        ));
      } else {
        // Ingredient type check
        final ingredient = ingredients.firstWhereOrNull((ing) => ing.id == id);
        final typeId = o['typeId'] ?? o['type'];
        if (ingredient != null &&
            typeId != null &&
            ingredientTypes.where((t) => t.id == typeId).isEmpty) {
          issues.add(MenuItemSchemaIssue(
            type: MenuItemSchemaIssueType.ingredientType,
            missingReference: typeId,
            label: o['name'],
            field: 'optionalAddOns',
            menuItemId: menuItem.id,
            context: 'Ingredient: ${o['name']}',
            severity: 'warning',
          ));
        }
      }
    }

    // --- CUSTOMIZATION GROUPS CHECK (by ingredientIds) ---
    // --- CUSTOMIZATION GROUPS CHECK ---
    // Support both: list of ingredientIds, and list of options (objects with ingredientId)
    final customizationGroups = menuItem.customizationGroups ?? [];
    for (final group in customizationGroups) {
      final groupLabel = group['label'] ?? '';
      // IngredientIds as List<String>
      final ingredientIds = group['ingredientIds'] as List?;
      if (ingredientIds != null) {
        for (final gid in ingredientIds) {
          if (ingredients.where((ing) => ing.id == gid).isEmpty) {
            issues.add(MenuItemSchemaIssue(
              type: MenuItemSchemaIssueType.ingredient,
              missingReference: gid.toString(),
              field: 'customizationGroups',
              menuItemId: menuItem.id,
              context: 'Group: $groupLabel',
              severity: 'error',
            ));
          }
        }
      }
      // NEW: Check options array (recommended modern structure)
      final options = group['options'] as List?;
      if (options != null) {
        for (final opt in options) {
          final ingId = opt['ingredientId'];
          if (ingId == null ||
              ingredients.where((ing) => ing.id == ingId).isEmpty) {
            issues.add(MenuItemSchemaIssue(
              type: MenuItemSchemaIssueType.ingredient,
              missingReference: ingId?.toString() ?? '',
              field: 'customizationGroups.options',
              menuItemId: menuItem.id,
              context: 'Group: $groupLabel',
              severity: 'error',
            ));
          }
          // Optional: Type checks for group options
          final typeId = opt['typeId'] ?? opt['type'];
          if (typeId != null &&
              ingredientTypes.where((t) => t.id == typeId).isEmpty) {
            issues.add(MenuItemSchemaIssue(
              type: MenuItemSchemaIssueType.ingredientType,
              missingReference: typeId,
              field: 'customizationGroups.options',
              menuItemId: menuItem.id,
              context: 'Group: $groupLabel',
              severity: 'warning',
            ));
          }
        }
      }
    }

    // --- CORE FIELD CHECKS (name, price, category, etc.) ---
    if (menuItem.name == null || menuItem.name.isEmpty) {
      issues.add(MenuItemSchemaIssue(
        type: MenuItemSchemaIssueType.missingField,
        missingReference: '',
        label: 'Name',
        field: 'name',
        menuItemId: menuItem.id,
        severity: 'error',
      ));
    }
    if (menuItem.categoryId == null || menuItem.categoryId.isEmpty) {
      issues.add(MenuItemSchemaIssue(
        type: MenuItemSchemaIssueType.missingField,
        missingReference: '',
        label: 'Category',
        field: 'categoryId',
        menuItemId: menuItem.id,
        severity: 'error',
      ));
    }
    if (menuItem.price == null || menuItem.price == 0.0) {
      issues.add(MenuItemSchemaIssue(
        type: MenuItemSchemaIssueType.missingField,
        missingReference: '',
        label: 'Price',
        field: 'price',
        menuItemId: menuItem.id,
        severity: 'error',
      ));
    }
// Add more as needed (e.g., description, image, etc.)

    // --- MORE CHECKS CAN GO HERE (future: templateRefs, etc.) ---

    return issues;
  }
}
