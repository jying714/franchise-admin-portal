// lib/admin/dashboard/onboarding/widgets/menu_items/menu_item_utility.dart

import '../package:shared_core/src/core/models/menu_item.dart';
import '../package:shared_core/src/core/models/customization_group.dart';
import '../package:shared_core/src/core/models/ingredient_reference.dart';
import '../package:shared_core/src/core/models/nutrition_info.dart';
import '../package:shared_core/src/core/models/menu_item_schema_issue.dart';
import '../package:shared_core/src/core/models/size_template.dart';
import '../package:shared_core/src/core/models/customization.dart';
import '../package:shared_core/src/core/models/category.dart';
import '../package:shared_core/src/core/models/ingredient_metadata.dart';
import '../package:shared_core/src/core/models/ingredient_type_model.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

/// --- SCHEMA & VALIDATION LOGIC ---

MenuItem buildMenuItemForSchemaCheck({
  required MenuItem? existing,
  required String? name,
  required String? description,
  required double price,
  required String? categoryId,
  required bool outOfStock,
  required String? imageUrl,
  required List<CustomizationGroup> customizationGroups,
  required List<IngredientReference> includedIngredients,
  required List<IngredientReference> optionalAddOns,
  required List<Customization> customizations,
  required NutritionInfo? nutrition,
  required List<String> selectedTemplateRefs,
  required List<SizeData> sizeData,
  required List<Category> categories,
  // All advanced fields:
  String? notes,
  String? sku,
  List<String> dietaryTags = const [],
  List<String> allergens = const [],
  int? prepTime,
  int? sortOrder,
  String taxCategory = 'standard',
  String? exportId,
  List<String>? crustTypes,
  List<String>? cookTypes,
  List<String>? cutStyles,
  List<String>? sauceOptions,
  List<String>? dressingOptions,
  int? maxFreeToppings,
  int? maxFreeSauces,
  int? maxFreeDressings,
  int? maxToppings,
  DateTime? customizationsUpdatedAt,
  DateTime? createdAt,
  String? comboId,
  List<String>? bundleItems,
  double? bundleDiscount,
  List<String>? highlightTags,
  bool? allowSpecialInstructions,
  bool? hideInMenu,
  dynamic freeSauceCount,
  double? extraSauceUpcharge,
  dynamic freeDressingCount,
  double? extraDressingUpcharge,
  List<String>? dippingSauceOptions,
  Map<String, int>? dippingSplits,
  List<String>? sideDipSauceOptions,
  Map<String, int>? freeDipCupCount,
  Map<String, double>? sideDipUpcharge,
  Map<String, dynamic>? extraCharges,
  List<Map<String, dynamic>>? rawCustomizations,
}) {
  final categoryName =
      categories.firstWhereOrNull((cat) => cat.id == categoryId)?.name ?? '';
  return MenuItem(
    id: existing?.id ?? '',
    available: !outOfStock,
    availability: !outOfStock,
    category: categoryName,
    categoryId: categoryId ?? '',
    name: name ?? '',
    price: price,
    description: description ?? '',
    notes: notes,
    sku: sku,
    dietaryTags: dietaryTags,
    allergens: allergens,
    prepTime: prepTime,
    sortOrder: sortOrder,
    taxCategory: taxCategory,
    exportId: exportId,
    customizationGroups: customizationGroups.map((g) => g.toMap()).toList(),
    includedIngredients: includedIngredients.map((i) => i.toMap()).toList(),
    optionalAddOns: optionalAddOns.map((i) => i.toMap()).toList(),
    customizations: customizations,
    image: imageUrl,
    nutrition: nutrition,
    templateRefs: selectedTemplateRefs,
    sizes: sizeData,
    crustTypes: crustTypes,
    cookTypes: cookTypes,
    cutStyles: cutStyles,
    sauceOptions: sauceOptions,
    dressingOptions: dressingOptions,
    maxFreeToppings: maxFreeToppings,
    maxFreeSauces: maxFreeSauces,
    maxFreeDressings: maxFreeDressings,
    maxToppings: maxToppings,
    customizationsUpdatedAt: customizationsUpdatedAt,
    createdAt: createdAt,
    comboId: comboId,
    bundleItems: bundleItems,
    bundleDiscount: bundleDiscount,
    highlightTags: highlightTags,
    allowSpecialInstructions: allowSpecialInstructions,
    hideInMenu: hideInMenu,
    freeSauceCount: freeSauceCount,
    extraSauceUpcharge: extraSauceUpcharge,
    freeDressingCount: freeDressingCount,
    extraDressingUpcharge: extraDressingUpcharge,
    dippingSauceOptions: dippingSauceOptions,
    dippingSplits: dippingSplits,
    sideDipSauceOptions: sideDipSauceOptions,
    freeDipCupCount: freeDipCupCount,
    sideDipUpcharge: sideDipUpcharge,
    extraCharges: extraCharges,
    rawCustomizations: rawCustomizations,
  );
}

List<MenuItemSchemaIssue> getMenuItemSchemaIssues({
  required MenuItem tempItem,
  required List<Category> categories,
  required List<IngredientMetadata> ingredients,
  required List<IngredientType> ingredientTypes,
}) {
  return MenuItemSchemaIssue.detectAllIssues(
    menuItem: tempItem,
    categories: categories,
    ingredients: ingredients,
    ingredientTypes: ingredientTypes,
  );
}

/// --- TEMPLATE APPLICATION LOGIC ---

Map<String, dynamic> extractTemplateFieldsForEditor(
  MenuItem item,
  List<IngredientMetadata> allIngredients,
) {
  // Deep copy and correct all required fields as in _applyTemplate.
  // For each field, apply the exact transformation/mapping logic as in the widget.
  final Map<String, IngredientMetadata> ingredientMap = {
    for (var ing in allIngredients) ing.id: ing
  };

  // --- Customization groups normalization ---
  List<CustomizationGroup> customizationGroups =
      (item.customizationGroups ?? []).map((g) {
    final groupMap = Map<String, dynamic>.from(g);

    // 1. If group has 'ingredientIds' (legacy), generate 'ingredients'
    if (groupMap['ingredientIds'] is List &&
        groupMap['ingredientIds'].isNotEmpty) {
      groupMap['ingredients'] = (groupMap['ingredientIds'] as List).map((id) {
        final meta = ingredientMap[id];
        if (meta != null) return meta.toMap();
        return {'id': id, 'name': id, 'typeId': '', 'isRemovable': true};
      }).toList();
    }

    // 2. If 'ingredients' exists, ensure every entry is a Map
    if (groupMap['ingredients'] is List) {
      groupMap['ingredients'] = (groupMap['ingredients'] as List).map((e) {
        if (e is String) {
          return {'id': e, 'name': e, 'typeId': '', 'isRemovable': true};
        }
        if (e is Map) return e;
        if (e is IngredientReference) return e.toMap();
        // Fallback for legacy/unknown
        return {
          'id': e.toString(),
          'name': e.toString(),
          'typeId': '',
          'isRemovable': true
        };
      }).toList();
    } else {
      // 3. Defensive: If 'ingredients' is missing or not a List, create empty list
      groupMap['ingredients'] = <Map<String, dynamic>>[];
    }

    // 4. Always remove 'ingredientIds' to prevent model confusion
    groupMap.remove('ingredientIds');

    // Now safe to call:
    return CustomizationGroup.fromMap(groupMap);
  }).toList();

  // --- Included Ingredients
  final includedIngredients = (item.includedIngredients ?? [])
      .map((e) => e is IngredientReference
          ? e
          : IngredientReference.fromMap(Map<String, dynamic>.from(e)))
      .toList()
      .cast<IngredientReference>();

  // --- Optional AddOns
  final optionalAddOns = (item.optionalAddOns ?? [])
      .map((e) => e is IngredientReference
          ? e
          : IngredientReference.fromMap(Map<String, dynamic>.from(e)))
      .toList()
      .cast<IngredientReference>();

  // --- Sizes / Pricing normalization ---
  List<SizeData> sizeData = [];
  final sizesValue = item.sizes;
  if (sizesValue != null &&
      sizesValue is List<SizeData> &&
      sizesValue.isNotEmpty) {
    sizeData = List<SizeData>.from(sizesValue);
  } else if (sizesValue != null &&
      sizesValue is List &&
      sizesValue.isNotEmpty &&
      (item.sizePrices != null || item.additionalToppingPrices != null)) {
    final basePriceMap = item.sizePrices ?? {};
    final toppingPriceMap = item.additionalToppingPrices ?? {};
    sizeData = sizesValue
        .map((s) => SizeData(
              label: s.toString(),
              basePrice:
                  (basePriceMap[s.toString()] as num?)?.toDouble() ?? 0.0,
              toppingPrice:
                  (toppingPriceMap[s.toString()] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();
  } else {
    sizeData = [];
  }

  // --- Full field extraction for editor state ---
  return {
    'name': item.name ?? '',
    'description': item.description ?? '',
    'price': item.price ?? 0.0,
    'categoryId': item.categoryId ?? '',
    'imageUrl': item.imageUrl ?? '',
    'nutrition': item.nutrition,
    'includedIngredients': includedIngredients,
    'optionalAddOns': optionalAddOns,
    'customizations': List<Customization>.from(item.customizations ?? []),
    'sizeData': sizeData,
    'customizationGroups': customizationGroups,
    'selectedTemplateRefs': List<String>.from(item.templateRefs ?? []),
    // Advanced:
    'notes': item.notes,
    'sku': item.sku,
    'dietaryTags': List<String>.from(item.dietaryTags ?? []),
    'allergens': List<String>.from(item.allergens ?? []),
    'prepTime': item.prepTime,
    'sortOrder': item.sortOrder,
    'taxCategory': item.taxCategory ?? 'standard',
    'exportId': item.exportId,
    'crustTypes': item.crustTypes,
    'cookTypes': item.cookTypes,
    'cutStyles': item.cutStyles,
    'sauceOptions': item.sauceOptions,
    'dressingOptions': item.dressingOptions,
    'maxFreeToppings': item.maxFreeToppings,
    'maxFreeSauces': item.maxFreeSauces,
    'maxFreeDressings': item.maxFreeDressings,
    'maxToppings': item.maxToppings,
    'customizationsUpdatedAt': item.customizationsUpdatedAt,
    'createdAt': item.createdAt,
    'comboId': item.comboId,
    'bundleItems': item.bundleItems,
    'bundleDiscount': item.bundleDiscount,
    'highlightTags': item.highlightTags,
    'allowSpecialInstructions': item.allowSpecialInstructions,
    'hideInMenu': item.hideInMenu,
    'freeSauceCount': item.freeSauceCount,
    'extraSauceUpcharge': item.extraSauceUpcharge,
    'freeDressingCount': item.freeDressingCount,
    'extraDressingUpcharge': item.extraDressingUpcharge,
    'dippingSauceOptions': item.dippingSauceOptions,
    'dippingSplits': item.dippingSplits,
    'sideDipSauceOptions': item.sideDipSauceOptions,
    'freeDipCupCount': item.freeDipCupCount,
    'sideDipUpcharge': item.sideDipUpcharge,
    'extraCharges': item.extraCharges,
    'rawCustomizations': item.rawCustomizations,
  };
}

/// --- MENU ITEM CONSTRUCTION LOGIC ---

MenuItem constructMenuItemFromEditorFields({
  required String? id,
  required bool outOfStock,
  required String categoryName,
  required String categoryId,
  required String name,
  required double price,
  required String description,
  required String? notes,
  required String? sku,
  required List<String> dietaryTags,
  required List<String> allergens,
  required int? prepTime,
  required int? sortOrder,
  required String taxCategory,
  required String? exportId,
  required List<CustomizationGroup> customizationGroups,
  required List<IngredientReference> includedIngredients,
  required List<IngredientReference> optionalAddOns,
  required List<Customization> customizations,
  required String imageUrl,
  required NutritionInfo? nutrition,
  required List<String> selectedTemplateRefs,
  required List<SizeData> sizeData,
  // --- Advanced ---
  List<String>? crustTypes,
  List<String>? cookTypes,
  List<String>? cutStyles,
  List<String>? sauceOptions,
  List<String>? dressingOptions,
  int? maxFreeToppings,
  int? maxFreeSauces,
  int? maxFreeDressings,
  int? maxToppings,
  DateTime? customizationsUpdatedAt,
  DateTime? createdAt,
  String? comboId,
  List<String>? bundleItems,
  double? bundleDiscount,
  List<String>? highlightTags,
  bool? allowSpecialInstructions,
  bool? hideInMenu,
  dynamic freeSauceCount,
  double? extraSauceUpcharge,
  dynamic freeDressingCount,
  double? extraDressingUpcharge,
  List<String>? dippingSauceOptions,
  Map<String, int>? dippingSplits,
  List<String>? sideDipSauceOptions,
  Map<String, int>? freeDipCupCount,
  Map<String, double>? sideDipUpcharge,
  Map<String, dynamic>? extraCharges,
  List<Map<String, dynamic>>? rawCustomizations,
}) {
  return MenuItem(
    id: id ?? '',
    available: !outOfStock,
    availability: !outOfStock,
    category: categoryName,
    categoryId: categoryId,
    name: name,
    price: price,
    description: description,
    notes: notes,
    sku: sku,
    dietaryTags: dietaryTags,
    allergens: allergens,
    prepTime: prepTime,
    sortOrder: sortOrder,
    taxCategory: taxCategory,
    exportId: exportId,
    customizationGroups: customizationGroups.map((g) => g.toMap()).toList(),
    includedIngredients: includedIngredients.map((i) => i.toMap()).toList(),
    optionalAddOns: optionalAddOns.map((i) => i.toMap()).toList(),
    customizations: customizations,
    image: imageUrl,
    nutrition: nutrition,
    templateRefs: selectedTemplateRefs,
    sizes: sizeData,
    // --- Advanced ---
    crustTypes: crustTypes is List<String> ? crustTypes : [],
    cookTypes: cookTypes,
    cutStyles: cutStyles,
    sauceOptions: sauceOptions,
    dressingOptions: dressingOptions,
    maxFreeToppings: maxFreeToppings,
    maxFreeSauces: maxFreeSauces,
    maxFreeDressings: maxFreeDressings,
    maxToppings: maxToppings,
    customizationsUpdatedAt: customizationsUpdatedAt,
    createdAt: createdAt,
    comboId: comboId,
    bundleItems: bundleItems,
    bundleDiscount: bundleDiscount,
    highlightTags: highlightTags,
    allowSpecialInstructions: allowSpecialInstructions,
    hideInMenu: hideInMenu,
    freeSauceCount: freeSauceCount,
    extraSauceUpcharge: extraSauceUpcharge,
    freeDressingCount: freeDressingCount,
    extraDressingUpcharge: extraDressingUpcharge,
    dippingSauceOptions: dippingSauceOptions,
    dippingSplits: dippingSplits,
    sideDipSauceOptions: sideDipSauceOptions,
    freeDipCupCount: freeDipCupCount,
    sideDipUpcharge: sideDipUpcharge,
    extraCharges: extraCharges,
    rawCustomizations: rawCustomizations,
  );
}

/// --- SCHEMA ISSUE REPAIR LOGIC ---

void repairSchemaIssueForCategory({
  required String newValue,
  required void Function(String) updateCategoryId,
}) {
  updateCategoryId(newValue);
}

void repairSchemaIssueForIngredient({
  required String missingReference,
  required String newValue,
  required List<IngredientReference> includedIngredients,
  required List<IngredientReference> optionalAddOns,
  required List<CustomizationGroup> customizationGroups,
}) {
  for (var i = 0; i < includedIngredients.length; i++) {
    if (includedIngredients[i].id == missingReference) {
      includedIngredients[i] = includedIngredients[i].copyWith(id: newValue);
    }
  }
  for (var i = 0; i < optionalAddOns.length; i++) {
    if (optionalAddOns[i].id == missingReference) {
      optionalAddOns[i] = optionalAddOns[i].copyWith(id: newValue);
    }
  }
  for (var groupIdx = 0; groupIdx < customizationGroups.length; groupIdx++) {
    final group = customizationGroups[groupIdx];
    for (var ingIdx = 0; ingIdx < group.ingredients.length; ingIdx++) {
      if (group.ingredients[ingIdx].id == missingReference) {
        group.ingredients[ingIdx] =
            group.ingredients[ingIdx].copyWith(id: newValue);
      }
    }
  }
}

void repairSchemaIssueForIngredientType({
  required String label,
  required String missingReference,
  required String newValue,
  required List<IngredientReference> includedIngredients,
  required List<IngredientReference> optionalAddOns,
  required List<CustomizationGroup> customizationGroups,
}) {
  for (var i = 0; i < includedIngredients.length; i++) {
    if (includedIngredients[i].name == label ||
        includedIngredients[i].id == missingReference) {
      includedIngredients[i] =
          includedIngredients[i].copyWith(typeId: newValue);
    }
  }
  for (var i = 0; i < optionalAddOns.length; i++) {
    if (optionalAddOns[i].name == label ||
        optionalAddOns[i].id == missingReference) {
      optionalAddOns[i] = optionalAddOns[i].copyWith(typeId: newValue);
    }
  }
  for (var group in customizationGroups) {
    for (var j = 0; j < group.ingredients.length; j++) {
      if (group.ingredients[j].name == label ||
          group.ingredients[j].id == missingReference) {
        group.ingredients[j] = group.ingredients[j].copyWith(typeId: newValue);
      }
    }
  }
}

/// --- DATA CONVERSION / MAPPING HELPERS ---

List<IngredientReference> mapToIngredientReferenceList(List<dynamic>? list) {
  if (list == null) return [];
  return list
      .map((e) => e is IngredientReference
          ? e
          : IngredientReference.fromMap(Map<String, dynamic>.from(e)))
      .toList()
      .cast<IngredientReference>();
}

List<CustomizationGroup> mapToCustomizationGroupList(
    List<dynamic>? list, List<IngredientMetadata> allIngredients) {
  if (list == null) return [];
  final ingredientMap = {for (var ing in allIngredients) ing.id: ing};
  return list.map((g) {
    final groupMap = Map<String, dynamic>.from(g);

    if (groupMap['ingredientIds'] is List &&
        groupMap['ingredientIds'].isNotEmpty) {
      groupMap['ingredients'] = (groupMap['ingredientIds'] as List).map((id) {
        final meta = ingredientMap[id];
        if (meta != null) return meta.toMap();
        return {'id': id, 'name': id, 'typeId': '', 'isRemovable': true};
      }).toList();
    }
    if (groupMap['ingredients'] is List) {
      groupMap['ingredients'] = (groupMap['ingredients'] as List).map((e) {
        if (e is String) {
          return {'id': e, 'name': e, 'typeId': '', 'isRemovable': true};
        }
        if (e is Map) return e;
        if (e is IngredientReference) return e.toMap();
        return {
          'id': e.toString(),
          'name': e.toString(),
          'typeId': '',
          'isRemovable': true
        };
      }).toList();
    } else {
      groupMap['ingredients'] = <Map<String, dynamic>>[];
    }
    groupMap.remove('ingredientIds');
    return CustomizationGroup.fromMap(groupMap);
  }).toList();
}

/// Handles all schema issue repairs for the MenuItemEditorSheet.
/// Mutates the passed-in fields directly.
/// Returns true if any changes were made, false if not.
bool repairMenuItemSchemaIssue({
  required MenuItemSchemaIssue issue,
  required String newValue,
  required void Function(String) updateCategoryId,
  required List<IngredientReference> includedIngredients,
  required List<IngredientReference> optionalAddOns,
  required List<CustomizationGroup> customizationGroups,
}) {
  bool changed = false;
  if (issue.type == MenuItemSchemaIssueType.category) {
    updateCategoryId(newValue);
    changed = true;
  } else if (issue.type == MenuItemSchemaIssueType.ingredient) {
    // Update all relevant ingredient IDs
    for (var i = 0; i < includedIngredients.length; i++) {
      if (includedIngredients[i].id == issue.missingReference) {
        includedIngredients[i] = includedIngredients[i].copyWith(id: newValue);
        changed = true;
      }
    }
    for (var i = 0; i < optionalAddOns.length; i++) {
      if (optionalAddOns[i].id == issue.missingReference) {
        optionalAddOns[i] = optionalAddOns[i].copyWith(id: newValue);
        changed = true;
      }
    }
    for (var groupIdx = 0; groupIdx < customizationGroups.length; groupIdx++) {
      final group = customizationGroups[groupIdx];
      for (var ingIdx = 0; ingIdx < group.ingredients.length; ingIdx++) {
        if (group.ingredients[ingIdx].id == issue.missingReference) {
          group.ingredients[ingIdx] =
              group.ingredients[ingIdx].copyWith(id: newValue);
          changed = true;
        }
      }
    }
  } else if (issue.type == MenuItemSchemaIssueType.ingredientType) {
    // Update typeId/type for all relevant ingredient references
    for (var i = 0; i < includedIngredients.length; i++) {
      if (includedIngredients[i].name == issue.label ||
          includedIngredients[i].id == issue.missingReference) {
        includedIngredients[i] =
            includedIngredients[i].copyWith(typeId: newValue);
        changed = true;
      }
    }
    for (var i = 0; i < optionalAddOns.length; i++) {
      if (optionalAddOns[i].name == issue.label ||
          optionalAddOns[i].id == issue.missingReference) {
        optionalAddOns[i] = optionalAddOns[i].copyWith(typeId: newValue);
        changed = true;
      }
    }
    for (var group in customizationGroups) {
      for (var j = 0; j < group.ingredients.length; j++) {
        if (group.ingredients[j].name == issue.label ||
            group.ingredients[j].id == issue.missingReference) {
          group.ingredients[j] =
              group.ingredients[j].copyWith(typeId: newValue);
          changed = true;
        }
      }
    }
  }
  return changed;
}

MenuItem buildPreviewMenuItem({
  required String? existingId,
  required bool outOfStock,
  required String? categoryId,
  required String name,
  required double price,
  required String description,
  required String imageUrl,
  required NutritionInfo? nutrition,
  required List<IngredientReference> includedIngredients,
  required List<IngredientReference> optionalAddOns,
  required List<Customization> customizations,
  required List<String> selectedTemplateRefs,
}) {
  return MenuItem(
    id: existingId ?? const Uuid().v4(),
    available: !outOfStock,
    category: categoryId ?? '',
    categoryId: categoryId ?? '',
    name: name,
    price: price,
    description: description,
    notes: null,
    customizationGroups: [],
    image: imageUrl,
    taxCategory: 'standard',
    availability: !outOfStock,
    sku: null,
    dietaryTags: [],
    allergens: [],
    prepTime: null,
    nutrition: nutrition,
    sortOrder: null,
    lastModified: null,
    lastModifiedBy: null,
    archived: false,
    exportId: null,
    sizes: null,
    sizePrices: null,
    additionalToppingPrices: null,
    includedIngredients: includedIngredients.map((e) => e.toMap()).toList(),
    optionalAddOns: optionalAddOns.map((e) => e.toMap()).toList(),
    customizations: customizations,
    crustTypes: null,
    cookTypes: null,
    cutStyles: null,
    sauceOptions: null,
    dressingOptions: null,
    maxFreeToppings: null,
    maxFreeSauces: null,
    maxFreeDressings: null,
    maxToppings: null,
    customizationsUpdatedAt: null,
    createdAt: null,
    comboId: null,
    bundleItems: null,
    bundleDiscount: null,
    highlightTags: null,
    allowSpecialInstructions: null,
    hideInMenu: null,
    freeSauceCount: null,
    extraSauceUpcharge: null,
    freeDressingCount: null,
    extraDressingUpcharge: null,
    dippingSauceOptions: null,
    dippingSplits: null,
    sideDipSauceOptions: null,
    freeDipCupCount: null,
    sideDipUpcharge: null,
    extraCharges: null,
    rawCustomizations: null,
    templateRefs: selectedTemplateRefs,
  );
}


