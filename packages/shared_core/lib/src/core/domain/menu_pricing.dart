// packages/shared_core/lib/src/core/domain/menu_pricing.dart
//
// Pure menu pricing helpers. No Flutter, no Firestore.
// Authority: docs/slices/customization-modal-decompose-v1.md (Phase B1)
// Arithmetic must match mobile_app customization_modal getters exactly.

import '../models/menu_item.dart';
import '../models/ingredient_metadata.dart';
import '../models/modifier_group.dart'; // MenuProfile
import 'menu_customization_selection.dart';

class MenuPricing {
  MenuPricing._();

  /// Maps UI size labels to Firestore sizePrices / additionalToppingPrices keys.
  /// Mirrors _normalizeSizeKey in customization_modal.dart.
  static String normalizeSizeKey(MenuItem item, String? uiSize) {
    if (uiSize == null || uiSize.isEmpty) return '';

    final toppingPrices = item.additionalToppingPrices;
    if (toppingPrices != null && toppingPrices.containsKey(uiSize)) {
      return uiSize;
    }

    final sizePrices = item.sizePrices;
    if (sizePrices != null && sizePrices.containsKey(uiSize)) {
      return uiSize;
    }

    // Pizza-oriented aliases used by the modal when sizePrices keys are "Small 10\"", etc.
    const pizzaSizeMap = <String, String>{
      'Small 10"': 'Small 10"',
      'Medium 12"': 'Medium 12"',
      'Large 14"': 'Large 14"',
      'XL 16"': 'XL 16"',
      'Small': 'Small 10"',
      'Medium': 'Medium 12"',
      'Large': 'Large 14"',
      'XL': 'XL 16"',
    };

    final mapped = pizzaSizeMap[uiSize];
    if (mapped != null) {
      if (sizePrices != null && sizePrices.containsKey(mapped)) return mapped;
      if (toppingPrices != null && toppingPrices.containsKey(mapped)) {
        return mapped;
      }
      return mapped;
    }

    return uiSize;
  }

  /// Resolve a per-size map entry (freeDipCupCount, sideDipUpcharge, etc.).
  /// Tries exact label, normalizeSizeKey, size-list labels, case-insensitive,
  /// then single-entry fallback.
  static V? lookupSizeMapValue<V>(
    MenuItem item,
    Map<String, V>? map,
    String? selectedSize,
  ) {
    if (map == null ||
        map.isEmpty ||
        selectedSize == null ||
        selectedSize.isEmpty) {
      return null;
    }
    if (map.containsKey(selectedSize)) return map[selectedSize];

    final key = normalizeSizeKey(item, selectedSize);
    if (key.isNotEmpty && map.containsKey(key)) return map[key];

    final sizes = item.sizes;
    if (sizes != null) {
      for (final s in sizes) {
        if (s.label == selectedSize ||
            (key.isNotEmpty && normalizeSizeKey(item, s.label) == key)) {
          if (map.containsKey(s.label)) return map[s.label];
        }
      }
    }

    final lower = selectedSize.toLowerCase().trim();
    final keyLower = key.toLowerCase().trim();
    for (final e in map.entries) {
      final ek = e.key.toLowerCase().trim();
      if (ek == lower || (keyLower.isNotEmpty && ek == keyLower)) {
        return e.value;
      }
    }

    // Compact labels: "6pc" vs "6 pc" vs "6-pc"
    String compact(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');
    final compactSel = compact(selectedSize);
    for (final e in map.entries) {
      if (compact(e.key) == compactSel) return e.value;
    }

    if (map.length == 1) return map.values.first;
    return null;
  }

  static int freeDipCupCountForSize(MenuItem item, String? selectedSize) {
    return lookupSizeMapValue(item, item.freeDipCupCount, selectedSize) ?? 0;
  }

  static double sideDipUpchargeForSize(MenuItem item, String? selectedSize) {
    return lookupSizeMapValue(item, item.sideDipUpcharge, selectedSize) ?? 0.95;
  }

  /// Unit base price for the selected size.
  /// Mirrors _basePrice in customization_modal.dart.
  static double basePrice(MenuItem item, String? selectedSize) {
    final key = normalizeSizeKey(item, selectedSize);
    if (key.isNotEmpty &&
        item.sizePrices != null &&
        item.sizePrices![key] != null) {
      return (item.sizePrices![key] as num).toDouble();
    }

    final sizes = item.sizes;
    if (sizes != null && selectedSize != null) {
      for (final s in sizes) {
        if (s.label == selectedSize || normalizeSizeKey(item, s.label) == key) {
          return s.basePrice;
        }
      }
    }

    return item.price;
  }

  /// Line total before cart-level promos: (base + customizations) * quantity.
  static double lineTotal({
    required MenuItem item,
    required String? selectedSize,
    required double customizationsTotal,
    required int quantity,
  }) {
    final q = quantity < 1 ? 1 : quantity;
    return (basePrice(item, selectedSize) + customizationsTotal) * q;
  }

  /// Free sauce count for size. Mirrors modal _getFreeSauceCount (without group max).
  /// Pass [maxFreeFromGroup] when the UI already resolved modifier-group maxFree for "sauces".
  static int freeSauceCount(
    MenuItem item,
    String? selectedSize, {
    int? maxFreeFromGroup,
  }) {
    if (maxFreeFromGroup != null) return maxFreeFromGroup;

    final value = item.freeSauceCount;
    if (value is Map) {
      final key = normalizeSizeKey(item, selectedSize);
      if (key.isNotEmpty && value[key] != null) {
        return (value[key] as num).toInt();
      }
      return 0;
    }
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  /// Free dressing count for size. Mirrors modal _getFreeDressingCount (without group max).
  static int freeDressingCount(
    MenuItem item,
    String? selectedSize, {
    int? maxFreeFromGroup,
  }) {
    // Item-level freeDressingCount is HQ source of truth for salad (and when set).
    // Group maxFree is only a fallback when the item field is absent.
    final value = item.freeDressingCount ?? item.freeSauceCount;
    if (value is Map) {
      final key = normalizeSizeKey(item, selectedSize);
      if (key.isNotEmpty && value[key] != null) {
        return (value[key] as num).toInt();
      }
      // Map present but no size key — fall through to group / 0
    } else if (value is int) {
      return value;
    } else if (value is num) {
      return value.toInt();
    }

    if (maxFreeFromGroup != null) return maxFreeFromGroup;
    return 0;
  }

  /// Extra sauce upcharge. Mirrors modal _getExtraSauceUpcharge.
  static double extraSauceUpcharge(MenuItem item) {
    return (item.extraSauceUpcharge as num?)?.toDouble() ?? 0.95;
  }

  /// Extra dressing upcharge. Mirrors modal _getExtraDressingUpcharge.
  static double extraDressingUpcharge(MenuItem item) {
    return (item.extraDressingUpcharge as num?)?.toDouble() ??
        (item.extraSauceUpcharge as num?)?.toDouble() ??
        0.50;
  }

  /// Charge for sauces beyond free allowance.
  static double extraSauceCharge({
    required MenuItem item,
    required String? selectedSize,
    required int selectedSauceTotal,
    int? maxFreeFromGroup,
  }) {
    final free =
        freeSauceCount(item, selectedSize, maxFreeFromGroup: maxFreeFromGroup);
    final extra = selectedSauceTotal > free ? (selectedSauceTotal - free) : 0;
    return extra * extraSauceUpcharge(item);
  }

  /// Charge for dressings beyond free allowance.
  static double extraDressingCharge({
    required MenuItem item,
    required String? selectedSize,
    required int selectedDressingTotal,
    int? maxFreeFromGroup,
  }) {
    final free = freeDressingCount(item, selectedSize,
        maxFreeFromGroup: maxFreeFromGroup);
    final extra =
        selectedDressingTotal > free ? (selectedDressingTotal - free) : 0;
    return extra * extraDressingUpcharge(item);
  }

  static bool isPizzaOrCalzone(MenuItem item) {
    final profile = item.effectiveMenuProfile.toLowerCase();
    if (profile == MenuProfile.pizza || profile == MenuProfile.calzone) {
      return true;
    }
    final cat = item.category.toLowerCase();
    return cat.contains('pizza') || cat.contains('calzone');
  }

  static bool isWings(MenuItem item) {
    final profile = item.effectiveMenuProfile.toLowerCase();
    if (profile == MenuProfile.wings) return true;
    return item.name.toLowerCase().contains('wings');
  }

  static bool isSalad(MenuItem item) {
    final profile = item.effectiveMenuProfile.toLowerCase().trim();
    if (profile == MenuProfile.salad) return true;
    final cat = item.category.toLowerCase();
    final catId = (item.categoryId ?? '').toLowerCase();
    return cat.contains('salad') || catId.contains('salad');
  }

  static bool isDinner(MenuItem item) {
    final cat = item.category.toLowerCase();
    final catId = (item.categoryId ?? '').toLowerCase();
    return cat.contains('dinner') || catId.contains('dinner');
  }

  static bool isSub(MenuItem item) {
    return item.effectiveMenuProfile.toLowerCase() == MenuProfile.sub;
  }

  /// True if [ingredientId] appears in includedIngredients (id or ingredientId keys).
  static bool wasIncludedIngredient(MenuItem item, String ingredientId) {
    final raw = item.includedIngredients;
    if (raw == null) return false;
    final want = ingredientId.trim();
    for (final e in raw) {
      final a = (e['ingredientId'] ?? '').toString().trim();
      final b = (e['id'] ?? '').toString().trim();
      if (a == want || b == want) return true;
    }
    return false;
  }

  static List<String> effectiveWingSauceIds(MenuItem item) {
    if (item.sideDipSauceOptions?.isNotEmpty == true) {
      return List<String>.from(item.sideDipSauceOptions!);
    }
    if (item.dippingSauceOptions?.isNotEmpty == true) {
      return List<String>.from(item.dippingSauceOptions!);
    }
    final groups = item.modifierGroups ?? const [];
    final fromGroups = <String>[];
    for (final g in groups) {
      final label = (g.label ?? g.id ?? '').toString().toLowerCase();
      if (label.contains('wing') &&
          (label.contains('sauce') || label.contains('dip'))) {
        for (final o in g.options) {
          final id = o.ingredientId ?? o.id;
          if (id != null && id.isNotEmpty) fromGroups.add(id);
        }
      }
    }
    return fromGroups;
  }

  /// Add-ons + dressings + sauces + wings side dips only.
  /// Ingredient-loop (section 4) stays in the modal until B1.4.
  static double customizationsTotalPartial({
    required MenuItem item,
    required MenuCustomizationSelection selection,
    required Map<String, IngredientMetadata> ingredientMetadata,
    double Function()? toppingUpcharge,
    double Function(IngredientMetadata meta)? ingredientUpcharge,
    List<String>? wingSauceIds,
    int? maxFreeSaucesFromGroup,
    int? maxFreeDressingsFromGroup,
  }) {
    double total = 0.0;
    final selectedSize = selection.selectedSize;
    final usesDynamicToppingPricing = selectedSize != null &&
        (item.additionalToppingPrices != null ||
            (item.sizes?.isNotEmpty ?? false));

    final saladDinnerSub = isSalad(item) || isDinner(item) || isSub(item);

    // 1. Add-ons
    if (item.optionalAddOns != null) {
      for (final addOn in item.optionalAddOns!) {
        final ingId = (addOn['ingredientId'] ?? addOn['id'])?.toString();
        if (ingId == null || ingId.isEmpty) continue;

        if (saladDinnerSub && selection.currentIngredients.contains(ingId)) {
          continue;
        }
        if (wasIncludedIngredient(item, ingId)) continue;

        if (selection.selectedAddOns.contains(ingId)) {
          final upcharge = resolveExtraIngredientPrice(
            item: item,
            selectedSize: selectedSize,
            ingId: ingId,
            ingredientMetadata: ingredientMetadata,
          );
          final multiplier = selection.doubleAddOns[ingId] == true ? 2 : 1;
          total += upcharge * multiplier;
        }
      }
    }

    // 2. Dressings
    if (selection.selectedDressingCounts.isNotEmpty) {
      final totalDressings =
          selection.selectedDressingCounts.values.fold(0, (a, b) => a + b);
      total += extraDressingCharge(
        item: item,
        selectedSize: selectedSize,
        selectedDressingTotal: totalDressings,
        maxFreeFromGroup: maxFreeDressingsFromGroup,
      );
    }

    // 3. Sauces
    if (selection.selectedSauceCounts.isNotEmpty) {
      final totalSauces =
          selection.selectedSauceCounts.values.fold(0, (a, b) => a + b);
      total += extraSauceCharge(
        item: item,
        selectedSize: selectedSize,
        selectedSauceTotal: totalSauces,
        maxFreeFromGroup: maxFreeSaucesFromGroup,
      );
    }

    // Wings side dips
    if (isWings(item)) {
      final upcharge = sideDipUpchargeForSize(item, selectedSize);
      final freeDips = freeDipCupCountForSize(item, selectedSize);
      final dipIds = wingSauceIds ?? effectiveWingSauceIds(item);
      final totalDipCups = dipIds.fold<int>(
        0,
        (sum, id) => sum + (selection.sideDipCounts[id] ?? 0),
      );
      final extraDips = (totalDipCups - freeDips).clamp(0, 1000);
      total += extraDips * upcharge;

      final sauceAddOnIds = (item.optionalAddOns ?? [])
          .where((a) => (a['type']?.toString().toLowerCase() == 'sauces'))
          .map((a) => (a['ingredientId'] ?? a['id'])?.toString())
          .whereType<String>();
      for (final id in sauceAddOnIds) {
        final count = selection.sideDipCounts[id] ?? 0;
        total += count * upcharge;
      }
    }

    return total;
  }

  static const Set<String> doughIds = {
    'dough_calzone',
    'dough_pizza',
    'dough',
  };

  static bool isDoughIngredient(String? ingId) =>
      ingId != null && doughIds.contains(ingId.toLowerCase());

  /// Mirrors modal _getToppingUpcharge.
  static double toppingUpcharge(MenuItem item, String? selectedSize) {
    final prices = item.additionalToppingPrices;
    final key = normalizeSizeKey(item, selectedSize);
    if (prices != null && key.isNotEmpty && prices[key] != null) {
      return (prices[key] as num).toDouble();
    }
    final sizes = item.sizes;
    if (sizes != null && selectedSize != null) {
      for (final s in sizes) {
        if (s.label == selectedSize || normalizeSizeKey(item, s.label) == key) {
          return s.toppingPrice;
        }
      }
    }
    return 0.0;
  }

  /// Mirrors modal _getIngredientUpcharge.
  static double ingredientUpcharge(IngredientMetadata? meta) {
    if (meta == null) return 0.0;
    if (meta.upcharge != null && meta.upcharge!.isNotEmpty) {
      return meta.upcharge!.values.first;
    }
    return 0.0;
  }

  /// Override map entry for [ingId], if any.
  static Map<String, dynamic>? _optionalOverrideFor(
    MenuItem item,
    String ingId,
  ) {
    final list = item.optionalAddonPriceOverrides;
    if (list == null) return null;
    for (final raw in list) {
      final id = (raw['ingredientId'] ?? raw['id'] ?? '').toString().trim();
      if (id == ingId) return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  static double? _priceFromOverrideMap(
    Map<String, dynamic> override,
    MenuItem item,
    String? selectedSize,
  ) {
    final bySize = override['priceBySize'];
    if (bySize is Map && selectedSize != null) {
      final key = normalizeSizeKey(item, selectedSize);
      for (final e in bySize.entries) {
        final k = e.key.toString();
        if (k == selectedSize || normalizeSizeKey(item, k) == key) {
          final v = e.value;
          if (v is num) return v.toDouble();
        }
      }
    }
    final flat = override['price'];
    if (flat is num) return flat.toDouble();
    return null;
  }

  /// Mirrors modal _resolveExtraIngredientPrice.
  static double resolveExtraIngredientPrice({
    required MenuItem item,
    required String? selectedSize,
    required String ingId,
    required Map<String, IngredientMetadata> ingredientMetadata,
  }) {
    // 1. Sparse override for this ingredient
    final override = _optionalOverrideFor(item, ingId);
    if (override != null) {
      final o = _priceFromOverrideMap(override, item, selectedSize);
      if (o != null) return o;
    }

    // 2. Size topping upcharge when item has sizes (house default extra)
    final usesDynamic = selectedSize != null &&
        (item.additionalToppingPrices != null ||
            (item.sizes?.isNotEmpty ?? false));
    if (usesDynamic) {
      return toppingUpcharge(item, selectedSize);
    }

    // 4. Legacy optionalAddOns[].price / upcharge
    for (final addOn in item.optionalAddOns ?? const []) {
      final id = (addOn['ingredientId'] ?? addOn['id'] ?? '').toString();
      if (id == ingId) {
        final p = addOn['price'] ?? addOn['upcharge'];
        if (p is num) return p.toDouble();
      }
    }

    // 5. Ingredient catalog upcharge
    final fromMeta = ingredientUpcharge(ingredientMetadata[ingId]);
    if (fromMeta > 0) return fromMeta;

    return 0.0;
  }

  /// Full customizations total = partial (1–3 + wings) + ingredient loop (4).
  static double customizationsTotal({
    required MenuItem item,
    required MenuCustomizationSelection selection,
    required Map<String, IngredientMetadata> ingredientMetadata,
    List<String>? wingSauceIds,
    int? maxFreeSaucesFromGroup,
    int? maxFreeDressingsFromGroup,
    int? maxFreeToppingsFromGroup,
    int? maxFreeMeatsFromGroup,
  }) {
    double total = customizationsTotalPartial(
      item: item,
      selection: selection,
      ingredientMetadata: ingredientMetadata,
      toppingUpcharge: () => toppingUpcharge(item, selection.selectedSize),
      ingredientUpcharge: ingredientUpcharge,
      wingSauceIds: wingSauceIds,
      maxFreeSaucesFromGroup: maxFreeSaucesFromGroup,
      maxFreeDressingsFromGroup: maxFreeDressingsFromGroup,
    );

    final selectedSize = selection.selectedSize;
    final usesDynamicToppingPricing = selectedSize != null &&
        (item.additionalToppingPrices != null ||
            (item.sizes?.isNotEmpty ?? false));

    for (final ingId in selection.currentIngredients) {
      if (isDoughIngredient(ingId)) continue;
      if (selection.selectedSauceCounts.containsKey(ingId)) continue;
      if (selection.selectedDressingCounts.containsKey(ingId)) continue;

      final meta = ingredientMetadata[ingId];

      if (meta?.type?.toLowerCase() == 'crust' ||
          meta?.type?.toLowerCase() == 'cook') {
        continue;
      }

      final cat = item.category.toLowerCase();
      final salad = cat.contains('salad');
      final wasIncluded = wasIncludedIngredient(item, ingId);

      double upcharge = usesDynamicToppingPricing
          ? toppingUpcharge(item, selectedSize)
          : ingredientUpcharge(meta);

      if (!wasIncluded &&
          (isDinner(item) || salad || isSub(item)) &&
          upcharge <= 0) {
        upcharge = resolveExtraIngredientPrice(
          item: item,
          selectedSize: selectedSize,
          ingId: ingId,
          ingredientMetadata: ingredientMetadata,
        );
      }

      final isDouble = selection.doubleToppings[ingId] == true;

      if (salad) {
        if (wasIncluded) {
          if (isDouble) total += upcharge;
        } else {
          total += upcharge * (isDouble ? 2 : 1);
        }
      } else {
        if (isPizzaOrCalzone(item) && !wasIncluded) {
          final freeToppings =
              maxFreeToppingsFromGroup ?? maxFreeMeatsFromGroup ?? 0;
          final extraIds = selection.currentIngredients.where((id) {
            if (isDoughIngredient(id)) return false;
            if (selection.selectedSauceCounts.containsKey(id)) return false;
            if (selection.selectedDressingCounts.containsKey(id)) return false;
            return !wasIncludedIngredient(item, id);
          }).toList();
          final indexAmongExtras = extraIds.indexOf(ingId);
          final beyondFree =
              freeToppings <= 0 || indexAmongExtras >= freeToppings;
          if (beyondFree) {
            total += upcharge * (isDouble ? 2 : 1);
          } else if (isDouble) {
            total += upcharge;
          }
        } else if (wasIncluded) {
          if (isDouble) total += upcharge;
        } else {
          total += upcharge * (isDouble ? 2 : 1);
        }
      }
    }

    // Pizza/calzone cheeses live outside currentIngredients. Double = one
    // topping upcharge (same as doubling an included topping).
    if (isPizzaOrCalzone(item)) {
      final cheeseUpcharge =
          usesDynamicToppingPricing ? toppingUpcharge(item, selectedSize) : 0.0;
      for (final cheeseId in selection.selectedCheeses) {
        if (selection.cheeseIsDouble[cheeseId] != true) continue;
        final meta = ingredientMetadata[cheeseId];
        final upcharge =
            cheeseUpcharge > 0 ? cheeseUpcharge : ingredientUpcharge(meta);
        total += upcharge;
      }
    }

    return total;
  }
}
