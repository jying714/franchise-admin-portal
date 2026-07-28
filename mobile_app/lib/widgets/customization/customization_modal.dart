// ignore_for_file: prefer_const_constructors
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/portion_selector.dart';
import 'package:franchise_mobile_app/widgets/customization/portion_pill_toggle.dart';
import 'package:franchise_mobile_app/widgets/customization/dressing_selector_group.dart';
import 'package:franchise_mobile_app/widgets/customization/sauce_selector_group.dart';
import 'package:franchise_mobile_app/widgets/customization/checkbox_customization_group.dart';
import 'package:franchise_mobile_app/widgets/customization/dinner_included_ingredients.dart';
import 'package:franchise_mobile_app/widgets/customization/radio_customization_group.dart';
import 'package:franchise_mobile_app/widgets/customization/drinks_flavor_selector.dart';
import 'package:franchise_mobile_app/widgets/customization/optional_addons_group.dart';
import 'package:franchise_mobile_app/widgets/customization/wings_optional_addons_group.dart';
import 'package:franchise_mobile_app/widgets/customization/wings_dip_sauce_selector.dart';
import 'package:franchise_mobile_app/widgets/customization/wings_portion_selector.dart';
import 'package:franchise_mobile_app/widgets/customization/size_dropdown.dart';
import 'package:franchise_mobile_app/widgets/customization/topping_cost_label.dart';
import 'package:franchise_mobile_app/widgets/customization/header.dart';
import 'package:franchise_mobile_app/widgets/customization/bottom_bar.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';

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
  final shared.MenuItem menuItem;
  final int initialQuantity;
  final Map<String, dynamic>? initialCustomizations;
  final void Function(
    Map<String, dynamic> customizations,
    int quantity,
    double totalPrice,
  ) onConfirm;
  final Map<String, shared.IngredientMetadata>? ingredientMetadata;

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
  late Map<String, shared.IngredientMetadata> _ingredientMetadata;

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

  // AFTER
  void _handleSauceTap(int index) {
    setState(() {
      final selectedCount =
          _pizzaSauceSelections.where((s) => s.selected).length;
      final current = _pizzaSauceSelections[index];

      // Max 2 sauces (same spirit as cheeses max)
      if (!current.selected && selectedCount >= 2) {
        return;
      }

      final nextSelected = !current.selected;
      _pizzaSauceSelections[index] = current.copyWith(
        selected: nextSelected,
        portion: nextSelected ? Portion.whole : current.portion,
      );

      // Do not force a sauce to stay selected (parity with cheeses)
      // Do not touch _currentIngredients — sauces stay in Sauces section only
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
      // AFTER
      final includedSauceId =
          widget.menuItem.includedIngredients?.firstWhereOrNull((ing) {
        final t = (ing['typeId'] ?? ing['type'] ?? '').toString().toLowerCase();
        return t == 'sauces' || t == 'sauce';
      })?['ingredientId']?.toString();
      if (includedSauceId != null) {
        final idx =
            _pizzaSauceSelections.indexWhere((s) => s.id == includedSauceId);
        if (idx >= 0) {
          _pizzaSauceSelections[idx].selected = true;
          _pizzaSauceSelections[idx].portion = Portion.whole;
          _pizzaSauceSelections[idx].amount = 'regular';
        }
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

  bool _wasIncludedIngredient(String ingId) {
    final raw = widget.menuItem.includedIngredients;
    if (raw == null || raw.isEmpty) return false;
    final want = ingId.trim();
    if (want.isEmpty) return false;
    for (final e in raw) {
      final a = (e['ingredientId'] ?? '').toString().trim();
      final b = (e['id'] ?? '').toString().trim();
      if (a == want || b == want) return true;
    }
    return false;
  }

  bool _showsCurrentIngredients() {
    if (_isWings()) return false;
    final profile = widget.menuItem.effectiveMenuProfile.toLowerCase();
    if (profile == shared.MenuProfile.pizza ||
        profile == shared.MenuProfile.calzone) {
      return true;
    }
    final cat = widget.menuItem.category.toLowerCase();
    final catId = (widget.menuItem.categoryId ?? '').toLowerCase();
    return [cat, catId].any((c) =>
        c.contains('pizza') ||
        c.contains('calzone') ||
        c.contains('salad') ||
        c.contains('sub'));
  }

  bool _isPizzaOrCalzone() {
    final profile = widget.menuItem.effectiveMenuProfile.toLowerCase();
    if (profile == shared.MenuProfile.pizza ||
        profile == shared.MenuProfile.calzone) return true;
    final cat = widget.menuItem.category.toLowerCase();
    return cat.contains('pizza') || cat.contains('calzone');
  }

  bool _isCalzone() {
    final profile = widget.menuItem.effectiveMenuProfile.toLowerCase();
    if (profile == shared.MenuProfile.calzone) return true;
    return widget.menuItem.category.toLowerCase().contains('calzone');
  }

  bool _isWings() {
    final profile = widget.menuItem.effectiveMenuProfile.toLowerCase();
    if (profile == shared.MenuProfile.wings) return true;
    final name = widget.menuItem.name.toLowerCase();
    return name.contains('wings');
  }

  bool _isSalad() {
    final cat = widget.menuItem.category.toLowerCase();
    final catId = (widget.menuItem.categoryId ?? '').toLowerCase();
    return cat.contains('salad') || catId.contains('salad');
  }

  bool _isDinner() {
    final cat = widget.menuItem.category.toLowerCase();
    final catId = (widget.menuItem.categoryId ?? '').toLowerCase();
    return cat.contains('dinner') || catId.contains('dinner');
  }

  void _resyncWingsForSize(String? size) {
    if (!_isWings()) return;
    final splitCount = widget.menuItem.dippingSplits?[size] ?? 2;

    // Rebuild portion slots (always max 2 product rule; map may still say 2)
    final nextSplits = <String, String?>{};
    for (var i = 0; i < splitCount; i++) {
      final key = 'split_$i';
      nextSplits[key] = _selectedDippedSauces[key] ?? 'plain';
    }
    _selectedDippedSauces = nextSplits;
    _isAnyDipped =
        _selectedDippedSauces.values.any((v) => v != null && v != 'plain');

    // Keep dip cup counts for known sauce ids; drop unknown keys
    final dipIds = (widget.menuItem.sideDipSauceOptions?.isNotEmpty == true)
        ? widget.menuItem.sideDipSauceOptions!
        : (widget.menuItem.dippingSauceOptions ?? const <String>[]);
    final nextCups = <String, int>{};
    for (final id in dipIds) {
      nextCups[id] = _sideDipCounts[id] ?? 0;
    }
    _sideDipCounts = nextCups;
  }

  bool _showPortionToggle(String groupLabel) {
    if (!_isPizzaOrCalzone()) return false;
    return groupLabel == "Meats" ||
        groupLabel == "Veggies" ||
        groupLabel == "Cheeses";
  }

  List<Map<String, dynamic>> _groupsForUi() {
    Map<String, dynamic> groupToMap(shared.ModifierGroup g) {
      final optionIds = g.options
          .map((o) {
            final ing = o.ingredientId?.trim();
            if (ing != null && ing.isNotEmpty) return ing;
            return o.id.trim();
          })
          .where((id) => id.isNotEmpty)
          .toList();
      final optionLabels = <String, String>{
        for (final o in g.options)
          if (o.id.trim().isNotEmpty)
            (o.ingredientId != null && o.ingredientId!.trim().isNotEmpty
                    ? o.ingredientId!.trim()
                    : o.id.trim()):
                o.label.trim().isNotEmpty ? o.label.trim() : o.id.trim(),
      };
      return <String, dynamic>{
        'id': g.id,
        'label': g.label,
        'ingredientIds': optionIds,
        'optionLabels': optionLabels,
        'min': g.min,
        'max': g.max,
        if (g.maxFree != null) 'maxFree': g.maxFree,
      };
    }

    var groups =
        widget.menuItem.effectiveModifierGroups.map(groupToMap).toList();

    // Pizza: ensure Crust / Cook / Cut from template when missing or empty
    // (stored modifierGroups often only have food groups after HQ re-seed).
    if (_isPizza()) {
      final template = shared.MenuProfileTemplates.seedGroups(
        shared.MenuProfile.pizza,
      );
      for (final structuralId in ['crust', 'cook', 'cut']) {
        final idx = groups.indexWhere(
          (g) =>
              (g['id'] ?? '').toString().toLowerCase() == structuralId ||
              (g['label'] ?? '').toString().toLowerCase() == structuralId,
        );
        final hasOptions = idx >= 0 &&
            ((groups[idx]['ingredientIds'] as List?)?.isNotEmpty ?? false);
        if (hasOptions) continue;
        final seed = template.firstWhere(
          (g) => g.id.toLowerCase() == structuralId,
          orElse: () => template.firstWhere(
            (g) => g.label.toLowerCase() == structuralId,
            orElse: () => shared.ModifierGroup(
              id: structuralId,
              label: structuralId[0].toUpperCase() + structuralId.substring(1),
              selectMode: shared.ModifierSelectMode.single,
              min: 1,
              max: 1,
              options: const [],
            ),
          ),
        );
        final mapped = groupToMap(seed);
        if (idx >= 0) {
          groups[idx] = mapped;
        } else {
          groups.insert(0, mapped);
        }
      }
    }

    if (groups.isNotEmpty) return groups;

    return List<Map<String, dynamic>>.from(
      widget.menuItem.customizationGroups ?? const [],
    );
  }

  int? _maxFreeForGroupLabel(String label) {
    final key = label.trim().toLowerCase();
    for (final g in _groupsForUi()) {
      final gl = (g['label'] ?? '').toString().trim().toLowerCase();
      if (gl == key && g['maxFree'] is int) {
        return g['maxFree'] as int;
      }
    }
    if (key == 'meats' || key == 'veggies' || key == 'toppings') {
      for (final g in _groupsForUi()) {
        final gl = (g['label'] ?? '').toString().trim().toLowerCase();
        if ((gl == 'toppings' || gl == 'meats' || gl == 'veggies') &&
            g['maxFree'] is int) {
          return g['maxFree'] as int;
        }
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    // --- Cheeses: available from optionalAddOns; defaults from included ---
    final cheeseIds = _optionalIdsByType('cheeses');
    _selectedCheeses = {
      ...?widget.menuItem.includedIngredients?.where((i) {
        final id = (i['ingredientId'] ?? i['id'])?.toString() ?? '';
        final type = (i['typeId'] ?? i['type'] ?? '').toString().toLowerCase();
        return type == 'cheeses' || cheeseIds.contains(id);
      }).map((i) => (i['ingredientId'] ?? i['id']).toString()),
    };
    final storedCheeseGroups = widget.menuItem.modifierGroups?.where(
      (g) =>
          g.label.toLowerCase() == 'cheeses' || g.id.toLowerCase() == 'cheeses',
    );
    if (storedCheeseGroups != null) {
      for (final g in storedCheeseGroups) {
        for (final o in g.options) {
          if (!o.defaultSelected) continue;
          final key =
              (o.ingredientId != null && o.ingredientId!.trim().isNotEmpty)
                  ? o.ingredientId!.trim()
                  : o.id.trim();
          if (key.isNotEmpty && cheeseIds.contains(key)) {
            _selectedCheeses.add(key);
          }
        }
      }
    }
    _cheesePortions = {};
    _cheeseIsDouble = {};
    for (final id in _selectedCheeses) {
      _cheesePortions[id] = Portion.whole;
      _cheeseIsDouble[id] = false;
    }

    _quantity = widget.initialQuantity;
    _ingredientMetadata = widget.ingredientMetadata ??
        Provider.of<Map<String, shared.IngredientMetadata>>(context,
            listen: false);
    final sizes = widget.menuItem.sizes;
    _selectedSize =
        (sizes != null && sizes.isNotEmpty) ? sizes.first.label : null;
    _drinkFlavorCounts = {};

    if (_isPizzaOrCalzone()) {
      // AFTER
      var sauceIds = _optionalIdsByType('sauces');
      // Include sauces that come on the item but aren't in optionalAddOns
      for (final ing in widget.menuItem.includedIngredients ?? const []) {
        final t = (ing['typeId'] ?? ing['type'] ?? '').toString().toLowerCase();
        if (t != 'sauces' && t != 'sauce') continue;
        final id = (ing['ingredientId'] ?? ing['id'])?.toString() ?? '';
        if (id.isNotEmpty && !sauceIds.contains(id)) {
          sauceIds = [...sauceIds, id];
        }
      }
      var sauceLabels = <String, String>{
        for (final id in sauceIds) id: _optionalLabel(id, 'sauces'),
      };
      for (final ing in widget.menuItem.includedIngredients ?? const []) {
        final id = (ing['ingredientId'] ?? ing['id'])?.toString() ?? '';
        final name = (ing['name'] ?? '').toString();
        if (id.isNotEmpty && name.isNotEmpty) {
          sauceLabels[id] = name;
        }
      }
      if (sauceIds.isEmpty) {
        final saucesGroup = _groupsForUi().firstWhereOrNull(
          (g) => (g['label']?.toString().toLowerCase() ?? '') == 'sauces',
        );
        sauceIds = (saucesGroup?['ingredientIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        sauceLabels = (saucesGroup?['optionLabels'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), v.toString())) ??
            const <String, String>{};
      }

      _pizzaSauceSelections = sauceIds.map((id) {
        final meta = _ingredientMetadata[id];
        return PizzaSauceSelection(
          id: id,
          name: meta?.name ?? sauceLabels[id] ?? id,
          selected: false,
          portion: Portion.whole,
          amount: 'regular',
        );
      }).toList();

      // Prefer included sauce (typeId), else first available
      final includedSauceId =
          widget.menuItem.includedIngredients?.firstWhereOrNull((ing) {
        final t = (ing['typeId'] ?? ing['type'] ?? '').toString().toLowerCase();
        return t == 'sauces' || t == 'sauce';
      })?['ingredientId']?.toString();

      // AFTER
      if (_pizzaSauceSelections.isNotEmpty) {
        // Clear all, then select included only (cheeses-style defaults)
        for (var i = 0; i < _pizzaSauceSelections.length; i++) {
          _pizzaSauceSelections[i] =
              _pizzaSauceSelections[i].copyWith(selected: false);
        }
        if (includedSauceId != null && includedSauceId.isNotEmpty) {
          final idx =
              _pizzaSauceSelections.indexWhere((s) => s.id == includedSauceId);
          if (idx >= 0) {
            _pizzaSauceSelections[idx] = _pizzaSauceSelections[idx].copyWith(
              selected: true,
              portion: Portion.whole,
            );
          }
        }
      }
    }

    _initializeSelections();

    if (_isPizzaOrCalzone()) {
      final optionalSauceIds = _optionalIdsByType('sauces');
      final includedSauceId =
          widget.menuItem.includedIngredients?.firstWhereOrNull((ing) {
        final t = (ing['typeId'] ?? ing['type'] ?? '').toString().toLowerCase();
        return t == 'sauces' || t == 'sauce';
      })?['ingredientId']?.toString();
      _selectedPizzaSauceId = includedSauceId ??
          (optionalSauceIds.isNotEmpty ? optionalSauceIds.first : 'sauce_none');
      _selectedSaucePortion = 'whole';
      _selectedSauceAmount = 'regular';
    }

    _sortCustomizationGroups();

    // Additional toppings tabs: meats / veggies from optionalAddOns
    if (_isPizzaOrCalzone()) {
      final meatIds = _optionalIdsByType('meats');
      final vegIds = _optionalIdsByType('veggies');
      _toppingTabGroups = <Map<String, dynamic>>[
        if (meatIds.isNotEmpty)
          {
            'id': 'meats',
            'label': 'Meats',
            'ingredientIds': meatIds,
            'optionLabels': {
              for (final id in meatIds) id: _optionalLabel(id, 'meats'),
            },
            'max': 20,
            'maxFree': _maxFreeForGroupLabel('meats') ?? 0,
          },
        if (vegIds.isNotEmpty)
          {
            'id': 'veggies',
            'label': 'Veggies',
            'ingredientIds': vegIds,
            'optionLabels': {
              for (final id in vegIds) id: _optionalLabel(id, 'veggies'),
            },
            'max': 20,
            'maxFree': _maxFreeForGroupLabel('veggies') ?? 0,
          },
      ];
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

    if (_isWings()) {
      final wingSizes = widget.menuItem.sizes ?? [];
      _selectedSize ??= wingSizes.isNotEmpty ? wingSizes.first.label : null;
      _selectedDippedSauces = {};
      _sideDipCounts = {};
      _isAnyDipped = false;
      _resyncWingsForSize(_selectedSize);
    }

    if (widget.menuItem.includedIngredients != null) {
      for (final ing in widget.menuItem.includedIngredients!) {
        final ingId = ing['ingredientId'] ?? ing['id'];
        final meta = _ingredientMetadata[ingId];
        final List<String>? options = meta?.amountOptions ??
            (ing['amountOptions'] is List
                ? List<String>.from(ing['amountOptions'])
                : null);
        final bool selectable = meta?.amountSelectable ??
            (ing['amountSelectable'] == true && options != null);

        if (selectable && options != null && options.isNotEmpty) {
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
      _drinkMaxPerFlavor =
          (widget.menuItem.toMap()['maxPerFlavor'] as int?) ?? 10;
      for (final ing in widget.menuItem.includedIngredients ?? []) {
        final ingId = ing['ingredientId'] ?? ing['id'];
        _drinkFlavorCounts[ingId] = 0;
      }
    }
  }

  // AFTER
  void _initializeSelections() {
    _currentIngredients = {};
    if (widget.menuItem.includedIngredients != null) {
      for (final ing in widget.menuItem.includedIngredients!) {
        final ingId = ing['ingredientId'] ?? ing['id'];
        _currentIngredients.add(ingId);
      }
    }
    // Cheeses & sauces stay in their own sections, not Current Toppings
    _currentIngredients.removeWhere((id) {
      final meta = _ingredientMetadata[id];
      final type = (meta?.type ?? '').toLowerCase();
      final typeId = (meta?.typeId ?? type).toLowerCase();
      if (type == 'cheeses' ||
          typeId == 'cheeses' ||
          type == 'sauces' ||
          type == 'sauce' ||
          typeId == 'sauces' ||
          typeId == 'sauce') {
        return true;
      }
      final included = widget.menuItem.includedIngredients?.firstWhereOrNull(
        (e) => (e['ingredientId'] ?? e['id'])?.toString() == id,
      );
      if (included != null) {
        final t = (included['typeId'] ?? included['type'] ?? '')
            .toString()
            .toLowerCase();
        if (t == 'cheeses' || t == 'sauces' || t == 'sauce') return true;
      }
      return false;
    });
    _groupSelections = {};
    _radioSelections = {};
    final groups = _groupsForUi();
    if (groups.isNotEmpty) {
      for (final group in groups) {
        final groupLabel = (group['label'] ?? '').toString();
        if (groupLabel.isEmpty) continue;
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
          String included = ids.firstWhere(
            (id) => _currentIngredients.contains(id),
            orElse: () => '',
          );
          if (included.isEmpty && ids.isNotEmpty) {
            // Prefer option marked defaultSelected in modifierGroups when present
            final stored = widget.menuItem.modifierGroups;
            if (stored != null) {
              final match = stored.where(
                (g) => g.label.toLowerCase() == groupLabel.toLowerCase(),
              );
              if (match.isNotEmpty) {
                final def = match.first.options.where((o) => o.defaultSelected);
                if (def.isNotEmpty) {
                  final o = def.first;
                  final key = (o.ingredientId != null &&
                          o.ingredientId!.trim().isNotEmpty)
                      ? o.ingredientId!.trim()
                      : o.id.trim();
                  if (key.isNotEmpty) included = key;
                }
              }
            }
            if (included.isEmpty) included = ids.first;
          }
          _radioSelections[groupLabel] = included;
          if (included.isNotEmpty) {
            _currentIngredients.add(included);
          }
        } else {
          _groupSelections[groupLabel] = <String>{};
        }
      }
    }

    _selectedAddOns = {};
  }

  void _initializeSauceCounts() {
    for (final group in _groupsForUi()) {
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
    for (final group in _groupsForUi()) {
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

  void _sortCustomizationGroups() {
    _checkboxGroups = [];
    _radioGroups = [];
    for (final group in _groupsForUi()) {
      final groupLabel = (group['label'] ?? '').toString();
      final isSauceGroup = groupLabel.toLowerCase() == 'sauces';
      final isDressingGroup = groupLabel.toLowerCase() == 'dressings';
      if (_isRadioGroup(groupLabel) || isSauceGroup || isDressingGroup) {
        _radioGroups.add(group);
      } else {
        if (!_isPizzaOrCalzone() ||
            (groupLabel.toLowerCase() != 'meats' &&
                groupLabel.toLowerCase() != 'veggies' &&
                groupLabel.toLowerCase() != 'toppings')) {
          _checkboxGroups.add(group);
        }
      }
    }

    // Pizza/calzone: cheeses available list from optionalAddOns when group missing/sparse
    if (_isPizzaOrCalzone()) {
      final cIds = _optionalIdsByType('cheeses');
      final hasCheese = _checkboxGroups.any(
        (g) => (g['label']?.toString().toLowerCase() ?? '') == 'cheeses',
      );
      if (!hasCheese && cIds.isNotEmpty) {
        _checkboxGroups.add({
          'id': 'cheeses',
          'label': 'Cheeses',
          'ingredientIds': cIds,
          'optionLabels': {
            for (final id in cIds) id: _optionalLabel(id, 'cheeses'),
          },
          'max': 2,
        });
      } else if (hasCheese && cIds.isNotEmpty) {
        // Prefer full optional pool over sparse modifier options
        final idx = _checkboxGroups.indexWhere(
          (g) => (g['label']?.toString().toLowerCase() ?? '') == 'cheeses',
        );
        if (idx >= 0) {
          final existing = Map<String, dynamic>.from(_checkboxGroups[idx]);
          existing['ingredientIds'] = cIds;
          existing['optionLabels'] = {
            for (final id in cIds) id: _optionalLabel(id, 'cheeses'),
          };
          if ((existing['max'] as int?) == null ||
              (existing['max'] as int) > 2) {
            existing['max'] = 2;
          }
          _checkboxGroups[idx] = existing;
        }
      }
    }

    // Pizza: sauces section from optionalAddOns when no sauces modifier group
    // AFTER
    if (_isPizzaOrCalzone()) {
      var sauceIds = _optionalIdsByType('sauces');
      final sauceLabels = <String, String>{
        for (final id in sauceIds) id: _optionalLabel(id, 'sauces'),
      };
      for (final ing in widget.menuItem.includedIngredients ?? const []) {
        final t = (ing['typeId'] ?? ing['type'] ?? '').toString().toLowerCase();
        if (t != 'sauces' && t != 'sauce') continue;
        final id = (ing['ingredientId'] ?? ing['id'])?.toString() ?? '';
        if (id.isEmpty) continue;
        if (!sauceIds.contains(id)) sauceIds = [...sauceIds, id];
        final name = (ing['name'] ?? '').toString();
        if (name.isNotEmpty) sauceLabels[id] = name;
      }
      final hasSauces = _radioGroups.any(
        (g) => (g['label']?.toString().toLowerCase() ?? '') == 'sauces',
      );
      if (!hasSauces && sauceIds.isNotEmpty) {
        _radioGroups.add({
          'id': 'sauces',
          'label': 'Sauces',
          'ingredientIds': sauceIds,
          'optionLabels': sauceLabels,
        });
      } else if (hasSauces && sauceIds.isNotEmpty) {
        final idx = _radioGroups.indexWhere(
          (g) => (g['label']?.toString().toLowerCase() ?? '') == 'sauces',
        );
        if (idx >= 0) {
          final existing = Map<String, dynamic>.from(_radioGroups[idx]);
          existing['ingredientIds'] = sauceIds;
          existing['optionLabels'] = sauceLabels;
          _radioGroups[idx] = existing;
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

  // AFTER
  Set<String> get _originalIncludedIds {
    final raw = widget.menuItem.includedIngredients;
    if (raw == null || raw.isEmpty) return <String>{};
    return raw
        .map((e) => (e['ingredientId'] ?? e['id'])?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  /// Available extras from optionalAddOns, filtered by typeId (meats|veggies|cheeses|sauces).
  List<Map<String, dynamic>> _optionalByType(String typeId) {
    final raw = widget.menuItem.optionalAddOns;
    if (raw == null || raw.isEmpty) return const [];
    final want = typeId.toLowerCase();
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final e in raw) {
      final tid = (e['typeId'] ?? e['type'] ?? '').toString().toLowerCase();
      if (tid != want) continue;
      final id = (e['ingredientId'] ?? e['id'] ?? '').toString();
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      out.add(Map<String, dynamic>.from(e));
    }
    return out;
  }

  List<String> _optionalIdsByType(String typeId) {
    return _optionalByType(typeId)
        .map((e) => (e['ingredientId'] ?? e['id']).toString())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  String _optionalLabel(String id, String typeId) {
    for (final e in _optionalByType(typeId)) {
      final eid = (e['ingredientId'] ?? e['id']).toString();
      if (eid == id) {
        return (e['name'] ?? _ingredientMetadata[id]?.name ?? id).toString();
      }
    }
    return _ingredientMetadata[id]?.name ?? id;
  }

  bool _isPizza() {
    final profile = widget.menuItem.effectiveMenuProfile.toLowerCase();
    // Calzone re-uses the full pizza sauce / toppings path; left/right is
    // suppressed separately by _isCalzone().
    if (profile == shared.MenuProfile.pizza ||
        profile == shared.MenuProfile.calzone) return true;
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
    if (prices != null && key.isNotEmpty && prices[key] != null) {
      return (prices[key] as num).toDouble();
    }
    final sizes = widget.menuItem.sizes;
    if (sizes != null && _selectedSize != null) {
      for (final s in sizes) {
        if (s.label == _selectedSize || _normalizeSizeKey(s.label) == key) {
          return s.toppingPrice;
        }
      }
    }
    return 0.0;
  }

  double _getIngredientUpcharge(shared.IngredientMetadata? meta) {
    if (meta == null) return 0.0;
    if (meta.upcharge != null && meta.upcharge!.isNotEmpty) {
      return meta.upcharge!.values.first;
    }
    return 0.0;
  }

  int _getFreeSauceCount() {
    final fromGroup = _maxFreeForGroupLabel('sauces');
    if (fromGroup != null) return fromGroup;

    final value = widget.menuItem.freeSauceCount;
    if (value is Map) {
      final key = _normalizeSizeKey(_selectedSize);
      return (key.isNotEmpty && value[key] != null) ? value[key] as int : 0;
    }
    if (value is int) return value;
    return 0;
  }

  int _getFreeDressingCount() {
    final fromGroup = _maxFreeForGroupLabel('dressings');
    if (fromGroup != null) return fromGroup;

    final value =
        widget.menuItem.freeDressingCount ?? widget.menuItem.freeSauceCount;
    if (value is Map) {
      final key = _normalizeSizeKey(_selectedSize);
      return (key.isNotEmpty && value[key] != null) ? value[key] as int : 0;
    }
    if (value is int) return value;
    return 0;
  }

  double _getExtraSauceUpcharge() {
    // Use extraSauceUpcharge if present, fallback to 0.95
    return (widget.menuItem.extraSauceUpcharge as num?)?.toDouble() ?? 0.95;
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
    final usesDynamicToppingPricing = _selectedSize != null &&
        (widget.menuItem.additionalToppingPrices != null ||
            (widget.menuItem.sizes?.isNotEmpty ?? false));

    // 1. Add-ons
    if (widget.menuItem.optionalAddOns != null) {
      for (final addOn in widget.menuItem.optionalAddOns!) {
        final ingId = addOn['ingredientId'] ?? addOn['id'];
        // Salad/dinner: priced via _currentIngredients path below
        if ((_isSalad() || _isDinner()) &&
            _currentIngredients.contains(ingId)) {
          continue;
        }
        if (_wasIncludedIngredient(ingId.toString())) {
          continue; // included in base price — never charge as add-on
        }
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
      final wasIncluded = _wasIncludedIngredient(ingId);

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
        if (_isPizzaOrCalzone() && !wasIncluded) {
          final freeToppings = _maxFreeForGroupLabel('toppings') ??
              _maxFreeForGroupLabel('meats') ??
              0;
          final extraIds = _currentIngredients.where((id) {
            if (_isDoughIngredient(id)) return false;
            if (_selectedSauceCounts.containsKey(id)) return false;
            if (_selectedDressingCounts.containsKey(id)) return false;
            return !_wasIncludedIngredient(id);
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

  double get _basePrice {
    final key = _normalizeSizeKey(_selectedSize);
    if (key.isNotEmpty &&
        widget.menuItem.sizePrices != null &&
        widget.menuItem.sizePrices![key] != null) {
      return (widget.menuItem.sizePrices![key] as num).toDouble();
    }
    final sizes = widget.menuItem.sizes;
    if (sizes != null && _selectedSize != null) {
      for (final s in sizes) {
        if (s.label == _selectedSize || _normalizeSizeKey(s.label) == key) {
          return s.basePrice;
        }
      }
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
        return;
      }

      final group = _groupsForUi().firstWhere(
        (g) => (g['label']?.toString() ?? '') == groupLabel,
        orElse: () => <String, dynamic>{},
      );
      final max = (group['max'] as int?) ?? 0;
      if (max > 0) {
        final ids = (group['ingredientIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toSet();
        if (_currentIngredients.where((id) => ids.contains(id)).length >= max) {
          return;
        }
      }

      _currentIngredients.add(ingId);
      if (_isPizzaOrCalzone()) {
        _doubleToppings[ingId] = false;
        _ingredientPortions[ingId] = Portion.whole;
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
      final group = _groupsForUi().firstWhere(
        (g) => (g['label']?.toString() ?? '') == groupLabel,
        orElse: () => <String, dynamic>{},
      );
      final ids = (group['ingredientIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      for (final id in ids) {
        _currentIngredients.remove(id);
      }
      if (ingId != null && ingId.isNotEmpty) {
        _currentIngredients.add(ingId);
      }
    });
  }

  void _submit() {
    final loc = AppLocalizations.of(context)!;
    setState(() => _error = null);

    // --- RADIO + GROUP MIN/MAX VALIDATION ---
    for (final group in _groupsForUi()) {
      final groupLabel = (group['label'] ?? '').toString();
      if (groupLabel.isEmpty) continue;
      final min = (group['min'] as int?) ?? 0;
      final max = (group['max'] as int?) ?? 0;

      if (_isRadioGroup(groupLabel)) {
        final selected = _radioSelections[groupLabel];
        if (selected == null || selected.isEmpty) {
          setState(() => _error =
              loc.pleaseSelectRequired.replaceFirst('{name}', groupLabel));
          return;
        }
        continue;
      }

      final ids = (group['ingredientIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toSet();
      var totalSelected =
          _currentIngredients.where((id) => ids.contains(id)).length;
      if (groupLabel.toLowerCase() == 'cheeses') {
        totalSelected = _selectedCheeses.where((id) => ids.contains(id)).length;
      }

      if (min > 0 && totalSelected < min) {
        setState(() => _error =
            loc.pleaseSelectRequired.replaceFirst('{name}', groupLabel));
        return;
      }
      if (max > 0 && totalSelected > max) {
        setState(() {
          _error = 'Too many selected for $groupLabel (max $max).';
        });
        return;
      }
    }

    // --- PIZZA SAUCE SPLIT VALIDATION ---
    if (_isPizzaOrCalzone()) {
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
      'currentIngredients': _currentIngredients.where((id) {
        if (_selectedDressingCounts.containsKey(id)) return false;
        if (_selectedSauceCounts.containsKey(id)) return false;
        if (_radioSelections.values.contains(id)) return false;
        final lower = id.toLowerCase();
        if (lower.startsWith('crust_') ||
            lower.startsWith('cook_') ||
            lower.startsWith('cut_')) {
          return false;
        }
        return true;
      }).toList(),
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
    if (_isPizzaOrCalzone()) {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Consumer<shared.FranchiseProvider>(
      builder: (context, provider, child) {
        if (!provider.hasValidFranchise) {
          return const Dialog(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // franchiseId scoped for all customizations, addons, pricing (P1 enforcement)
        Provider.of<shared.FranchiseProvider>(context, listen: false);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
          ),
          backgroundColor: shared.UiConfig.surfaceColor,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              minWidth: 300,
              maxWidth: 440,
            ),
            child: Padding(
              padding: shared.UiConfig.cardPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomizationHeader(
                            menuItem: widget.menuItem,
                            theme: theme,
                            loc: loc,
                          ),
                          SizedBox(height: shared.DesignTokens.gridSpacing),

                          if (widget.menuItem.category.toLowerCase() !=
                                  'drinks' &&
                              widget.menuItem.sizes != null &&
                              widget.menuItem.sizes!.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: SizeDropdown(
                                menuItem: widget.menuItem,
                                selectedSize: _selectedSize,
                                onChanged: (newSize) {
                                  setState(() {
                                    _selectedSize = newSize;
                                    _resyncWingsForSize(newSize);
                                  });
                                },
                                toppingCostLabel: _isPizzaOrCalzone()
                                    ? ToppingCostLabel(
                                        theme: theme,
                                        loc: loc,
                                        getToppingUpcharge: _getToppingUpcharge,
                                        currencyFormat: (BuildContext context,
                                                double amount) =>
                                            shared.UiConfig.currencyFormat(
                                                amount),
                                      )
                                    : null,
                                normalizeSizeKey: _normalizeSizeKey,
                              ),
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
                              onPortionChanged: (splitKey, sauceId) {
                                setState(() {
                                  _selectedDippedSauces[splitKey] = sauceId;
                                  _isAnyDipped = _selectedDippedSauces.values
                                      .any((v) => v != null && v != 'plain');
                                });
                              },
                            ),
                            WingsDipSauceSelector(
                              menuItem: widget.menuItem,
                              theme: theme,
                              loc: loc,
                              ingredientMetadata: _ingredientMetadata,
                              sideDipCounts: _sideDipCounts,
                              selectedSize: _selectedSize,
                              setState: setState,
                            ),
                          ],

                          if (widget.menuItem.category.toLowerCase() ==
                              'drinks')
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
                            Builder(
                              builder: (context) {
                                final currentFoodIds =
                                    _currentIngredients.where((id) {
                                  final meta = _ingredientMetadata[id];
                                  final type = meta?.type?.toLowerCase() ?? '';
                                  if (_radioSelections.values.contains(id)) {
                                    return false;
                                  }
                                  final lower = id.toLowerCase();
                                  if (lower.startsWith('crust_') ||
                                      lower.startsWith('cook_') ||
                                      lower.startsWith('cut_')) {
                                    return false;
                                  }
                                  // AFTER
                                  // AFTER
                                  final typeId = (meta?.typeId ?? type)
                                      .toString()
                                      .toLowerCase();
                                  if (type == 'cheeses' ||
                                      typeId == 'cheeses' ||
                                      type == 'sauces' ||
                                      type == 'sauce' ||
                                      typeId == 'sauces' ||
                                      typeId == 'sauce') {
                                    return false;
                                  }
                                  // Also hide if this id is a selected pizza sauce
                                  if (_pizzaSauceSelections
                                      .any((s) => s.id == id && s.selected)) {
                                    return false;
                                  }
                                  if (_selectedCheeses.contains(id)) {
                                    return false;
                                  }
                                  return !_selectedDressingCounts
                                          .containsKey(id) &&
                                      !_selectedSauceCounts.containsKey(id) &&
                                      type != 'crust' &&
                                      type != 'cook' &&
                                      type != 'cut';
                                }).toList();

                                // AFTER
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 10, bottom: 10),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: shared.UiConfig.primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 14),
                                        child: Text(
                                          "Current Toppings",
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            color:
                                                shared.UiConfig.onPrimaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (currentFoodIds.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 8, left: 4, right: 4),
                                        child: Text(
                                          "None — defaults appear here when set on the item. Add extras below.",
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: shared
                                                .UiConfig.secondaryTextColor,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ...currentFoodIds.map((ingId) {
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
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      meta?.name ?? ingId,
                                                      style: theme
                                                          .textTheme.bodyLarge,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  TextButton(
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: theme
                                                          .colorScheme.error,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _currentIngredients
                                                            .remove(ingId);
                                                        _doubleToppings
                                                            .remove(ingId);
                                                        _ingredientPortions
                                                            .remove(ingId);
                                                        _selectedCheeses
                                                            .remove(ingId);
                                                        // Return to optional list (salad/dinner add-ons)
                                                        _selectedAddOns
                                                            .remove(ingId);
                                                        _doubleAddOns
                                                            .remove(ingId);
                                                        for (var i = 0;
                                                            i <
                                                                _pizzaSauceSelections
                                                                    .length;
                                                            i++) {
                                                          if (_pizzaSauceSelections[
                                                                      i]
                                                                  .id ==
                                                              ingId) {
                                                            _pizzaSauceSelections[
                                                                    i] =
                                                                _pizzaSauceSelections[
                                                                        i]
                                                                    .copyWith(
                                                                        selected:
                                                                            false);
                                                          }
                                                        }
                                                      });
                                                    },
                                                    child: Text(loc.remove),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  // Left/right only on pizza (not calzone, not salad)
                                                  if (_isPizza() &&
                                                      !_isCalzone()) ...[
                                                    Flexible(
                                                      fit: FlexFit.tight,
                                                      child: PortionSelector(
                                                        value:
                                                            _ingredientPortions[
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
                                                      isDouble: _doubleToppings[
                                                              ingId] ==
                                                          true,
                                                      onTap: () =>
                                                          _handleDoubleChanged(
                                                              ingId,
                                                              !(_doubleToppings[
                                                                      ingId] ??
                                                                  false)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                          // --- Begin Pizza/Calzone Topping Tabs UI ---
                          if (_isPizzaOrCalzone() &&
                              _toppingTabLabels.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 18, bottom: 4),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: shared.UiConfig.primaryColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 14),
                                child: Text(
                                  "Additional Toppings",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: shared.UiConfig.onPrimaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                          if (_isPizzaOrCalzone() &&
                              _toppingTabLabels.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6.0), // Much tighter vertical space
                              child: Container(
                                decoration: BoxDecoration(
                                  color: shared.UiConfig.cardColor,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                      color: shared.UiConfig.dividerColor,
                                      width: 1),
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
                                                ? shared.UiConfig.secondaryColor
                                                : shared.UiConfig.cardColor
                                                    .withValues(alpha: 0.0),
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          alignment: Alignment.center,
                                          child: Text(
                                            label,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              color: selected
                                                  ? shared.UiConfig.cardColor
                                                  : shared
                                                      .UiConfig.secondaryColor,
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

                          if (_isPizzaOrCalzone() &&
                              _selectedToppingTab.isNotEmpty)
                            Builder(
                              builder: (context) {
                                final group =
                                    _toppingTabGroups.firstWhereOrNull((g) =>
                                        g['label'] == _selectedToppingTab);
                                if (group == null) return SizedBox.shrink();

                                final ingredientIds =
                                    (group['ingredientIds'] as List<dynamic>? ??
                                            [])
                                        .map((e) => e.toString())
                                        .toList();

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 4, bottom: 4),
                                      child: Divider(
                                        thickness: 2,
                                        color:
                                            shared.UiConfig.secondaryTextColor,
                                      ),
                                    ),
                                    ...ingredientIds
                                        .where((ingId) => !_currentIngredients
                                            .contains(ingId))
                                        .map((ingId) {
                                      final meta = _ingredientMetadata[ingId];
                                      final labels =
                                          (group['optionLabels'] as Map?)?.map(
                                                  (k, v) => MapEntry(
                                                      k.toString(),
                                                      v.toString())) ??
                                              const <String, String>{};
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
                                                child: Text(
                                                    meta?.name ??
                                                        labels[ingId] ??
                                                        ingId,
                                                    style: theme
                                                        .textTheme.bodyLarge),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    final max = (group['max']
                                                            as int?) ??
                                                        0;
                                                    if (max > 0) {
                                                      final ids =
                                                          (group['ingredientIds']
                                                                      as List<
                                                                          dynamic>? ??
                                                                  [])
                                                              .map((e) =>
                                                                  e.toString())
                                                              .toSet();
                                                      final selectedInGroup =
                                                          _currentIngredients
                                                              .where((id) => ids
                                                                  .contains(id))
                                                              .length;
                                                      if (selectedInGroup >=
                                                          max) {
                                                        return;
                                                      }
                                                    }
                                                    _currentIngredients
                                                        .add(ingId);
                                                    _doubleToppings[ingId] =
                                                        false;
                                                    _ingredientPortions[ingId] =
                                                        Portion.whole;
                                                  });
                                                },
                                                child: Text('Click to Add',
                                                    style: TextStyle(
                                                        color: theme.colorScheme
                                                            .primary)),
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
                                        color:
                                            shared.UiConfig.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                          // --- End Pizza/Calzone Topping Tabs UI ---

                          if (!_isWings())
                            ..._checkboxGroups.map((group) {
                              final label = (group['label'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              // Pizza/calzone: only Cheeses — no Sauce / Add-ons / other groups
                              if ((_isPizzaOrCalzone() || _isSalad()) &&
                                  label != 'cheeses') {
                                return const SizedBox.shrink();
                              }
                              // Salads: no cheeses section from modifier groups either
                              if (_isSalad()) {
                                return const SizedBox.shrink();
                              }
                              if (label == 'cheeses') {
                                // AFTER
                                final cheeseIds = _optionalIdsByType('cheeses');
                                if (cheeseIds.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final selectedCheeses = cheeseIds
                                    .where(
                                        (id) => _selectedCheeses.contains(id))
                                    .toList();
                                final summary = selectedCheeses.isEmpty
                                    ? "None"
                                    : selectedCheeses.map((id) {
                                        final meta = _ingredientMetadata[id];
                                        final isDouble =
                                            _cheeseIsDouble[id] == true;
                                        final portion = _cheesePortions[id] ??
                                            Portion.whole;
                                        // Only show portion if not calzone and not whole
                                        final labels =
                                            (group['optionLabels'] as Map?)
                                                    ?.map((k, v) => MapEntry(
                                                        k.toString(),
                                                        v.toString())) ??
                                                const <String, String>{};
                                        return "${meta?.name ?? labels[id] ?? id}"
                                            "${isDouble ? " (Double)" : ""}"
                                            "${(!_isCalzone() && portion != Portion.whole) ? " (${portionNames[portion]})" : ""}";
                                      }).join(", ");
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 0),
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: shared.UiConfig.primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 14),
                                          child: Text(
                                            "Cheeses",
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              color: shared
                                                  .UiConfig.onPrimaryColor,
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
                                              ?.copyWith(
                                                  color: shared.UiConfig
                                                      .secondaryTextColor),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            "Add extra cheeses for an additional charge.",
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color:
                                                  shared.UiConfig.hintTextColor,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                        children: cheeseIds.map((cheeseId) {
                                          final meta =
                                              _ingredientMetadata[cheeseId];
                                          final selected = _selectedCheeses
                                              .contains(cheeseId);
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
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          meta?.name ??
                                                              ((group['optionLabels']
                                                                          as Map?)?[
                                                                      cheeseId]
                                                                  ?.toString()) ??
                                                              cheeseId,
                                                          style: theme.textTheme
                                                              .bodyLarge,
                                                        ),
                                                      ),
                                                      if (selected)
                                                        TextButton(
                                                          style: TextButton
                                                              .styleFrom(
                                                            foregroundColor:
                                                                theme
                                                                    .colorScheme
                                                                    .error,
                                                          ),
                                                          // AFTER
                                                          onPressed: () {
                                                            setState(() {
                                                              // AFTER
                                                              _selectedCheeses
                                                                  .remove(
                                                                      cheeseId);
                                                              _cheesePortions
                                                                  .remove(
                                                                      cheeseId);
                                                              _cheeseIsDouble
                                                                  .remove(
                                                                      cheeseId);
                                                            });
                                                          },
                                                          child: Text('Remove'),
                                                        )
                                                      else
                                                        TextButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              final max = (group[
                                                                          'max']
                                                                      as int?) ??
                                                                  0;
                                                              if (max > 0 &&
                                                                  _selectedCheeses
                                                                          .length >=
                                                                      max) {
                                                                return;
                                                              }
                                                              // AFTER
                                                              // AFTER
                                                              _selectedCheeses
                                                                  .add(
                                                                      cheeseId);
                                                              _cheesePortions[
                                                                      cheeseId] =
                                                                  Portion.whole;
                                                              _cheeseIsDouble[
                                                                      cheeseId] =
                                                                  false;
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
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 6.0),
                                                      child: Row(
                                                        children: [
                                                          if (!_isCalzone()) ...[
                                                            Flexible(
                                                              fit:
                                                                  FlexFit.tight,
                                                              child:
                                                                  PortionSelector(
                                                                value: _cheesePortions[
                                                                        cheeseId] ??
                                                                    Portion
                                                                        .whole,
                                                                onChanged:
                                                                    (portion) {
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
                                                            child:
                                                                PortionPillToggle(
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

                          if (!_isWings())
                            ..._radioGroups.map((group) {
                              final label =
                                  (group['label'] as String?)?.toLowerCase();
                              // AFTER
                              if (label == 'sauces' && _isPizzaOrCalzone()) {
                                // Same UX as Cheeses: list + Click to Add / Remove + portion
                                final sauceIds = _pizzaSauceSelections
                                    .map((s) => s.id)
                                    .toList();
                                if (sauceIds.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final selectedSauces = _pizzaSauceSelections
                                    .where((s) => s.selected)
                                    .toList();
                                final summary = selectedSauces.isEmpty
                                    ? "None"
                                    : selectedSauces.map((s) {
                                        final name =
                                            _ingredientMetadata[s.id]?.name ??
                                                s.name;
                                        final portion = s.portion;
                                        return "$name"
                                            "${(!_isCalzone() && portion != Portion.whole) ? " (${portionNames[portion]})" : ""}";
                                      }).join(", ");
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 0),
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: shared.UiConfig.primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 14),
                                          child: Text(
                                            "Sauces",
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              color: shared
                                                  .UiConfig.onPrimaryColor,
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
                                              ?.copyWith(
                                                  color: shared.UiConfig
                                                      .secondaryTextColor),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            "Choose sauces; use portion for left / right / whole.",
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color:
                                                  shared.UiConfig.hintTextColor,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                        children:
                                            _pizzaSauceSelections.map((sauce) {
                                          final meta =
                                              _ingredientMetadata[sauce.id];
                                          final selected = sauce.selected;
                                          final idx =
                                              _pizzaSauceSelections.indexWhere(
                                                  (s) => s.id == sauce.id);
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
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          meta?.name ??
                                                              sauce.name,
                                                          style: theme.textTheme
                                                              .bodyLarge,
                                                        ),
                                                      ),
                                                      if (selected)
                                                        TextButton(
                                                          style: TextButton
                                                              .styleFrom(
                                                            foregroundColor:
                                                                theme
                                                                    .colorScheme
                                                                    .error,
                                                          ),
                                                          onPressed: () {
                                                            if (idx < 0) return;
                                                            setState(() {
                                                              _pizzaSauceSelections[
                                                                      idx] =
                                                                  sauce.copyWith(
                                                                      selected:
                                                                          false);
                                                            });
                                                          },
                                                          child: Text('Remove'),
                                                        )
                                                      else
                                                        TextButton(
                                                          onPressed: () {
                                                            if (idx < 0) return;
                                                            setState(() {
                                                              final selectedCount =
                                                                  _pizzaSauceSelections
                                                                      .where((s) =>
                                                                          s.selected)
                                                                      .length;
                                                              if (selectedCount >=
                                                                  2) {
                                                                return;
                                                              }
                                                              _pizzaSauceSelections[
                                                                      idx] =
                                                                  sauce
                                                                      .copyWith(
                                                                selected: true,
                                                                portion: Portion
                                                                    .whole,
                                                              );
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
                                                  // AFTER
                                                  if (selected)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 6.0),
                                                      child: Row(
                                                        children: [
                                                          if (!_isCalzone()) ...[
                                                            Flexible(
                                                              fit:
                                                                  FlexFit.tight,
                                                              child:
                                                                  PortionSelector(
                                                                value: sauce
                                                                    .portion,
                                                                onChanged:
                                                                    (portion) {
                                                                  if (idx < 0) {
                                                                    return;
                                                                  }
                                                                  setState(() {
                                                                    _pizzaSauceSelections[
                                                                            idx] =
                                                                        sauce
                                                                            .copyWith(
                                                                      portion:
                                                                          portion,
                                                                      selected:
                                                                          true,
                                                                    );
                                                                  });
                                                                },
                                                              ),
                                                            ),
                                                            SizedBox(width: 10),
                                                          ],
                                                          Flexible(
                                                            fit: FlexFit.tight,
                                                            child:
                                                                PortionPillToggle(
                                                              isDouble: sauce
                                                                          .amount
                                                                          .toLowerCase() ==
                                                                      'extra' ||
                                                                  sauce.amount
                                                                          .toLowerCase() ==
                                                                      'double',
                                                              onTap: () {
                                                                if (idx < 0) {
                                                                  return;
                                                                }
                                                                setState(() {
                                                                  final isDouble = sauce
                                                                              .amount
                                                                              .toLowerCase() ==
                                                                          'extra' ||
                                                                      sauce.amount
                                                                              .toLowerCase() ==
                                                                          'double';
                                                                  _pizzaSauceSelections[
                                                                          idx] =
                                                                      sauce
                                                                          .copyWith(
                                                                    amount: isDouble
                                                                        ? 'regular'
                                                                        : 'extra',
                                                                    selected:
                                                                        true,
                                                                  );
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
                              } else if (label == 'dressings') {
                                // --- Dressings logic ---
                                return DressingSelectorGroup(
                                  group: group,
                                  theme: theme,
                                  loc: loc,
                                  selectedDressingCounts:
                                      _selectedDressingCounts,
                                  onCountChanged: (ingId, newCount) {
                                    setState(() =>
                                        _selectedDressingCounts[ingId] =
                                            newCount);
                                  },
                                  getFreeDressingCount: _getFreeDressingCount,
                                  getExtraDressingUpcharge:
                                      _getExtraDressingUpcharge,
                                  ingredientMetadata: _ingredientMetadata,
                                );
                              }
                              // DO NOT RENDER crust, cook, cut here
                              return null;
                            }).whereType<Widget>(),

                          // AFTER
                          // Optional ingredients: only when HQ attached optionalAddOns
                          // (salads e.g. garbanzo; dinners e.g. meatballs). Not pizza/calzone/wings.
                          if (!_isWings() &&
                              !_isPizzaOrCalzone() &&
                              widget.menuItem.optionalAddOns != null &&
                              widget.menuItem.optionalAddOns!.isNotEmpty)
                            OptionalAddOnsGroup(
                              menuItem: widget.menuItem,
                              theme: theme,
                              loc: loc,
                              ingredientMetadata: _ingredientMetadata,
                              selectedAddOns: _selectedAddOns,
                              currentIngredientIds: _currentIngredients,
                              doubleAddOns: _doubleAddOns,
                              selectedSauceCounts: _selectedSauceCounts,
                              usesDynamicToppingPricing:
                                  widget.menuItem.additionalToppingPrices !=
                                          null &&
                                      _selectedSize != null,
                              getToppingUpcharge: _getToppingUpcharge,
                              getIngredientUpcharge: _getIngredientUpcharge,
                              onToggleAddOn: (ingId, val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedAddOns.add(ingId);
                                    _doubleAddOns[ingId] = false;
                                    // Salad/dinner: show under Current Toppings
                                    if (_isSalad() || _isDinner()) {
                                      _currentIngredients.add(ingId);
                                      _doubleToppings[ingId] = false;
                                    }
                                  } else {
                                    _selectedAddOns.remove(ingId);
                                    _doubleAddOns.remove(ingId);
                                    if (_isSalad() || _isDinner()) {
                                      _currentIngredients.remove(ingId);
                                      _doubleToppings.remove(ingId);
                                    }
                                  }
                                });
                              },
                              onChangeSauceCount: (ingId, delta) {
                                setState(() {
                                  final count =
                                      _selectedSauceCounts[ingId] ?? 0;
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

                          // --- ORDER DETAILS: crust/cook/cut — pizza only ---
                          if (!_isWings() &&
                              !_isCalzone() &&
                              !_isSalad() &&
                              !_isDinner())
                            Builder(
                              builder: (context) {
                                // Get crust / cook / cut for pizza Order Details
                                var orderDetailGroups =
                                    _radioGroups.where((group) {
                                  final label = (group['label'] as String?)
                                      ?.toLowerCase();
                                  final id =
                                      (group['id'] as String?)?.toLowerCase() ??
                                          '';
                                  return label == 'crust' ||
                                      label == 'cook' ||
                                      label == 'cut' ||
                                      id == 'crust' ||
                                      id == 'cook' ||
                                      id == 'cut';
                                }).toList();

                                // Fallback: template structural groups when stored groups omit them
                                if (_isPizza() && orderDetailGroups.isEmpty) {
                                  orderDetailGroups =
                                      shared.MenuProfileTemplates.seedGroups(
                                    shared.MenuProfile.pizza,
                                  )
                                          .where((g) {
                                            final id = g.id.toLowerCase();
                                            return id == 'crust' ||
                                                id == 'cook' ||
                                                id == 'cut';
                                          })
                                          .map((g) => <String, dynamic>{
                                                'id': g.id,
                                                'label': g.label,
                                                'ingredientIds': g.options
                                                    .map((o) => o.id)
                                                    .toList(),
                                                'optionLabels': {
                                                  for (final o in g.options)
                                                    o.id: o.label,
                                                },
                                                'min': g.min,
                                                'max': g.max,
                                              })
                                          .toList();
                                  for (final g in orderDetailGroups) {
                                    final label = (g['label'] as String?) ?? '';
                                    if (label.isEmpty) continue;
                                    if ((_radioSelections[label] ?? '')
                                        .isNotEmpty) {
                                      continue;
                                    }
                                    final ids =
                                        (g['ingredientIds'] as List? ?? [])
                                            .map((e) => e.toString())
                                            .toList();
                                    if (ids.isEmpty) continue;
                                    _radioSelections[label] = ids.first;
                                  }
                                }

                                // Compose summary for collapsed state
                                String detailsSummary = orderDetailGroups
                                    .map((group) {
                                      final label =
                                          (group['label'] as String?) ?? '';
                                      final selected = _radioSelections[label];
                                      if (selected == null) return '';
                                      final meta =
                                          _ingredientMetadata[selected];
                                      final labels =
                                          (group['optionLabels'] as Map?)?.map(
                                                  (k, v) => MapEntry(
                                                      k.toString(),
                                                      v.toString())) ??
                                              const <String, String>{};
                                      return "${label.capitalize()}: ${meta?.name ?? labels[selected] ?? selected}";
                                    })
                                    .where((str) => str.isNotEmpty)
                                    .join(" | ");

                                return Padding(
                                  padding: const EdgeInsets.only(
                                      top: 12.0, bottom: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 0),
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: shared.UiConfig.primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 14),
                                          child: Text(
                                            "Order Details",
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              color: shared
                                                  .UiConfig.onPrimaryColor,
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
                                              ?.copyWith(
                                                  color: shared.UiConfig
                                                      .secondaryTextColor),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            "Tap to customize crust, cook, or cut.",
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color:
                                                  shared.UiConfig.hintTextColor,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                        children:
                                            orderDetailGroups.map((group) {
                                          return RadioCustomizationGroup(
                                            group: group,
                                            theme: theme,
                                            loc: loc,
                                            ingredientMetadata:
                                                _ingredientMetadata,
                                            radioSelections: _radioSelections,
                                            getIngredientUpcharge:
                                                _getIngredientUpcharge,
                                            handleRadioSelect:
                                                _handleRadioSelect,
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
                    sizes: widget.menuItem.sizes?.map((s) => s.label).toList(),
                    menuItemPrice: widget.menuItem.price,
                    drinkMaxPerFlavor: _drinkMaxPerFlavor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
