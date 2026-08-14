// customer_web/lib/features/menu/menu_item_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/sign_in_screen.dart';
import 'package:provider/provider.dart';
import '../cart/cart_screen.dart';

// widgets
import 'widgets/menu_item_size_section.dart';
import 'widgets/menu_item_order_details_section.dart';
import 'widgets/menu_item_current_toppings_section.dart';
import 'widgets/menu_item_additional_toppings_section.dart';
import 'widgets/menu_item_cheeses_section.dart';
import 'widgets/menu_item_sauces_section.dart';
import 'widgets/menu_item_qty_total_section.dart';
import 'widgets/menu_item_notes_section.dart';
import 'widgets/menu_item_wings_sauce_section.dart';
import 'widgets/menu_item_wings_dips_section.dart';

/// Phase 4a: detail + size + modifier group shells.
/// Cart write and auth gate land in Phase 5/6.
class MenuItemDetailScreen extends StatefulWidget {
  const MenuItemDetailScreen({
    super.key,
    required this.item,
    this.initialQuantity = 1,
    this.cartItemKeyToReplace,
  });

  final shared.MenuItem item;

  /// When editing a cart line.
  final int initialQuantity;
  final String? cartItemKeyToReplace;

  @override
  State<MenuItemDetailScreen> createState() => _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends State<MenuItemDetailScreen> {
  late String? _selectedSize;
  int _qty = 1;
  final TextEditingController _notesController = TextEditingController();

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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

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
      if (_selectedSauces.contains(id) && _selectedSauces.length == 2) {
        if (value == _portionWhole) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'With 2 sauces, each must be Left or Right — not Whole',
              ),
            ),
          );
          return;
        }
        _enforceSaucePortions(preferredId: id, preferredPortion: value);
        return;
      }
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

  void _addSauce(String id) {
    if (_selectedSauces.length >= _maxSauces) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Max $_maxSauces sauces')));
      return;
    }
    setState(() {
      _selectedSauces.add(id);
      if (_selectedSauces.length == 2) {
        // Two sauces cannot both cover the whole pie.
        _enforceSaucePortions();
      }
    });
  }

  void _removeSauce(String id) {
    setState(() {
      _selectedSauces.remove(id);
      _isDouble.remove(id);
      _portion.remove(id);
    });
  }

  /// When two sauces are selected, both cannot be whole: force Left + Right.
  void _enforceSaucePortions({String? preferredId, String? preferredPortion}) {
    if (_selectedSauces.length < 2) return;
    final ids = _selectedSauces.toList();
    final a = ids[0];
    final b = ids[1];

    if (preferredId != null && preferredPortion != null) {
      if (preferredPortion == _portionWhole) {
        // Cannot set whole while two sauces exist — ignore / keep halves.
        return;
      }
      _portion[preferredId] = preferredPortion;
      final other = preferredId == a ? b : a;
      _portion[other] = preferredPortion == _portionLeft
          ? _portionRight
          : _portionLeft;
      return;
    }

    final pa = _getPortion(a);
    final pb = _getPortion(b);
    if (pa == _portionWhole && pb == _portionWhole) {
      _portion[a] = _portionLeft;
      _portion[b] = _portionRight;
      return;
    }
    if (pa == _portionWhole) {
      _portion[a] = pb == _portionLeft ? _portionRight : _portionLeft;
      return;
    }
    if (pb == _portionWhole) {
      _portion[b] = pa == _portionLeft ? _portionRight : _portionLeft;
      return;
    }
    // Both already half — if same side, flip the second.
    if (pa == pb) {
      _portion[b] = pa == _portionLeft ? _portionRight : _portionLeft;
    }
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

  bool _isWings() {
    return item.effectiveMenuProfile.toLowerCase() == shared.MenuProfile.wings;
  }

  Map<String, dynamic>? _wingGroupMap(String groupId) {
    final id = groupId.toLowerCase();
    for (final g in _groupsForUi()) {
      if ((g['id'] ?? '').toString().toLowerCase() == id) return g;
    }
    return null;
  }

  static const String _wingPlainId = 'plain';

  List<String> _wingSauceOptionIds() {
    final g = _wingGroupMap('wing_sauce');
    final raw = (g?['ingredientIds'] as List? ?? [])
        .map((e) => e.toString().trim())
        .where((id) => id.isNotEmpty)
        .toList();
    // Product rule: Plain is always a valid portion choice.
    if (!raw.any((id) => id.toLowerCase() == _wingPlainId)) {
      return [_wingPlainId, ...raw];
    }
    return raw;
  }

  /// Wings side dip cups: sauceId → cup count.
  final Map<String, int> _wingDipCounts = {};
  static const int _maxWingDipCups = 4;

  String _wingOptionLabel(String groupId, String optionId) {
    if (optionId.toLowerCase() == _wingPlainId) return 'Plain';
    final g = _wingGroupMap(groupId);
    final labels =
        (g?['optionLabels'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ) ??
        const <String, String>{};
    return labels[optionId] ?? _ingredientDisplayName(optionId);
  }

  void _setWingPortionLeft(String id) {
    setState(() {
      _wingPortionLeft = id;
    });
  }

  void _setWingPortionRight(String id) {
    setState(() {
      _wingPortionRight = id;
    });
  }

  bool _isWingPlain(String id) => id.toLowerCase() == _wingPlainId;

  List<String> _wingDipOptionIds() {
    final g = _wingGroupMap('wing_dips');
    final raw = (g?['ingredientIds'] as List? ?? [])
        .map((e) => e.toString().trim())
        .where((id) => id.isNotEmpty)
        .toList();
    if (raw.isNotEmpty) return raw;
    // Same catalog as toss (product rule); exclude synthetic plain.
    return _wingSauceOptionIds()
        .where((id) => id.toLowerCase() != _wingPlainId)
        .toList();
  }

  int _freeDipCupsForSize() {
    return item.getFreeDipCupCountForSize(_selectedSize);
  }

  double _sideDipUpchargeForSize() {
    return item.getSideDipUpchargeForSize(_selectedSize);
  }

  int get _totalWingDipCups => _wingDipCounts.values.fold(0, (a, b) => a + b);

  int get _paidWingDipCups {
    final free = _freeDipCupsForSize();
    final total = _totalWingDipCups;
    return total > free ? total - free : 0;
  }

  void _setWingDipCount(String id, int count) {
    setState(() {
      if (count <= 0) {
        _wingDipCounts.remove(id);
        return;
      }
      final others = _totalWingDipCups - (_wingDipCounts[id] ?? 0);
      final allowed = _maxWingDipCups - others;
      final next = count > allowed ? allowed : count;
      if (next <= 0) {
        _wingDipCounts.remove(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Max $_maxWingDipCups dip cups')),
        );
        return;
      }
      _wingDipCounts[id] = next;
    });
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

    // Wings: ensure wing_sauce + wing_dips shells when missing/empty.
    if (_isWings()) {
      final template = shared.MenuProfileTemplates.seedGroups(
        shared.MenuProfile.wings,
      );
      for (final seed in template) {
        final sid = seed.id.toLowerCase();
        final idx = groups.indexWhere(
          (g) =>
              (g['id'] ?? '').toString().toLowerCase() == sid ||
              (g['label'] ?? '').toString().toLowerCase() ==
                  seed.label.toLowerCase(),
        );
        final hasOptions =
            idx >= 0 &&
            ((groups[idx]['ingredientIds'] as List?)?.isNotEmpty ?? false);
        if (hasOptions) continue;

        // Prefer options already bound on item.modifierGroups even if map empty.
        final stored = item.modifierGroups?.where(
          (mg) =>
              mg.id.toLowerCase() == sid ||
              mg.label.toLowerCase() == seed.label.toLowerCase(),
        );
        final source = (stored != null && stored.isNotEmpty)
            ? stored.first
            : seed;
        final mapped = groupToMap(source);
        if (idx >= 0) {
          groups[idx] = mapped;
        } else {
          groups.add(mapped);
        }
      }

      // If wing_sauce still has no options, bind dippingSauceOptions ids.
      final sauceIdx = groups.indexWhere(
        (g) => (g['id'] ?? '').toString().toLowerCase() == 'wing_sauce',
      );
      if (sauceIdx >= 0) {
        final ids = (groups[sauceIdx]['ingredientIds'] as List? ?? []);
        if (ids.isEmpty) {
          final fromItem = item.dippingSauceOptions ?? const <String>[];
          if (fromItem.isNotEmpty) {
            groups[sauceIdx] = {
              ...groups[sauceIdx],
              'ingredientIds': List<String>.from(fromItem),
              'optionLabels': {
                for (final id in fromItem) id: _ingredientDisplayName(id),
              },
            };
          }
        }
      }

      // wing_dips: prefer sideDipSauceOptions, else same pool as sauces.
      final dipsIdx = groups.indexWhere(
        (g) => (g['id'] ?? '').toString().toLowerCase() == 'wing_dips',
      );
      if (dipsIdx >= 0) {
        final ids = (groups[dipsIdx]['ingredientIds'] as List? ?? []);
        if (ids.isEmpty) {
          final fromItem =
              item.sideDipSauceOptions ??
              item.dippingSauceOptions ??
              const <String>[];
          if (fromItem.isNotEmpty) {
            groups[dipsIdx] = {
              ...groups[dipsIdx],
              'ingredientIds': List<String>.from(fromItem),
              'optionLabels': {
                for (final id in fromItem) id: _ingredientDisplayName(id),
              },
            };
          }
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

  bool _isWingsDedicatedGroup(String id, String label) {
    final v = '${id.toLowerCase().trim()} ${label.toLowerCase().trim()}';
    return v.contains('wing_sauce') ||
        v.contains('wing_dips') ||
        v == 'sauce' ||
        v.contains('dipping') ||
        v.contains('dip cup') ||
        v.contains('dip');
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

  shared.Portion _portionEnum(String id) {
    switch (_getPortion(id)) {
      case _portionLeft:
        return shared.Portion.left;
      case _portionRight:
        return shared.Portion.right;
      default:
        return shared.Portion.whole;
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

  /// Wings toss sauces (wing_sauce group) — max 2.
  /// Wings flavor portions: always 2 halves (mobile parity).
  late String _wingPortionLeft;
  late String _wingPortionRight;

  /// ingredientId → isDouble (Current toppings, cheeses, sauces).
  final Map<String, bool> _isDouble = {};

  static const int _maxDoubles = 4;

  @override
  void initState() {
    super.initState();
    final sizes = item.sizes;
    _qty = widget.initialQuantity < 1 ? 1 : widget.initialQuantity;
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

    // Sauces: defaults from included + optional pool (stay in Sauces section).
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

    // Pizza/calzone: cheeses & sauces live in their own sections — not in Current.
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

    // Wings toss sauces — always initialize (avoids LateInitializationError).
    // Wings: always two portions (default both Plain).
    _wingPortionLeft = _wingPlainId;
    _wingPortionRight = _wingPlainId;
    if (_isWings()) {
      final defaults = <String>[];
      final stored = item.modifierGroups?.where(
        (mg) =>
            mg.id.toLowerCase() == 'wing_sauce' ||
            mg.label.toLowerCase() == 'sauce',
      );
      if (stored != null && stored.isNotEmpty) {
        for (final o in stored.first.options) {
          if (!o.defaultSelected) continue;
          final key =
              (o.ingredientId != null && o.ingredientId!.trim().isNotEmpty)
              ? o.ingredientId!.trim()
              : o.id.trim();
          if (key.isNotEmpty) defaults.add(key);
        }
      }
      if (defaults.isNotEmpty) {
        _wingPortionLeft = defaults.first;
        _wingPortionRight = defaults.length > 1 ? defaults[1] : defaults.first;
      }
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

    // Wings side dip cups (extras only).
    if (_isWings()) {
      final paid = _paidWingDipCups;
      if (paid > 0) {
        total += paid * _sideDipUpchargeForSize();
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

    if (_isWings()) {
      if (_wingPortionLeft.trim().isEmpty || _wingPortionRight.trim().isEmpty) {
        return 'Select a sauce (or Plain) for both halves';
      }
    }
    // Two sauces cannot both be whole.
    if (_selectedSauces.length == 2) {
      final ids = _selectedSauces.toList();
      final bothWhole =
          _getPortion(ids[0]) == _portionWhole &&
          _getPortion(ids[1]) == _portionWhole;
      final sameHalf =
          _getPortion(ids[0]) != _portionWhole &&
          _getPortion(ids[0]) == _getPortion(ids[1]);
      if (bothWhole || sameHalf) {
        return 'With 2 sauces, set one Left and one Right';
      }
    }
    for (final g in item.effectiveModifierGroups) {
      if (_isStructuralIdOrLabel(g.id) || _isStructuralIdOrLabel(g.label)) {
        continue;
      }
      // Wings: wing_sauce / wing_dips are owned by dedicated state, not _selectedByGroup.
      if (_isWings() && _isWingsDedicatedGroup(g.id, g.label)) {
        continue;
      }
      // Pizza dedicated groups are owned by Current / Cheeses / Sauces sections.
      if (_isPizza() && _isPizzaDedicatedGroup(g.id, g.label)) {
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
          ingredientId: id,
          name: nameParts.length == 1
              ? display
              : '${nameParts.first} (${nameParts.skip(1).join(', ')})',
          isGroup: false,
          price: unitPrice * units * mult,
          group: 'Current',
          selected: true,
          isDefault: _wasIncludedIngredient(id),
          portion: _portionEnum(id),
          quantity: _getDouble(id) ? 2 : 1,
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
          ingredientId: id,
          name: nameParts.length == 1
              ? display
              : '${nameParts.first} (${nameParts.skip(1).join(', ')})',
          isGroup: false,
          price: unitPrice * units * mult,
          group: 'Cheeses',
          selected: true,
          isDefault: _isOriginallyIncluded(id),
          portion: _portionEnum(id),
          quantity: _getDouble(id) ? 2 : 1,
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

    // Wings toss sauces — two halves (mobile parity).
    if (_isWings()) {
      list.add(
        shared.Customization(
          id: 'wing_left_${_wingPortionLeft}',
          ingredientId: _isWingPlain(_wingPortionLeft)
              ? null
              : _wingPortionLeft,
          name: _isWingPlain(_wingPortionLeft)
              ? 'Plain (Left)'
              : '${_wingOptionLabel('wing_sauce', _wingPortionLeft)} (Left)',
          isGroup: false,
          price: 0,
          group: 'Sauce',
          selected: true,
          portion: shared.Portion.left,
        ),
      );
      list.add(
        shared.Customization(
          id: 'wing_right_${_wingPortionRight}',
          ingredientId: _isWingPlain(_wingPortionRight)
              ? null
              : _wingPortionRight,
          name: _isWingPlain(_wingPortionRight)
              ? 'Plain (Right)'
              : '${_wingOptionLabel('wing_sauce', _wingPortionRight)} (Right)',
          isGroup: false,
          price: 0,
          group: 'Sauce',
          selected: true,
          portion: shared.Portion.right,
        ),
      );
    }

    // Wings side dip cups.
    if (_isWings()) {
      final free = _freeDipCupsForSize();
      final upcharge = _sideDipUpchargeForSize();
      // Assign free to first cups in stable id order, then charge rest.
      var freeLeft = free;
      final ids = _wingDipCounts.keys.toList()..sort();
      for (final id in ids) {
        final count = _wingDipCounts[id] ?? 0;
        for (var i = 0; i < count; i++) {
          final isFree = freeLeft > 0;
          if (isFree) freeLeft--;
          list.add(
            shared.Customization(
              id: '${id}_cup_$i',
              ingredientId: id,
              name: '${_wingOptionLabel('wing_dips', id)} (cup)',
              isGroup: false,
              price: isFree ? 0 : upcharge,
              group: 'Dipping cups',
              selected: true,
              quantity: 1,
            ),
          );
        }
      }
    }

    // Non-structural modifier groups (extras the user added via chips).
    for (final g in item.effectiveModifierGroups) {
      if (_isStructuralIdOrLabel(g.id) || _isStructuralIdOrLabel(g.label)) {
        continue;
      }
      if (_isWings() && _isWingsDedicatedGroup(g.id, g.label)) {
        continue;
      }
      if (_isPizza() && _isPizzaDedicatedGroup(g.id, g.label)) {
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
    final replaceKey = widget.cartItemKeyToReplace?.trim();
    if (replaceKey != null && replaceKey.isNotEmpty) {
      await fs.removeFromCart(user.uid, replaceKey, franchiseId: franchiseId);
    }
    try {
      await fs.addToCart(
        userId: user.uid,
        franchiseId: franchiseId,
        menuItem: item,
        customizations: {
          'groups': customizations.map((c) => c.toMap()).toList(),
        },
        quantity: _qty,
        price: unit,
        specialInstructions: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              if (item.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => ColoredBox(
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
              MenuItemSizeSection(
                sizeLabels: sizes,
                selectedSize: _selectedSize,
                onSizeSelected: (label) =>
                    setState(() => _selectedSize = label),
              ),
              if (_showsCurrentIngredients())
                MenuItemCurrentToppingsSection(
                  ingredientIds: _currentIngredients,
                  displayName: _ingredientDisplayName,
                  isDouble: _getDouble,
                  portion: _getPortion,
                  showPortionControls: _showsPortionControls(),
                  onToggleDouble: _setDouble,
                  onSetPortion: _setPortion,
                  onRemove: (id) {
                    setState(() {
                      _currentIngredients.remove(id);
                      _isDouble.remove(id);
                      _portion.remove(id);
                    });
                  },
                ),
              if (_isPizza() && !_isWings())
                MenuItemAdditionalToppingsSection(
                  meatIds: _availableIdsByType('meats'),
                  veggieIds: _availableIdsByType('veggies'),
                  labelFor: _optionalLabel,
                  toppingPrice: _toppingUnitPrice(),
                  onAdd: (id) {
                    setState(() {
                      _currentIngredients.add(id);
                    });
                  },
                ),
              if (_isPizza())
                MenuItemCheesesSection(
                  selectedIds: _selectedCheeses.toList(),
                  availableIds: _availableCheeseIds(),
                  maxCheeses: _maxCheeses,
                  labelFor: _optionalLabel,
                  isDouble: _getDouble,
                  portion: _getPortion,
                  isOriginallyIncluded: _isOriginallyIncluded,
                  toppingPrice: _toppingUnitPrice(),
                  showPortionControls: _showsPortionControls(),
                  onToggleDouble: _setDouble,
                  onSetPortion: _setPortion,
                  onRemove: _removeCheese,
                  onAdd: _addCheese,
                ),
              if (_isPizza())
                MenuItemSaucesSection(
                  selectedIds: _selectedSauces.toList(),
                  availableIds: _availableSauceIds(),
                  maxSauces: _maxSauces,
                  labelFor: _optionalLabel,
                  isDouble: _getDouble,
                  portion: _getPortion,
                  isOriginallyIncluded: _isOriginallyIncluded,
                  toppingPrice: _toppingUnitPrice(),
                  showPortionControls: _showsPortionControls(),
                  onToggleDouble: _setDouble,
                  onSetPortion: _setPortion,
                  onRemove: _removeSauce,
                  onAdd: _addSauce,
                ),
              if (!_isWings())
                MenuItemOrderDetailsSection(
                  groups: _structuralGroupsForUi(),
                  selections: _structuralSelections,
                  isSub: _isSub(),
                  onSelected: (groupLabel, optionId) {
                    setState(() {
                      _structuralSelections[groupLabel] = optionId;
                    });
                  },
                ),
              if (_isWings())
                MenuItemWingsSauceSection(
                  optionIds: _wingSauceOptionIds(),
                  leftId: _wingPortionLeft,
                  rightId: _wingPortionRight,
                  labelFor: (id) => _wingOptionLabel('wing_sauce', id),
                  onLeftSelected: _setWingPortionLeft,
                  onRightSelected: _setWingPortionRight,
                ),
              if (_isWings())
                MenuItemWingsDipsSection(
                  optionIds: _wingDipOptionIds(),
                  counts: Map<String, int>.from(_wingDipCounts),
                  freeCups: _freeDipCupsForSize(),
                  upcharge: _sideDipUpchargeForSize(),
                  maxCups: _maxWingDipCups,
                  labelFor: (id) => _wingOptionLabel('wing_dips', id),
                  onSetCount: _setWingDipCount,
                ),
              for (final group in item.effectiveModifierGroups) ...[
                if (_isStructuralIdOrLabel(group.id) ||
                    _isStructuralIdOrLabel(group.label))
                  const SizedBox.shrink()
                else if (_isPizza() &&
                    _isPizzaDedicatedGroup(group.id, group.label))
                  const SizedBox.shrink()
                else if (_isWings() &&
                    _isWingsDedicatedGroup(group.id, group.label))
                  const SizedBox.shrink()
                else ...[
                  const SizedBox(height: 20),
                  Text(
                    group.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
                              _selectedByGroup[group.id]?.contains(opt.id) ??
                              false,
                          onSelected: (_) => _toggleOption(group, opt.id),
                        ),
                    ],
                  ),
                ],
              ],
              MenuItemNotesSection(controller: _notesController),
              const SizedBox(height: 8),
            ],
          ),
        ),
        // Sticky footer — always visible
        Material(
          elevation: 8,
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: MenuItemQtyTotalSection(
                qty: _qty,
                baseSizePrice: _baseSizePrice,
                unitPrice: _unitPrice,
                selectedSize: _selectedSize,
                isSignedIn: FirebaseAuth.instance.currentUser != null,
                onQtyChanged: (v) => setState(() => _qty = v),
                onPrimaryPressed: () async {
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
              ),
            ),
          ),
        ),
      ],
    );
  }
}
