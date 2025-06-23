import 'package:cloud_firestore/cloud_firestore.dart';
import 'nutrition_info.dart';
import 'customization.dart';

extension IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Enum for supported crust/cook/cut types.
enum CrustType { thin, regular, thick, glutenFree }

enum CookType { regular, crispy, wellDone }

enum CutStyle { square, pie }

class MenuItem {
  final String id;
  final String category;
  final String categoryId;
  final String name;
  final double price; // Default/base price (typically for 'Large')
  final String description;
  final String? notes;
  final String? image;
  final String taxCategory;
  final bool availability;
  final String? sku;
  final List<String> dietaryTags;
  final List<String> allergens;
  final int? prepTime;
  final NutritionInfo? nutrition;
  final int? sortOrder;
  final DateTime? lastModified;
  final String? lastModifiedBy;
  final bool archived;
  final String? exportId;

  // --- Dynamic pricing / multi-size ---
  final List<String>? sizes; // ['Small', 'Medium', 'Large']
  final Map<String, double>? sizePrices; // {'Small': 10.99, 'Large': 13.99}

  /// Per-size upcharges for additional toppings (e.g., { 'Large': 2.25, 'Small': 0.85 })
  final Map<String, double>? additionalToppingPrices;

  // --- Ingredient customization support ---
  /// Ingredients included by default (e.g., pepperoni, cheese, etc.)
  /// {ingredientId, name, type, removable}
  final List<Map<String, dynamic>>? includedIngredients;

  /// Ingredient customization groups (e.g., Meats, Veggies, Cheeses, Crust, etc.)
  /// Each group: {label, ingredientIds}
  final List<Map<String, dynamic>>? customizationGroups;

  /// Optional add-ons (not included by default)
  /// {ingredientId, name, type, removable, price?}
  final List<Map<String, dynamic>>? optionalAddOns;

  /// Full structured customizations (advanced, e.g., pizza builder)
  final List<Customization> customizations;

  /// Raw customizations from schema (may include `templateRef`)
  final List<Map<String, dynamic>>? rawCustomizations;

  // --- Firestore/admin integration fields ---
  final List<String>? crustTypes; // ['Regular', 'Thin', ...]
  final List<String>? cookTypes; // ['Regular', 'Crispy', ...]
  final List<String>? cutStyles; // ['Pie', 'Square', ...]
  final List<String>? sauceOptions; // (if relevant)
  final List<String>? dressingOptions; // (if relevant)
  final int? maxFreeToppings;
  final int? maxFreeSauces;
  final int? maxFreeDressings;
  final int? maxToppings;
  final DateTime? customizationsUpdatedAt;
  final DateTime? createdAt;

  // --- Combo/Bundle support ---
  final String? comboId;
  final List<String>? bundleItems;
  final double? bundleDiscount;

  // --- Dietary/Allergen UI tags ---
  final List<String>? highlightTags;

  // --- Admin feature flags ---
  final bool? allowSpecialInstructions;
  final bool? hideInMenu;

  // --- NEW: Sauce/Dressing upcharge fields ---
  final dynamic freeSauceCount; // int or Map<String, int>
  final double? extraSauceUpcharge;
  final dynamic freeDressingCount; // int or Map<String, int>
  final double? extraDressingUpcharge;

  // --- Wings customization fields ---
  final List<String>? dippingSauceOptions; // For dipped/tossed wings
  final Map<String, int>?
      dippingSplits; // E.g., { '8pc': 2, '16pc': 2, '24pc': 2 }
  final List<String>? sideDipSauceOptions; // For side dip cups (IDs)
  final Map<String, int>? freeDipCupCount; // Free dip cups by size
  final Map<String, double>? sideDipUpcharge; // Upcharge per dip cup by size

  /// List of customization template IDs used to populate the menu item.
  final List<String>? templateRefs;

  Map<String, dynamic>? extraCharges;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'categoryId': categoryId,
      'price': price,
      'available': availability,
      'description': description,
      'image': image,
      'taxCategory': taxCategory,
      'notes': notes,
      'nutrition': nutrition?.toJson(),
      'sizes': sizes,
      'sizePrices': sizePrices,
      'includedIngredients': includedIngredients,
      'optionalAddOns': optionalAddOns,
      'customizations': customizations.map((c) => c.toFirestore()).toList(),
      'maxFreeSauces': maxFreeSauces,
      'extraSauceUpcharge': extraSauceUpcharge,
      'extraCharges': extraCharges,
      'customizationGroups': customizationGroups,
    };
  }

  MenuItem({
    required this.id,
    required this.category,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.description,
    this.notes,
    required this.customizationGroups,
    this.image,
    required this.taxCategory,
    required this.availability,
    this.sku,
    List<String>? dietaryTags,
    List<String>? allergens,
    this.prepTime,
    this.nutrition,
    this.sortOrder,
    this.lastModified,
    this.lastModifiedBy,
    this.archived = false,
    this.exportId,
    this.sizes,
    this.sizePrices,
    this.additionalToppingPrices,
    this.includedIngredients,
    this.optionalAddOns,
    required this.customizations,
    this.crustTypes,
    this.cookTypes,
    this.cutStyles,
    this.sauceOptions,
    this.dressingOptions,
    this.maxFreeToppings,
    this.maxFreeSauces,
    this.maxFreeDressings,
    this.maxToppings,
    this.customizationsUpdatedAt,
    this.createdAt,
    this.comboId,
    this.bundleItems,
    this.bundleDiscount,
    this.highlightTags,
    this.allowSpecialInstructions,
    this.hideInMenu,
    // Sauce/Dressing fields
    this.freeSauceCount,
    this.extraSauceUpcharge,
    this.freeDressingCount,
    this.extraDressingUpcharge,
    // WINGS fields
    this.dippingSauceOptions,
    this.dippingSplits,
    this.sideDipSauceOptions,
    this.freeDipCupCount,
    this.sideDipUpcharge,
    this.extraCharges,
    // NEW: raw customizations
    this.rawCustomizations,
    this.templateRefs,
  })  : dietaryTags = dietaryTags ?? [],
        allergens = allergens ?? [];

  // --- Firestore/JSON/Map Serialization ---

  factory MenuItem.fromFirestore(Map<String, dynamic> data, String id) {
    //print('[DEBUG] Raw Firestore doc: $data');
    //print('[DEBUG] doc id: $id');
    double resolvedPrice = 0.0;
    Map<String, double>? resolvedSizePrices;

    final priceField = data['price'];
    if (priceField is num) {
      resolvedPrice = priceField.toDouble();
    } else if (priceField is Map) {
      resolvedSizePrices = (priceField as Map).map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      );
      resolvedPrice = resolvedSizePrices['Large'] ??
          resolvedSizePrices['large'] ??
          resolvedSizePrices.values.firstOrNull ??
          0.0;
    }

    List<Customization> customizations = [];
    if (data['customizations'] != null) {
      customizations = (data['customizations'] as List)
          .map((e) => Customization.fromFirestore(Map<String, dynamic>.from(e)))
          .toList();
    }

    List<Map<String, dynamic>>? customizationGroups;
    if (data['customizationGroups'] != null) {
      customizationGroups = List<Map<String, dynamic>>.from(
        data['customizationGroups'].map((g) => Map<String, dynamic>.from(g)),
      );
    }

    // print(
    //     '[DEBUG] after parse, sideDipSauceOptions: ${data['sideDipSauceOptions']}');
    return MenuItem(
      id: id,
      category: data['category'] ?? '',
      categoryId: data['categoryId'] ?? '',
      name: data['name'] ?? '',
      price: resolvedPrice,
      description: data['description'] ?? '',
      notes: data['notes'],
      image: data['image'],
      taxCategory: data['taxCategory'] ?? '',
      availability: data['availability'] ?? data['available'] ?? true,
      sku: data['sku'],
      dietaryTags: data['dietaryTags'] == null
          ? []
          : List<String>.from(data['dietaryTags'] as List),
      allergens: data['allergens'] == null
          ? []
          : List<String>.from(data['allergens'] as List),
      prepTime: data['prepTime'],
      nutrition: data['nutrition'] != null
          ? NutritionInfo.fromFirestore(
              Map<String, dynamic>.from(data['nutrition']))
          : null,
      sortOrder: data['sortOrder'],
      lastModified: (data['lastModified'] is Timestamp)
          ? (data['lastModified'] as Timestamp).toDate()
          : null,
      lastModifiedBy: data['lastModifiedBy'],
      archived: data['archived'] ?? false,
      exportId: data['exportId'],
      sizes: data['sizes'] == null ? null : List<String>.from(data['sizes']),
      sizePrices: data['sizePrices'] != null
          ? Map<String, double>.from(
              (data['sizePrices'] as Map).map(
                (key, value) => MapEntry(key, (value as num).toDouble()),
              ),
            )
          : resolvedSizePrices,
      additionalToppingPrices: data['additionalToppingPrices'] != null
          ? Map<String, double>.from(
              (data['additionalToppingPrices'] as Map).map(
                (key, value) => MapEntry(key, (value as num).toDouble()),
              ),
            )
          : null,
      includedIngredients: data['includedIngredients'] == null
          ? null
          : List<Map<String, dynamic>>.from(
              (data['includedIngredients'] as List)
                  .map((e) => Map<String, dynamic>.from(e))),
      customizationGroups: data['customizationGroups'] == null
          ? null
          : List<Map<String, dynamic>>.from(
              (data['customizationGroups'] as List)
                  .map((e) => Map<String, dynamic>.from(e))),
      optionalAddOns: data['optionalAddOns'] == null
          ? null
          : List<Map<String, dynamic>>.from((data['optionalAddOns'] as List)
              .map((e) => Map<String, dynamic>.from(e))),
      customizations: customizations,
      crustTypes: data['crustTypes'] == null
          ? null
          : List<String>.from(data['crustTypes']),
      cookTypes: data['cookTypes'] == null
          ? null
          : List<String>.from(data['cookTypes']),
      cutStyles: data['cutStyles'] == null
          ? null
          : List<String>.from(data['cutStyles']),
      sauceOptions: data['sauceOptions'] == null
          ? null
          : List<String>.from(data['sauceOptions']),
      dressingOptions: data['dressingOptions'] == null
          ? null
          : List<String>.from(data['dressingOptions']),
      maxFreeToppings: data['maxFreeToppings'],
      maxFreeSauces: data['maxFreeSauces'],
      maxFreeDressings: data['maxFreeDressings'],
      maxToppings: data['maxToppings'],
      customizationsUpdatedAt: data['customizationsUpdatedAt'] is Timestamp
          ? (data['customizationsUpdatedAt'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      comboId: data['comboId'],
      bundleItems: data['bundleItems'] == null
          ? null
          : List<String>.from(data['bundleItems']),
      bundleDiscount: (data['bundleDiscount'] as num?)?.toDouble(),
      highlightTags: data['highlightTags'] == null
          ? null
          : List<String>.from(data['highlightTags']),
      allowSpecialInstructions: data['allowSpecialInstructions'],
      hideInMenu: data['hideInMenu'],
      // NEW
      freeSauceCount: data['freeSauceCount'],
      extraSauceUpcharge: (data['extraSauceUpcharge'] as num?)?.toDouble(),
      freeDressingCount: data['freeDressingCount'],
      extraDressingUpcharge:
          (data['extraDressingUpcharge'] as num?)?.toDouble(),
      // Wings fields
      dippingSauceOptions: data['dippingSauceOptions'] == null
          ? null
          : List<String>.from(data['dippingSauceOptions']),
      dippingSplits: data['dippingSplits'] == null
          ? null
          : Map<String, int>.from((data['dippingSplits'] as Map).map(
              (key, value) => MapEntry(key, (value as num).toInt()),
            )),
      sideDipSauceOptions: data['sideDipSauceOptions'] == null
          ? null
          : List<String>.from(data['sideDipSauceOptions']),
      freeDipCupCount: data['freeDipCupCount'] == null
          ? null
          : Map<String, int>.from((data['freeDipCupCount'] as Map).map(
              (key, value) => MapEntry(key, (value as num).toInt()),
            )),
      sideDipUpcharge: data['sideDipUpcharge'] == null
          ? null
          : Map<String, double>.from((data['sideDipUpcharge'] as Map).map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            )),
      // NEW: raw customizations
      templateRefs:
          (data['templateRefs'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  factory MenuItem.fromMap(Map<String, dynamic> data, [String? id]) =>
      MenuItem.fromFirestore(data, id ?? data['id'] ?? '');

  Map<String, dynamic> toFirestore() {
    final priceField =
        sizePrices != null && sizePrices!.isNotEmpty ? sizePrices : price;

    final map = {
      'category': category,
      'categoryId': categoryId,
      'name': name,
      'price': priceField,
      'description': description,
      'notes': notes,
      'image': image,
      'taxCategory': taxCategory,
      'available': availability,
      'sku': sku,
      'dietaryTags': dietaryTags,
      'allergens': allergens,
      'prepTime': prepTime,
      'nutrition': nutrition?.toFirestore(),
      'sortOrder': sortOrder,
      'lastModified':
          lastModified != null ? Timestamp.fromDate(lastModified!) : null,
      'lastModifiedBy': lastModifiedBy,
      'archived': archived,
      'exportId': exportId,
      //customization groups
      if (customizationGroups != null)
        'customizationGroups': customizationGroups,
      if (sizes != null) 'sizes': sizes,
      if (sizePrices != null) 'sizePrices': sizePrices,
      if (additionalToppingPrices != null)
        'additionalToppingPrices': additionalToppingPrices,
      if (includedIngredients != null)
        'includedIngredients': includedIngredients,
      if (customizationGroups != null)
        'customizationGroups': customizationGroups,
      if (optionalAddOns != null) 'optionalAddOns': optionalAddOns,
      'customizations': customizations.map((c) => c.toFirestore()).toList(),
      'customizationGroups': customizationGroups,
      if (crustTypes != null) 'crustTypes': crustTypes,
      if (cookTypes != null) 'cookTypes': cookTypes,
      if (cutStyles != null) 'cutStyles': cutStyles,
      if (sauceOptions != null) 'sauceOptions': sauceOptions,
      if (dressingOptions != null) 'dressingOptions': dressingOptions,
      if (maxFreeToppings != null) 'maxFreeToppings': maxFreeToppings,
      if (maxFreeSauces != null) 'maxFreeSauces': maxFreeSauces,
      if (maxFreeDressings != null) 'maxFreeDressings': maxFreeDressings,
      if (maxToppings != null) 'maxToppings': maxToppings,
      if (customizationsUpdatedAt != null)
        'customizationsUpdatedAt': Timestamp.fromDate(customizationsUpdatedAt!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (comboId != null) 'comboId': comboId,
      if (bundleItems != null) 'bundleItems': bundleItems,
      if (bundleDiscount != null) 'bundleDiscount': bundleDiscount,
      if (highlightTags != null) 'highlightTags': highlightTags,
      if (allowSpecialInstructions != null)
        'allowSpecialInstructions': allowSpecialInstructions,
      if (hideInMenu != null) 'hideInMenu': hideInMenu,
      // Sauce/Dressing fields
      if (freeSauceCount != null) 'freeSauceCount': freeSauceCount,
      if (extraSauceUpcharge != null) 'extraSauceUpcharge': extraSauceUpcharge,
      if (freeDressingCount != null) 'freeDressingCount': freeDressingCount,
      if (extraDressingUpcharge != null)
        'extraDressingUpcharge': extraDressingUpcharge,
      // Wings fields
      if (dippingSauceOptions != null)
        'dippingSauceOptions': dippingSauceOptions,
      if (dippingSplits != null) 'dippingSplits': dippingSplits,
      if (sideDipSauceOptions != null)
        'sideDipSauceOptions': sideDipSauceOptions,
      if (freeDipCupCount != null) 'freeDipCupCount': freeDipCupCount,
      if (sideDipUpcharge != null) 'sideDipUpcharge': sideDipUpcharge,
    };
    map.removeWhere((_, v) => v == null);
    return map;
  }

  Map<String, dynamic> toMap() => toFirestore();

  /// Utility: List of all included ingredient IDs (for quick lookup in UI)
  List<String> get includedIngredientIds {
    if (includedIngredients == null) return [];
    return includedIngredients!
        .map((e) => e['ingredientId'] ?? e['id'])
        .whereType<String>()
        .toList();
  }

  /// Utility: All available ingredient IDs from all customization groups
  List<String> get allGroupIngredientIds {
    if (customizationGroups == null) return [];
    return customizationGroups!
        .expand((group) =>
            (group['ingredientIds'] as List<dynamic>).whereType<String>())
        .toList();
  }

  /// Utility: Add-on ingredient IDs
  List<String> get optionalAddOnIds {
    if (optionalAddOns == null) return [];
    return optionalAddOns!
        .map((e) => e['ingredientId'] ?? e['id'])
        .whereType<String>()
        .toList();
  }

  // ==== UTILITY GETTERS for Upcharge Logic ====

  /// Returns the free sauce count for the given size (if available).
  int getFreeSauceCountForSize(String? size) {
    if (freeSauceCount == null) return 0;
    if (freeSauceCount is int) return freeSauceCount;
    if (freeSauceCount is Map) {
      if (size != null && (freeSauceCount as Map).containsKey(size)) {
        return (freeSauceCount as Map)[size] as int;
      }
      final map = freeSauceCount as Map;
      return map.values.cast<int>().first;
    }
    return 0;
  }

  double getExtraSauceUpcharge() => extraSauceUpcharge ?? 0.0;

  int getFreeDressingCountForSize(String? size) {
    if (freeDressingCount == null) return 0;
    if (freeDressingCount is int) return freeDressingCount;
    if (freeDressingCount is Map) {
      if (size != null && (freeDressingCount as Map).containsKey(size)) {
        return (freeDressingCount as Map)[size] as int;
      }
      final map = freeDressingCount as Map;
      return map.values.cast<int>().first;
    }
    return 0;
  }

  double getExtraDressingUpcharge() => extraDressingUpcharge ?? 0.0;

  // --- Wings-specific utility accessors ---

  /// Number of splits allowed for dipped wings for this size.
  int getDippingSplitsForSize(String? size) {
    if (dippingSplits == null || size == null) return 1;
    return dippingSplits![size] ?? 1;
  }

  /// List of allowed dipping sauce IDs for wings (dipped/tossed).
  List<String> getDippingSauceOptions() => dippingSauceOptions ?? [];

  /// List of allowed side dip cup options for this wings item.
  List<String> getSideDipSauceOptions() => sideDipSauceOptions ?? [];

  /// How many free side dip cups allowed per wings size.
  int getFreeDipCupCountForSize(String? size) {
    if (freeDipCupCount == null || size == null) return 0;
    return freeDipCupCount![size] ?? 0;
  }

  /// The per-cup upcharge for side dips, by size.
  double getSideDipUpchargeForSize(String? size) {
    if (sideDipUpcharge == null || size == null) return 0.0;
    return sideDipUpcharge![size] ?? 0.0;
  }

  MenuItem copyWith({
    String? id,
    String? category,
    String? categoryId,
    String? name,
    double? price,
    String? description,
    String? notes,
    String? image,
    String? taxCategory,
    bool? availability,
    String? sku,
    List<String>? dietaryTags,
    List<String>? allergens,
    int? prepTime,
    NutritionInfo? nutrition,
    int? sortOrder,
    DateTime? lastModified,
    String? lastModifiedBy,
    bool? archived,
    String? exportId,
    List<String>? sizes,
    Map<String, double>? sizePrices,
    Map<String, double>? additionalToppingPrices,
    List<Map<String, dynamic>>? includedIngredients,
    List<Map<String, dynamic>>? customizationGroups,
    List<Map<String, dynamic>>? optionalAddOns,
    List<Customization>? customizations,
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
    List<String>? templateRefs,
    bool? allowSpecialInstructions,
    bool? hideInMenu,
    // NEW fields
    dynamic freeSauceCount,
    double? extraSauceUpcharge,
    dynamic freeDressingCount,
    double? extraDressingUpcharge,
    // Wings fields
    List<String>? dippingSauceOptions,
    Map<String, int>? dippingSplits,
    List<String>? sideDipSauceOptions,
    Map<String, int>? freeDipCupCount,
    Map<String, double>? sideDipUpcharge,
    // NEW: template refs
  }) {
    return MenuItem(
      id: id ?? this.id,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      image: image ?? this.image,
      taxCategory: taxCategory ?? this.taxCategory,
      availability: availability ?? this.availability,
      sku: sku ?? this.sku,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      allergens: allergens ?? this.allergens,
      prepTime: prepTime ?? this.prepTime,
      nutrition: nutrition ?? this.nutrition,
      sortOrder: sortOrder ?? this.sortOrder,
      lastModified: lastModified ?? this.lastModified,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      archived: archived ?? this.archived,
      exportId: exportId ?? this.exportId,
      sizes: sizes ?? this.sizes,
      sizePrices: sizePrices ?? this.sizePrices,
      additionalToppingPrices:
          additionalToppingPrices ?? this.additionalToppingPrices,
      includedIngredients: includedIngredients ?? this.includedIngredients,
      customizationGroups: customizationGroups ?? this.customizationGroups,
      optionalAddOns: optionalAddOns ?? this.optionalAddOns,
      customizations: customizations ?? this.customizations,
      crustTypes: crustTypes ?? this.crustTypes,
      cookTypes: cookTypes ?? this.cookTypes,
      cutStyles: cutStyles ?? this.cutStyles,
      sauceOptions: sauceOptions ?? this.sauceOptions,
      dressingOptions: dressingOptions ?? this.dressingOptions,
      maxFreeToppings: maxFreeToppings ?? this.maxFreeToppings,
      maxFreeSauces: maxFreeSauces ?? this.maxFreeSauces,
      maxFreeDressings: maxFreeDressings ?? this.maxFreeDressings,
      maxToppings: maxToppings ?? this.maxToppings,
      customizationsUpdatedAt:
          customizationsUpdatedAt ?? this.customizationsUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      comboId: comboId ?? this.comboId,
      bundleItems: bundleItems ?? this.bundleItems,
      bundleDiscount: bundleDiscount ?? this.bundleDiscount,
      highlightTags: highlightTags ?? this.highlightTags,
      allowSpecialInstructions:
          allowSpecialInstructions ?? this.allowSpecialInstructions,
      hideInMenu: hideInMenu ?? this.hideInMenu,
      freeSauceCount: freeSauceCount ?? this.freeSauceCount,
      extraSauceUpcharge: extraSauceUpcharge ?? this.extraSauceUpcharge,
      freeDressingCount: freeDressingCount ?? this.freeDressingCount,
      extraDressingUpcharge:
          extraDressingUpcharge ?? this.extraDressingUpcharge,
      // Wings
      dippingSauceOptions: dippingSauceOptions ?? this.dippingSauceOptions,
      dippingSplits: dippingSplits ?? this.dippingSplits,
      sideDipSauceOptions: sideDipSauceOptions ?? this.sideDipSauceOptions,
      freeDipCupCount: freeDipCupCount ?? this.freeDipCupCount,
      sideDipUpcharge: sideDipUpcharge ?? this.sideDipUpcharge,
      // NEW: template refs
      templateRefs: templateRefs ?? this.templateRefs,
    );
  }
}
