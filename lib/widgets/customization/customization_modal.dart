// ignore_for_file: prefer_const_constructors
import 'package:franchise_admin_portal/widgets/customization/pizza_sauce_selector_tab.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:franchise_admin_portal/core/utils/formatting.dart';
import 'package:franchise_admin_portal/core/models/menu_item.dart';
import 'package:franchise_admin_portal/core/models/ingredient_metadata.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/widgets/portion_selector.dart';
import 'package:franchise_admin_portal/widgets/customization/dressing_selector_group.dart';
import 'package:franchise_admin_portal/widgets/customization/sauce_selector_group.dart';
import 'package:franchise_admin_portal/widgets/customization/checkbox_customization_group.dart';
import 'package:franchise_admin_portal/widgets/customization/dinner_included_ingredients.dart';
import 'package:franchise_admin_portal/widgets/customization/radio_customization_group.dart';
import 'package:franchise_admin_portal/widgets/customization/drinks_flavor_selector.dart';
import 'package:franchise_admin_portal/widgets/customization/portion_pill_toggle.dart';
import 'package:franchise_admin_portal/widgets/customization/optional_addons_group.dart';
import 'package:franchise_admin_portal/widgets/customization/wings_optional_addons_group.dart';
import 'package:franchise_admin_portal/widgets/customization/wings_dip_sauce_selector.dart';
import 'package:franchise_admin_portal/widgets/customization/wings_portion_selector.dart';
import 'package:franchise_admin_portal/widgets/customization/size_dropdown.dart';
import 'package:franchise_admin_portal/widgets/customization/topping_cost_label.dart';
import 'package:franchise_admin_portal/widgets/customization/current_ingredients.dart';
import 'package:franchise_admin_portal/widgets/customization/header.dart';
import 'package:franchise_admin_portal/widgets/customization/bottom_bar.dart';

const MAX_DOUBLES = 4;
const DOUGH_IDS = {'dough_calzone', 'dough_pizza', 'dough'};
int _wingsDipSauceTabIndex = 0;
const portionNames = {
  Portion.whole: "Whole",
  Portion.left: "Left",
  Portion.right: "Right"
};

extension StringCasingExtension on String {
  String capitalize() =>
      this.isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

class PizzaSauceSelection {
  final String id;
  final String name;
  bool selected;
  Portion portion;
  String amount;

  PizzaSauceSelection({
    required this.id,
    required this.name,
    this.selected = false,
    this.portion = Portion.whole,
    this.amount = 'regular',
  });

  PizzaSauceSelection copyWith({
    bool? selected,
    Portion? portion,
    String? amount,
  }) {
    return PizzaSauceSelection(
      id: id,
      name: name,
      selected: selected ?? this.selected,
      portion: portion ?? this.portion,
      amount: amount ?? this.amount,
    );
  }
}

class CustomizationModal extends StatefulWidget {
  final MenuItem menuItem;
  final int initialQuantity;
  final Map<String, dynamic>? initialCustomizations;
  final void Function(
    Map<String, dynamic> customizations,
    int quantity,
    double totalPrice,
  ) onConfirm;
  final Map<String, IngredientMetadata>? ingredientMetadata;

  const CustomizationModal({
    super.key,
    required this.menuItem,
    this.ingredientMetadata,
    this.initialQuantity = 1,
    this.initialCustomizations,
    required this.onConfirm,
  });

  @override
  State<CustomizationModal> createState() => _CustomizationModalState();
}

class _CustomizationModalState extends State<CustomizationModal> {
  late int _quantity;
  late Set<String> _currentIngredients;
  late Map<String, Set<String>> _groupSelections;
  late Set<String> _selectedAddOns;
  late Map<String, String?> _radioSelections;
  String? _selectedSize;
  String? _error;
  late Map<String, IngredientMetadata> _ingredientMetadata;

  late List<Map<String, dynamic>> _checkboxGroups;
  late List<Map<String, dynamic>> _radioGroups;
  String? _selectedSauceId;

  final Map<String, bool> _doubleToppings = {};
  final Map<String, Portion> _ingredientPortions = {};
  final Map<String, bool> _doubleAddOns = {};
  final Map<String, int> _selectedSauceCounts = {};
  final Map<String, int> _selectedDressingCounts = {};

  final Map<String, String> _ingredientAmounts =
      {}; // ingredientId -> "Light"/"Regular"/"Extra"

  // --- Cheeses-specific fields ---
  late Set<String> _selectedCheeses;
  late Map<String, Portion> _cheesePortions;
  late Map<String, bool> _cheeseIsDouble;

  // --- Wings-specific fields ---
  late Map<String, String?> _selectedDippedSauces; // For split dipped choices
  late bool _isAnyDipped; // True if any part is dipped
  late Map<String, int> _sideDipCounts; // For extra dip cups per flavor

  // Drinks state
  late Map<String, int> _drinkFlavorCounts; // ingredientId -> count
  int _drinkTotalCount = 0;
  int _drinkMaxPerFlavor = 10; // Default, overwritten by Firestore value

  // --- Pizza Sauce State ---
  String? _selectedPizzaSauceId;
  String _selectedSaucePortion = 'whole'; // 'whole', 'left', 'right'
  String _selectedSauceAmount = 'regular'; // 'light', 'regular', 'extra'

  List<PizzaSauceSelection> _pizzaSauceSelections = [];
  bool _sauceSplitValidationError = false;

  // --- grouped tabs for meats and veggies for pizzas / calzones ---
  late List<String>
      _toppingTabLabels; // Will be ["Meats", "Veggies"] if present
  String _selectedToppingTab = '';
  late List<Map<String, dynamic>> _toppingTabGroups;

  void _handleSauceTap(int index) {
    setState(() {
      final selectedCount =
          _pizzaSauceSelections.where((s) => s.selected).length;
      final current = _pizzaSauceSelections[index];

      // If currently not selected and already two other sauces are selected, block
      if (!current.selected && selectedCount >= 2) {
        return; // Only allow two
      }

      // Toggling selection
      _pizzaSauceSelections[index] =
          current.copyWith(selected: !current.selected);

      // Always keep at least one sauce selected
      if (_pizzaSauceSelections.where((s) => s.selected).isEmpty) {
        _pizzaSauceSelections[index] = current.copyWith(selected: true);
      }

      // If toggled to selected, set to default portion if not set
      if (_pizzaSauceSelections[index].selected) {
        // Set default to 'whole', unless already split
        _pizzaSauceSelections[index] =
            _pizzaSauceSelections[index].copyWith(portion: Portion.whole);
      }

      // If toggling off in a split, clear validation error
      _sauceSplitValidationError = false;
    });
  }

// This function ensures only valid splits
  void _handleSaucePortionChange(int index, Portion portion) {
    setState(() {
      _pizzaSauceSelections[index] = _pizzaSauceSelections[index]
          .copyWith(portion: portion, selected: true);

      // If setting to 'whole', clear all other sauce selections except this one
      if (portion == Portion.whole) {
        for (int i = 0; i < _pizzaSauceSelections.length; i++) {
          if (i != index) {
            _pizzaSauceSelections[i] = _pizzaSauceSelections[i]
                .copyWith(selected: false, portion: Portion.whole);
          }
        }
      } else {
        // If now split, allow one more 'half' selection only
        int halfCount = _pizzaSauceSelections
            .where((s) => s.selected && s.portion != Portion.whole)
            .length;
        if (halfCount == 2) {
          // Lock out any other selections
          for (int i = 0; i < _pizzaSauceSelections.length; i++) {
            if (i != index &&
                _pizzaSauceSelections[i].selected &&
                _pizzaSauceSelections[i].portion == portion) {
              // Prevent both selected sauces from being on the same side
              _pizzaSauceSelections[i] = _pizzaSauceSelections[i]
                  .copyWith(selected: false, portion: Portion.whole);
            }
          }
        }
      }
      _sauceSplitValidationError = false;
    });
  }

  void _resetPizzaSauceSelections() {
    setState(() {
      for (var s in _pizzaSauceSelections) {
        s.selected = false;
        s.portion = Portion.whole;
        s.amount = 'regular';
      }
      if (_pizzaSauceSelections.isNotEmpty) {
        _pizzaSauceSelections[0].selected = true;
        _pizzaSauceSelections[0].portion = Portion.whole;
        _pizzaSauceSelections[0].amount = 'regular';
      }
      _sauceSplitValidationError = false;
    });
  }

  // Helper to map UI size to Firestore key for upcharges
  String _normalizeSizeKey(String? uiSize) {
    if (uiSize == null) return '';
    final toppingPrices = widget.menuItem.additionalToppingPrices;
    if (toppingPrices != null && toppingPrices.containsKey(uiSize)) {
      return uiSize;
    }
    final pizzaSizeMap = <String, String>{
      "Small 10\"": "Small 10\"",
      "Medium 12\"": "Medium 12\"",
      "Large 14\"": "Large 14\"",
      "XL 16\"": "XL 16\"",
      "Small": "Small 10\"",
      "Medium": "Medium 12\"",
      "Large": "Large 14\"",
      "XL": "XL 16\"",
    };
    if (_isPizzaOrCalzone()) {
      if (pizzaSizeMap.containsKey(uiSize)) return pizzaSizeMap[uiSize]!;
      final lowerUi = uiSize.toLowerCase();
      for (final key in pizzaSizeMap.keys) {
        if (key.toLowerCase() == lowerUi ||
            key.toLowerCase().contains(lowerUi)) {
          return pizzaSizeMap[key]!;
        }
      }
    }
    return uiSize; // guaranteed not null by above
  }

  bool _showsCurrentIngredients() {
    final cat = widget.menuItem.category.toLowerCase();
    final catId = (widget.menuItem.categoryId ?? '').toLowerCase();
    return [cat, catId].any((c) =>
        c.contains('pizza') ||
        c.contains('calzone') ||
        c.contains('salad') ||
        c.contains('sub'));
  }

  bool _isPizzaOrCalzone() {
    final cat = widget.menuItem.category.toLowerCase();
    return cat.contains('pizza') || cat.contains('calzone');
  }

  bool _isCalzone() {
    return widget.menuItem.category.toLowerCase().contains('calzone');
  }

  bool _isWings() {
    final name = widget.menuItem.name.toLowerCase();
    return name.contains('wings');
  }

  bool _showPortionToggle(String groupLabel) {
    if (!_isPizzaOrCalzone()) return false;
    return groupLabel == "Meats" ||
        groupLabel == "Veggies" ||
        groupLabel == "Cheeses";
  }

  @override
  @override
  void initState() {
    super.initState();
    //print('[DEBUG] MenuItem for customization: ${widget.menuItem.toMap()}');

    // --- Initialize cheeses state (self-contained) ---
    final cheeseGroup = widget.menuItem.customizationGroups?.firstWhereOrNull(
        (g) => (g['label'] as String).toLowerCase() == 'cheeses');
    final cheeseIds =
        (cheeseGroup?['ingredientIds'] as List?)?.cast<String>() ?? [];
    _selectedCheeses = {
      ...?widget.menuItem.includedIngredients
          ?.where((i) => cheeseIds.contains(i['ingredientId'] ?? i['id']))
          .map((i) => i['ingredientId'] ?? i['id'])
    };
    _cheesePortions = {};
    _cheeseIsDouble = {};
    for (final id in _selectedCheeses) {
      _cheesePortions[id] = Portion.whole;
      _cheeseIsDouble[id] = false;
    }

    _quantity = widget.initialQuantity;
    _ingredientMetadata = widget.ingredientMetadata ??
        Provider.of<Map<String, IngredientMetadata>>(context, listen: false);
    final sizes = widget.menuItem.sizes;
    _selectedSize = (sizes != null && sizes.isNotEmpty) ? sizes.first : null;
    _drinkFlavorCounts = {};
    if (_isPizza()) {
      final saucesGroup = widget.menuItem.customizationGroups?.firstWhereOrNull(
          (g) => (g['label'] as String).toLowerCase() == 'sauces');
      final sauceIds =
          (saucesGroup?['ingredientIds'] as List?)?.cast<String>() ?? [];
      _pizzaSauceSelections = sauceIds.map((id) {
        final meta = _ingredientMetadata[id];
        return PizzaSauceSelection(
          id: id,
          name: meta?.name ?? id,
          selected: false,
          portion: Portion.whole,
          amount: 'regular',
        );
      }).toList();

      // Default to first available sauce, 'whole'
      if (_pizzaSauceSelections.isNotEmpty) {
        _pizzaSauceSelections[0].selected = true;
        _pizzaSauceSelections[0].portion = Portion.whole;
      }
    }
    _initializeSelections();
    if (_isPizza()) {
      // Find default sauce (first from sauces group, fallback to included ingredient, fallback to null)
      final saucesGroup = widget.menuItem.customizationGroups?.firstWhereOrNull(
          (g) => (g['label'] as String).toLowerCase() == 'sauces');
      final sauceIds =
          (saucesGroup?['ingredientIds'] as List?)?.cast<String>() ?? [];
      // Default: included sauce or first from group, or 'sauce_none'
      final includedSauceId =
          widget.menuItem.includedIngredients?.firstWhereOrNull(
        (ing) => (ing['type']?.toString()?.toLowerCase() == 'sauces'),
      )?['ingredientId'];
      _selectedPizzaSauceId = includedSauceId ??
          (sauceIds.isNotEmpty ? sauceIds.first : 'sauce_none');
      _selectedSaucePortion = 'whole';
      _selectedSauceAmount = 'regular';
    }
    _sortCustomizationGroups();
    // Setup pizza/calzone topping tabs for "Meats" and "Veggies" ONLY
    if (_isPizzaOrCalzone() && widget.menuItem.customizationGroups != null) {
      _toppingTabGroups = widget.menuItem.customizationGroups!
          .where((g) => (g['label']?.toString().toLowerCase() == 'meats' ||
              g['label']?.toString().toLowerCase() == 'veggies'))
          .toList();
      _toppingTabLabels =
          _toppingTabGroups.map((g) => g['label'].toString()).toList();
      _selectedToppingTab =
          _toppingTabLabels.isNotEmpty ? _toppingTabLabels.first : '';
    } else {
      _toppingTabLabels = [];
      _selectedToppingTab = '';
      _toppingTabGroups = [];
    }

    _initializeSauceCounts();
    _initializeDressingCounts();

    // --- Wings initialization ---
    if (_isWings()) {
      final sizes = widget.menuItem.sizes ?? [];
      _selectedSize ??= sizes.isNotEmpty ? sizes.first : null;
      final splitCount = widget.menuItem.dippingSplits?[_selectedSize] ?? 2;
      _selectedDippedSauces = {};
      final sauceOptions = widget.menuItem.dippingSauceOptions ?? [];
      for (var i = 0; i < splitCount; i++) {
        _selectedDippedSauces['split_$i'] = "plain";
      }

      _isAnyDipped = false;
      _sideDipCounts = {};
      final sideOptions = widget.menuItem.sideDipSauceOptions ?? [];
      for (final id in sideOptions) {
        _sideDipCounts[id] = 0;
      }
    }

    // --- Initialize ingredientAmounts for amountSelectable included ingredients ---
    if (widget.menuItem.includedIngredients != null) {
      for (final ing in widget.menuItem.includedIngredients!) {
        // First: check if present in ingredient_metadata, else fallback to map
        final ingId = ing['ingredientId'] ?? ing['id'];
        final meta = _ingredientMetadata[ingId];
        final List<String>? options = meta?.amountOptions ??
            (ing['amountOptions'] is List
                ? List<String>.from(ing['amountOptions'])
                : null);
        final bool selectable = meta?.amountSelectable ??
            (ing['amountSelectable'] == true && options != null);

        if (selectable && options != null && options.isNotEmpty) {
          // Prefer 'Regular' as default, fallback to first option
          _ingredientAmounts[ingId] = options.firstWhere(
            (opt) => opt.toLowerCase() == 'regular',
            orElse: () => options.first,
          );
        }
      }
    }
    if (widget.menuItem.category.toLowerCase() == 'drinks') {
      _drinkFlavorCounts = {};
      _drinkTotalCount = 0;
      // Try to get maxPerFlavor from Firestore field, else fallback
      _drinkMaxPerFlavor =
          (widget.menuItem.toMap()['maxPerFlavor'] as int?) ?? 10;
      for (final ing in widget.menuItem.includedIngredients ?? []) {
        final ingId = ing['ingredientId'] ?? ing['id'];
        _drinkFlavorCounts[ingId] = 0;
      }
    }
  }

  void _initializeSelections() {
    _currentIngredients = {};
    if (widget.menuItem.includedIngredients != null) {
      for (final ing in widget.menuItem.includedIngredients!) {
        final ingId = ing['ingredientId'] ?? ing['id'];
        _currentIngredients.add(ingId);
      }
    }
    _groupSelections = {};
    _radioSelections = {};
    if (widget.menuItem.customizationGroups != null) {
      for (final group in widget.menuItem.customizationGroups!) {
        final groupLabel = group['label'];
        final ids = (group['ingredientIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();

        // --- Default Cook to Regular for Calzones ---
        if (groupLabel.toLowerCase() == 'cook' &&
            widget.menuItem.category.toLowerCase().contains('calzone')) {
          _radioSelections[groupLabel] =
              ids.contains('cook_regular') ? 'cook_regular' : ids.first;
          _currentIngredients.add(_radioSelections[groupLabel]!);
          continue;
        }

        if (_isRadioGroup(groupLabel)) {
          final included = ids.firstWhere(
            (id) => _currentIngredients.contains(id),
            orElse: () => ids.isNotEmpty ? ids.first : '',
          );
          _radioSelections[groupLabel] = included;
        } else {
          _groupSelections[groupLabel] = <String>{};
        }
      }
    }

    _selectedAddOns = {};
  }

  void _initializeSauceCounts() {
    if (widget.menuItem.customizationGroups != null) {
      for (final group in widget.menuItem.customizationGroups!) {
        final label = (group['label'] as String?)?.toLowerCase();
        if (label == 'sauces') {
          final ids = (group['ingredientIds'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();
          for (final id in ids) {
            _selectedSauceCounts[id] = 0;
          }
        }
      }
    }
    // Also init for optionalAddOns that are sauces (for appetizers, etc)
    if (widget.menuItem.optionalAddOns != null) {
      for (final addOn in widget.menuItem.optionalAddOns!) {
        final ingId = addOn['ingredientId'] ?? addOn['id'];
        final meta = _ingredientMetadata[ingId];
        if (meta?.type?.toLowerCase() == "sauces" ||
            addOn['type']?.toString()?.toLowerCase() == "sauces") {
          _selectedSauceCounts[ingId] = 0;
        }
      }
    }
  }

  void _initializeDressingCounts() {
    if (widget.menuItem.customizationGroups != null) {
      for (final group in widget.menuItem.customizationGroups!) {
        final label = (group['label'] as String?)?.toLowerCase();
        if (label == 'dressings') {
          final ids = (group['ingredientIds'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();
          for (final id in ids) {
            _selectedDressingCounts[id] = 0;
          }
        }
      }
    }
  }

  void _sortCustomizationGroups() {
    _checkboxGroups = [];
    _radioGroups = [];
    if (widget.menuItem.customizationGroups != null) {
      for (final group in widget.menuItem.customizationGroups!) {
        final groupLabel = (group['label'] ?? '').toString();
        final isSauceGroup = groupLabel.toLowerCase() == 'sauces';
        final isDressingGroup = groupLabel.toLowerCase() == 'dressings';
        if (_isRadioGroup(groupLabel) || isSauceGroup || isDressingGroup) {
          _radioGroups.add(group);
        } else {
          // Exclude "Meats" and "Veggies" for pizza/calzone, they'll be handled as tabs
          if (!_isPizzaOrCalzone() ||
              (groupLabel.toLowerCase() != 'meats' &&
                  groupLabel.toLowerCase() != 'veggies')) {
            _checkboxGroups.add(group);
          }
        }
      }
    }
  }

  bool _isRadioGroup(String label) {
    final lower = label.toLowerCase();
    return lower == 'crust' || lower == 'cook' || lower == 'cut';
  }

  bool _isDoughIngredient(String? ingId) =>
      ingId != null && DOUGH_IDS.contains(ingId.toLowerCase());

  bool _canDoubleCurrentIngredient(String? groupLabel) {
    final cat = widget.menuItem.category.toLowerCase();
    if (cat.contains('pizza') || cat.contains('calzone')) {
      return groupLabel != null &&
          (groupLabel == "Meats" ||
              groupLabel == "Veggies" ||
              groupLabel == "Cheeses");
    }
    if (cat.contains('sub') || cat.contains('salad')) {
      return true;
    }
    return false;
  }

  bool _isPizza() {
    final cat = widget.menuItem.category.toLowerCase();
    return cat.contains('pizza');
  }

  Map<String, bool> _getPizzaSaucePortionDisables(int sauceIdx) {
    if (!_isPizza()) return {};
    final selected = _pizzaSauceSelections;
    // Find which sides (left/right/whole) are already used
    int leftIdx = -1, rightIdx = -1, wholeIdx = -1;
    for (int i = 0; i < selected.length; i++) {
      if (!selected[i].selected) continue;
      if (selected[i].portion == Portion.whole) wholeIdx = i;
      if (selected[i].portion == Portion.left) leftIdx = i;
      if (selected[i].portion == Portion.right) rightIdx = i;
    }

    // Default: nothing disabled
    bool disableLeft = false, disableRight = false, disableWhole = false;

    // If another sauce is selected as whole, only allow this to be whole if this is that sauce, otherwise disable all toggles
    if (wholeIdx != -1 && wholeIdx != sauceIdx) {
      disableLeft = true;
      disableRight = true;
      disableWhole = true;
    } else if ((leftIdx != -1 && leftIdx != sauceIdx) &&
        (rightIdx != -1 && rightIdx != sauceIdx)) {
      // If both halves are taken and this isn't one of them, everything disabled
      disableLeft = true;
      disableRight = true;
      disableWhole = true;
    } else if (leftIdx != -1 && leftIdx != sauceIdx) {
      // If Left is taken elsewhere, only Right is allowed here
      disableLeft = true;
      disableWhole = true;
    } else if (rightIdx != -1 && rightIdx != sauceIdx) {
      // If Right is taken elsewhere, only Left is allowed here
      disableRight = true;
      disableWhole = true;
    }
    // If this sauce isn't selected, and 2 sauces are already selected, don't allow selecting more
    if (!selected[sauceIdx].selected &&
        selected.where((s) => s.selected).length >= 2) {
      disableLeft = true;
      disableRight = true;
      disableWhole = true;
    }

    return {
      'left': disableLeft,
      'right': disableRight,
      'whole': disableWhole,
    };
  }

  double _getToppingUpcharge() {
    final prices = widget.menuItem.additionalToppingPrices;
    final key = _normalizeSizeKey(_selectedSize);
    if (prices != null && key != null && prices[key] != null) {
      return (prices[key] as num).toDouble();
    }
    return 0.0;
  }

  double _getIngredientUpcharge(IngredientMetadata? meta) {
    if (meta == null) return 0.0;
    if (meta.upcharge != null && meta.upcharge!.isNotEmpty) {
      return meta.upcharge!.values.first;
    }
    return 0.0;
  }

  int _getFreeSauceCount() {
    // Use freeSauceCount for sauces, and fallback to 2 if missing
    final value = widget.menuItem.freeSauceCount;
    if (value is Map) {
      final key = _normalizeSizeKey(_selectedSize);
      return (key != null && value[key] != null) ? value[key] as int : 0;
    }
    if (value is int) return value;
    return 0;
  }

  double _getExtraSauceUpcharge() {
    // Use extraSauceUpcharge if present, fallback to 0.95
    return (widget.menuItem.extraSauceUpcharge as num?)?.toDouble() ?? 0.95;
  }

  int _getFreeDressingCount() {
    final value =
        widget.menuItem.freeDressingCount ?? widget.menuItem.freeSauceCount;
    if (value is Map) {
      final key = _normalizeSizeKey(_selectedSize);
      return (key != null && value[key] != null) ? value[key] as int : 0;
    }
    if (value is int) return value;
    return 0;
  }

  double _getExtraDressingUpcharge() {
    return (widget.menuItem.extraDressingUpcharge as num?)?.toDouble() ??
        (widget.menuItem.extraSauceUpcharge as num?)?.toDouble() ??
        0.50;
  }

  double _getSaladToppingUpcharge() {
    final prices = widget.menuItem.additionalToppingPrices;
    final key = _normalizeSizeKey(_selectedSize);
    if (prices != null && key != null && prices[key] != null) {
      return (prices[key] as num).toDouble();
    }
    return 0.80;
  }

  double get _customizationsTotal {
    double total = 0.0;
    final usesDynamicToppingPricing =
        widget.menuItem.additionalToppingPrices != null &&
            _selectedSize != null;

    // 1. Add-ons
    if (widget.menuItem.optionalAddOns != null) {
      for (final addOn in widget.menuItem.optionalAddOns!) {
        final ingId = addOn['ingredientId'] ?? addOn['id'];
        if (_selectedAddOns.contains(ingId)) {
          final meta = _ingredientMetadata[ingId];
          double upcharge = usesDynamicToppingPricing
              ? _getToppingUpcharge()
              : (meta != null
                  ? _getIngredientUpcharge(meta)
                  : (addOn['price'] as num?)?.toDouble() ?? 0.0);
          int multiplier = _doubleAddOns[ingId] == true ? 2 : 1;
          total += upcharge * multiplier;
        }
      }
    }

    // 2. Dressings (stepper logic for salads, etc)
    if (_selectedDressingCounts.isNotEmpty) {
      final int freeDressings = _getFreeDressingCount();
      final double extraDressingUpcharge = _getExtraDressingUpcharge();
      final totalDressings =
          _selectedDressingCounts.values.fold(0, (a, b) => a + b);
      final extraDressings =
          totalDressings > freeDressings ? (totalDressings - freeDressings) : 0;
      total += extraDressings * extraDressingUpcharge;
    }

    // 3. Sauces (stepper logic for sauces as customization group or add-on)
    if (_selectedSauceCounts.isNotEmpty) {
      final int freeSauces = _getFreeSauceCount();
      final double extraSauceUpcharge = _getExtraSauceUpcharge();
      final totalSauces = _selectedSauceCounts.values.fold(0, (a, b) => a + b);
      final extraSauces =
          totalSauces > freeSauces ? (totalSauces - freeSauces) : 0;
      total += extraSauces * extraSauceUpcharge;
    }

    // --- Wings Side Dip Pricing ---
    if (_isWings()) {
      final upcharge = widget.menuItem.sideDipUpcharge?[_selectedSize] ?? 0.95;
      final freeDips = widget.menuItem.freeDipCupCount?[_selectedSize] ?? 0;
      // Only dips in dippingSauceOptions are eligible as "free"
      final dipIds = widget.menuItem.dippingSauceOptions ?? [];
      final totalDipCups = dipIds.fold<int>(
        0,
        (sum, id) => sum + (_sideDipCounts[id] ?? 0),
      );
      final extraDips = (totalDipCups - freeDips).clamp(0, 1000);
      total += extraDips * upcharge;

      // Now always upcharge for sauces (add-ons of type "sauces")
      final sauceAddOnIds = (widget.menuItem.optionalAddOns ?? [])
          .where((a) => (a['type']?.toString()?.toLowerCase() == 'sauces'))
          .map((a) => a['ingredientId'] ?? a['id'])
          .toList();
      for (final id in sauceAddOnIds) {
        final count = _sideDipCounts[id] ?? 0;
        total += count * upcharge; // No "free" sauces—always upcharge
      }
    }

    // 4. Ingredients (included or not) - handle doubles robustly!
    for (final ingId in _currentIngredients) {
      if (_isDoughIngredient(ingId)) continue;
      if (_selectedSauceCounts.containsKey(ingId)) continue; // skip sauces
      if (_selectedDressingCounts.containsKey(ingId))
        continue; // skip dressings

      final meta = _ingredientMetadata[ingId];

      // **NEW: skip Crust type (never charge for crust selection)**
      if (meta?.type?.toLowerCase() == 'crust' ||
          meta?.type?.toLowerCase() == 'cook') continue;

      final cat = widget.menuItem.category.toLowerCase();
      final isSalad = cat.contains('salad');
      final wasIncluded = (widget.menuItem.includedIngredients?.any(
            (e) => (e['ingredientId'] ?? e['id']) == ingId,
          ) ??
          false);

      double upcharge = usesDynamicToppingPricing
          ? _getToppingUpcharge()
          : _getIngredientUpcharge(meta);

      final isDouble = _doubleToppings[ingId] == true;

      if (isSalad) {
        // SALADS: Only apply upcharge for double, never for simple re-adding
        if (wasIncluded) {
          if (isDouble) total += upcharge;
          // else no upcharge, even if toggled off/on
        } else {
          // Not included: always apply upcharge (regular/double)
          total += upcharge * (isDouble ? 2 : 1);
        }
      } else {
        // All other categories: original logic
        if (wasIncluded) {
          if (isDouble) total += upcharge;
        } else {
          total += upcharge * (isDouble ? 2 : 1);
        }
      }
    }

    return total;
  }

  double get _basePrice {
    final key = _normalizeSizeKey(_selectedSize);
    if (key != null &&
        widget.menuItem.sizePrices != null &&
        widget.menuItem.sizePrices![key] != null) {
      return (widget.menuItem.sizePrices![key] as num).toDouble();
    }
    return widget.menuItem.price;
  }

  double get _totalPrice => (_basePrice + _customizationsTotal) * _quantity;

  int get _doublesCount =>
      _doubleToppings.values.where((isDouble) => isDouble).length;

  void _toggleIngredient(String ingId, String groupLabel) {
    setState(() {
      if (_currentIngredients.contains(ingId)) {
        _currentIngredients.remove(ingId);
        _doubleToppings.remove(ingId);
        _ingredientPortions.remove(ingId);
      } else {
        _currentIngredients.add(ingId);
        if (_isPizzaOrCalzone()) {
          _doubleToppings[ingId] = false;
          _ingredientPortions[ingId] = Portion.whole;
        }
      }
    });
  }

  void _handleDoubleChanged(String ingId, bool value) {
    if (!value && _doubleToppings[ingId] != true) return;
    setState(() {
      if (value && _doublesCount >= MAX_DOUBLES) return;
      _doubleToppings[ingId] = value;
    });
  }

  void _handlePortionChanged(String ingId, Portion? portion) {
    if (portion == null) return;
    setState(() {
      _ingredientPortions[ingId] = portion;
    });
  }

  void _handleRadioSelect(String groupLabel, String? ingId) {
    setState(() {
      _radioSelections[groupLabel] = ingId;
      if (widget.menuItem.customizationGroups != null) {
        final group = widget.menuItem.customizationGroups!.firstWhere(
            (g) => (g['label'] as String) == groupLabel,
            orElse: () => {});
        final ids = (group['ingredientIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        for (final id in ids) {
          _currentIngredients.remove(id);
        }
        if (ingId != null && ingId.isNotEmpty) _currentIngredients.add(ingId);
      }
    });
  }

  void _submit() {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[YourWidget] loc is null! Localization not available for this context.');
      // Show error to user if needed, e.g. using a SnackBar:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Localization missing! [debug]')),
      );
      return;
    }
    setState(() => _error = null);

    // --- RADIO GROUP VALIDATION ---
    if (widget.menuItem.customizationGroups != null) {
      for (final group in widget.menuItem.customizationGroups!) {
        final groupLabel = group['label'];
        if ((_isRadioGroup(groupLabel)) &&
            (_radioSelections[groupLabel] == null ||
                _radioSelections[groupLabel]!.isEmpty)) {
          setState(() => _error =
              loc.pleaseSelectRequired.replaceFirst('{name}', groupLabel));
          return;
        }
      }
    }

    // --- PIZZA SAUCE SPLIT VALIDATION ---
    if (_isPizza()) {
      final selected = _pizzaSauceSelections.where((s) => s.selected).toList();

      final halves = selected.where((s) => s.portion != Portion.whole).toList();
      if (halves.length == 1) {
        setState(() => _sauceSplitValidationError = true);
        return; // Must choose both halves or none!
      }
      if (selected.length > 2) {
        setState(() => _sauceSplitValidationError = true);
        return; // No more than 2!
      }
      // Validate no duplicate side selection (can't have two 'lefts' or two 'rights')
      if (halves.length == 2) {
        final sides = halves.map((s) => s.portion).toSet();
        if (sides.length < 2) {
          setState(() => _sauceSplitValidationError = true);
          return;
        }
      }
      setState(() => _sauceSplitValidationError = false);
    }

    final Map<String, dynamic> ingredientOptions = {};
    if (_isPizzaOrCalzone()) {
      for (final ingId in _currentIngredients) {
        if (_doubleToppings.containsKey(ingId) ||
            _ingredientPortions.containsKey(ingId)) {
          ingredientOptions[ingId] = {
            'double': _doubleToppings[ingId] == true,
            'portion': _ingredientPortions[ingId]?.toString().split('.').last ??
                'whole',
          };
        }
      }
    }

    // Only include sauces with a count > 0
    final nonZeroSauces = Map.fromEntries(
      _selectedSauceCounts.entries.where((e) => e.value > 0),
    );
    final nonZeroDressings = Map.fromEntries(
      _selectedDressingCounts.entries.where((e) => e.value > 0),
    );

    // Add cheese selections to submission result
    final Map<String, dynamic> cheeseOptions = {};
    for (final cheeseId in _selectedCheeses) {
      cheeseOptions[cheeseId] = {
        'portion':
            _cheesePortions[cheeseId]?.toString().split('.').last ?? 'whole',
        'double': _cheeseIsDouble[cheeseId] == true,
      };
    }

    final Map<String, dynamic> result = {
      'currentIngredients': _currentIngredients
          .where((id) => !_selectedDressingCounts.containsKey(id))
          .toList(),
      'groupSelections':
          _groupSelections.map((k, v) => MapEntry(k, v.toList())),
      'selectedAddOns': _selectedAddOns.toList(),
      'size': _selectedSize,
      ..._radioSelections,
      if (ingredientOptions.isNotEmpty) 'ingredientOptions': ingredientOptions,
      if (_selectedCheeses.isNotEmpty) 'cheeses': _selectedCheeses.toList(),
      if (cheeseOptions.isNotEmpty) 'cheeseOptions': cheeseOptions,
      if (nonZeroSauces.isNotEmpty) 'sauces': nonZeroSauces,
      if (nonZeroDressings.isNotEmpty) 'dressings': nonZeroDressings,
    };

    // --- Wings-specific ---
    if (_isWings()) {
      result['dippedSplits'] = _isAnyDipped
          ? _selectedDippedSauces.values.where((v) => v != null).toList()
          : [];
      result['isAnyDipped'] = _isAnyDipped;
      result['sideDipCups'] = Map<String, int>.from(_sideDipCounts);
    }

    if (_ingredientAmounts.isNotEmpty) {
      result['ingredientAmounts'] = {..._ingredientAmounts};
    }

    // --- PIZZA: Capture full split sauce selection ---
    if (_isPizza()) {
      final selected = _pizzaSauceSelections.where((s) => s.selected).toList();
      result['sauce'] = selected
          .map((s) => {
                'id': s.id,
                'portion': s.portion.toString().split('.').last,
                'amount': s.amount,
              })
          .toList();
    }

    widget.onConfirm(
      result,
      _quantity,
      _totalPrice,
    );
    Navigator.of(context).pop();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      backgroundColor: DesignTokens.surfaceColor,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          minWidth: 300,
          maxWidth: 440,
        ),
        child: Padding(
          padding: DesignTokens.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomizationHeader(
                        menuItem: widget.menuItem,
                        theme: theme,
                        loc: loc,
                      ),
                      SizedBox(height: DesignTokens.gridSpacing),
                      if (widget.menuItem.category.toLowerCase() != 'drinks' &&
                          widget.menuItem.sizes != null &&
                          widget.menuItem.sizes!.isNotEmpty)
                        SizeDropdown(
                          menuItem: widget.menuItem,
                          selectedSize: _selectedSize,
                          onChanged: (newSize) {
                            setState(() {
                              _selectedSize = newSize;
                            });
                          },
                          toppingCostLabel: _isPizzaOrCalzone()
                              ? ToppingCostLabel(
                                  theme: theme,
                                  loc: loc,
                                  getToppingUpcharge: _getToppingUpcharge,
                                  currencyFormat: currencyFormat,
                                )
                              : null,
                          normalizeSizeKey: _normalizeSizeKey,
                        ),
                      if (_isWings()) ...[
                        WingsPortionSelector(
                          menuItem: widget.menuItem,
                          theme: theme,
                          loc: loc,
                          selectedSize: _selectedSize,
                          ingredientMetadata: _ingredientMetadata,
                          selectedDippedSauces: Map.fromEntries(
                            _selectedDippedSauces.entries
                                .where((e) => e.value != null)
                                .map((e) => MapEntry(e.key, e.value!)),
                          ),
                          setState: setState,
                        ),
                        WingsDipSauceSelector(
                          menuItem: widget.menuItem,
                          theme: theme,
                          loc: loc,
                          ingredientMetadata: _ingredientMetadata,
                          sideDipCounts: _sideDipCounts,
                          wingsDipSauceTabIndex: _wingsDipSauceTabIndex,
                          setState: setState,
                          onTabChanged: (newIndex) {
                            setState(() {
                              _wingsDipSauceTabIndex = newIndex;
                            });
                          },
                        ),
                        WingsOptionalAddOnsGroup(
                          menuItem: widget.menuItem,
                          theme: theme,
                          loc: loc,
                          ingredientMetadata: _ingredientMetadata,
                          selectedAddOns: _selectedAddOns,
                          doubleAddOns: _doubleAddOns,
                          setState: setState,
                          onChanged: (ingId, checked) {
                            if (checked) {
                              _selectedAddOns.add(ingId);
                              _doubleAddOns[ingId] = false;
                            } else {
                              _selectedAddOns.remove(ingId);
                              _doubleAddOns.remove(ingId);
                            }
                          },
                        ),
                      ],
                      if (widget.menuItem.category.toLowerCase() == 'drinks')
                        DrinksFlavorSelector(
                          menuItem: widget.menuItem,
                          theme: theme,
                          loc: loc,
                          ingredientMetadata: _ingredientMetadata,
                          selectedSauceCounts: _selectedSauceCounts,
                          setState: setState,
                        )
                      else if (widget.menuItem.category.toLowerCase() ==
                          'dinners')
                        DinnerIncludedIngredients(
                          menuItem: widget.menuItem,
                          theme: theme,
                          loc: loc,
                          ingredientMetadata: _ingredientMetadata,
                          currentIngredients: _currentIngredients,
                          ingredientAmounts: _ingredientAmounts,
                          setState: setState,
                        )
                      else if (_showsCurrentIngredients())
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 10, bottom: 10),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: DesignTokens.primaryColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 14),
                                child: Text(
                                  "Current Toppings",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            ..._currentIngredients.where((id) {
                              final meta = _ingredientMetadata[id];
                              // Exclude dressing, sauce, and crust types from "Current Toppings"
                              final type = meta?.type?.toLowerCase() ?? '';
                              return !_selectedDressingCounts.containsKey(id) &&
                                  !_selectedSauceCounts.containsKey(id) &&
                                  type != 'crust' &&
                                  type != 'cheeses';
                            }).map((ingId) {
                              final meta = _ingredientMetadata[ingId];
                              return Card(
                                margin: EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 0),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ...rest of your row/ingredient UI...
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              meta?.name ?? ingId,
                                              style: theme.textTheme.bodyLarge,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  theme.colorScheme.error,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _currentIngredients
                                                    .remove(ingId);
                                                _doubleToppings.remove(ingId);
                                                _ingredientPortions
                                                    .remove(ingId);
                                              });
                                            },
                                            child: Text(loc.remove),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6),
                                      Row(
                                        children: [
                                          if (!_isCalzone()) ...[
                                            Flexible(
                                              fit: FlexFit.tight,
                                              child: PortionSelector(
                                                value: _ingredientPortions[
                                                        ingId] ??
                                                    Portion.whole,
                                                onChanged: (portion) =>
                                                    _handlePortionChanged(
                                                        ingId, portion),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                          ],
                                          Flexible(
                                            fit: FlexFit.tight,
                                            child: PortionPillToggle(
                                              isDouble:
                                                  _doubleToppings[ingId] ==
                                                      true,
                                              onTap: () => _handleDoubleChanged(
                                                  ingId,
                                                  !_doubleToppings[ingId]!),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),

                      // --- Begin Pizza/Calzone Topping Tabs UI ---
                      if (_isPizzaOrCalzone() && _toppingTabLabels.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 4),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: DesignTokens.primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 14),
                            child: Text(
                              "Additional Toppings",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6.0), // Much tighter vertical space
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border:
                                Border.all(color: Colors.grey[300]!, width: 1),
                          ),
                          // The Row is now wrapped in a Container, acting like a tab bar.
                          child: Row(
                            children: _toppingTabLabels.map((label) {
                              final bool selected =
                                  _selectedToppingTab == label;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedToppingTab = label),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 150),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? DesignTokens.secondaryColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    alignment: Alignment.center,
                                    child: Text(
                                      label,
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        color: selected
                                            ? Colors.white
                                            : DesignTokens.secondaryColor,
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      if (_isPizzaOrCalzone() && _selectedToppingTab.isNotEmpty)
                        Builder(
                          builder: (context) {
                            final group = _toppingTabGroups.firstWhereOrNull(
                                (g) => g['label'] == _selectedToppingTab);
                            if (group == null) return SizedBox.shrink();

                            final ingredientIds =
                                (group['ingredientIds'] as List<dynamic>? ?? [])
                                    .map((e) => e.toString())
                                    .toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4, bottom: 4),
                                  child: Divider(
                                    thickness: 2,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                ...ingredientIds
                                    .where((ingId) =>
                                        !_currentIngredients.contains(ingId))
                                    .map((ingId) {
                                  final meta = _ingredientMetadata[ingId];
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                        vertical: 2, horizontal: 0),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(meta?.name ?? ingId,
                                                style:
                                                    theme.textTheme.bodyLarge),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _currentIngredients.add(ingId);
                                                _doubleToppings[ingId] = false;
                                                _ingredientPortions[ingId] =
                                                    Portion.whole;
                                              });
                                            },
                                            child: Text('Click to Add',
                                                style: TextStyle(
                                                    color: theme
                                                        .colorScheme.primary)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Divider(
                                    thickness: 2,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                      // --- End Pizza/Calzone Topping Tabs UI ---

                      ..._checkboxGroups.map((group) {
                        final label =
                            (group['label'] ?? '').toString().toLowerCase();
                        if (label == 'cheeses') {
                          final cheeseIds =
                              (group['ingredientIds'] as List<dynamic>? ?? [])
                                  .cast<String>();
                          final selectedCheeses = cheeseIds
                              .where((id) => _selectedCheeses.contains(id))
                              .toList();
                          final summary = selectedCheeses.isEmpty
                              ? "None"
                              : selectedCheeses.map((id) {
                                  final meta = _ingredientMetadata[id];
                                  final isDouble = _cheeseIsDouble[id] == true;
                                  final portion =
                                      _cheesePortions[id] ?? Portion.whole;
                                  // Only show portion if not calzone and not whole
                                  return "${meta?.name ?? id}"
                                      "${isDouble ? " (Double)" : ""}"
                                      "${(!_isCalzone() && portion != Portion.whole) ? " (${portionNames[portion]})" : ""}";
                                }).join(", ");
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 0),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: DesignTokens.primaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 14),
                                    child: Text(
                                      "Cheeses",
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                ExpansionTile(
                                  tilePadding:
                                      EdgeInsets.symmetric(horizontal: 0),
                                  title: Text(
                                    summary,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      "Add extra cheeses for an additional charge.",
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                  children: cheeseIds.map((cheeseId) {
                                    final meta = _ingredientMetadata[cheeseId];
                                    final selected =
                                        _selectedCheeses.contains(cheeseId);
                                    return Card(
                                      margin: EdgeInsets.symmetric(
                                          vertical: 2, horizontal: 0),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    meta?.name ?? cheeseId,
                                                    style: theme
                                                        .textTheme.bodyLarge,
                                                  ),
                                                ),
                                                if (selected)
                                                  TextButton(
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: theme
                                                          .colorScheme.error,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _selectedCheeses
                                                            .remove(cheeseId);
                                                        _cheesePortions
                                                            .remove(cheeseId);
                                                        _cheeseIsDouble
                                                            .remove(cheeseId);
                                                      });
                                                    },
                                                    child: Text('Remove'),
                                                  )
                                                else
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _selectedCheeses
                                                            .add(cheeseId);
                                                        _cheesePortions[
                                                                cheeseId] =
                                                            Portion.whole;
                                                        _cheeseIsDouble[
                                                            cheeseId] = false;
                                                      });
                                                    },
                                                    child: Text(
                                                      'Click to Add',
                                                      style: TextStyle(
                                                          color: theme
                                                              .colorScheme
                                                              .primary),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (selected)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 6.0),
                                                child: Row(
                                                  children: [
                                                    if (!_isCalzone()) ...[
                                                      Flexible(
                                                        fit: FlexFit.tight,
                                                        child: PortionSelector(
                                                          value: _cheesePortions[
                                                                  cheeseId] ??
                                                              Portion.whole,
                                                          onChanged: (portion) {
                                                            setState(() {
                                                              _cheesePortions[
                                                                      cheeseId] =
                                                                  portion;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                    ],
                                                    Flexible(
                                                      fit: FlexFit.tight,
                                                      child: PortionPillToggle(
                                                        isDouble:
                                                            _cheeseIsDouble[
                                                                    cheeseId] ==
                                                                true,
                                                        onTap: () {
                                                          setState(() {
                                                            _cheeseIsDouble[
                                                                    cheeseId] =
                                                                !(_cheeseIsDouble[
                                                                        cheeseId] ??
                                                                    false);
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Non-cheese group: render as before
                          return CheckboxCustomizationGroup(
                            group: group,
                            theme: theme,
                            loc: loc,
                            category: widget.menuItem.category,
                            includedIngredients:
                                widget.menuItem.includedIngredients,
                            ingredientMetadata: _ingredientMetadata,
                            currentIngredients: _currentIngredients,
                            usesDynamicToppingPricing:
                                widget.menuItem.additionalToppingPrices !=
                                        null &&
                                    _selectedSize != null,
                            showPortionToggle: _showPortionToggle,
                            getToppingUpcharge: _getToppingUpcharge,
                            getIngredientUpcharge: _getIngredientUpcharge,
                            toggleIngredient: _toggleIngredient,
                            buildPortionPillToggle: (ingId) =>
                                PortionPillToggle(
                              isDouble: _doubleToppings[ingId] == true,
                              onTap: () {
                                setState(() {
                                  if (_doubleToppings[ingId] == true) {
                                    _doubleToppings[ingId] = false;
                                  } else {
                                    if (_doublesCount < MAX_DOUBLES)
                                      _doubleToppings[ingId] = true;
                                  }
                                });
                              },
                            ),
                          );
                        }
                      }),

                      ..._radioGroups.map((group) {
                        final label =
                            (group['label'] as String?)?.toLowerCase();
                        if (label == 'sauces') {
                          // --- Unified Sauce Summary Logic (works for both pizza/calzone) ---
                          final saucesGroup = group;
                          final sauceIds =
                              (saucesGroup['ingredientIds'] as List?)
                                      ?.cast<String>() ??
                                  [];

                          String sauceSummary;

                          if (_isCalzone()) {
                            // CALZONE: summarize by stepper sauce count
                            final selectedSauceIds = sauceIds
                                .where(
                                    (id) => (_selectedSauceCounts[id] ?? 0) > 0)
                                .toList();
                            if (selectedSauceIds.isEmpty) {
                              sauceSummary = "None";
                            } else {
                              sauceSummary = selectedSauceIds.map((id) {
                                final name =
                                    _ingredientMetadata[id]?.name ?? id;
                                final count = _selectedSauceCounts[id] ?? 0;
                                return count > 1 ? "$name (x$count)" : "$name";
                              }).join(", ");
                            }
                          } else {
                            // PIZZA: use split/portion/amount summary
                            final selectedSauces = _pizzaSauceSelections
                                .where((s) => s.selected)
                                .toList();
                            if (selectedSauces.isEmpty) {
                              sauceSummary = "None";
                            } else {
                              sauceSummary = selectedSauces.map((s) {
                                final name =
                                    _ingredientMetadata[s.id]?.name ?? s.name;
                                final amount = s.amount.capitalize();
                                if (s.portion != Portion.whole) {
                                  final portion = portionNames[s.portion] ?? "";
                                  return "$name ($portion, $amount)";
                                } else {
                                  return "$name ($amount)";
                                }
                              }).join(", ");
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 0),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: DesignTokens.primaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 14),
                                    child: Text(
                                      "Sauces",
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                ExpansionTile(
                                  tilePadding:
                                      EdgeInsets.symmetric(horizontal: 0),
                                  title: Text(
                                    sauceSummary,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      "Split your sauce or add extra for an additional charge.",
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                  children: [
                                    SauceSelectorGroup(
                                      group: group,
                                      theme: theme,
                                      loc: loc,
                                      isPizza: _isPizza,
                                      pizzaSauceSelections:
                                          _pizzaSauceSelections,
                                      ingredientMetadata: _ingredientMetadata,
                                      sauceSplitValidationError:
                                          _sauceSplitValidationError,
                                      resetPizzaSauceSelections:
                                          _resetPizzaSauceSelections,
                                      setState: setState,
                                      selectedSauceCounts: _selectedSauceCounts,
                                      getFreeSauceCount: _getFreeSauceCount,
                                      getExtraSauceUpcharge:
                                          _getExtraSauceUpcharge,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        } else if (label == 'dressings') {
                          // --- Dressings logic ---
                          return DressingSelectorGroup(
                            group: group,
                            theme: theme,
                            loc: loc,
                            selectedDressingCounts: _selectedDressingCounts,
                            onCountChanged: (ingId, newCount) {
                              setState(() =>
                                  _selectedDressingCounts[ingId] = newCount);
                            },
                            getFreeDressingCount: _getFreeDressingCount,
                            getExtraDressingUpcharge: _getExtraDressingUpcharge,
                            ingredientMetadata: _ingredientMetadata,
                          );
                        }
                        // DO NOT RENDER crust, cook, cut here
                        return null;
                      }).whereType<Widget>(),

                      if (!_isWings() &&
                          widget.menuItem.optionalAddOns != null &&
                          widget.menuItem.optionalAddOns!.isNotEmpty)
                        OptionalAddOnsGroup(
                          menuItem: widget.menuItem,
                          theme: theme,
                          loc: loc,
                          ingredientMetadata: _ingredientMetadata,
                          selectedAddOns: _selectedAddOns,
                          doubleAddOns: _doubleAddOns,
                          selectedSauceCounts: _selectedSauceCounts,
                          usesDynamicToppingPricing:
                              widget.menuItem.additionalToppingPrices != null &&
                                  _selectedSize != null,
                          getToppingUpcharge: _getToppingUpcharge,
                          getIngredientUpcharge: _getIngredientUpcharge,
                          onToggleAddOn: (ingId, val) {
                            setState(() {
                              if (val == true) {
                                _selectedAddOns.add(ingId);
                                _doubleAddOns[ingId] = false;
                              } else {
                                _selectedAddOns.remove(ingId);
                                _doubleAddOns.remove(ingId);
                              }
                            });
                          },
                          onChangeSauceCount: (ingId, delta) {
                            setState(() {
                              final count = _selectedSauceCounts[ingId] ?? 0;
                              _selectedSauceCounts[ingId] =
                                  (count + delta).clamp(0, 100);
                            });
                          },
                          buildAddOnDoublePill: (ingId, isDouble, onTap) =>
                              PortionPillToggle(
                            isDouble: isDouble,
                            onTap: onTap,
                          ),
                          maxFreeSauces: _getFreeSauceCount(),
                          extraSauceUpcharge: _getExtraSauceUpcharge(),
                        ),

                      // --- ORDER DETAILS SECTION: Always at the very end, collapsed by default ---
                      Builder(
                        builder: (context) {
                          // Get all remaining radio groups (crust, cook, cut)
                          final orderDetailGroups = _radioGroups.where((group) {
                            final label =
                                (group['label'] as String?)?.toLowerCase();
                            return label == 'crust' ||
                                label == 'cook' ||
                                label == 'cut';
                          }).toList();

                          // Compose summary for collapsed state
                          String detailsSummary = orderDetailGroups
                              .map((group) {
                                final label = (group['label'] as String?) ?? '';
                                final selected = _radioSelections[label];
                                if (selected == null) return '';
                                final meta = _ingredientMetadata[selected];
                                return "${label.capitalize()}: ${meta?.name ?? selected}";
                              })
                              .where((str) => str.isNotEmpty)
                              .join(" | ");

                          return Padding(
                            padding:
                                const EdgeInsets.only(top: 12.0, bottom: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 0),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: DesignTokens.primaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 14),
                                    child: Text(
                                      "Order Details",
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                ExpansionTile(
                                  tilePadding:
                                      EdgeInsets.symmetric(horizontal: 0),
                                  title: Text(
                                    detailsSummary.isEmpty
                                        ? "Customize crust, cook, and cut."
                                        : detailsSummary,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      "Tap to customize crust, cook, or cut.",
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                  children: orderDetailGroups.map((group) {
                                    return RadioCustomizationGroup(
                                      group: group,
                                      theme: theme,
                                      loc: loc,
                                      ingredientMetadata: _ingredientMetadata,
                                      radioSelections: _radioSelections,
                                      getIngredientUpcharge:
                                          _getIngredientUpcharge,
                                      handleRadioSelect: _handleRadioSelect,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              CustomizationBottomBar(
                menuItem: widget.menuItem,
                theme: theme,
                loc: loc,
                totalPrice: _totalPrice,
                error: _error,
                onCancel: () => Navigator.of(context).pop(),
                onSubmit: _submit,
                onConfirm: widget.onConfirm,
                drinkFlavorCounts: _drinkFlavorCounts,
                sizePrices: widget.menuItem.sizePrices,
                sizes: widget.menuItem.sizes,
                menuItemPrice: widget.menuItem.price,
                drinkMaxPerFlavor: _drinkMaxPerFlavor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
