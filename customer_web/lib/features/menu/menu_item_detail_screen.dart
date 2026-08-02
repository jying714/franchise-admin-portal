// customer_web/lib/features/menu/menu_item_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/sign_in_screen.dart';
import '../../widgets/branding_shell.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import '../cart/cart_screen.dart';

/// Phase 4a: detail + size + modifier group shells.
/// Cart write and auth gate land in Phase 5/6.
class MenuItemDetailScreen extends StatefulWidget {
  const MenuItemDetailScreen({super.key, required this.item});

  final shared.MenuItem item;

  @override
  State<MenuItemDetailScreen> createState() => _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends State<MenuItemDetailScreen> {
  late String? _selectedSize;
  int _qty = 1;

  /// groupId → selected option ids (multi where maxSelectable > 1).
  final Map<String, Set<String>> _selectedByGroup = {};

  /// ingredientId → typeId (from ingredient_metadata)
  Map<String, String> _ingredientTypeId = {};

  /// typeId → display name (from ingredient_types)
  Map<String, String> _typeLabels = {};

  bool _typesLoaded = false;
  String? _typesForFranchiseId;

  shared.MenuItem get item => widget.item;

  /// ingredientId → portion: 'whole' | 'left' | 'right'
  final Map<String, String> _portion = {};

  static const String _portionWhole = 'whole';
  static const String _portionLeft = 'left';
  static const String _portionRight = 'right';

  Future<void> _loadTypeMaps(String franchiseId) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    try {
      final metaSnap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_metadata')
          .get();
      final typeSnap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types')
          .get();

      final ingredientTypeId = <String, String>{};
      for (final doc in metaSnap.docs) {
        final d = doc.data();
        final typeId = (d['typeId'] ?? d['type'] ?? '').toString().trim();
        if (typeId.isEmpty) continue;
        ingredientTypeId[doc.id] = typeId;
        final altId = (d['ingredientId'] ?? d['id'] ?? '').toString().trim();
        if (altId.isNotEmpty) ingredientTypeId[altId] = typeId;
      }

      final typeLabels = <String, String>{};
      for (final doc in typeSnap.docs) {
        final d = doc.data();
        final name = (d['name'] ?? d['label'] ?? doc.id).toString().trim();
        typeLabels[doc.id] = name.isEmpty ? doc.id : name;
        final tid = (d['typeId'] ?? d['id'] ?? '').toString().trim();
        if (tid.isNotEmpty) typeLabels[tid] = name.isEmpty ? tid : name;
      }

      if (!mounted) return;
      setState(() {
        _ingredientTypeId = {..._ingredientTypeId, ...ingredientTypeId};
        _typeLabels = {..._typeLabels, ...typeLabels};
        _typesLoaded = true;
      });
    } catch (e) {
      debugPrint('[menu] type maps: $e');
      if (mounted) setState(() => _typesLoaded = true);
    }
  }

  List<String> _availableSauceIds() {
    final pool = _optionalIdsByType('sauces');
    if (pool.isEmpty) {
      for (final g in item.effectiveModifierGroups) {
        final gl = g.label.toLowerCase();
        final gid = g.id.toLowerCase();
        if (gl != 'sauces' &&
            gl != 'sauce' &&
            gid != 'sauces' &&
            gid != 'sauce') {
          continue;
        }
        for (final o in g.options) {
          final key =
              (o.ingredientId != null && o.ingredientId!.trim().isNotEmpty)
              ? o.ingredientId!.trim()
              : o.id.trim();
          if (key.isNotEmpty && !_selectedSauces.contains(key)) {
            pool.add(key);
          }
        }
      }
    }
    // Also typeId 'sauce' variants already covered by _optionalIdsByType('sauces');
    // merge 'sauce' singular if needed:
    for (final id in _optionalIdsByType('sauce')) {
      if (!_selectedSauces.contains(id) && !pool.contains(id)) pool.add(id);
    }
    return pool.where((id) => !_selectedSauces.contains(id)).toList();
  }

  String _getPortion(String id) => _portion[id] ?? _portionWhole;

  void _setPortion(String id, String value) {
    setState(() {
      if (value == _portionWhole) {
        _portion.remove(id);
      } else {
        _portion[id] = value;
      }
    });
  }

  bool _showsPortionControls() {
    // Pizza yes; calzone no left/right (mobile).
    return _isPizza() && !_isCalzone();
  }

  String _portionLabel(String id) {
    switch (_getPortion(id)) {
      case _portionLeft:
        return 'Left';
      case _portionRight:
        return 'Right';
      default:
        return 'Whole';
    }
  }

  void _addSauce(String id) {
    if (_selectedSauces.length >= _maxSauces) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Max $_maxSauces sauces')));
      return;
    }
    setState(() {
      _selectedSauces.add(id);
    });
  }

  void _removeSauce(String id) {
    setState(() {
      _selectedSauces.remove(id);
      _isDouble.remove(id);
      _portion.remove(id);
    });
  }

  void _seedTypesFromItem() {
    void ingest(List<Map<String, dynamic>>? list) {
      if (list == null) return;
      for (final e in list) {
        final typeId = (e['typeId'] ?? e['type'] ?? '').toString().trim();
        if (typeId.isEmpty) continue;
        final id = (e['ingredientId'] ?? e['id'] ?? '').toString().trim();
        if (id.isEmpty) continue;
        _ingredientTypeId[id] = typeId;
        _ingredientTypeId[id.toLowerCase()] = typeId;
        // addon_pepperoni style ids used on modifier options
        _ingredientTypeId['addon_$id'] = typeId;
      }
    }

    ingest(item.optionalAddOns);
    ingest(item.includedIngredients);

    for (final typeId in _ingredientTypeId.values.toSet()) {
      _typeLabels.putIfAbsent(typeId, () => _displayTypeName(typeId));
    }
  }

  String _displayTypeName(String typeId) {
    switch (typeId.toLowerCase()) {
      case 'meats':
      case 'meat':
        return 'Meats';
      case 'veggies':
      case 'veggie':
      case 'vegetables':
        return 'Veggies';
      case 'cheeses':
      case 'cheese':
        return 'Cheeses';
      case 'sauces':
      case 'sauce':
        return 'Sauces';
      case 'toppings':
      case 'topping':
        return 'Toppings';
      case 'proteins':
      case 'protein':
        return 'Proteins';
      default:
        return typeId
            .split(RegExp(r'[-_]'))
            .map(
              (w) => w.isEmpty
                  ? w
                  : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
            )
            .join(' ');
    }
  }

  // --- Profile helpers (mirror mobile; profile is source of truth) ---
  bool _isPizza() {
    final profile = item.effectiveMenuProfile.toLowerCase();
    return profile == shared.MenuProfile.pizza ||
        profile == shared.MenuProfile.calzone;
  }

  bool _isCalzone() {
    return item.effectiveMenuProfile.toLowerCase() ==
        shared.MenuProfile.calzone;
  }

  bool _isSub() {
    return item.effectiveMenuProfile.toLowerCase() == shared.MenuProfile.sub;
  }

  bool _isStructuralIdOrLabel(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    return v == 'crust' || v == 'cook' || v == 'cut';
  }

  /// Mobile-equivalent groupsForUi: effectiveModifierGroups + template seed for
  /// missing/empty structural groups on pizza/calzone (and cook on sub).
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
                : o.id.trim()): o.label.trim().isNotEmpty
                ? o.label.trim()
                : o.id.trim(),
      };
      return <String, dynamic>{
        'id': g.id,
        'label': g.label,
        'ingredientIds': optionIds,
        'optionLabels': optionLabels,
        'min': g.min,
        'max': g.max,
        if (g.maxFree != null) 'maxFree': g.maxFree,
        'selectMode': g.selectMode.firestoreValue,
      };
    }

    var groups = item.effectiveModifierGroups.map(groupToMap).toList();

    // Pizza / calzone: ensure Crust / Cook / Cut from template when missing or empty.
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
        final hasOptions =
            idx >= 0 &&
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

    // Sub: ensure cook when group is absent (HQ-cleared options stay empty → hide later).
    if (_isSub()) {
      final hasCook = groups.any(
        (g) =>
            (g['id'] ?? '').toString().toLowerCase() == 'cook' ||
            (g['label'] ?? '').toString().toLowerCase() == 'cook',
      );
      if (!hasCook) {
        final seed = shared.MenuProfileTemplates.seedGroups(
          shared.MenuProfile.sub,
        ).where((g) => g.id.toLowerCase() == 'cook').toList();
        if (seed.isNotEmpty) {
          groups.insert(0, groupToMap(seed.first));
        }
      }
    }

    return groups;
  }

  bool _wasIncludedIngredient(String ingId) {
    final raw = item.includedIngredients;
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

  bool _isPizzaDedicatedGroup(String id, String label) {
    final v = '${id.toLowerCase().trim()} ${label.toLowerCase().trim()}';
    return v.contains('meat') ||
        v.contains('veggie') ||
        v.contains('vegetable') ||
        v.contains('cheese') ||
        v.contains('sauce') ||
        v.contains('topping') ||
        v.contains('add-on') ||
        v.contains('addon') ||
        v.contains('add on') ||
        v.contains('optional');
  }

  static const int _maxCheeses = 2;

  List<String> _availableCheeseIds() {
    final pool = _optionalIdsByType('cheeses');
    // If optionalAddOns has no cheeses, fall back to non-structural group options labeled cheeses.
    if (pool.isEmpty) {
      for (final g in item.effectiveModifierGroups) {
        if (g.label.toLowerCase() == 'cheeses' ||
            g.id.toLowerCase() == 'cheeses') {
          for (final o in g.options) {
            final key =
                (o.ingredientId != null && o.ingredientId!.trim().isNotEmpty)
                ? o.ingredientId!.trim()
                : o.id.trim();
            if (key.isNotEmpty && !_selectedCheeses.contains(key)) {
              pool.add(key);
            }
          }
        }
      }
    }
    return pool.where((id) => !_selectedCheeses.contains(id)).toList();
  }

  /// Multiplier for half vs whole (left/right = 0.5).
  double _portionMultiplier(String id) {
    final p = _getPortion(id);
    if (p == 'left' || p == 'right') return 0.5;
    return 1.0;
  }

  String _portionSuffix(String id) {
    switch (_getPortion(id)) {
      case 'left':
        return ' (Left)';
      case 'right':
        return ' (Right)';
      default:
        return '';
    }
  }

  void _addCheese(String id) {
    if (_selectedCheeses.length >= _maxCheeses) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Max $_maxCheeses cheeses')));
      return;
    }
    setState(() {
      _selectedCheeses.add(id);
    });
  }

  void _removeCheese(String id) {
    setState(() {
      _selectedCheeses.remove(id);
      _isDouble.remove(id);
      _portion.remove(id);
    });
  }

  String _ingredientDisplayName(String id) {
    // Prefer name from includedIngredients / optionalAddOns.
    for (final list in [item.includedIngredients, item.optionalAddOns]) {
      if (list == null) continue;
      for (final e in list) {
        final eid = (e['ingredientId'] ?? e['id'] ?? '').toString().trim();
        if (eid == id) {
          final name = (e['name'] ?? '').toString().trim();
          if (name.isNotEmpty) return name;
        }
      }
    }
    // Fallback: strip common prefixes for display.
    if (id.startsWith('addon_')) return id.substring(6);
    return id;
  }

  bool _showsCurrentIngredients() {
    if (item.effectiveMenuProfile.toLowerCase() == shared.MenuProfile.wings) {
      return false;
    }
    if (_isPizza() || _isSub()) return true;
    final cat = item.category.toLowerCase();
    final catId = item.categoryId.toLowerCase();
    return cat.contains('salad') ||
        cat.contains('dinner') ||
        cat.contains('sub') ||
        catId.contains('salad') ||
        catId.contains('dinner');
  }

  /// Structural groups only (for Order Details section).
  List<Map<String, dynamic>> _structuralGroupsForUi() {
    return _groupsForUi().where((g) {
      final id = (g['id'] ?? '').toString().toLowerCase();
      final label = (g['label'] ?? '').toString().toLowerCase();
      if (_isSub()) {
        return id == 'cook' || label == 'cook';
      }
      return _isStructuralIdOrLabel(id) || _isStructuralIdOrLabel(label);
    }).toList();
  }

  /// optionalAddOns entries filtered by typeId (meats|veggies|…).
  List<Map<String, dynamic>> _optionalByType(String typeId) {
    final raw = item.optionalAddOns;
    if (raw == null || raw.isEmpty) return const [];
    final want = typeId.toLowerCase();
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final e in raw) {
      final tid = (e['typeId'] ?? e['type'] ?? '').toString().toLowerCase();
      if (tid != want) continue;
      final id = (e['ingredientId'] ?? e['id'] ?? '').toString().trim();
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      out.add(Map<String, dynamic>.from(e));
    }
    return out;
  }

  List<String> _optionalIdsByType(String typeId) {
    return _optionalByType(typeId)
        .map((e) => (e['ingredientId'] ?? e['id']).toString().trim())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  String _optionalLabel(String id, String typeId) {
    for (final e in _optionalByType(typeId)) {
      final eid = (e['ingredientId'] ?? e['id']).toString().trim();
      if (eid == id) {
        final name = (e['name'] ?? '').toString().trim();
        if (name.isNotEmpty) return name;
      }
    }
    return _ingredientDisplayName(id);
  }

  int get _doublesCount => _isDouble.values.where((v) => v == true).length;

  void _setDouble(String id, bool value) {
    if (value && !_isDouble.containsKey(id) && _doublesCount >= _maxDoubles) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Max $_maxDoubles doubles')));
      return;
    }
    if (value && _isDouble[id] == true) return;
    setState(() {
      if (value) {
        _isDouble[id] = true;
      } else {
        _isDouble.remove(id);
      }
    });
  }

  bool _getDouble(String id) => _isDouble[id] == true;

  /// Units charged for this id under mobile double rules.
  int _chargeUnits(String id) {
    final doubled = _getDouble(id);
    if (_isOriginallyIncluded(id)) {
      return doubled ? 1 : 0;
    }
    return doubled ? 2 : 1;
  }

  /// Available extra IDs for a type = optional pool minus anything currently on the item.
  List<String> _availableIdsByType(String typeId) {
    return _optionalIdsByType(
      typeId,
    ).where((id) => !_currentIngredients.contains(id)).toList();
  }

  double _toppingUnitPrice() {
    return _selectedSizeData?.toppingPrice ?? 0.0;
  }

  /// True if this id was on the item when the screen opened (or in includedIngredients).
  bool _isOriginallyIncluded(String id) {
    return _originalIncludedIds.contains(id);
  }

  /// Structural radio selections: group label → selected option id.
  final Map<String, String?> _structuralSelections = {};

  /// Food ingredients currently on the item (from included; user may remove).
  late Set<String> _currentIngredients;

  /// Snapshot of included ingredient IDs at open (for free re-add pricing).
  late Set<String> _originalIncludedIds;

  late Set<String> _selectedCheeses;

  late Set<String> _selectedSauces;
  static const int _maxSauces = 2;

  /// ingredientId → isDouble (Current toppings, cheeses, sauces).
  final Map<String, bool> _isDouble = {};

  static const int _maxDoubles = 4;

  @override
  void initState() {
    super.initState();
    final sizes = item.sizes;
    _seedTypesFromItem();
    if (sizes != null && sizes.isNotEmpty) {
      _selectedSize = sizes.first.label;
    } else if (item.sizePrices != null && item.sizePrices!.isNotEmpty) {
      _selectedSize = item.sizePrices!.keys.first;
    } else {
      _selectedSize = null;
    }

    // Non-structural groups (existing path).
    for (final g in item.effectiveModifierGroups) {
      if (_isStructuralIdOrLabel(g.id) || _isStructuralIdOrLabel(g.label)) {
        continue;
      }
      final defaults = <String>{};
      for (final o in g.options) {
        if (o.defaultSelected) defaults.add(o.id);
      }
      if (defaults.isNotEmpty) {
        _selectedByGroup[g.id] = defaults;
      }
    }

    // Structural defaults from seeded groups (mobile parity).
    for (final g in _structuralGroupsForUi()) {
      final label = (g['label'] ?? '').toString();
      if (label.isEmpty) continue;
      final ids = (g['ingredientIds'] as List? ?? [])
          .map((e) => e.toString())
          .where((id) => id.isNotEmpty)
          .toList();
      if (ids.isEmpty) continue;

      // Prefer defaultSelected from original ModifierGroup when present.
      String? chosen;
      final stored = item.modifierGroups?.where(
        (mg) =>
            mg.label.toLowerCase() == label.toLowerCase() ||
            mg.id.toLowerCase() == (g['id'] ?? '').toString().toLowerCase(),
      );
      if (stored != null && stored.isNotEmpty) {
        final def = stored.first.options.where((o) => o.defaultSelected);
        if (def.isNotEmpty) {
          final o = def.first;
          chosen = (o.ingredientId != null && o.ingredientId!.trim().isNotEmpty)
              ? o.ingredientId!.trim()
              : o.id.trim();
        }
      }
      // Sub / common default: Regular cook.
      if ((chosen == null || chosen.isEmpty) &&
          (label.toLowerCase() == 'cook')) {
        chosen = ids.firstWhere(
          (id) => id.toLowerCase() == 'cook_regular',
          orElse: () => ids.first,
        );
      }
      chosen ??= ids.first;
      _structuralSelections[label] = chosen;
    }

    // Current toppings from includedIngredients (mobile parity).
    _currentIngredients = {};
    _originalIncludedIds = {};
    // Also capture cheeses/sauces that were stripped from Current so re-add stays free later.
    if (item.includedIngredients != null) {
      for (final ing in item.includedIngredients!) {
        final id = (ing['ingredientId'] ?? ing['id'])?.toString().trim() ?? '';
        if (id.isNotEmpty) _originalIncludedIds.add(id);
      }
    }
    if (item.includedIngredients != null) {
      for (final ing in item.includedIngredients!) {
        final id = (ing['ingredientId'] ?? ing['id'])?.toString().trim() ?? '';
        if (id.isEmpty) continue;
        _currentIngredients.add(id);
      }
    }
    // Cheeses: defaults from included + optional pool of type cheeses.
    final cheesePool = _optionalIdsByType('cheeses');
    _selectedCheeses = {};
    if (item.includedIngredients != null) {
      for (final ing in item.includedIngredients!) {
        final id = (ing['ingredientId'] ?? ing['id'])?.toString().trim() ?? '';
        if (id.isEmpty) continue;
        final t = (ing['typeId'] ?? ing['type'] ?? '').toString().toLowerCase();
        if (t == 'cheeses' || t == 'cheese' || cheesePool.contains(id)) {
          _selectedCheeses.add(id);
          _originalIncludedIds.add(id);
        }
      }
    }
    // Also any defaultSelected on a cheeses modifier group.
    for (final g in item.effectiveModifierGroups) {
      final gl = g.label.toLowerCase();
      final gid = g.id.toLowerCase();
      if (gl != 'cheeses' && gid != 'cheeses') continue;
      for (final o in g.options) {
        if (!o.defaultSelected) continue;
        final key =
            (o.ingredientId != null && o.ingredientId!.trim().isNotEmpty)
            ? o.ingredientId!.trim()
            : o.id.trim();
        if (key.isNotEmpty) {
          _selectedCheeses.add(key);
          _originalIncludedIds.add(key);
        }
      }
    }

    // Sauces: defaults from included + optional pool of type sauces (stay in Sauces section).
    final saucePool = _optionalIdsByType('sauces');
    _selectedSauces = {};
    if (item.includedIngredients != null) {
      for (final ing in item.includedIngredients!) {
        final id = (ing['ingredientId'] ?? ing['id'])?.toString().trim() ?? '';
        if (id.isEmpty) continue;
        final t = (ing['typeId'] ?? ing['type'] ?? '').toString().toLowerCase();
        if (t == 'sauces' || t == 'sauce' || saucePool.contains(id)) {
          _selectedSauces.add(id);
          _originalIncludedIds.add(id);
        }
      }
    }
    for (final g in item.effectiveModifierGroups) {
      final gl = g.label.toLowerCase();
      final gid = g.id.toLowerCase();
      if (gl != 'sauces' &&
          gl != 'sauce' &&
          gid != 'sauces' &&
          gid != 'sauce') {
        continue;
      }
      for (final o in g.options) {
        if (!o.defaultSelected) continue;
        final key =
            (o.ingredientId != null && o.ingredientId!.trim().isNotEmpty)
            ? o.ingredientId!.trim()
            : o.id.trim();
        if (key.isNotEmpty) {
          _selectedSauces.add(key);
          _originalIncludedIds.add(key);
        }
      }
    }

    // Pizza/calzone: cheeses & sauces live in their own sections later — not in Current.
    if (_isPizza()) {
      _currentIngredients.removeWhere((id) {
        final typeId =
            (_ingredientTypeId[id] ?? _ingredientTypeId[id.toLowerCase()] ?? '')
                .toLowerCase();
        if (typeId == 'cheeses' ||
            typeId == 'cheese' ||
            typeId == 'sauces' ||
            typeId == 'sauce') {
          return true;
        }
        // Fallback: inspect the included map entry itself.
        final entry = item.includedIngredients?.firstWhere(
          (e) => (e['ingredientId'] ?? e['id'])?.toString().trim() == id,
          orElse: () => <String, dynamic>{},
        );
        final t = (entry?['typeId'] ?? entry?['type'] ?? '')
            .toString()
            .toLowerCase();
        return t == 'cheeses' || t == 'cheese' || t == 'sauces' || t == 'sauce';
      });
    }
  }

  /// Resolve upchargeBySize with exact, then case-insensitive key match.
  shared.SizeData? get _selectedSizeData {
    final sizes = item.sizes;
    if (sizes == null || sizes.isEmpty || _selectedSize == null) return null;
    for (final s in sizes) {
      if (s.label == _selectedSize ||
          s.label.toLowerCase() == _selectedSize!.toLowerCase()) {
        return s;
      }
    }
    return null;
  }

  /// Per-option delta: explicit option upcharge first; else size.toppingPrice.
  double _optionDelta(shared.ModifierOption opt) {
    final bySize = opt.upchargeBySize;
    if (bySize != null && bySize.isNotEmpty && _selectedSize != null) {
      final exact = bySize[_selectedSize];
      if (exact != null) return exact;
      final lower = _selectedSize!.toLowerCase();
      for (final e in bySize.entries) {
        if (e.key.toLowerCase() == lower) return e.value;
      }
    }
    if (opt.upcharge != null && opt.upcharge != 0) {
      return opt.upcharge!;
    }
    // Doughboys pattern: add-ons priced via SizeData.toppingPrice
    return _selectedSizeData?.toppingPrice ?? 0.0;
  }

  double get _baseSizePrice {
    final sizeData = _selectedSizeData;
    if (sizeData != null) return sizeData.basePrice;

    if (_selectedSize != null) {
      final sp = item.sizePrices;
      if (sp != null && sp.isNotEmpty) {
        if (sp.containsKey(_selectedSize)) return sp[_selectedSize]!;
        final lower = _selectedSize!.toLowerCase();
        for (final e in sp.entries) {
          if (e.key.toLowerCase() == lower) return e.value;
        }
      }
    }
    return item.price;
  }

  String _typeSectionLabel(shared.ModifierOption opt) {
    final ing = (opt.ingredientId ?? '').trim();
    final key = ing.isNotEmpty ? ing : opt.id.trim();

    final typeId =
        _ingredientTypeId[key] ?? _ingredientTypeId[key.toLowerCase()] ?? '';

    if (typeId.isNotEmpty) {
      final label =
          _typeLabels[typeId] ?? _typeLabels[typeId.toLowerCase()] ?? typeId;
      // Title-case slug if needed
      if (label == typeId && typeId.contains('-')) {
        return typeId
            .split(RegExp(r'[-_]'))
            .map(
              (w) => w.isEmpty
                  ? w
                  : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
            )
            .join(' ');
      }
      // Normalize common ids to display names if type doc missing name
      switch (typeId.toLowerCase()) {
        case 'meats':
        case 'meat':
          return 'Meats';
        case 'veggies':
        case 'veggie':
        case 'vegetables':
          return 'Veggies';
        case 'cheeses':
        case 'cheese':
          return 'Cheeses';
        case 'toppings':
        case 'topping':
          return 'Toppings';
        case 'proteins':
        case 'protein':
          return 'Proteins';
        default:
          return label;
      }
    }

    // Label-only structural options (cook/crust) — no section spam
    if (opt.isLabelOnly) return 'Options';
    return 'Other';
  }

  bool _isStructuralGroup(shared.ModifierGroup group) {
    final id = group.id.toLowerCase().trim();
    final label = group.label.toLowerCase().trim();
    const keys = <String>[
      'cook',
      'cut',
      'crust',
      'temp',
      'temperature',
      'doneness',
      'size',
      'sauce', // single sauce pick often structural for pizza
    ];
    for (final k in keys) {
      if (id == k ||
          id.startsWith('${k}_') ||
          id.endsWith('_$k') ||
          label == k ||
          label.startsWith('$k ') ||
          label.endsWith(' $k')) {
        return true;
      }
    }
    return false;
  }

  /// Section only when multi-select AND ≥2 options map to real ingredient types.
  bool _shouldSectionGroup(shared.ModifierGroup group) {
    if (_isStructuralGroup(group)) return false;
    if (group.selectMode == shared.ModifierSelectMode.single) return false;
    if (group.max <= 1) return false;

    final resolvedTypeLabels = <String>{};
    for (final o in group.options) {
      final ing = (o.ingredientId ?? '').trim();
      final key = ing.isNotEmpty ? ing : o.id.trim();
      if (key.isEmpty) continue;

      final typeId =
          _ingredientTypeId[key] ?? _ingredientTypeId[key.toLowerCase()];
      if (typeId == null || typeId.isEmpty) continue;

      resolvedTypeLabels.add(_typeSectionLabel(o));
    }
    return resolvedTypeLabels.length >= 2;
  }

  Widget _buildGroupOptions(BuildContext context, shared.ModifierGroup group) {
    final useSections = _shouldSectionGroup(group);

    FilterChip chipFor(shared.ModifierOption opt) {
      final delta = _optionDelta(opt);
      return FilterChip(
        label: Text(
          delta != 0
              ? '${opt.label} (+\$${delta.toStringAsFixed(2)})'
              : opt.label,
        ),
        selected: _selectedByGroup[group.id]?.contains(opt.id) ?? false,
        onSelected: (_) => _toggleOption(group, opt.id),
      );
    }

    if (!useSections) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final opt in group.options) chipFor(opt)],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in _optionsByType(group.options)) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              section.key,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final opt in section.value) chipFor(opt)],
          ),
        ],
      ],
    );
  }

  /// Stable display order for known sections; unknown labels sort after.
  int _sectionSortKey(String label) {
    const order = [
      'Meats',
      'Veggies',
      'Cheeses',
      'Proteins',
      'Sauces',
      'Toppings',
      'Options',
      'Other',
    ];
    final i = order.indexWhere((o) => o.toLowerCase() == label.toLowerCase());
    return i < 0 ? 100 : i;
  }

  List<MapEntry<String, List<shared.ModifierOption>>> _optionsByType(
    List<shared.ModifierOption> options,
  ) {
    final map = <String, List<shared.ModifierOption>>{};
    for (final o in options) {
      final label = _typeSectionLabel(o);
      map.putIfAbsent(label, () => []).add(o);
    }
    final entries = map.entries.toList()
      ..sort((a, b) {
        final c = _sectionSortKey(a.key).compareTo(_sectionSortKey(b.key));
        if (c != 0) return c;
        return a.key.compareTo(b.key);
      });
    return entries;
  }

  double get _unitPrice {
    var total = _baseSizePrice;

    // Charge only for ingredients currently on the item that were NOT originally included.
    final upcharge = _toppingUnitPrice();
    if (upcharge > 0) {
      for (final id in _currentIngredients) {
        final lower = id.toLowerCase();
        if (lower.startsWith('crust_') ||
            lower.startsWith('cook_') ||
            lower.startsWith('cut_')) {
          continue;
        }
        total += upcharge * _chargeUnits(id) * _portionMultiplier(id);
      }
      for (final id in _selectedCheeses) {
        total += upcharge * _chargeUnits(id) * _portionMultiplier(id);
      }
      for (final id in _selectedSauces) {
        total += upcharge * _chargeUnits(id) * _portionMultiplier(id);
      }
    }

    // Non-structural modifier groups that are not already represented in Current.
    for (final g in item.effectiveModifierGroups) {
      if (_isStructuralIdOrLabel(g.id) || _isStructuralIdOrLabel(g.label)) {
        continue;
      }
      final selectedIds = _selectedByGroup[g.id] ?? const <String>{};
      if (selectedIds.isEmpty) continue;

      final selectedOpts = g.options
          .where((o) => selectedIds.contains(o.id))
          .toList();
      final freeCount = (g.maxFree != null && g.maxFree! > 0) ? g.maxFree! : 0;
      selectedOpts.sort((a, b) => _optionDelta(b).compareTo(_optionDelta(a)));

      var paidIndex = 0;
      for (final opt in selectedOpts) {
        final key =
            (opt.ingredientId != null && opt.ingredientId!.trim().isNotEmpty)
            ? opt.ingredientId!.trim()
            : opt.id.trim();
        // Already handled via Current path.
        if (_currentIngredients.contains(key) ||
            _currentIngredients.contains(opt.id)) {
          continue;
        }
        if (_isOriginallyIncluded(key) || _isOriginallyIncluded(opt.id)) {
          continue;
        }
        if (paidIndex < freeCount) {
          paidIndex++;
          continue;
        }
        total += _optionDelta(opt);
        paidIndex++;
      }
    }
    return total;
  }

  String? _validateSelections() {
    // Structural required when min >= 1.
    for (final g in _structuralGroupsForUi()) {
      final label = (g['label'] ?? '').toString();
      final min = (g['min'] as int?) ?? 0;
      final selected = _structuralSelections[label];
      if (min > 0 && (selected == null || selected.isEmpty)) {
        return 'Select ${label.toLowerCase()}';
      }
    }
    for (final g in item.effectiveModifierGroups) {
      if (_isStructuralIdOrLabel(g.id) || _isStructuralIdOrLabel(g.label)) {
        continue;
      }
      final n = _selectedByGroup[g.id]?.length ?? 0;
      if (g.min > 0 && n < g.min) {
        return 'Select at least ${g.min} for ${g.label}';
      }
    }
    return null;
  }

  List<shared.Customization> _buildCustomizations() {
    final list = <shared.Customization>[];

    if (_selectedSize != null && _selectedSize!.isNotEmpty) {
      list.add(
        shared.Customization(
          id: 'size_$_selectedSize',
          name: _selectedSize!,
          isGroup: false,
          price: 0,
          group: 'Size',
          selected: true,
        ),
      );
    }

    // Structural first (price always 0).
    for (final g in _structuralGroupsForUi()) {
      final label = (g['label'] ?? '').toString();
      final selectedId = _structuralSelections[label];
      if (selectedId == null || selectedId.isEmpty) continue;
      final labels =
          (g['optionLabels'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          const <String, String>{};
      final name = labels[selectedId] ?? selectedId;
      list.add(
        shared.Customization(
          id: selectedId,
          name: name,
          isGroup: false,
          price: 0,
          group: label,
          selected: true,
        ),
      );
    }

    // Remaining current ingredients (food only).
    final unitPrice = _toppingUnitPrice();
    for (final id in _currentIngredients) {
      final lower = id.toLowerCase();
      if (lower.startsWith('crust_') ||
          lower.startsWith('cook_') ||
          lower.startsWith('cut_')) {
        continue;
      }
      final units = _chargeUnits(id);
      final mult = _portionMultiplier(id);
      final display = _ingredientDisplayName(id);
      final nameParts = <String>[display];
      if (_getDouble(id)) nameParts.add('Double');
      final p = _getPortion(id);
      if (p == 'left') nameParts.add('Left');
      if (p == 'right') nameParts.add('Right');
      list.add(
        shared.Customization(
          id: id,
          name: nameParts.length == 1
              ? display
              : '${nameParts.first} (${nameParts.skip(1).join(', ')})',
          isGroup: false,
          price: unitPrice * units * mult,
          group: 'Current',
          selected: true,
          isDefault: _wasIncludedIngredient(id),
        ),
      );
    }

    // Selected cheeses.
    for (final id in _selectedCheeses) {
      final units = _chargeUnits(id);
      final mult = _portionMultiplier(id);
      final display = _optionalLabel(id, 'cheeses');
      final nameParts = <String>[display];
      if (_getDouble(id)) nameParts.add('Double');
      final p = _getPortion(id);
      if (p == 'left') nameParts.add('Left');
      if (p == 'right') nameParts.add('Right');
      list.add(
        shared.Customization(
          id: id,
          name: nameParts.length == 1
              ? display
              : '${nameParts.first} (${nameParts.skip(1).join(', ')})',
          isGroup: false,
          price: unitPrice * units * mult,
          group: 'Cheeses',
          selected: true,
          isDefault: _isOriginallyIncluded(id),
        ),
      );
    }

    // Selected sauces.
    for (final id in _selectedSauces) {
      final units = _chargeUnits(id);
      final mult = _portionMultiplier(id);
      final display = _optionalLabel(id, 'sauces');
      final nameParts = <String>[display];
      if (_getDouble(id)) nameParts.add('Double');
      final p = _getPortion(id);
      if (p == 'left') nameParts.add('Left');
      if (p == 'right') nameParts.add('Right');
      list.add(
        shared.Customization(
          id: id,
          name: nameParts.length == 1
              ? display
              : '${nameParts.first} (${nameParts.skip(1).join(', ')})',
          isGroup: false,
          price: unitPrice * units * mult,
          group: 'Sauces',
          selected: true,
          isDefault: _isOriginallyIncluded(id),
        ),
      );
    }

    // Non-structural modifier groups (extras the user added via chips).
    for (final g in item.effectiveModifierGroups) {
      if (_isStructuralIdOrLabel(g.id) || _isStructuralIdOrLabel(g.label)) {
        continue;
      }
      final selected = _selectedByGroup[g.id] ?? const <String>{};
      for (final opt in g.options) {
        if (!selected.contains(opt.id)) continue;
        final key =
            (opt.ingredientId != null && opt.ingredientId!.trim().isNotEmpty)
            ? opt.ingredientId!.trim()
            : opt.id.trim();
        if (_currentIngredients.contains(key) ||
            _currentIngredients.contains(opt.id) ||
            _selectedCheeses.contains(key) ||
            _selectedCheeses.contains(opt.id) ||
            _selectedSauces.contains(key) ||
            _selectedSauces.contains(opt.id)) {
          continue;
        }
        final delta = _optionDelta(opt);
        list.add(
          shared.Customization(
            id: opt.id,
            ingredientId: opt.ingredientId,
            name: opt.label,
            isGroup: false,
            price: delta,
            group: g.label,
            selected: true,
            isDefault: opt.defaultSelected,
          ),
        );
      }
    }
    return list;
  }

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    final fs = Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseId = fp.currentFranchiseId;
    if (!fp.hasValidFranchise) return;

    final validationError = _validateSelections();
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    final customizations = _buildCustomizations();
    final unit = _unitPrice;

    try {
      await fs.addToCart(
        userId: user.uid,
        franchiseId: franchiseId,
        menuItem: item,
        customizations: customizations,
        quantity: _qty,
        price: unit,
        specialInstructions: null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${item.name} × $_qty'),
          action: SnackBarAction(
            label: 'View cart',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CartScreen()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add to cart: $e')));
    }
  }

  double get _linePreview => _unitPrice * _qty;

  List<String> get _sizeLabels {
    if (item.sizes != null && item.sizes!.isNotEmpty) {
      return item.sizes!.map((s) => s.label).toList();
    }
    if (item.sizePrices != null && item.sizePrices!.isNotEmpty) {
      return item.sizePrices!.keys.toList();
    }
    return const [];
  }

  void _toggleOption(shared.ModifierGroup group, String optionId) {
    final current = Set<String>.from(_selectedByGroup[group.id] ?? {});
    final max = group.max < 1 ? 1 : group.max;
    final single =
        group.selectMode == shared.ModifierSelectMode.single || max <= 1;

    if (current.contains(optionId)) {
      current.remove(optionId);
    } else {
      if (single) {
        current
          ..clear()
          ..add(optionId);
      } else if (current.length < max) {
        current.add(optionId);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Max $max for ${group.label}')));
        return;
      }
    }
    setState(() => _selectedByGroup[group.id] = current);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sizes = _sizeLabels;

    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    final franchiseId = fp.currentFranchiseId;
    if (_typesForFranchiseId != franchiseId) {
      _typesForFranchiseId = franchiseId;
      _typesLoaded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTypeMaps(franchiseId);
      });
    }

    return BrandingShell(
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (item.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: const Icon(Icons.restaurant, size: 48),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.description),
          ],
          if (item.allergens.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Allergens: ${item.allergens.join(', ')}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Profile: ${item.effectiveMenuProfile}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (sizes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Size', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in sizes)
                  ChoiceChip(
                    label: Text(label),
                    selected: _selectedSize == label,
                    onSelected: (_) => setState(() => _selectedSize = label),
                  ),
              ],
            ),
          ],

          // --- Current Toppings (included; removable) ---
          if (_showsCurrentIngredients()) ...[
            const SizedBox(height: 24),
            Text(
              'Current Toppings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_currentIngredients.isEmpty)
              Text(
                'None — defaults appear here when set on the item. Add extras below.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ..._currentIngredients.map((id) {
                final doubled = _getDouble(id);
                final portion = _getPortion(id);
                final display = _ingredientDisplayName(id);
                final titleBits = <String>[display];
                if (doubled) titleBits.add('Double');
                if (portion == 'left') titleBits.add('Left');
                if (portion == 'right') titleBits.add('Right');
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                titleBits.length == 1
                                    ? display
                                    : '${titleBits.first} (${titleBits.skip(1).join(', ')})',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _setDouble(id, !doubled),
                              child: Text(doubled ? 'Single' : 'Double'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: scheme.error,
                              ),
                              onPressed: () {
                                setState(() {
                                  _currentIngredients.remove(id);
                                  _isDouble.remove(id);
                                  _portion.remove(id);
                                });
                              },
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                        if (_isPizza()) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              ChoiceChip(
                                label: const Text('Left'),
                                selected: portion == 'left',
                                onSelected: (_) => _setPortion(id, 'left'),
                              ),
                              ChoiceChip(
                                label: const Text('Whole'),
                                selected: portion == 'whole',
                                onSelected: (_) => _setPortion(id, 'whole'),
                              ),
                              ChoiceChip(
                                label: const Text('Right'),
                                selected: portion == 'right',
                                onSelected: (_) => _setPortion(id, 'right'),
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

          // --- Additional Toppings (optionalAddOns by type, minus Current) ---
          if (_isPizza()) ...[
            Builder(
              builder: (context) {
                final meatIds = _availableIdsByType('meats');
                final vegIds = _availableIdsByType('veggies');
                if (meatIds.isEmpty && vegIds.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Additional Toppings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to add. Added items move to Current Toppings.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (meatIds.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Meats',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final id in meatIds)
                            ActionChip(
                              label: Text(() {
                                final price = _toppingUnitPrice();
                                final name = _optionalLabel(id, 'meats');
                                if (price > 0) {
                                  return '$name (+\$${price.toStringAsFixed(2)})';
                                }
                                return name;
                              }()),
                              onPressed: () {
                                setState(() {
                                  _currentIngredients.add(id);
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                    if (vegIds.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Veggies',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final id in vegIds)
                            ActionChip(
                              label: Text(() {
                                final price = _toppingUnitPrice();
                                final name = _optionalLabel(id, 'veggies');
                                if (price > 0) {
                                  return '$name (+\$${price.toStringAsFixed(2)})';
                                }
                                return name;
                              }()),
                              onPressed: () {
                                setState(() {
                                  _currentIngredients.add(id);
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],

          // --- Cheeses (max 2; side-by-side available chips) ---
          if (_isPizza()) ...[
            Builder(
              builder: (context) {
                final available = _availableCheeseIds();
                final selected = _selectedCheeses.toList();
                if (selected.isEmpty && available.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Cheeses',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Up to $_maxCheeses. Selected cheeses are free if they came on the item.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (selected.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Selected',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final id in selected) ...[
                            InputChip(
                              label: Text(() {
                                final bits = <String>[
                                  _optionalLabel(id, 'cheeses'),
                                ];
                                if (_getDouble(id)) bits.add('Double');
                                final p = _getPortion(id);
                                if (p == 'left') bits.add('Left');
                                if (p == 'right') bits.add('Right');
                                return bits.length == 1
                                    ? bits.first
                                    : '${bits.first} (${bits.skip(1).join(', ')})';
                              }()),
                              onPressed: () => _setDouble(id, !_getDouble(id)),
                              onDeleted: () => _removeCheese(id),
                              deleteIconColor: scheme.error,
                            ),
                            if (_isPizza())
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Wrap(
                                  spacing: 4,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('L'),
                                      selected: _getPortion(id) == 'left',
                                      onSelected: (_) =>
                                          _setPortion(id, 'left'),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    ChoiceChip(
                                      label: const Text('W'),
                                      selected: _getPortion(id) == 'whole',
                                      onSelected: (_) =>
                                          _setPortion(id, 'whole'),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    ChoiceChip(
                                      label: const Text('R'),
                                      selected: _getPortion(id) == 'right',
                                      onSelected: (_) =>
                                          _setPortion(id, 'right'),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ],
                    if (available.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Available',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final id in available)
                            ActionChip(
                              label: Text(() {
                                final price = _toppingUnitPrice();
                                final name = _optionalLabel(id, 'cheeses');
                                final free = _isOriginallyIncluded(id);
                                if (free || price <= 0) return name;
                                return '$name (+\$${price.toStringAsFixed(2)})';
                              }()),
                              onPressed: () => _addCheese(id),
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],

          // --- Sauces (max 2; own section; not in Current / not in Add-ons) ---
          if (_isPizza()) ...[
            Builder(
              builder: (context) {
                final available = _availableSauceIds();
                final selected = _selectedSauces.toList();
                if (selected.isEmpty && available.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Sauces',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Up to $_maxSauces. Included sauces stay selected here (not under Current Toppings).',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (selected.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Selected',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final id in selected) ...[
                            InputChip(
                              label: Text(() {
                                final bits = <String>[
                                  _optionalLabel(id, 'sauces'),
                                ];
                                if (_getDouble(id)) bits.add('Double');
                                final p = _getPortion(id);
                                if (p == 'left') bits.add('Left');
                                if (p == 'right') bits.add('Right');
                                return bits.length == 1
                                    ? bits.first
                                    : '${bits.first} (${bits.skip(1).join(', ')})';
                              }()),
                              onPressed: () => _setDouble(id, !_getDouble(id)),
                              onDeleted: () => _removeSauce(id),
                              deleteIconColor: scheme.error,
                            ),
                            if (_isPizza())
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Wrap(
                                  spacing: 4,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('L'),
                                      selected: _getPortion(id) == 'left',
                                      onSelected: (_) =>
                                          _setPortion(id, 'left'),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    ChoiceChip(
                                      label: const Text('W'),
                                      selected: _getPortion(id) == 'whole',
                                      onSelected: (_) =>
                                          _setPortion(id, 'whole'),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    ChoiceChip(
                                      label: const Text('R'),
                                      selected: _getPortion(id) == 'right',
                                      onSelected: (_) =>
                                          _setPortion(id, 'right'),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ],
                    if (available.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Available',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final id in available)
                            ActionChip(
                              label: Text(() {
                                final price = _toppingUnitPrice();
                                final name = _optionalLabel(id, 'sauces');
                                final free = _isOriginallyIncluded(id);
                                if (free || price <= 0) return name;
                                return '$name (+\$${price.toStringAsFixed(2)})';
                              }()),
                              onPressed: () => _addSauce(id),
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],

          // --- Order Details: Crust / Cook / Cut (or Cook only for sub) ---
          if (_structuralGroupsForUi().isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Order Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _isSub()
                  ? 'Choose how your sub is cooked.'
                  : 'Crust, cook, and cut.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            for (final g in _structuralGroupsForUi()) ...[
              Text(
                (g['label'] ?? '').toString(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Builder(
                builder: (context) {
                  final label = (g['label'] ?? '').toString();
                  final ids = (g['ingredientIds'] as List? ?? [])
                      .map((e) => e.toString())
                      .where((id) => id.isNotEmpty)
                      .toList();
                  final labels =
                      (g['optionLabels'] as Map?)?.map(
                        (k, v) => MapEntry(k.toString(), v.toString()),
                      ) ??
                      const <String, String>{};
                  final selected = _structuralSelections[label];
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final id in ids)
                        ChoiceChip(
                          label: Text(labels[id] ?? id),
                          selected: selected == id,
                          onSelected: (_) {
                            setState(() {
                              _structuralSelections[label] = id;
                            });
                          },
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ],

          // Non-structural modifier groups only.
          // Pizza: skip groups handled by Current / Additional / Cheeses / Sauces sections.
          for (final group in item.effectiveModifierGroups) ...[
            if (_isStructuralIdOrLabel(group.id) ||
                _isStructuralIdOrLabel(group.label))
              const SizedBox.shrink()
            else if (_isPizza() &&
                _isPizzaDedicatedGroup(group.id, group.label))
              const SizedBox.shrink()
            else ...[
              const SizedBox(height: 20),
              Text(group.label, style: Theme.of(context).textTheme.titleMedium),
              Text(
                [
                  if (group.min > 0) 'min ${group.min}',
                  'max ${group.max}',
                  if (group.maxFree != null) 'max free ${group.maxFree}',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final opt in group.options)
                    FilterChip(
                      label: Text(() {
                        final delta = _optionDelta(opt);
                        if (delta != 0) {
                          return '${opt.label} (+\$${delta.toStringAsFixed(2)})';
                        }
                        return opt.label;
                      }()),
                      selected:
                          _selectedByGroup[group.id]?.contains(opt.id) ?? false,
                      onSelected: (_) => _toggleOption(group, opt.id),
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Qty', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(
                onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_qty', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                onPressed: () => setState(() => _qty++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Line total'),
            trailing: Text(
              '\$${_linePreview.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Base \$${_baseSizePrice.toStringAsFixed(2)}'
              ' + extras \$${(_unitPrice - _baseSizePrice).toStringAsFixed(2)}'
              ' × $_qty'
              '${_selectedSize != null ? ' · $_selectedSize' : ''}',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await _addToCart();
                return;
              }
              final ok = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
              );
              if (!mounted) return;
              if (ok == true && FirebaseAuth.instance.currentUser != null) {
                await _addToCart();
              }
            },
            child: Text(
              FirebaseAuth.instance.currentUser == null
                  ? 'Sign in to add'
                  : 'Add to cart',
            ),
          ),
        ],
      ),
    );
  }
}
