// lib/admin/dashboard/onboarding/widgets/menu_items/menu_item_utility.dart

import 'package:shared_core/shared_core.dart' as shared;
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

/// --- SCHEMA & VALIDATION LOGIC ---

shared.MenuItem buildMenuItemForSchemaCheck({
  required shared.MenuItem? existing,
  required String? name,
  required String? description,
  required double price,
  required String? categoryId,
  required bool outOfStock,
  required String? imageUrl,
  required List<shared.CustomizationGroup> customizationGroups,
  required List<shared.IngredientReference> includedIngredients,
  required List<shared.IngredientReference> optionalAddOns,
  required List<shared.Customization> customizations,
  required shared.NutritionInfo? nutrition,
  required List<String> selectedTemplateRefs,
  required List<shared.SizeData> sizeData,
  required List<shared.Category> categories,
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
  return shared.MenuItem(
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

List<shared.MenuItemSchemaIssue> getMenuItemSchemaIssues({
  required shared.MenuItem tempItem,
  required List<shared.Category> categories,
  required List<shared.IngredientMetadata> ingredients,
  required List<shared.IngredientType> ingredientTypes,
}) {
  return shared.MenuItemSchemaIssue.detectAllIssues(
    menuItem: tempItem,
    categories: categories,
    ingredients: ingredients,
    ingredientTypes: ingredientTypes,
  );
}

/// --- TEMPLATE APPLICATION LOGIC ---

Map<String, dynamic> extractTemplateFieldsForEditor(
  shared.MenuItem item,
  List<shared.IngredientMetadata> allIngredients,
) {
  final Map<String, shared.IngredientMetadata> ingredientMap = {
    for (var ing in allIngredients) ing.id: ing
  };

  // Customization groups normalization
  List<shared.CustomizationGroup> customizationGroups =
      (item.customizationGroups ?? []).map((g) {
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
        if (e is String)
          return {'id': e, 'name': e, 'typeId': '', 'isRemovable': true};
        if (e is Map) return e;
        if (e is shared.IngredientReference) return e.toMap();
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
    return shared.CustomizationGroup.fromMap(groupMap);
  }).toList();

  // Included / Optional AddOns
  final includedIngredients = (item.includedIngredients ?? [])
      .map((e) => e is shared.IngredientReference
          ? e
          : shared.IngredientReference.fromMap(Map<String, dynamic>.from(e)))
      .toList()
      .cast<shared.IngredientReference>();

  final optionalAddOns = (item.optionalAddOns ?? [])
      .map((e) => e is shared.IngredientReference
          ? e
          : shared.IngredientReference.fromMap(Map<String, dynamic>.from(e)))
      .toList()
      .cast<shared.IngredientReference>();

  // Sizes / Pricing
  List<shared.SizeData> sizeData = [];
  final sizesValue = item.sizes;
  if (sizesValue != null &&
      sizesValue is List<shared.SizeData> &&
      sizesValue.isNotEmpty) {
    sizeData = List<shared.SizeData>.from(sizesValue);
  } else if (sizesValue != null &&
      sizesValue is List &&
      sizesValue.isNotEmpty) {
    final basePriceMap = item.sizePrices ?? {};
    final toppingPriceMap = item.additionalToppingPrices ?? {};
    sizeData = sizesValue
        .map((s) => shared.SizeData(
              label: s.toString(),
              basePrice:
                  (basePriceMap[s.toString()] as num?)?.toDouble() ?? 0.0,
              toppingPrice:
                  (toppingPriceMap[s.toString()] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();
  }

  return {
    'name': item.name ?? '',
    'description': item.description ?? '',
    'price': item.price ?? 0.0,
    'categoryId': item.categoryId ?? '',
    'imageUrl': item.imageUrl ?? '',
    'nutrition': item.nutrition,
    'includedIngredients': includedIngredients,
    'optionalAddOns': optionalAddOns,
    'customizations':
        List<shared.Customization>.from(item.customizations ?? []),
    'sizeData': sizeData,
    'customizationGroups': customizationGroups,
    'selectedTemplateRefs': List<String>.from(item.templateRefs ?? []),
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

shared.MenuItem constructMenuItemFromEditorFields({
  required String? id,
  required bool outOfStock,
  required String categoryName,
  required String categoryId,
  required String name,
  required double price,
  required String description,
  String? notes,
  String? sku,
  List<String> dietaryTags = const [],
  List<String> allergens = const [],
  int? prepTime,
  int? sortOrder,
  String taxCategory = 'standard',
  String? exportId,
  List<shared.CustomizationGroup> customizationGroups = const [],
  List<shared.IngredientReference> includedIngredients = const [],
  List<shared.IngredientReference> optionalAddOns = const [],
  List<shared.Customization> customizations = const [],
  String imageUrl = '',
  shared.NutritionInfo? nutrition,
  List<String> selectedTemplateRefs = const [],
  List<shared.SizeData> sizeData = const [],
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
  return shared.MenuItem(
    id: id ?? const Uuid().v4(),
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
    image: imageUrl, // Matches your MenuItem 'image' field
    nutrition: nutrition,
    templateRefs: selectedTemplateRefs,
    sizes: sizeData,
    crustTypes: crustTypes ?? [],
    cookTypes: cookTypes ?? [],
    cutStyles: cutStyles ?? [],
    sauceOptions: sauceOptions ?? [],
    dressingOptions: dressingOptions ?? [],
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

bool repairMenuItemSchemaIssue({
  required shared.MenuItemSchemaIssue issue,
  required String newValue,
  required void Function(String) updateCategoryId,
  required List<shared.IngredientReference> includedIngredients,
  required List<shared.IngredientReference> optionalAddOns,
  required List<shared.CustomizationGroup> customizationGroups,
}) {
  bool changed = false;

  if (issue.type == shared.MenuItemSchemaIssueType.category) {
    updateCategoryId(newValue);
    changed = true;
  } else if (issue.type == shared.MenuItemSchemaIssueType.ingredient) {
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
    for (var group in customizationGroups) {
      for (var j = 0; j < group.ingredients.length; j++) {
        if (group.ingredients[j].id == issue.missingReference) {
          group.ingredients[j] = group.ingredients[j].copyWith(id: newValue);
          changed = true;
        }
      }
    }
  } else if (issue.type == shared.MenuItemSchemaIssueType.ingredientType) {
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

shared.MenuItem buildPreviewMenuItem({
  required String? existingId,
  required bool outOfStock,
  required String? categoryId,
  required String name,
  required double price,
  required String description,
  required String imageUrl,
  required shared.NutritionInfo? nutrition,
  required List<shared.IngredientReference> includedIngredients,
  required List<shared.IngredientReference> optionalAddOns,
  required List<shared.Customization> customizations,
  required List<String> selectedTemplateRefs,
}) {
  return shared.MenuItem(
    id: existingId ?? const Uuid().v4(),
    available: !outOfStock,
    availability: !outOfStock,
    category: categoryId ?? '',
    categoryId: categoryId ?? '',
    name: name,
    price: price,
    description: description,
    image: imageUrl,
    nutrition: nutrition,
    templateRefs: selectedTemplateRefs,
    customizations: customizations,
    includedIngredients: includedIngredients.map((e) => e.toMap()).toList(),
    optionalAddOns: optionalAddOns.map((e) => e.toMap()).toList(),
    taxCategory: 'standard',
    customizationGroups: [],
  );
}

shared.MenuItem repairMenuItem(
  shared.MenuItem item,
  shared.MenuItemSchemaIssue issue,
  String newValue,
) {
  final included = ingredientRefsFromDraft(item.includedIngredients);
  final optional = ingredientRefsFromDraft(item.optionalAddOns);
  final groups = customizationGroupsFromDraft(item.customizationGroups);

  bool changed = repairMenuItemSchemaIssue(
    issue: issue,
    newValue: newValue,
    updateCategoryId: (v) => item = item.copyWith(categoryId: v),
    includedIngredients: included,
    optionalAddOns: optional,
    customizationGroups: groups,
  );

  if (!changed) return item;

  return item.copyWith(
    includedIngredients: ingredientRefsToDraft(included),
    optionalAddOns: ingredientRefsToDraft(optional),
    customizationGroups: customizationGroupsToDraft(groups),
  );
}

shared.MenuItem applyTemplateToDraft(
    shared.MenuItem draft, shared.MenuItem template) {
  final fields = extractTemplateFieldsForEditor(template, []);

  return draft.copyWith(
    name: fields['name'] as String? ?? draft.name,
    description: fields['description'] as String? ?? draft.description,
    price: fields['price'] as double? ?? draft.price,
    categoryId: fields['categoryId'] as String? ?? draft.categoryId,
    image: fields['imageUrl'] as String? ?? draft.image,
    nutrition: fields['nutrition'] as shared.NutritionInfo?,
    includedIngredients: (fields['includedIngredients'] as List?)
            ?.map((e) => e is shared.IngredientReference
                ? e.toMap() // Convert back to Map for MenuItem model
                : e as Map<String, dynamic>)
            .toList() ??
        draft.includedIngredients ??
        [],
    optionalAddOns: (fields['optionalAddOns'] as List?)
            ?.map((e) => e is shared.IngredientReference
                ? e.toMap()
                : e as Map<String, dynamic>)
            .toList() ??
        draft.optionalAddOns ??
        [],
    customizationGroups: (fields['customizationGroups'] as List?)
            ?.map((g) => g is shared.CustomizationGroup
                ? g.toMap()
                : g as Map<String, dynamic>)
            .toList() ??
        draft.customizationGroups ??
        [],
    sizes: fields['sizeData'] as List<shared.SizeData>? ?? draft.sizes,
    templateRefs:
        fields['selectedTemplateRefs'] as List<String>? ?? draft.templateRefs,
  );
}

// Helper for empty draft (used in editor initState)
shared.MenuItem emptyDraft() {
  return shared.MenuItem(
    id: '',
    name: '',
    description: '',
    price: 0.0,
    categoryId: '',
    category: '',
    available: true,
    availability: true,
    image: '', // Matches MenuItem 'image' field
    taxCategory: 'standard', // Required
    sizes: [],
    customizationGroups: [],
    includedIngredients: [], // Use empty list (model expects List<Map> or references depending on shared)
    optionalAddOns: [],
    customizations: [],
  );
}

// ── Draft (maps) ↔ Editor (typed) helpers ─────────────────────────────
List<shared.IngredientReference> ingredientRefsFromDraft(List<dynamic>? raw) {
  if (raw == null || raw.isEmpty) return const [];
  return raw
      .map((e) => e is shared.IngredientReference
          ? e
          : shared.IngredientReference.fromMap(
              Map<String, dynamic>.from(e as Map)))
      .toList(growable: false);
}

List<shared.CustomizationGroup> customizationGroupsFromDraft(
    List<dynamic>? raw) {
  if (raw == null || raw.isEmpty) return const [];
  return raw
      .map((g) => g is shared.CustomizationGroup
          ? g
          : shared.CustomizationGroup.fromMap(
              Map<String, dynamic>.from(g as Map)))
      .toList(growable: false);
}

List<Map<String, dynamic>> ingredientRefsToDraft(List<dynamic>? raw) {
  if (raw == null || raw.isEmpty) return const [];
  return raw
      .map((e) => e is shared.IngredientReference
          ? e.toMap()
          : e is Map<String, dynamic>
              ? e
              : Map<String, dynamic>.from(e as Map))
      .toList(growable: false);
}

List<Map<String, dynamic>> customizationGroupsToDraft(List<dynamic>? raw) {
  if (raw == null || raw.isEmpty) return const [];
  return raw
      .map((g) => g is shared.CustomizationGroup
          ? g.toMap()
          : g is Map<String, dynamic>
              ? g
              : Map<String, dynamic>.from(g as Map))
      .toList(growable: false);
}
