import 'package:cloud_firestore/cloud_firestore.dart';
import 'nutrition_info.dart';
import 'customization.dart';
import 'package:admin_portal/core/models/size_template.dart';
import 'dart:convert';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:flutter/material.dart';

extension IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Enum for supported crust/cook/cut types.
enum CrustType { thin, regular, thick, glutenFree }

enum CookType { regular, crispy, wellDone }

enum CutStyle { square, pie }

class MenuItem {
  final String id;
  final bool available;
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
  final List<SizeData>? sizes; // ['Small', 'Medium', 'Large']
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
      'sizes': sizes?.map((s) => s.toMap()).toList(),
      'sizePrices': sizePrices,
      'includedIngredients': includedIngredients,
      'optionalAddOns': optionalAddOns,
      'customizations': customizations.map((c) => c.toFirestore()).toList(),
      'rawCustomizations': rawCustomizations,
      'maxFreeSauces': maxFreeSauces,
      'extraSauceUpcharge': extraSauceUpcharge,
      'extraCharges': extraCharges,
      'customizationGroups': customizationGroups,
    };
  }

  MenuItem({
    required this.id,
    required this.available,
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

  /// Convenience: returns true if this item is marked unavailable
  bool get outOfStock => !availability;

  /// Convenience: returns a non-null image string
  String get imageUrl => image ?? '';

  factory MenuItem.fromFirestore(Map<String, dynamic> data, String id) {
    try {
      double resolvedPrice = 0.0;
      Map<String, double>? resolvedSizePrices;

      Map<String, double>? parseStringDoubleMap(dynamic raw) {
        try {
          if (raw == null) return null;
          if (raw is Map) {
            return raw.map((k, v) => MapEntry(
                k.toString(),
                (v is num)
                    ? v.toDouble()
                    : double.tryParse(v.toString()) ?? 0));
          }
          if (raw is String) {
            final parsed = jsonDecode(raw);
            if (parsed is Map) {
              return parsed.map((k, v) => MapEntry(
                  k.toString(),
                  (v is num)
                      ? v.toDouble()
                      : double.tryParse(v.toString()) ?? 0));
            }
          }
        } catch (e, st) {
          debugPrint('[MenuItem] Failed to parse string-double map: $e');
          ErrorLogger.log(
            message: 'Failed to parse string-double map',
            stack: st.toString(),
            source: 'MenuItem.fromFirestore',
            screen: 'MenuItem',
            contextData: {'raw': raw.toString()},
          );
        }
        return null;
      }

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
      if (data['customizations'] is List) {
        try {
          customizations = (data['customizations'] as List)
              .map((e) =>
                  Customization.fromFirestore(Map<String, dynamic>.from(e)))
              .toList();
        } catch (e, st) {
          ErrorLogger.log(
            message: 'Malformed customization entry',
            stack: st.toString(),
            source: 'MenuItem.fromFirestore',
            screen: 'MenuItem',
          );
        }
      }

      final safeGroups = <Map<String, dynamic>>[];
      for (final g in (data['customizationGroups'] as List?) ?? []) {
        if (g is Map) {
          safeGroups.add(Map<String, dynamic>.from(g));
        } else {
          debugPrint('[MenuItem] Skipped invalid customizationGroup: $g');
          ErrorLogger.log(
            message: 'Skipped malformed customizationGroup entry',
            source: 'MenuItem.fromFirestore',
            screen: 'MenuItem',
            contextData: {'entry': g.toString()},
          );
        }
      }

      final safeAddOns = <Map<String, dynamic>>[];
      for (final o in (data['optionalAddOns'] as List?) ?? []) {
        if (o is Map) {
          safeAddOns.add(Map<String, dynamic>.from(o));
        } else {
          debugPrint('[MenuItem] Skipped invalid optionalAddOn: $o');
          ErrorLogger.log(
            message: 'Skipped malformed optionalAddOn entry',
            source: 'MenuItem.fromFirestore',
            screen: 'MenuItem',
            contextData: {'entry': o.toString()},
          );
        }
      }

      final safeIncluded = <Map<String, dynamic>>[];
      for (final i in (data['includedIngredients'] as List?) ?? []) {
        if (i is Map) {
          safeIncluded.add(Map<String, dynamic>.from(i));
        } else {
          debugPrint('[MenuItem] Skipped invalid includedIngredient: $i');
          ErrorLogger.log(
            message: 'Skipped malformed includedIngredient entry',
            source: 'MenuItem.fromFirestore',
            screen: 'MenuItem',
            contextData: {'entry': i.toString()},
          );
        }
      }

      return MenuItem(
        id: id,
        available: data['available'] ?? true,
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
        dietaryTags: List<String>.from(data['dietaryTags'] ?? []),
        allergens: List<String>.from(data['allergens'] ?? []),
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
        sizes: (() {
          final sizesRaw = data['sizes'];
          final pricesRaw = data['sizePrices'];
          final toppingPricesRaw = data['additionalToppingPrices'];

          if (sizesRaw is List && sizesRaw.isNotEmpty) {
            // If list of maps, use as is (standard app save)
            if (sizesRaw.first is Map) {
              return sizesRaw
                  .map((e) => SizeData.fromMap(Map<String, dynamic>.from(e)))
                  .toList();
            }
            // If list of strings, pair with price maps
            if (sizesRaw.first is String || sizesRaw.first is! Map) {
              final sizeLabels = sizesRaw.map((e) => e.toString()).toList();

              Map<String, double> priceMap = {};
              if (pricesRaw is Map) {
                priceMap = pricesRaw.map(
                  (k, v) =>
                      MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0.0),
                );
              }

              Map<String, double> toppingMap = {};
              if (toppingPricesRaw is Map) {
                toppingMap = toppingPricesRaw.map(
                  (k, v) =>
                      MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0.0),
                );
              }

              return sizeLabels
                  .map((size) => SizeData(
                        label: size,
                        basePrice: priceMap[size] ?? 0.0,
                        toppingPrice: toppingMap[size] ?? 0.0,
                      ))
                  .toList();
            }
          }
          return <SizeData>[];
        })(),
        sizePrices: data['sizePrices'] != null
            ? Map<String, double>.from((data['sizePrices'] as Map)
                .map((key, value) => MapEntry(key, (value as num).toDouble())))
            : resolvedSizePrices,
        additionalToppingPrices:
            parseStringDoubleMap(data['additionalToppingPrices']),
        includedIngredients: safeIncluded.isEmpty ? null : safeIncluded,
        customizationGroups: safeGroups.isEmpty ? null : safeGroups,
        optionalAddOns: safeAddOns.isEmpty ? null : safeAddOns,
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
        bundleItems: (data['bundleItems'] is List)
            ? List<String>.from(data['bundleItems'])
            : null,
        bundleDiscount: (data['bundleDiscount'] as num?)?.toDouble(),
        highlightTags: data['highlightTags'] == null
            ? null
            : List<String>.from(data['highlightTags']),
        allowSpecialInstructions: data['allowSpecialInstructions'],
        hideInMenu: data['hideInMenu'],
        freeSauceCount: (data['freeSauceCount'] is Map)
            ? Map.fromEntries(
                (data['freeSauceCount'] as Map)
                    .entries
                    .where((e) => e.key != null && e.value != null)
                    .map((e) {
                  final parsed = int.tryParse(e.value.toString());
                  return MapEntry(e.key.toString(), parsed ?? 0);
                }),
              )
            : null,
        extraSauceUpcharge: (data['extraSauceUpcharge'] as num?)?.toDouble(),
        freeDressingCount: data['freeDressingCount'],
        extraDressingUpcharge:
            (data['extraDressingUpcharge'] as num?)?.toDouble(),
        dippingSauceOptions: data['dippingSauceOptions'] == null
            ? null
            : List<String>.from(data['dippingSauceOptions']),
        dippingSplits: (data['dippingSplits'] is Map)
            ? Map.fromEntries(
                (data['dippingSplits'] as Map)
                    .entries
                    .where((e) => e.key != null && e.value != null)
                    .map((e) {
                  final parsed = int.tryParse(e.value.toString());
                  return MapEntry(e.key.toString(), parsed ?? 0);
                }),
              )
            : null,
        sideDipSauceOptions: data['sideDipSauceOptions'] == null
            ? null
            : List<String>.from(data['sideDipSauceOptions']),
        freeDipCupCount: (data['freeDipCupCount'] is Map)
            ? Map.fromEntries(
                (data['freeDipCupCount'] as Map)
                    .entries
                    .where((e) => e.key != null && e.value != null)
                    .map((e) {
                  final parsed = int.tryParse(e.value.toString());
                  return MapEntry(e.key.toString(), parsed ?? 0);
                }),
              )
            : null,
        sideDipUpcharge: (data['sideDipUpcharge'] is Map)
            ? Map.fromEntries(
                (data['sideDipUpcharge'] as Map)
                    .entries
                    .where((e) => e.key != null && e.value != null)
                    .map((e) {
                  final parsed = double.tryParse(e.value.toString());
                  return MapEntry(e.key.toString(), parsed ?? 0.0);
                }),
              )
            : null,
        templateRefs:
            (data['templateRefs'] as List?)?.map((e) => e.toString()).toList(),
      );
    } catch (e, st) {
      ErrorLogger.log(
        message: 'MenuItem.fromFirestore threw exception',
        source: 'MenuItem.fromFirestore',
        screen: 'menu_item_provider.dart',
        severity: 'error',
        stack: st.toString(),
        contextData: {
          'id': id,
          'rawData': data.map((k, v) => MapEntry(
              k, v is Timestamp ? v.toDate().toIso8601String() : v.toString())),
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  factory MenuItem.fromMap(Map<String, dynamic> data, [String? id]) {
    try {
      return MenuItem.fromFirestore(data, id ?? data['id'] ?? '');
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'MenuItem.fromMap failed',
        source: 'MenuItem.fromMap',
        screen: 'menu_item_provider.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'id': id ?? data['id'] ?? '',
          'rawData': data.map((k, v) => MapEntry(k, v.toString())),
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Creates a MenuItem for onboarding from a raw template map.
  /// Ensures all model fields are present and ready for mapping/repair UI.
  /// Fields not present in the template are set to '' (String), 0.0 (double), or null/empty for advanced fields.
  /// Use this to create the initial onboarding state for a menu item from template.
  factory MenuItem.fromTemplate(Map<String, dynamic> template,
      {String? idOverride}) {
    // Safely unwrap and initialize all model fields.
    return MenuItem(
      id: idOverride ?? template['id'] ?? '',
      name: template['name'] ?? '',
      description: template['description'] ?? '',
      price: (template['price'] is num)
          ? (template['price'] as num).toDouble()
          : 0.0,
      category: template['category'] ?? '',
      categoryId: template['categoryId'] ?? '',
      image: template['image'],
      available: template['available'] ?? true,
      availability: template['availability'] ?? template['available'] ?? true,
      notes: template['notes'],
      taxCategory: template['taxCategory'] ?? '',
      sku: template['sku'],
      dietaryTags: List<String>.from(template['dietaryTags'] ?? []),
      allergens: List<String>.from(template['allergens'] ?? []),
      prepTime: template['prepTime'],
      nutrition: template['nutrition'] != null
          ? NutritionInfo.fromFirestore(
              Map<String, dynamic>.from(template['nutrition']))
          : null,
      sortOrder: template['sortOrder'],
      lastModified: null,
      lastModifiedBy: null,
      archived: template['archived'] ?? false,
      exportId: template['exportId'],
      sizes: (template['sizes'] as List?)
          ?.whereType<Map>()
          .map((e) => SizeData.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      sizePrices: template['sizePrices'] != null
          ? Map<String, double>.from((template['sizePrices'] as Map)
              .map((key, value) => MapEntry(key, (value as num).toDouble())))
          : null,
      additionalToppingPrices: template['additionalToppingPrices'] != null
          ? Map<String, double>.from((template['additionalToppingPrices']
                  as Map)
              .map((key, value) => MapEntry(key, (value as num).toDouble())))
          : null,
      includedIngredients: (template['includedIngredients'] as List?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      customizationGroups: (template['customizationGroups'] as List?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      optionalAddOns: (template['optionalAddOns'] as List?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      customizations: (template['customizations'] as List?)
              ?.map((e) =>
                  Customization.fromFirestore(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      rawCustomizations: (template['rawCustomizations'] as List?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      crustTypes: template['crustTypes'] == null
          ? null
          : List<String>.from(template['crustTypes']),
      cookTypes: template['cookTypes'] == null
          ? null
          : List<String>.from(template['cookTypes']),
      cutStyles: template['cutStyles'] == null
          ? null
          : List<String>.from(template['cutStyles']),
      sauceOptions: template['sauceOptions'] == null
          ? null
          : List<String>.from(template['sauceOptions']),
      dressingOptions: template['dressingOptions'] == null
          ? null
          : List<String>.from(template['dressingOptions']),
      maxFreeToppings: template['maxFreeToppings'],
      maxFreeSauces: template['maxFreeSauces'],
      maxFreeDressings: template['maxFreeDressings'],
      maxToppings: template['maxToppings'],
      customizationsUpdatedAt: null,
      createdAt: null,
      comboId: template['comboId'],
      bundleItems: template['bundleItems'] == null
          ? null
          : List<String>.from(template['bundleItems']),
      bundleDiscount: (template['bundleDiscount'] as num?)?.toDouble(),
      highlightTags: template['highlightTags'] == null
          ? null
          : List<String>.from(template['highlightTags']),
      allowSpecialInstructions: template['allowSpecialInstructions'],
      hideInMenu: template['hideInMenu'],
      freeSauceCount: template['freeSauceCount'],
      extraSauceUpcharge: (template['extraSauceUpcharge'] as num?)?.toDouble(),
      freeDressingCount: template['freeDressingCount'],
      extraDressingUpcharge:
          (template['extraDressingUpcharge'] as num?)?.toDouble(),
      dippingSauceOptions: template['dippingSauceOptions'] == null
          ? null
          : List<String>.from(template['dippingSauceOptions']),
      dippingSplits: template['dippingSplits'] == null
          ? null
          : Map<String, int>.from(template['dippingSplits']),
      sideDipSauceOptions: template['sideDipSauceOptions'] == null
          ? null
          : List<String>.from(template['sideDipSauceOptions']),
      freeDipCupCount: template['freeDipCupCount'] == null
          ? null
          : Map<String, int>.from(template['freeDipCupCount']),
      sideDipUpcharge: template['sideDipUpcharge'] == null
          ? null
          : Map<String, double>.from(template['sideDipUpcharge']),
      templateRefs: template['templateRefs'] == null
          ? null
          : List<String>.from(template['templateRefs']),
      extraCharges: template['extraCharges'],
    );
  }

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
      if (sizes != null) 'sizes': sizes!.map((s) => s.toMap()).toList(),
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
      if (templateRefs != null) 'templateRefs': templateRefs,
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
    bool? available,
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
    List<SizeData>? sizes,
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
      available: available ?? this.available,
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

  factory MenuItem.fromJson(Map<String, dynamic> data) =>
      MenuItem.fromMap(data);

  /// Checks if this menu item references a given categoryId (case-insensitive).
  bool matchesCategoryId(String? otherCategoryId) =>
      otherCategoryId != null &&
      categoryId.toLowerCase() == otherCategoryId.toLowerCase();

  /// Checks if this menu item references a given category name (case-insensitive, trimmed).
  bool matchesCategoryName(String? otherName) =>
      otherName != null &&
      category.trim().toLowerCase() == otherName.trim().toLowerCase();

  /// Returns a list of all ingredient IDs referenced by this item (included, add-ons, customization groups).
  List<String> get allReferencedIngredientIds {
    final ids = <String>{};
    ids.addAll(includedIngredientIds);
    ids.addAll(optionalAddOnIds);
    ids.addAll(allGroupIngredientIds);
    return ids.toList();
  }

  /// Returns all referenced ingredient type IDs, if present.
  List<String> get allReferencedIngredientTypeIds {
    // Checks includedIngredients and optionalAddOns for 'typeId'
    final ids = <String>{};
    if (includedIngredients != null) {
      for (final e in includedIngredients!) {
        if (e.containsKey('typeId') &&
            e['typeId'] is String &&
            (e['typeId'] as String).isNotEmpty) {
          ids.add(e['typeId']);
        }
      }
    }
    if (optionalAddOns != null) {
      for (final e in optionalAddOns!) {
        if (e.containsKey('typeId') &&
            e['typeId'] is String &&
            (e['typeId'] as String).isNotEmpty) {
          ids.add(e['typeId']);
        }
      }
    }
    return ids.toList();
  }

  /// Utility: Checks for missing references by comparing to schema lists.
  /// Returns a map of schema element type to list of missing values.
  Map<String, List<String>> findSchemaIssues({
    required List<String> validCategoryIds,
    required List<String> validIngredientIds,
    required List<String> validIngredientTypeIds,
  }) {
    final issues = <String, List<String>>{};

    // Category
    if (!validCategoryIds.any((id) => matchesCategoryId(id))) {
      issues['categoryId'] = [categoryId];
    }

    // Ingredients
    final missingIngredients = allReferencedIngredientIds
        .where((id) => !validIngredientIds.contains(id))
        .toList();
    if (missingIngredients.isNotEmpty) {
      issues['ingredients'] = missingIngredients;
    }

    // Ingredient Types
    final missingTypes = allReferencedIngredientTypeIds
        .where((id) => !validIngredientTypeIds.contains(id))
        .toList();
    if (missingTypes.isNotEmpty) {
      issues['ingredientTypes'] = missingTypes;
    }

    return issues;
  }

  /// Warn if critical fields are missing (for onboarding/mapping/debugging).
  String? get schemaWarning {
    if (id.isEmpty || name.isEmpty || categoryId.isEmpty) {
      return "MenuItem missing required id, name, or categoryId: id='$id', name='$name', categoryId='$categoryId'";
    }
    return null;
  }

  /// Returns a list of all required or critical fields missing from onboarding/template import.
  /// Used to block Save and drive the repair UI.
  /// Update this list as your onboarding requirements evolve!
  List<String> missingRequiredFields() {
    final missing = <String>[];

    // Core fields
    if (name.isEmpty) missing.add('name');
    if (description.isEmpty) missing.add('description');
    if (categoryId.isEmpty) missing.add('categoryId');
    if (category.isEmpty) missing.add('category');
    if (image == null || image!.isEmpty) missing.add('image');
    if (taxCategory.isEmpty) missing.add('taxCategory');
    if (price == 0.0 && (sizePrices == null || sizePrices!.isEmpty))
      missing.add('price');
    if (availability != true && available != true) missing.add('available');

    // Ingredient/Customization structure
    if (includedIngredients == null || includedIngredients!.isEmpty)
      missing.add('includedIngredients');
    if (customizationGroups == null || customizationGroups!.isEmpty)
      missing.add('customizationGroups');

    // Add-ons (optional, but commonly required for certain categories)
    // if (optionalAddOns == null || optionalAddOns!.isEmpty) missing.add('optionalAddOns');

    // Sizing (for multi-size items)
    if ((sizePrices != null && sizePrices!.isNotEmpty) &&
        (sizes == null || sizes!.isEmpty)) missing.add('sizes');

    // Customizations
    if (customizations.isEmpty) missing.add('customizations');

    // Advanced/Meta fields (optional—uncomment if needed for your workflow)
    // if (sku == null || sku!.isEmpty) missing.add('sku');
    // if (prepTime == null) missing.add('prepTime');
    // if (nutrition == null) missing.add('nutrition');
    // if (notes == null || notes!.isEmpty) missing.add('notes');

    // Advanced upcharge fields (required for certain categories like pizza/wings)
    // if (additionalToppingPrices == null) missing.add('additionalToppingPrices');
    // if (freeSauceCount == null) missing.add('freeSauceCount');

    // Required fields for your platform
    // if (templateRefs == null || templateRefs!.isEmpty) missing.add('templateRefs');

    // Add any other logic as needed for your onboarding flow

    return missing;
  }
}
