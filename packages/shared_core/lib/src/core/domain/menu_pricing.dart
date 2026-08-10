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
    if (maxFreeFromGroup != null) return maxFreeFromGroup;

    final value = item.freeDressingCount ?? item.freeSauceCount;
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
          final meta = ingredientMetadata[ingId];
          double upcharge = usesDynamicToppingPricing
              ? (toppingUpcharge?.call() ?? 0.0)
              : (meta != null
                  ? (ingredientUpcharge?.call(meta) ?? 0.0)
                  : (addOn['price'] as num?)?.toDouble() ?? 0.0);
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
      final upcharge = item.sideDipUpcharge?[selectedSize] ?? 0.95;
      final freeDips = item.freeDipCupCount?[selectedSize] ?? 0;
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

  /// Mirrors modal _resolveExtraIngredientPrice.
  static double resolveExtraIngredientPrice({
    required MenuItem item,
    required String? selectedSize,
    required String ingId,
    required Map<String, IngredientMetadata> ingredientMetadata,
  }) {
    final usesDynamic = selectedSize != null &&
        (item.additionalToppingPrices != null ||
            (item.sizes?.isNotEmpty ?? false));
    if (usesDynamic) {
      return toppingUpcharge(item, selectedSize);
    }
    final fromMeta = ingredientUpcharge(ingredientMetadata[ingId]);
    if (fromMeta > 0) return fromMeta;
    for (final addOn in item.optionalAddOns ?? const []) {
      final id = (addOn['ingredientId'] ?? addOn['id'] ?? '').toString();
      if (id == ingId) {
        return (addOn['price'] as num?)?.toDouble() ?? 0.0;
      }
    }
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

      if (!wasIncluded && (isDinner(item) || salad) && upcharge <= 0) {
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

    return total;
  }
}
