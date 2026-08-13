// packages/shared_core/lib/src/core/domain/menu_customization_selection.dart
// Snapshot of modal selection state for pure pricing. Phase B1.3

class MenuCustomizationSelection {
  const MenuCustomizationSelection({
    required this.selectedSize,
    required this.currentIngredients,
    required this.selectedAddOns,
    required this.doubleAddOns,
    required this.doubleToppings,
    required this.selectedSauceCounts,
    required this.selectedDressingCounts,
    required this.sideDipCounts,
    this.selectedCheeses = const <String>{},
    this.cheeseIsDouble = const <String, bool>{},
  });

  final String? selectedSize;
  final Set<String> currentIngredients;
  final Set<String> selectedAddOns;
  final Map<String, bool> doubleAddOns;
  final Map<String, bool> doubleToppings;
  final Map<String, int> selectedSauceCounts;
  final Map<String, int> selectedDressingCounts;
  final Map<String, int> sideDipCounts;
  final Set<String> selectedCheeses;
  final Map<String, bool> cheeseIsDouble;
}
