// packages/shared_core/lib/src/core/domain/menu_pricing.dart
//
// Pure menu pricing helpers. No Flutter, no Firestore.
// Authority: docs/slices/customization-modal-decompose-v1.md (Phase B1)
// Arithmetic must match mobile_app customization_modal getters exactly.

import '../models/menu_item.dart';

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
}
