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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customization_controller.dart';

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
  late Map<String, String?> _radioSelections;
  String? _selectedSize;
  String? _error;
  late Map<String, shared.IngredientMetadata> _ingredientMetadata;

  late List<Map<String, dynamic>> _checkboxGroups;
  late List<Map<String, dynamic>> _radioGroups;

  final Map<String, Portion> _ingredientPortions = {};

  final Map<String, String> _ingredientAmounts =
      {}; // ingredientId -> "Light"/"Regular"/"Extra"

  // --- Wings-specific fields ---
  Map<String, String?> _selectedDippedSauces = {};
  bool _isAnyDipped = false;
  Map<String, int> _sideDipCounts = {};

  /// W2: franchise config/menu_profile_wings.sauceIngredientIds when item has none.
  List<String> _franchiseWingSauceIds = const [];

  // Drinks state
  late Map<String, int> _drinkFlavorCounts; // ingredientId -> count
  int _drinkTotalCount = 0;
  int _drinkMaxPerFlavor = 10; // Default, overwritten by Firestore value

  // --- Pizza Sauce State ---
  bool _sauceSplitValidationError = false;

  // --- grouped tabs for meats and veggies for pizzas / calzones ---
  late List<String>
      _toppingTabLabels; // Will be ["Meats", "Veggies"] if present
  String _selectedToppingTab = '';
  late List<Map<String, dynamic>> _toppingTabGroups;

  late final CustomizationController _controller;
  // AFTER
  void _handleSauceTap(String sauceId, bool currentlySelected) {
    setState(() {
      _controller.setPizzaSauceSelected(
        sauceId,
        !currentlySelected,
        max: 2,
      );
    });
  }

  void _handleSaucePortionChange(String sauceId, Portion portion) {
    final name = portion.toString().split('.').last;
    setState(() {
      _controller.setPizzaSaucePortion(sauceId, name);
    });
  }

  void _resetPizzaSauceSelections() {
    setState(() {
      for (final s in List<Map<String, dynamic>>.from(
          _controller.pizzaSauceSelections)) {
        final id = s['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        _controller.setPizzaSauceSelected(id, false);
      }
      final includedSauceId =
          widget.menuItem.includedIngredients?.firstWhereOrNull((ing) {
        final t = (ing['typeId'] ?? ing['type'] ?? '').toString().toLowerCase();
        return t == 'sauces' || t == 'sauce';
      })?['ingredientId']?.toString();
      if (includedSauceId != null && includedSauceId.isNotEmpty) {
        _controller.setPizzaSauceSelected(includedSauceId, true, max: 2);
        _controller.setPizzaSaucePortion(includedSauceId, 'whole');
        _controller.setPizzaSauceAmount(includedSauceId, 'regular');
      }
    });
  }

  // Helper to map UI size to Firestore key for upcharges
  String _normalizeSizeKey(String? uiSize) {
    return shared.MenuPricing.normalizeSizeKey(widget.menuItem, uiSize);
  }

  bool _wasIncludedIngredient(String ingredientId) =>
      shared.MenuPricing.wasIncludedIngredient(widget.menuItem, ingredientId);

  bool _showsCurrentIngredients() {
    if (_isWings()) return false;
    final profile = widget.menuItem.effectiveMenuProfile.toLowerCase();
    if (profile == shared.MenuProfile.pizza ||
        profile == shared.MenuProfile.calzone ||
        profile == shared.MenuProfile.sub) {
      return true;
    }
    final cat = widget.menuItem.category.toLowerCase();
    final catId = (widget.menuItem.categoryId ?? '').toLowerCase();
    return [cat, catId].any((c) =>
        c.contains('pizza') ||
        c.contains('calzone') ||
        c.contains('salad') ||
        c.contains('sub') ||
        c.contains('dinner'));
  }

  bool _isPizzaOrCalzone() =>
      shared.MenuPricing.isPizzaOrCalzone(widget.menuItem);

  bool _isCalzone() {
    final profile = widget.menuItem.effectiveMenuProfile.toLowerCase();
    if (profile == shared.MenuProfile.calzone) return true;
    return widget.menuItem.category.toLowerCase().contains('calzone');
  }

  bool _isWings() => shared.MenuPricing.isWings(widget.menuItem);

  bool _isSalad() => shared.MenuPricing.isSalad(widget.menuItem);

  bool _isDinner() => shared.MenuPricing.isDinner(widget.menuItem);

  bool _isSub() => shared.MenuPricing.isSub(widget.menuItem);

  List<String> _effectiveWingSauceIds() {
    if (widget.menuItem.sideDipSauceOptions?.isNotEmpty == true) {
      return List<String>.from(widget.menuItem.sideDipSauceOptions!);
    }
    if (widget.menuItem.dippingSauceOptions?.isNotEmpty == true) {
      return List<String>.from(widget.menuItem.dippingSauceOptions!);
    }
    // modifierGroups wing_sauce / wing_dips
    final groups = widget.menuItem.modifierGroups ?? const [];
    final fromGroups = <String>[];
    for (final g in groups) {
      final id = g.id.toLowerCase();
      final label = g.label.toLowerCase();
      if (id == 'wing_sauce' ||
          id == 'wing_dips' ||
          label.contains('sauce') ||
          label.contains('dip')) {
        for (final o in g.options) {
          final key =
              (o.ingredientId != null && o.ingredientId!.trim().isNotEmpty)
                  ? o.ingredientId!.trim()
                  : o.id.trim();
          if (key.isNotEmpty && key.toLowerCase() != 'plain') {
            fromGroups.add(key);
          }
        }
      }
    }
    if (fromGroups.isNotEmpty) return fromGroups;
    // W2 franchise pool
    if (_franchiseWingSauceIds.isNotEmpty) {
      return List<String>.from(_franchiseWingSauceIds);
    }
    return const [];
  }

  void _resyncWingsForSize(String? size) {
    if (!_isWings()) return;
    final splitCount = widget.menuItem.dippingSplits?[size] ?? 2;

    final nextSplits = <String, String?>{};
    for (var i = 0; i < splitCount; i++) {
      final key = 'split_$i';
      nextSplits[key] = _selectedDippedSauces[key] ?? 'plain';
    }
    _selectedDippedSauces = nextSplits;
    _isAnyDipped =
        _selectedDippedSauces.values.any((v) => v != null && v != 'plain');

    final dipIds = _effectiveWingSauceIds();
    final nextCups = <String, int>{};
    for (final id in dipIds) {
      nextCups[id] = _sideDipCounts[id] ?? 0;
    }
    _sideDipCounts = nextCups;
  }

  Future<void> _loadFranchiseWingSaucePoolIfNeeded() async {
    if (!_isWings()) return;
    if ((widget.menuItem.sideDipSauceOptions?.isNotEmpty ?? false) ||
        (widget.menuItem.dippingSauceOptions?.isNotEmpty ?? false)) {
      return;
    }
    try {
      final franchiseId =
          Provider.of<shared.FranchiseProvider>(context, listen: false)
              .currentFranchiseId;
      if (franchiseId.isEmpty || franchiseId == 'unknown') return;
      final doc = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('config')
          .doc('menu_profile_wings')
          .get();
      if (!doc.exists || doc.data() == null) return;
      final raw = doc.data()!['sauceIngredientIds'];
      if (raw is! List) return;
      final ids =
          raw.map((e) => e.toString()).where((id) => id.isNotEmpty).toList();
      if (!mounted || ids.isEmpty) return;
      setState(() {
        _franchiseWingSauceIds = ids;
        _resyncWingsForSize(_selectedSize);
      });
    } catch (_) {
      // Non-fatal — Plain-only remains valid
    }
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

    // --- Cheeses: init-only locals → syncSelection (no State fields) ---
    final cheeseIds = _optionalIdsByType('cheeses');
    final initSelectedCheeses = <String>{
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
            initSelectedCheeses.add(key);
          }
        }
      }
    }
    final initCheesePortions = <String, String>{
      for (final id in initSelectedCheeses) id: 'whole',
    };
    final initCheeseIsDouble = <String, bool>{
      for (final id in initSelectedCheeses) id: false,
    };

    _quantity = widget.initialQuantity;
    _ingredientMetadata = widget.ingredientMetadata ??
        Provider.of<Map<String, shared.IngredientMetadata>>(context,
            listen: false);
    final sizes = widget.menuItem.sizes;
    _selectedSize =
        (sizes != null && sizes.isNotEmpty) ? sizes.first.label : null;
    _drinkFlavorCounts = {};

    _controller = CustomizationController(
      item: widget.menuItem,
      ingredientMap: _ingredientMetadata,
      initialQuantity: widget.initialQuantity,
      initialCustomizations: widget.initialCustomizations,
    );
    if (_selectedSize != null) {
      _controller.setSelectedSize(_selectedSize);
    }
    _controller.setQuantity(_quantity);

    var initPizzaSauceSelections = <Map<String, dynamic>>[];
    if (_isPizzaOrCalzone()) {
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

      initPizzaSauceSelections = sauceIds.map((id) {
        final meta = _ingredientMetadata[id];
        return <String, dynamic>{
          'id': id,
          'name': meta?.name ?? sauceLabels[id] ?? id,
          'selected': false,
          'portion': 'whole',
          'amount': 'regular',
        };
      }).toList();

      // Prefer included sauce (typeId), else first available
      final includedSauceId =
          widget.menuItem.includedIngredients?.firstWhereOrNull((ing) {
        final t = (ing['typeId'] ?? ing['type'] ?? '').toString().toLowerCase();
        return t == 'sauces' || t == 'sauce';
      })?['ingredientId']?.toString();

      if (includedSauceId != null && includedSauceId.isNotEmpty) {
        final idx = initPizzaSauceSelections
            .indexWhere((s) => s['id']?.toString() == includedSauceId);
        if (idx >= 0) {
          initPizzaSauceSelections[idx] = {
            ...initPizzaSauceSelections[idx],
            'selected': true,
            'portion': 'whole',
          };
        }
      }
    }

    _initializeSelections();

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

    final initSelectedAddOns = <String>{};
    final initDoubleAddOns = <String, bool>{};
    final initSauceCounts = _buildInitialSauceCounts();
    final initDressingCounts = _buildInitialDressingCounts();

    // Always init — pricing/syncSelection read these for every menu profile.
    _selectedDippedSauces = {};
    _sideDipCounts = {};
    _isAnyDipped = false;

    if (_isWings()) {
      final wingSizes = widget.menuItem.sizes ?? [];
      _selectedSize ??= wingSizes.isNotEmpty ? wingSizes.first.label : null;
      _resyncWingsForSize(_selectedSize);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFranchiseWingSaucePoolIfNeeded();
      });
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

    // Hydrate controller from post-init selection maps (B2.2.1 + B2.2.3.1).
    _controller.syncSelection(
      currentIngredients: _currentIngredients,
      selectedAddOns: initSelectedAddOns,
      doubleAddOns: initDoubleAddOns,
      doubleToppings: <String, bool>{},
      selectedSauceCounts: initSauceCounts,
      selectedDressingCounts: initDressingCounts,
      sideDipCounts: Map<String, int>.from(_sideDipCounts),
      selectedCheeses: initSelectedCheeses,
      cheeseIsDouble: initCheeseIsDouble,
      maxFreeSaucesFromGroup: _maxFreeForGroupLabel('sauces'),
      maxFreeDressingsFromGroup: _maxFreeForGroupLabel('dressings'),
      maxFreeToppingsFromGroup: _maxFreeForGroupLabel('toppings'),
      maxFreeMeatsFromGroup: _maxFreeForGroupLabel('meats'),
      wingSauceIds: _effectiveWingSauceIds(),
      cheesePortions: initCheesePortions,
      pizzaSauceSelections: initPizzaSauceSelections,
      sauceSplitValidationError: _sauceSplitValidationError,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // AFTER
  void _initializeSelections() {
    _currentIngredients = {};
    if (widget.menuItem.includedIngredients != null) {
      for (final ing in widget.menuItem.includedIngredients!) {
        final ingId = (ing['ingredientId'] ?? ing['id'])?.toString() ?? '';
        if (ingId.isEmpty) continue;
        _currentIngredients.add(ingId);
      }
    }
    // Pizza/calzone only: cheeses & sauces live in their own sections, not
    // Current Toppings. Dinner/salad/standard keep all included ingredients on
    // Current so they do not open as "Removed" or leak into optional pool.
    if (_isPizzaOrCalzone()) {
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
    }
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

        // --- Default Cook to Regular for Calzones / Subs ---
        if (groupLabel.toLowerCase() == 'cook' &&
            (widget.menuItem.category.toLowerCase().contains('calzone') ||
                _isSub())) {
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
  }

  Map<String, int> _buildInitialSauceCounts() {
    final counts = <String, int>{};
    for (final group in _groupsForUi()) {
      final label = (group['label'] as String?)?.toLowerCase();
      if (label == 'sauces') {
        final ids = (group['ingredientIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        for (final id in ids) {
          counts[id] = 0;
        }
      }
    }
    if (widget.menuItem.optionalAddOns != null) {
      for (final addOn in widget.menuItem.optionalAddOns!) {
        final ingId = addOn['ingredientId'] ?? addOn['id'];
        final meta = _ingredientMetadata[ingId];
        if (meta?.type?.toLowerCase() == "sauces" ||
            addOn['type']?.toString()?.toLowerCase() == "sauces") {
          counts[ingId] = 0;
        }
      }
    }
    return counts;
  }

  Map<String, int> _buildInitialDressingCounts() {
    final counts = <String, int>{};
    for (final group in _groupsForUi()) {
      final label = (group['label'] as String?)?.toLowerCase();
      if (label == 'dressings') {
        final ids = (group['ingredientIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        for (final id in ids) {
          counts[id] = 0;
        }
      }
    }
    return counts;
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
      shared.MenuPricing.isDoughIngredient(ingId);

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

  double _getToppingUpcharge() {
    return shared.MenuPricing.toppingUpcharge(widget.menuItem, _selectedSize);
  }

  double _getIngredientUpcharge(shared.IngredientMetadata? meta) {
    return shared.MenuPricing.ingredientUpcharge(meta);
  }

  /// Price for an optional extra (not part of base included set).
  /// Order matches OptionalAddOnsGroup: dynamic size → meta.upcharge → optionalAddOns.price.
  double _resolveExtraIngredientPrice(String ingId) {
    return shared.MenuPricing.resolveExtraIngredientPrice(
      item: widget.menuItem,
      selectedSize: _selectedSize,
      ingId: ingId,
      ingredientMetadata: _ingredientMetadata,
    );
  }

  int _getFreeSauceCount() {
    final fromGroup = _maxFreeForGroupLabel('sauces');
    return shared.MenuPricing.freeSauceCount(
      widget.menuItem,
      _selectedSize,
      maxFreeFromGroup: fromGroup,
    );
  }

  int _getFreeDressingCount() {
    final fromGroup = _maxFreeForGroupLabel('dressings');
    return shared.MenuPricing.freeDressingCount(
      widget.menuItem,
      _selectedSize,
      maxFreeFromGroup: fromGroup,
    );
  }

  double _getExtraSauceUpcharge() {
    return shared.MenuPricing.extraSauceUpcharge(widget.menuItem);
  }

  double _getExtraDressingUpcharge() {
    return shared.MenuPricing.extraDressingUpcharge(widget.menuItem);
  }

  double _getSaladToppingUpcharge() {
    final prices = widget.menuItem.additionalToppingPrices;
    final key = _normalizeSizeKey(_selectedSize);
    if (prices != null && key != null && prices[key] != null) {
      return (prices[key] as num).toDouble();
    }
    return 0.80;
  }

  void _syncControllerSelection() {
    _controller.maxFreeSaucesFromGroup = _maxFreeForGroupLabel('sauces');
    _controller.maxFreeDressingsFromGroup = _maxFreeForGroupLabel('dressings');
    _controller.maxFreeToppingsFromGroup = _maxFreeForGroupLabel('toppings');
    _controller.maxFreeMeatsFromGroup = _maxFreeForGroupLabel('meats');
    _controller.wingSauceIds = _effectiveWingSauceIds();
  }

  double get _basePrice {
    _syncControllerSelection();
    return _controller.basePrice;
  }

  double get _customizationsTotal {
    _syncControllerSelection();
    return _controller.customizationsTotal;
  }

  double get _totalPrice {
    _syncControllerSelection();
    return _controller.totalPrice;
  }

  int get _doublesCount =>
      _controller.doubleToppings.values.where((isDouble) => isDouble).length;

  void _toggleIngredient(String ingId, String groupLabel) {
    setState(() {
      _controller.toggleIngredient(
        ingId: ingId,
        groupLabel: groupLabel,
        groupsForUi: _groupsForUi(),
        isPizzaOrCalzone: _isPizzaOrCalzone(),
      );
    });
  }

  void _handleDoubleChanged(String ingId, bool value) {
    setState(() {
      _controller.setDoubleTopping(ingId, value, maxDoubles: MAX_DOUBLES);
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
          _controller.currentIngredients.where((id) => ids.contains(id)).length;
      if (groupLabel.toLowerCase() == 'cheeses') {
        totalSelected =
            _controller.selectedCheeses.where((id) => ids.contains(id)).length;
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
      final selected = _controller.pizzaSauceSelections
          .where((s) => s['selected'] == true)
          .toList();

      final halves = selected.where((s) {
        final p = (s['portion'] as String? ?? 'whole').toLowerCase();
        return p != 'whole';
      }).toList();
      if (halves.length == 1) {
        setState(() => _sauceSplitValidationError = true);
        return;
      }
      if (selected.length > 2) {
        setState(() => _sauceSplitValidationError = true);
        return;
      }
      if (halves.length == 2) {
        final sides = halves
            .map((s) => (s['portion'] as String? ?? 'whole').toLowerCase())
            .toSet();
        if (sides.length < 2) {
          setState(() => _sauceSplitValidationError = true);
          return;
        }
      }
      setState(() => _sauceSplitValidationError = false);
    }

    final Map<String, dynamic> ingredientOptions = {};
    if (_isPizzaOrCalzone()) {
      for (final ingId in _controller.currentIngredients) {
        if (_controller.doubleToppings.containsKey(ingId) ||
            _ingredientPortions.containsKey(ingId)) {
          ingredientOptions[ingId] = {
            'double': _controller.doubleToppings[ingId] == true,
            'portion': _ingredientPortions[ingId]?.toString().split('.').last ??
                'whole',
          };
        }
      }
    }

    // Only include sauces with a count > 0
    final nonZeroSauces = Map.fromEntries(
      _controller.selectedSauceCounts.entries.where((e) => e.value > 0),
    );
    final nonZeroDressings = Map.fromEntries(
      _controller.selectedDressingCounts.entries.where((e) => e.value > 0),
    );

    // Add cheese selections to submission result
    final Map<String, dynamic> cheeseOptions = {};
    for (final cheeseId in _controller.selectedCheeses) {
      cheeseOptions[cheeseId] = {
        'portion': _controller.cheesePortions[cheeseId] ?? 'whole',
        'double': _controller.cheeseIsDouble[cheeseId] == true,
      };
    }

    final Map<String, dynamic> result = {
      'currentIngredients': _controller.currentIngredients.where((id) {
        if (_controller.selectedDressingCounts.containsKey(id)) return false;
        if (_controller.selectedSauceCounts.containsKey(id)) return false;
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
      'selectedAddOns': _controller.selectedAddOns.toList(),
      'size': _selectedSize,
      ..._radioSelections,
      if (ingredientOptions.isNotEmpty) 'ingredientOptions': ingredientOptions,
      if (_controller.selectedCheeses.isNotEmpty)
        'cheeses': _controller.selectedCheeses.toList(),
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
      final selected = _controller.pizzaSauceSelections
          .where((s) => s['selected'] == true)
          .toList();
      result['sauce'] = selected
          .map((s) => {
                'id': s['id'],
                'portion': s['portion'] ?? 'whole',
                'amount': s['amount'] ?? 'regular',
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
          backgroundColor: Theme.of(context).colorScheme.surface,
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
                                    _controller.setSelectedSize(newSize);
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
                              sauceIdsOverride: _effectiveWingSauceIds(),
                            ),
                            WingsDipSauceSelector(
                              menuItem: widget.menuItem,
                              theme: theme,
                              loc: loc,
                              ingredientMetadata: _ingredientMetadata,
                              sideDipCounts: _sideDipCounts,
                              selectedSize: _selectedSize,
                              setState: setState,
                              sauceIdsOverride: _effectiveWingSauceIds(),
                            ),
                          ],

                          if (widget.menuItem.category.toLowerCase() ==
                              'drinks')
                            DrinksFlavorSelector(
                              menuItem: widget.menuItem,
                              theme: theme,
                              loc: loc,
                              ingredientMetadata: _ingredientMetadata,
                              selectedSauceCounts:
                                  _controller.selectedSauceCounts,
                              setState: setState,
                            )
                          else if (_showsCurrentIngredients())
                            Builder(
                              builder: (context) {
                                final currentFoodIds =
                                    _controller.currentIngredients.where((id) {
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
                                  // Also hide if this id is a selected pizza sauce
                                  if (_controller.pizzaSauceSelections.any(
                                      (s) =>
                                          s['id']?.toString() == id &&
                                          s['selected'] == true)) {
                                    return false;
                                  }
                                  if (_controller.selectedCheeses
                                      .contains(id)) {
                                    return false;
                                  }
                                  return !_controller.selectedDressingCounts
                                          .containsKey(id) &&
                                      !_controller.selectedSauceCounts
                                          .containsKey(id) &&
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 14),
                                        child: Text(
                                          "Current Toppings",
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
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
                                                        _controller
                                                            .toggleIngredient(
                                                          ingId: ingId,
                                                          groupLabel: '',
                                                          groupsForUi:
                                                              _groupsForUi(),
                                                          isPizzaOrCalzone:
                                                              _isPizzaOrCalzone(),
                                                        );
                                                        _ingredientPortions
                                                            .remove(ingId);
                                                        _controller
                                                            .removeCheese(
                                                                ingId);
                                                        // Return to optional list (salad/dinner add-ons)
                                                        _controller
                                                            .selectedAddOns
                                                            .remove(ingId);
                                                        _controller.doubleAddOns
                                                            .remove(ingId);
                                                        _controller
                                                            .setPizzaSauceSelected(
                                                                ingId, false);
                                                      });
                                                    },
                                                    child: Text(loc.remove),
                                                  ),
                                                ],
                                              ),
                                              // Pizza/calzone only: portion + double.
                                              // Dinner/salad/standard: name + Remove only
                                              // (same card chrome, no extra modifiers).
                                              if (_isPizzaOrCalzone()) ...[
                                                SizedBox(height: 6),
                                                Row(
                                                  children: [
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
                                                                  ingId,
                                                                  portion),
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                    ],
                                                    Flexible(
                                                      fit: FlexFit.tight,
                                                      child: PortionPillToggle(
                                                        isDouble: _controller
                                                                    .doubleToppings[
                                                                ingId] ==
                                                            true,
                                                        onTap: () =>
                                                            _handleDoubleChanged(
                                                                ingId,
                                                                !(_controller
                                                                            .doubleToppings[
                                                                        ingId] ??
                                                                    false)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
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
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 14),
                                child: Text(
                                  "Additional Toppings",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
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
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .surface
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
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onSecondary
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                    ...ingredientIds
                                        .where((ingId) => !_controller
                                            .currentIngredients
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
                                                          _controller
                                                              .currentIngredients
                                                              .where((id) => ids
                                                                  .contains(id))
                                                              .length;
                                                      if (selectedInGroup >=
                                                          max) {
                                                        return;
                                                      }
                                                    }
                                                    _controller
                                                        .toggleIngredient(
                                                      ingId: ingId,
                                                      groupLabel:
                                                          (group['label'] ?? '')
                                                              .toString(),
                                                      groupsForUi:
                                                          _groupsForUi(),
                                                      isPizzaOrCalzone:
                                                          _isPizzaOrCalzone(),
                                                    );
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
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
                                final cheeseIds = _optionalIdsByType('cheeses');
                                if (cheeseIds.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final selectedCheeses = cheeseIds
                                    .where((id) => _controller.selectedCheeses
                                        .contains(id))
                                    .toList();
                                final summary = selectedCheeses.isEmpty
                                    ? "None"
                                    : selectedCheeses.map((id) {
                                        final meta = _ingredientMetadata[id];
                                        final isDouble =
                                            _controller.cheeseIsDouble[id] ==
                                                true;
                                        final portionName =
                                            (_controller.cheesePortions[id] ??
                                                    'whole')
                                                .toLowerCase();
                                        final portion = portionName == 'left'
                                            ? Portion.left
                                            : portionName == 'right'
                                                ? Portion.right
                                                : Portion.whole;
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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 14),
                                          child: Text(
                                            "Cheeses",
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
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
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant),
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
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                        children: cheeseIds.map((cheeseId) {
                                          final meta =
                                              _ingredientMetadata[cheeseId];
                                          final selected = _controller
                                              .selectedCheeses
                                              .contains(cheeseId);
                                          final portionName =
                                              (_controller.cheesePortions[
                                                          cheeseId] ??
                                                      'whole')
                                                  .toLowerCase();
                                          final portion = portionName == 'left'
                                              ? Portion.left
                                              : portionName == 'right'
                                                  ? Portion.right
                                                  : Portion.whole;
                                          final isDouble = _controller
                                                  .cheeseIsDouble[cheeseId] ==
                                              true;
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
                                                          onPressed: () {
                                                            setState(() {
                                                              _controller
                                                                  .removeCheese(
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
                                                              _controller
                                                                  .addCheese(
                                                                cheeseId,
                                                                max: max,
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
                                                                value: portion,
                                                                onChanged: (p) {
                                                                  setState(() {
                                                                    final name = p
                                                                        .toString()
                                                                        .split(
                                                                            '.')
                                                                        .last;
                                                                    _controller
                                                                        .setCheesePortion(
                                                                            cheeseId,
                                                                            name);
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
                                                                  isDouble,
                                                              onTap: () {
                                                                setState(() {
                                                                  _controller
                                                                      .toggleCheeseDouble(
                                                                          cheeseId);
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
                                  currentIngredients:
                                      _controller.currentIngredients,
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
                                    isDouble:
                                        _controller.doubleToppings[ingId] ==
                                            true,
                                    onTap: () {
                                      setState(() {
                                        final next =
                                            _controller.doubleToppings[ingId] !=
                                                true;
                                        _controller.setDoubleTopping(
                                          ingId,
                                          next,
                                          maxDoubles: MAX_DOUBLES,
                                        );
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
                                final sauceIds = _controller
                                    .pizzaSauceSelections
                                    .map((s) => s['id']?.toString() ?? '')
                                    .where((id) => id.isNotEmpty)
                                    .toList();
                                if (sauceIds.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final selectedSauces = _controller
                                    .pizzaSauceSelections
                                    .where((s) => s['selected'] == true)
                                    .toList();
                                final summary = selectedSauces.isEmpty
                                    ? "None"
                                    : selectedSauces.map((s) {
                                        final name = _ingredientMetadata[
                                                    s['id']?.toString()]
                                                ?.name ??
                                            s['name']?.toString() ??
                                            '';
                                        final portionStr =
                                            (s['portion'] as String? ?? 'whole')
                                                .toLowerCase();
                                        final showPortion = !_isCalzone() &&
                                            portionStr != 'whole';
                                        final portionLabel = portionStr ==
                                                'left'
                                            ? portionNames[Portion.left]
                                            : portionStr == 'right'
                                                ? portionNames[Portion.right]
                                                : portionNames[Portion.whole];
                                        return showPortion
                                            ? "$name ($portionLabel)"
                                            : name;
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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 14),
                                          child: Text(
                                            "Sauces",
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
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
                                        children: _controller
                                            .pizzaSauceSelections
                                            .map((sauce) {
                                          final id =
                                              sauce['id']?.toString() ?? '';
                                          final displayName =
                                              sauce['name']?.toString() ?? id;
                                          final meta = _ingredientMetadata[id];
                                          final selected =
                                              sauce['selected'] == true;
                                          final portionStr =
                                              (sauce['portion'] as String? ??
                                                      'whole')
                                                  .toLowerCase();
                                          final portion = portionStr == 'left'
                                              ? Portion.left
                                              : portionStr == 'right'
                                                  ? Portion.right
                                                  : Portion.whole;
                                          final amount =
                                              (sauce['amount'] as String? ??
                                                      'regular')
                                                  .toLowerCase();
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
                                                              displayName,
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
                                                            setState(() {
                                                              _controller
                                                                  .setPizzaSauceSelected(
                                                                id,
                                                                false,
                                                              );
                                                            });
                                                          },
                                                          child: Text('Remove'),
                                                        )
                                                      else
                                                        TextButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              _controller
                                                                  .setPizzaSauceSelected(
                                                                id,
                                                                true,
                                                                max: 2,
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
                                                                value: portion,
                                                                onChanged: (p) {
                                                                  setState(() {
                                                                    _controller
                                                                        .setPizzaSaucePortion(
                                                                      id,
                                                                      p
                                                                          .toString()
                                                                          .split(
                                                                              '.')
                                                                          .last,
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
                                                              isDouble: amount ==
                                                                      'extra' ||
                                                                  amount ==
                                                                      'double',
                                                              onTap: () {
                                                                setState(() {
                                                                  _controller
                                                                      .togglePizzaSauceAmountDouble(
                                                                    id,
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
                                      _controller.selectedDressingCounts,
                                  onCountChanged: (ingId, newCount) {
                                    setState(() {
                                      _controller.setDressingCount(
                                          ingId, newCount);
                                    });
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
                              ((widget.menuItem.optionalAddOns != null &&
                                      widget.menuItem.optionalAddOns!
                                          .isNotEmpty) ||
                                  // Dinner/salad: keep Optional Add-ons mounted so
                                  // removable included ingredients can be re-added
                                  // after Remove from Current Toppings.
                                  ((_isDinner() || _isSalad()) &&
                                      (widget.menuItem.includedIngredients
                                              ?.isNotEmpty ??
                                          false))))
                            OptionalAddOnsGroup(
                              menuItem: widget.menuItem,
                              theme: theme,
                              loc: loc,
                              ingredientMetadata: _ingredientMetadata,
                              selectedAddOns: _controller.selectedAddOns,
                              currentIngredientIds:
                                  _controller.currentIngredients,
                              doubleAddOns: _controller.doubleAddOns,
                              selectedSauceCounts:
                                  _controller.selectedSauceCounts,
                              usesDynamicToppingPricing:
                                  widget.menuItem.additionalToppingPrices !=
                                          null &&
                                      _selectedSize != null,
                              getToppingUpcharge: _getToppingUpcharge,
                              getIngredientUpcharge: _getIngredientUpcharge,
                              onToggleAddOn: (ingId, val) {
                                setState(() {
                                  _controller.toggleAddOn(
                                    ingId,
                                    val == true,
                                    addToCurrentIngredients:
                                        _isSalad() || _isDinner() || _isSub(),
                                  );
                                });
                              },
                              onChangeSauceCount: (ingId, delta) {
                                setState(() {
                                  final count =
                                      _controller.selectedSauceCounts[ingId] ??
                                          0;
                                  _controller.setSauceCount(
                                      ingId, count + delta);
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

                          // --- ORDER DETAILS: pizza (crust/cook/cut) or sub (cook only) ---
                          if (_isPizza() || _isSub())
                            Builder(
                              builder: (context) {
                                var orderDetailGroups =
                                    _radioGroups.where((group) {
                                  final label = (group['label'] as String?)
                                      ?.toLowerCase();
                                  final id =
                                      (group['id'] as String?)?.toLowerCase() ??
                                          '';
                                  if (_isSub()) {
                                    // Sub: cook only — never crust/cut
                                    return label == 'cook' || id == 'cook';
                                  }
                                  return label == 'crust' ||
                                      label == 'cook' ||
                                      label == 'cut' ||
                                      id == 'crust' ||
                                      id == 'cook' ||
                                      id == 'cut';
                                }).toList();

                                // Pizza: seed structural groups when stored groups omit them
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

                                // Sub: seed cook from sub template when group missing;
                                // if HQ cleared options → hide entire section.
                                if (_isSub()) {
                                  final hasCookOptions = orderDetailGroups.any(
                                    (g) => ((g['ingredientIds'] as List?)
                                            ?.isNotEmpty ??
                                        false),
                                  );
                                  if (!hasCookOptions) {
                                    final seed =
                                        shared.MenuProfileTemplates.seedGroups(
                                                shared.MenuProfile.sub)
                                            .where((g) =>
                                                g.id.toLowerCase() == 'cook' &&
                                                g.options.isNotEmpty)
                                            .toList();
                                    // Prefer stored empty (HQ off) over always re-seeding:
                                    // only seed when no cook group exists at all.
                                    final hasCookGroup = _radioGroups.any((g) {
                                      final label = (g['label'] as String?)
                                          ?.toLowerCase();
                                      final id =
                                          (g['id'] as String?)?.toLowerCase() ??
                                              '';
                                      return label == 'cook' || id == 'cook';
                                    });
                                    if (!hasCookGroup && seed.isNotEmpty) {
                                      orderDetailGroups = seed
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
                                        final label =
                                            (g['label'] as String?) ?? '';
                                        if (label.isEmpty) continue;
                                        if ((_radioSelections[label] ?? '')
                                            .isNotEmpty) {
                                          continue;
                                        }
                                        final ids =
                                            (g['ingredientIds'] as List? ?? [])
                                                .map((e) => e.toString())
                                                .toList();
                                        // Prefer Regular
                                        final regular = ids.firstWhere(
                                          (id) =>
                                              id.toLowerCase() ==
                                              'cook_regular',
                                          orElse: () =>
                                              ids.isNotEmpty ? ids.first : '',
                                        );
                                        if (regular.isNotEmpty) {
                                          _radioSelections[label] = regular;
                                        }
                                      }
                                    } else if (!hasCookOptions) {
                                      // HQ cleared options → do not show section
                                      return const SizedBox.shrink();
                                    }
                                  } else {
                                    // Ensure Regular default when nothing selected yet
                                    for (final g in orderDetailGroups) {
                                      final label =
                                          (g['label'] as String?) ?? '';
                                      if (label.isEmpty) continue;
                                      if ((_radioSelections[label] ?? '')
                                          .isNotEmpty) {
                                        continue;
                                      }
                                      final ids =
                                          (g['ingredientIds'] as List? ?? [])
                                              .map((e) => e.toString())
                                              .toList();
                                      final regular = ids.firstWhere(
                                        (id) =>
                                            id.toLowerCase() == 'cook_regular',
                                        orElse: () =>
                                            ids.isNotEmpty ? ids.first : '',
                                      );
                                      if (regular.isNotEmpty) {
                                        _radioSelections[label] = regular;
                                      }
                                    }
                                  }
                                }

                                if (orderDetailGroups.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                final isSub = _isSub();
                                final emptyTitle = isSub
                                    ? 'Choose how your sub is cooked — Regular or Crispy.'
                                    : 'Customize crust, cook, and cut.';
                                final subtitle = isSub
                                    ? 'Choose how your sub is cooked — Regular or Crispy.'
                                    : 'Tap to customize crust, cook, or cut.';

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
                                      return '${label.capitalize()}: ${meta?.name ?? labels[selected] ?? selected}';
                                    })
                                    .where((str) => str.isNotEmpty)
                                    .join(' | ');

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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 14),
                                          child: Text(
                                            'Order Details',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
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
                                              ? emptyTitle
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
                                            subtitle,
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
