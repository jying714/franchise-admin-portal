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

  // Selection maps — populated/synced by modal; mutations migrate in B2.2.x.
  Set<String> currentIngredients = <String>{};
  Set<String> selectedAddOns = <String>{};
  Map<String, bool> doubleAddOns = <String, bool>{};
  Map<String, bool> doubleToppings = <String, bool>{};
  Map<String, int> selectedSauceCounts = <String, int>{};
  Map<String, int> selectedDressingCounts = <String, int>{};
  Map<String, int> sideDipCounts = <String, int>{};

  // Cheeses (B2.2.2)
  Set<String> selectedCheeses = <String>{};
  Map<String, bool> cheeseIsDouble = <String, bool>{};

  /// Values are portion name strings: 'whole' | 'left' | 'right'
  Map<String, String> cheesePortions = <String, String>{};

  // UI-resolved maxFree (from _groupsForUi) — set by modal before reading totals.
  int? maxFreeSaucesFromGroup;
  int? maxFreeDressingsFromGroup;
  int? maxFreeToppingsFromGroup;
  int? maxFreeMeatsFromGroup;
  List<String> wingSauceIds = const [];

  int get quantity => _quantity;
  String? get selectedSize => _selectedSize;
  Map<String, shared.IngredientMetadata> get ingredientMap => _ingredientMap;

  // Pizza sauces (B2.2.3) — parallel to modal PizzaSauceSelection
  /// Each entry: id, name, selected, portion ('whole'|'left'|'right'), amount
  List<Map<String, dynamic>> pizzaSauceSelections = <Map<String, dynamic>>[];
  bool sauceSplitValidationError = false;

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
    Set<String>? selectedCheeses,
    Map<String, bool>? cheeseIsDouble,
    Map<String, String>? cheesePortions,
    int? maxFreeSaucesFromGroup,
    int? maxFreeDressingsFromGroup,
    int? maxFreeToppingsFromGroup,
    int? maxFreeMeatsFromGroup,
    List<String>? wingSauceIds,
    List<Map<String, dynamic>>? pizzaSauceSelections,
    bool? sauceSplitValidationError,
  }) {
    this.currentIngredients = currentIngredients;
    this.selectedAddOns = selectedAddOns;
    this.doubleAddOns = doubleAddOns;
    this.doubleToppings = doubleToppings;
    this.selectedSauceCounts = selectedSauceCounts;
    this.selectedDressingCounts = selectedDressingCounts;
    this.sideDipCounts = sideDipCounts;
    if (selectedCheeses != null) {
      this.selectedCheeses = selectedCheeses;
    }
    if (cheeseIsDouble != null) {
      this.cheeseIsDouble = cheeseIsDouble;
    }
    if (cheesePortions != null) {
      this.cheesePortions = cheesePortions;
    }
    this.maxFreeSaucesFromGroup = maxFreeSaucesFromGroup;
    this.maxFreeDressingsFromGroup = maxFreeDressingsFromGroup;
    this.maxFreeToppingsFromGroup = maxFreeToppingsFromGroup;
    this.maxFreeMeatsFromGroup = maxFreeMeatsFromGroup;
    if (wingSauceIds != null) this.wingSauceIds = wingSauceIds;
    if (pizzaSauceSelections != null) {
      this.pizzaSauceSelections =
          List<Map<String, dynamic>>.from(pizzaSauceSelections);
    }
    if (sauceSplitValidationError != null) {
      this.sauceSplitValidationError = sauceSplitValidationError;
    }
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

  void toggleIngredient({
    required String ingId,
    required String groupLabel,
    required List<Map<String, dynamic>> groupsForUi,
    required bool isPizzaOrCalzone,
  }) {
    if (currentIngredients.contains(ingId)) {
      currentIngredients.remove(ingId);
      doubleToppings.remove(ingId);
      notifyListeners();
      return;
    }

    final group = groupsForUi.firstWhere(
      (g) => (g['label']?.toString() ?? '') == groupLabel,
      orElse: () => <String, dynamic>{},
    );
    final max = (group['max'] as int?) ?? 0;
    if (max > 0) {
      final ids = (group['ingredientIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toSet();
      if (currentIngredients.where((id) => ids.contains(id)).length >= max) {
        return;
      }
    }

    currentIngredients.add(ingId);
    if (isPizzaOrCalzone) {
      doubleToppings[ingId] = false;
    }
    notifyListeners();
  }

  void setDoubleTopping(String ingId, bool value, {int maxDoubles = 4}) {
    if (!value && doubleToppings[ingId] != true) return;
    if (value) {
      final count = doubleToppings.values.where((v) => v).length;
      if (count >= maxDoubles) return;
    }
    doubleToppings[ingId] = value;
    notifyListeners();
  }

  void setSauceCount(String ingId, int count) {
    selectedSauceCounts[ingId] = count.clamp(0, 100);
    notifyListeners();
  }

  void setDressingCount(String ingId, int count) {
    selectedDressingCounts[ingId] = count.clamp(0, 100);
    notifyListeners();
  }

  void toggleAddOn(
    String ingId,
    bool val, {
    required bool addToCurrentIngredients,
  }) {
    if (val) {
      selectedAddOns.add(ingId);
      doubleAddOns[ingId] = false;
      if (addToCurrentIngredients) {
        currentIngredients.add(ingId);
        doubleToppings[ingId] = false;
      }
    } else {
      selectedAddOns.remove(ingId);
      doubleAddOns.remove(ingId);
      if (addToCurrentIngredients) {
        currentIngredients.remove(ingId);
        doubleToppings.remove(ingId);
      }
    }
    notifyListeners();
  }

  void setSideDipCount(String ingId, int count) {
    sideDipCounts[ingId] = count.clamp(0, 1000);
    notifyListeners();
  }

  void addCheese(String cheeseId, {int max = 0}) {
    if (max > 0 && selectedCheeses.length >= max) return;
    if (selectedCheeses.contains(cheeseId)) return;
    selectedCheeses.add(cheeseId);
    cheeseIsDouble[cheeseId] = false;
    cheesePortions[cheeseId] = 'whole';
    notifyListeners();
  }

  void removeCheese(String cheeseId) {
    selectedCheeses.remove(cheeseId);
    cheeseIsDouble.remove(cheeseId);
    cheesePortions.remove(cheeseId);
    notifyListeners();
  }

  void setCheesePortion(String cheeseId, String portion) {
    if (!selectedCheeses.contains(cheeseId)) return;
    cheesePortions[cheeseId] = portion;
    notifyListeners();
  }

  void setCheeseDouble(String cheeseId, bool value) {
    if (!selectedCheeses.contains(cheeseId)) return;
    cheeseIsDouble[cheeseId] = value;
    notifyListeners();
  }

  void toggleCheeseDouble(String cheeseId) {
    if (!selectedCheeses.contains(cheeseId)) return;
    cheeseIsDouble[cheeseId] = !(cheeseIsDouble[cheeseId] ?? false);
    notifyListeners();
  }

  int get _selectedPizzaSauceCount =>
      pizzaSauceSelections.where((s) => s['selected'] == true).length;

  void setPizzaSauceSelected(String sauceId, bool selected, {int max = 2}) {
    final idx = pizzaSauceSelections.indexWhere((s) => s['id'] == sauceId);
    if (idx < 0) return;
    if (selected && _selectedPizzaSauceCount >= max) return;
    final next = Map<String, dynamic>.from(pizzaSauceSelections[idx]);
    next['selected'] = selected;
    if (selected) {
      next['portion'] = next['portion'] ?? 'whole';
    }
    pizzaSauceSelections[idx] = next;
    sauceSplitValidationError = false;
    notifyListeners();
  }

  void setPizzaSaucePortion(String sauceId, String portion) {
    final idx = pizzaSauceSelections.indexWhere((s) => s['id'] == sauceId);
    if (idx < 0) return;
    final next = Map<String, dynamic>.from(pizzaSauceSelections[idx]);
    next['portion'] = portion;
    next['selected'] = true;
    pizzaSauceSelections[idx] = next;

    if (portion == 'whole') {
      for (var i = 0; i < pizzaSauceSelections.length; i++) {
        if (i == idx) continue;
        final other = Map<String, dynamic>.from(pizzaSauceSelections[i]);
        other['selected'] = false;
        other['portion'] = 'whole';
        pizzaSauceSelections[i] = other;
      }
    } else {
      for (var i = 0; i < pizzaSauceSelections.length; i++) {
        if (i == idx) continue;
        final other = pizzaSauceSelections[i];
        if (other['selected'] == true && other['portion'] == portion) {
          final cleared = Map<String, dynamic>.from(other);
          cleared['selected'] = false;
          cleared['portion'] = 'whole';
          pizzaSauceSelections[i] = cleared;
        }
      }
    }
    sauceSplitValidationError = false;
    notifyListeners();
  }

  void setPizzaSauceAmount(String sauceId, String amount) {
    final idx = pizzaSauceSelections.indexWhere((s) => s['id'] == sauceId);
    if (idx < 0) return;
    final next = Map<String, dynamic>.from(pizzaSauceSelections[idx]);
    next['amount'] = amount;
    next['selected'] = true;
    pizzaSauceSelections[idx] = next;
    notifyListeners();
  }

  void togglePizzaSauceAmountDouble(String sauceId) {
    final idx = pizzaSauceSelections.indexWhere((s) => s['id'] == sauceId);
    if (idx < 0) return;
    final cur = (pizzaSauceSelections[idx]['amount'] as String? ?? 'regular')
        .toLowerCase();
    final isDouble = cur == 'extra' || cur == 'double';
    setPizzaSauceAmount(sauceId, isDouble ? 'regular' : 'extra');
  }
}
