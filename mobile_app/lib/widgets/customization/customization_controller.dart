// mobile_app/lib/widgets/customization/customization_controller.dart
//
// Owns customization selection + pricing. Phase B2.
// Authority: docs/slices/customization-modal-decompose-v1.md

import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart' as shared;

class CustomizationController extends ChangeNotifier {
  CustomizationController({
    required this.item,
    required Map<String, shared.IngredientMetadata> ingredientMap,
    int initialQuantity = 1,
    Map<String, dynamic>? initialCustomizations,
  }) : _ingredientMap =
            Map<String, shared.IngredientMetadata>.from(ingredientMap) {
    _quantity = initialQuantity < 1 ? 1 : initialQuantity;
    // Size default: first size label if present, else null (caller may set).
    final sizes = item.sizes;
    if (sizes != null && sizes.isNotEmpty) {
      _selectedSize = sizes.first.label;
    }
    // initialCustomizations applied by modal for now (B2.2).
  }

  final shared.MenuItem item;
  final Map<String, shared.IngredientMetadata> _ingredientMap;

  int _quantity = 1;
  String? _selectedSize;

  // Selection maps — populated/synced by modal until B2.2 owns mutations.
  Set<String> currentIngredients = <String>{};
  Set<String> selectedAddOns = <String>{};
  Map<String, bool> doubleAddOns = <String, bool>{};
  Map<String, bool> doubleToppings = <String, bool>{};
  Map<String, int> selectedSauceCounts = <String, int>{};
  Map<String, int> selectedDressingCounts = <String, int>{};
  Map<String, int> sideDipCounts = <String, int>{};

  // UI-resolved maxFree (from _groupsForUi) — set by modal before reading totals.
  int? maxFreeSaucesFromGroup;
  int? maxFreeDressingsFromGroup;
  int? maxFreeToppingsFromGroup;
  int? maxFreeMeatsFromGroup;
  List<String> wingSauceIds = const [];

  int get quantity => _quantity;
  String? get selectedSize => _selectedSize;
  Map<String, shared.IngredientMetadata> get ingredientMap => _ingredientMap;

  void setQuantity(int value) {
    final q = value < 1 ? 1 : value;
    if (q == _quantity) return;
    _quantity = q;
    notifyListeners();
  }

  void setSelectedSize(String? size) {
    if (size == _selectedSize) return;
    _selectedSize = size;
    notifyListeners();
  }

  /// Sync selection maps from modal State without owning mutations yet.
  void syncSelection({
    required Set<String> currentIngredients,
    required Set<String> selectedAddOns,
    required Map<String, bool> doubleAddOns,
    required Map<String, bool> doubleToppings,
    required Map<String, int> selectedSauceCounts,
    required Map<String, int> selectedDressingCounts,
    required Map<String, int> sideDipCounts,
    int? maxFreeSaucesFromGroup,
    int? maxFreeDressingsFromGroup,
    int? maxFreeToppingsFromGroup,
    int? maxFreeMeatsFromGroup,
    List<String>? wingSauceIds,
  }) {
    this.currentIngredients = currentIngredients;
    this.selectedAddOns = selectedAddOns;
    this.doubleAddOns = doubleAddOns;
    this.doubleToppings = doubleToppings;
    this.selectedSauceCounts = selectedSauceCounts;
    this.selectedDressingCounts = selectedDressingCounts;
    this.sideDipCounts = sideDipCounts;
    this.maxFreeSaucesFromGroup = maxFreeSaucesFromGroup;
    this.maxFreeDressingsFromGroup = maxFreeDressingsFromGroup;
    this.maxFreeToppingsFromGroup = maxFreeToppingsFromGroup;
    this.maxFreeMeatsFromGroup = maxFreeMeatsFromGroup;
    if (wingSauceIds != null) this.wingSauceIds = wingSauceIds;
  }

  shared.MenuCustomizationSelection get selectionSnapshot =>
      shared.MenuCustomizationSelection(
        selectedSize: _selectedSize,
        currentIngredients: currentIngredients,
        selectedAddOns: selectedAddOns,
        doubleAddOns: Map<String, bool>.from(doubleAddOns),
        doubleToppings: Map<String, bool>.from(doubleToppings),
        selectedSauceCounts: Map<String, int>.from(selectedSauceCounts),
        selectedDressingCounts: Map<String, int>.from(selectedDressingCounts),
        sideDipCounts: Map<String, int>.from(sideDipCounts),
      );

  double get basePrice => shared.MenuPricing.basePrice(item, _selectedSize);

  double get customizationsTotal => shared.MenuPricing.customizationsTotal(
        item: item,
        selection: selectionSnapshot,
        ingredientMetadata: _ingredientMap,
        wingSauceIds: wingSauceIds,
        maxFreeSaucesFromGroup: maxFreeSaucesFromGroup,
        maxFreeDressingsFromGroup: maxFreeDressingsFromGroup,
        maxFreeToppingsFromGroup: maxFreeToppingsFromGroup,
        maxFreeMeatsFromGroup: maxFreeMeatsFromGroup,
      );

  double get totalPrice => shared.MenuPricing.lineTotal(
        item: item,
        selectedSize: _selectedSize,
        customizationsTotal: customizationsTotal,
        quantity: _quantity,
      );
}
