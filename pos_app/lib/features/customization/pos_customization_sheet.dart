import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

/// Station builder shell (mobile pricing contract).
/// P0: size + modifier groups + addonPrices / line total.
/// P1+: pizza portions, calzone, salad, wings.
class PosCustomizationSheet extends StatefulWidget {
  final MenuItem item;

  const PosCustomizationSheet({super.key, required this.item});

  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    MenuItem item,
  ) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SafeArea(child: PosCustomizationSheet(item: item)),
    );
  }

  @override
  State<PosCustomizationSheet> createState() => _PosCustomizationSheetState();
}

class _PosCustomizationSheetState extends State<PosCustomizationSheet> {
  final Map<String, Set<String>> _selected = {};
  final Map<String, String> _portions = {}; // whole | left | right
  final Map<String, bool> _doubles = {};
  String? _selectedSize;
  String? _wingHalfA; // 'plain' or option id
  String? _wingHalfB;

  List<ModifierGroup> get _groups {
    if (_isPizza || _isCalzone) return _pizzaCalzoneGroups();
    if (_isSalad) return _saladGroups();
    if (_isSub) return _subGroups();
    if (_isDinner) return _dinnerGroups();
    final effective = widget.item.effectiveModifierGroups;
    if (effective.isNotEmpty) return effective;
    return widget.item.modifierGroups ?? const [];
  }

  String _rowType(Map<String, dynamic> row) =>
      (row['typeId'] ?? row['type'] ?? '').toString().toLowerCase();

  String _rowId(Map<String, dynamic> row) =>
      (row['ingredientId'] ?? row['id'] ?? '').toString();

  String _rowName(Map<String, dynamic> row) =>
      (row['name'] ?? row['label'] ?? _rowId(row)).toString();

  List<ModifierGroup> _dinnerGroups() {
    final extras = <ModifierOption>[];
    final seen = <String>{};
    for (final raw in widget.item.optionalAddOns ?? const []) {
      if (raw is! Map) continue;
      final row = Map<String, dynamic>.from(raw);
      final id = _rowId(row);
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      extras.add(
        ModifierOption(id: id, label: _rowName(row), ingredientId: id),
      );
    }
    if (extras.isEmpty) return const [];
    return [
      ModifierGroup(
        id: 'optional_addons',
        label: 'Optional add-ons',
        selectMode: ModifierSelectMode.multi,
        min: 0,
        max: 40,
        options: extras,
      ),
    ];
  }

  List<ModifierGroup> _subGroups() {
    final seed = MenuProfileTemplates.seedGroups(MenuProfile.sub);
    final out = <ModifierGroup>[];
    for (final g in seed) {
      if (g.id.toLowerCase() == 'cook') out.add(g);
    }
    out.add(_groupFromType('meats', 'Meats'));
    out.add(_groupFromType('veggies', 'Veggies'));
    out.add(_groupFromType('cheeses', 'Cheeses'));
    return out
        .where((g) => g.options.isNotEmpty || g.id.toLowerCase() == 'cook')
        .toList();
  }

  List<ModifierGroup> _saladGroups() {
    final fromItem = widget.item.effectiveModifierGroups.where((g) {
      final t = '${g.id} ${g.label}'.toLowerCase();
      return t.contains('dressing');
    }).toList();
    final dressings = fromItem.isNotEmpty
        ? fromItem
        : [
            _groupFromType('dressings', 'Dressings'),
          ].where((g) => g.options.isNotEmpty).toList();

    final extras = <ModifierOption>[];
    final seen = <String>{};
    for (final g in dressings) {
      for (final o in g.options) {
        seen.add(_optionKey(o));
        final ing = o.ingredientId?.trim();
        if (ing != null && ing.isNotEmpty) seen.add(ing);
      }
    }
    for (final raw in widget.item.optionalAddOns ?? const []) {
      if (raw is! Map) continue;
      final row = Map<String, dynamic>.from(raw);
      if (_rowType(row) == 'dressings') continue;
      final id = _rowId(row);
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      extras.add(
        ModifierOption(id: id, label: _rowName(row), ingredientId: id),
      );
    }
    return [
      ...dressings,
      if (extras.isNotEmpty)
        ModifierGroup(
          id: 'optional_addons',
          label: 'Optional add-ons',
          selectMode: ModifierSelectMode.multi,
          min: 0,
          max: 40,
          options: extras,
        ),
    ];
  }

  List<ModifierGroup> _pizzaCalzoneGroups() {
    final profile = _isCalzone ? MenuProfile.calzone : MenuProfile.pizza;
    final seed = MenuProfileTemplates.seedGroups(profile);
    final out = <ModifierGroup>[];
    for (final g in seed) {
      final id = g.id.toLowerCase();
      if (id == 'crust' || id == 'cook' || id == 'cut') {
        if (_isCalzone && (id == 'crust' || id == 'cut')) continue;
        out.add(g);
      }
    }
    out.add(_groupFromType('cheeses', 'Cheeses'));
    out.add(_groupFromType('sauces', 'Sauces'));
    out.add(_groupFromType('meats', 'Meats'));
    out.add(_groupFromType('veggies', 'Veggies'));
    return out
        .where((g) => g.options.isNotEmpty || _isDetailsGroup(g))
        .toList();
  }

  ModifierGroup _groupFromType(String typeId, String label) {
    final options = <ModifierOption>[];
    final seen = <String>{};

    void addRow(Map<String, dynamic> row, {required bool included}) {
      final tid = _rowType(row);
      if (tid != typeId) return;
      final id = _rowId(row);
      if (id.isEmpty || seen.contains(id)) return;
      seen.add(id);
      options.add(
        ModifierOption(
          id: id,
          label: _rowName(row),
          ingredientId: id,
          defaultSelected: included,
        ),
      );
    }

    for (final raw in widget.item.includedIngredients ?? const []) {
      if (raw is Map) {
        addRow(Map<String, dynamic>.from(raw), included: true);
      }
    }
    for (final raw in widget.item.optionalAddOns ?? const []) {
      if (raw is Map) {
        addRow(Map<String, dynamic>.from(raw), included: false);
      }
    }

    return ModifierGroup(
      id: typeId,
      label: label,
      selectMode: ModifierSelectMode.multi,
      min: 0,
      max: 20,
      allowsPortion: _isPizza,
      allowsDouble: true,
      options: options,
    );
  }

  List<SizeData> get _sizes => widget.item.sizes ?? const [];

  String _groupKey(ModifierGroup g) => g.id.isNotEmpty ? g.id : g.label;

  String _optionKey(ModifierOption o) => o.id.isNotEmpty ? o.id : o.label;

  bool get _isPizza =>
      (widget.item.menuProfile ?? '').trim().toLowerCase() == 'pizza';

  bool get _isCalzone =>
      (widget.item.menuProfile ?? '').trim().toLowerCase() == 'calzone';

  bool get _isSalad =>
      (widget.item.menuProfile ?? '').trim().toLowerCase() == 'salad';

  bool get _isWings =>
      (widget.item.menuProfile ?? '').trim().toLowerCase() == 'wings';

  bool get _isSub =>
      (widget.item.menuProfile ?? '').trim().toLowerCase() == 'sub';

  bool get _isDinner {
    final p = (widget.item.menuProfile ?? '').trim().toLowerCase();
    if (p == 'dinner') return true;
    if (p == 'standard' || p.isEmpty) {
      return widget.item.optionalAddOns?.isNotEmpty ?? false;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    if (_sizes.isNotEmpty) {
      _selectedSize = _sizes.first.label;
    }
    for (final g in _groups) {
      final key = _groupKey(g);
      _selected[key] = {};
      for (final opt in g.options) {
        if (opt.defaultSelected) {
          _selected[key]!.add(_optionKey(opt));
        }
      }
    }
  }

  bool _isDetailsGroup(ModifierGroup g) {
    final t = '${g.id} ${g.label}'.toLowerCase();
    return t.contains('crust') || t.contains('cook') || t.contains('cut');
  }

  bool _isCheeseGroup(ModifierGroup g) {
    final t = '${g.id} ${g.label}'.toLowerCase();
    return t.contains('cheese');
  }

  bool _isSauceGroup(ModifierGroup g) {
    final t = '${g.id} ${g.label}'.toLowerCase();
    return t.contains('sauce');
  }

  List<ModifierGroup> _groupsWhere(bool Function(ModifierGroup) test) =>
      _groups.where(test).toList();

  bool _isVisibleGroup(ModifierGroup g) {
    if (_isCalzone) {
      final t = '${g.id} ${g.label}'.toLowerCase();
      if (t.contains('crust') || t.contains('cut')) return false;
    }
    return true;
  }

  bool get _valid {
    for (final g in _groups) {
      if (!_isVisibleGroup(g)) continue;
      if (_isWings) {
        final t = '${g.id} ${g.label}'.toLowerCase();
        if (t.contains('wing_sauce') ||
            (t.contains('sauce') && !t.contains('dip'))) {
          continue;
        }
      }
      final count = _selected[_groupKey(g)]?.length ?? 0;
      if (count < g.min) return false;
      if (count > g.max) return false;
    }
    if (_sizes.isNotEmpty &&
        (_selectedSize == null || _selectedSize!.trim().isEmpty)) {
      return false;
    }
    if (!_sauceSplitOk()) return false;
    if (_isWings && (_wingHalfA == null || _wingHalfA!.isEmpty)) {
      return false;
    }
    return true;
  }

  void _applyWingHalves() {
    final sauceGroups = _groups.where((g) {
      final t = '${g.id} ${g.label}'.toLowerCase();
      return t.contains('wing_sauce') ||
          (t.contains('sauce') && !t.contains('dip'));
    });
    final ids = <String>{};
    for (final h in [_wingHalfA, _wingHalfB]) {
      if (h != null && h.isNotEmpty && h != 'plain') ids.add(h);
    }
    for (final g in sauceGroups) {
      _selected[_groupKey(g)] = ids;
    }
  }

  double get _basePrice {
    if (_selectedSize != null) {
      for (final s in _sizes) {
        if (s.label == _selectedSize) return s.basePrice;
      }
    }
    return widget.item.price;
  }

  bool _wasIncluded(String id) {
    for (final raw in widget.item.includedIngredients ?? const []) {
      if (raw is! Map) continue;
      final row = Map<String, dynamic>.from(raw);
      final rid = (row['ingredientId'] ?? row['id'] ?? '').toString();
      if (rid == id) return true;
    }
    return false;
  }

  Map<String, double> _addonPrices() {
    final prices = <String, double>{};
    for (final g in _groups) {
      final label = g.label.trim().toLowerCase();
      final id = g.id.trim().toLowerCase();
      if (label == 'crust' ||
          label == 'cook' ||
          label == 'cut' ||
          id == 'crust' ||
          id == 'cook' ||
          id == 'cut') {
        continue;
      }
      final isDressing = label.contains('dressing') || id.contains('dressing');
      if (_isSalad && isDressing) continue;
      if (_isWings &&
          (label.contains('sauce') || id.contains('sauce')) &&
          !label.contains('dip') &&
          !id.contains('dip')) {
        continue;
      }
      for (final optId in _selected[_groupKey(g)] ?? {}) {
        ModifierOption? opt;
        for (final o in g.options) {
          if (_optionKey(o) == optId) {
            opt = o;
            break;
          }
        }
        if (opt == null) continue;
        final ingId =
            (opt.ingredientId != null && opt.ingredientId!.trim().isNotEmpty)
            ? opt.ingredientId!
            : optId;
        final fromOpt = opt.upcharge;
        var p = (fromOpt != null && fromOpt > 0)
            ? fromOpt
            : MenuPricing.resolveExtraIngredientPrice(
                item: widget.item,
                selectedSize: _selectedSize,
                ingId: ingId,
                ingredientMetadata: const {},
              );
        if (p <= 0 && (_isPizza || _isCalzone)) {
          p = MenuPricing.toppingUpcharge(widget.item, _selectedSize);
        }
        if (p <= 0 && _isDinner) {
          p = MenuPricing.resolveExtraIngredientPrice(
            item: widget.item,
            selectedSize: _selectedSize,
            ingId: ingId,
            ingredientMetadata: const {},
          );
        }
        if (p <= 0) continue;
        final doubled = _doubles[optId] == true;
        final included = _wasIncluded(ingId) || _wasIncluded(optId);
        if (included && !doubled) continue;
        if (included && doubled) {
          prices[optId] = p;
        } else {
          prices[optId] = doubled ? p * 2 : p;
        }
      }
    }
    if (_isSalad) {
      final dressingIds = <String>{};
      for (final g in _groups) {
        final t = '${g.id} ${g.label}'.toLowerCase();
        if (!t.contains('dressing')) continue;
        dressingIds.addAll(_selected[_groupKey(g)] ?? {});
      }
      final free =
          widget.item.freeDressingCount ?? widget.item.maxFreeDressings ?? 0;
      final extra = widget.item.extraDressingUpcharge ?? 0.0;
      final paid = (dressingIds.length - free).clamp(0, 100);
      if (paid > 0 && extra > 0) {
        prices['_dressings_extra'] = extra * paid;
      }
    }

    if (_isWings) {
      final dipIds = <String>{};
      for (final g in _groups) {
        final t = '${g.id} ${g.label}'.toLowerCase();
        if (!t.contains('dip')) continue;
        dipIds.addAll(_selected[_groupKey(g)] ?? {});
        for (final id in dipIds) {
          prices.remove(id);
        }
      }
      var free = 0;
      final map = widget.item.freeDipCupCount;
      if (map != null && _selectedSize != null) {
        for (final e in map.entries) {
          if (e.key.toString() == _selectedSize) {
            free = e.value;
            break;
          }
        }
      }
      var extra = 0.0;
      final up = widget.item.sideDipUpcharge;
      if (up != null && _selectedSize != null) {
        extra = up[_selectedSize] ?? up.values.firstOrNull ?? 0.0;
      }
      extra = extra > 0 ? extra : 0.75;
      final paid = (dipIds.length - free).clamp(0, 100);
      if (paid > 0) {
        prices['_dips_extra'] = extra * paid;
      }
    }
    return prices;
  }

  List<Widget> _buildGroupSection(
    BuildContext context, {
    required String heading,
    required List<ModifierGroup> groups,
  }) {
    if (groups.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(heading, style: Theme.of(context).textTheme.titleMedium),
      ),
      for (final g in groups) ...[
        if (g.label.trim().toLowerCase() != heading.toLowerCase())
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(g.label, style: Theme.of(context).textTheme.titleSmall),
          ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final opt in g.options)
              FilterChip(
                label: Text(opt.label),
                selected: (_selected[_groupKey(g)] ?? {}).contains(
                  _optionKey(opt),
                ),
                onSelected: (_) => _toggle(g, opt),
              ),
          ],
        ),
        if (_allowsPortion(g) || _allowsDouble(g))
          for (final opt in g.options)
            if ((_selected[_groupKey(g)] ?? {}).contains(_optionKey(opt)))
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Row(
                  children: [
                    Text(
                      opt.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    ChoiceChip(
                      label: const Text('L'),
                      selected:
                          (_portions[_optionKey(opt)] ?? 'whole') == 'left',
                      onSelected: (_) => _setPortion(_optionKey(opt), 'left'),
                    ),
                    const SizedBox(width: 4),
                    ChoiceChip(
                      label: const Text('W'),
                      selected:
                          (_portions[_optionKey(opt)] ?? 'whole') == 'whole',
                      onSelected: (_) => _setPortion(_optionKey(opt), 'whole'),
                    ),
                    const SizedBox(width: 4),
                    ChoiceChip(
                      label: const Text('R'),
                      selected:
                          (_portions[_optionKey(opt)] ?? 'whole') == 'right',
                      onSelected: (_) => _setPortion(_optionKey(opt), 'right'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Dbl'),
                      selected: _doubles[_optionKey(opt)] == true,
                      onSelected: (_) => _toggleDouble(_optionKey(opt)),
                    ),
                  ],
                ),
              ),
      ],
    ];
  }

  double get _extrasTotal {
    var n = 0.0;
    for (final p in _addonPrices().values) {
      n += p;
    }
    return n;
  }

  double get _linePrice => _basePrice + _extrasTotal;

  void _toggle(ModifierGroup g, ModifierOption opt) {
    final groupKey = _groupKey(g);
    final optionKey = _optionKey(opt);
    final set = _selected[groupKey] ?? <String>{};
    if (set.contains(optionKey)) {
      set.remove(optionKey);
      _portions.remove(optionKey);
      _doubles.remove(optionKey);
    } else {
      if (g.selectMode == ModifierSelectMode.single || g.max == 1) {
        for (final old in set) {
          _portions.remove(old);
          _doubles.remove(old);
        }
        set.clear();
        set.add(optionKey);
      } else if (set.length >= g.max) {
        return;
      } else {
        set.add(optionKey);
      }
      _portions[optionKey] = 'whole';
      _doubles[optionKey] = false;
    }
    setState(() => _selected[groupKey] = set);
  }

  void _setPortion(String id, String portion) {
    setState(() => _portions[id] = portion);
  }

  void _toggleDouble(String id) {
    setState(() => _doubles[id] = !(_doubles[id] == true));
  }

  bool _allowsPortion(ModifierGroup g) => _isPizza && !_isDetailsGroup(g);

  bool _allowsDouble(ModifierGroup g) =>
      (_isPizza || _isCalzone || _isSub || _isDinner) && !_isDetailsGroup(g);

  bool _sauceSplitOk() {
    if (!_isPizza) return true;
    final sauces = _selected['sauces'] ?? {};
    if (sauces.isEmpty) return true;
    if (sauces.length == 1) {
      return (_portions[sauces.first] ?? 'whole') == 'whole';
    }
    if (sauces.length != 2) return false;
    final a = _portions[sauces.first] ?? 'whole';
    final b = _portions[sauces.last] ?? 'whole';
    return (a == 'left' && b == 'right') || (a == 'right' && b == 'left');
  }

  List<ModifierOption> get _wingSauces {
    for (final g in _groups) {
      final t = '${g.id} ${g.label}'.toLowerCase();
      if (t.contains('wing_sauce') ||
          (t.contains('sauce') && !t.contains('dip'))) {
        return g.options;
      }
    }
    return const [];
  }

  Widget _wingHalfRow(
    BuildContext context, {
    required String label,
    required String? value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('Plain'),
              selected: value == 'plain',
              onSelected: (_) => onChanged('plain'),
            ),
            for (final o in _wingSauces)
              ChoiceChip(
                label: Text(o.label),
                selected: value == _optionKey(o),
                onSelected: (_) => onChanged(_optionKey(o)),
              ),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> _payload() {
    if (_isWings) _applyWingHalves();
    final out = <String, dynamic>{
      for (final e in _selected.entries)
        if (e.value.isNotEmpty) e.key: e.value.toList(),
    };
    if (_isWings) {
      out['wingHalves'] = {
        if (_wingHalfA != null) 'a': _wingHalfA,
        if (_wingHalfB != null) 'b': _wingHalfB,
      };
    }
    if (_selectedSize != null && _selectedSize!.trim().isNotEmpty) {
      out['size'] = _selectedSize;
    }
    final prices = _addonPrices();
    if (prices.isNotEmpty) out['addonPrices'] = prices;
    if (_portions.isNotEmpty)
      out['portions'] = Map<String, String>.from(_portions);
    if (_doubles.values.any((v) => v)) {
      out['doubles'] = {
        for (final e in _doubles.entries)
          if (e.value) e.key: true,
      };
    }
    final labels = <String, String>{};
    for (final g in _groups) {
      for (final o in g.options) {
        final id = _optionKey(o);
        if (id.isEmpty) continue;
        labels[id] = o.label.trim().isNotEmpty ? o.label.trim() : id;
      }
    }
    if (labels.isNotEmpty) out['optionLabels'] = labels;
    out['_linePrice'] = _linePrice;
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = _isPizza
        ? 'Build pizza'
        : _isCalzone
        ? 'Build calzone'
        : _isSalad
        ? 'Build salad'
        : _isWings
        ? 'Build wings'
        : _isSub
        ? 'Build sub'
        : _isDinner
        ? 'Build dinner'
        : 'Customize ${widget.item.name}';

    final bottomInset =
        MediaQuery.paddingOf(context).bottom +
        MediaQuery.viewInsetsOf(context).bottom +
        28;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_sizes.isNotEmpty) ...[
                      Text(
                        'Size',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in _sizes)
                            ChoiceChip(
                              label: Text(
                                '${s.label}  \$${s.basePrice.toStringAsFixed(2)}',
                              ),
                              selected: _selectedSize == s.label,
                              onSelected: (_) =>
                                  setState(() => _selectedSize = s.label),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_isWings) ...[
                      Text(
                        'Build your wings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _wingHalfRow(
                        context,
                        label: 'Half 1',
                        value: _wingHalfA,
                        onChanged: (v) => setState(() => _wingHalfA = v),
                      ),
                      const SizedBox(height: 8),
                      _wingHalfRow(
                        context,
                        label: 'Half 2',
                        value: _wingHalfB,
                        onChanged: (v) => setState(() => _wingHalfB = v),
                      ),
                      const SizedBox(height: 16),
                      ..._buildGroupSection(
                        context,
                        heading: 'Dipping cups',
                        groups: _groups.where((g) {
                          final t = '${g.id} ${g.label}'.toLowerCase();
                          return t.contains('dip');
                        }).toList(),
                      ),
                    ] else if (_isSub) ...[
                      ..._buildGroupSection(
                        context,
                        heading: 'Order details',
                        groups: _groupsWhere((g) {
                          final t = '${g.id} ${g.label}'.toLowerCase();
                          return t.contains('cook');
                        }),
                      ),
                      ..._buildGroupSection(
                        context,
                        heading: 'Optional add-ons',
                        groups: _groups.where((g) {
                          final t = '${g.id} ${g.label}'.toLowerCase();
                          return !t.contains('cook');
                        }).toList(),
                      ),
                    ] else if (_isDinner) ...[
                      ..._buildGroupSection(
                        context,
                        heading: 'Optional add-ons',
                        groups: _groups,
                      ),
                    ] else if (_isSalad) ...[
                      ..._buildGroupSection(
                        context,
                        heading: 'Optional add-ons',
                        groups: _groups.where((g) {
                          final t = '${g.id} ${g.label}'.toLowerCase();
                          return !t.contains('dressing');
                        }).toList(),
                      ),
                      ..._buildGroupSection(
                        context,
                        heading: 'Dressings',
                        groups: _groups.where((g) {
                          final t = '${g.id} ${g.label}'.toLowerCase();
                          return t.contains('dressing');
                        }).toList(),
                      ),
                    ] else ...[
                      ..._buildGroupSection(
                        context,
                        heading: 'Order details',
                        groups: _isPizza
                            ? _groupsWhere(_isDetailsGroup)
                            : _isCalzone
                            ? _groupsWhere((g) {
                                final t = '${g.id} ${g.label}'.toLowerCase();
                                return t.contains('cook');
                              })
                            : _groupsWhere(_isDetailsGroup),
                      ),
                      ..._buildGroupSection(
                        context,
                        heading: 'Cheeses',
                        groups: _groupsWhere(_isCheeseGroup),
                      ),
                      ..._buildGroupSection(
                        context,
                        heading: 'Sauces',
                        groups: _groupsWhere(_isSauceGroup),
                      ),
                      ..._buildGroupSection(
                        context,
                        heading: 'Optional add-ons',
                        groups: () {
                          final extras = _groups.where((g) {
                            if (!_isVisibleGroup(g)) return false;
                            if (_isDetailsGroup(g) ||
                                _isCheeseGroup(g) ||
                                _isSauceGroup(g)) {
                              return false;
                            }
                            return true;
                          }).toList();
                          if (extras.isNotEmpty) return extras;
                          final anySection =
                              _groupsWhere(_isDetailsGroup).isNotEmpty ||
                              _groupsWhere(_isCheeseGroup).isNotEmpty ||
                              _groupsWhere(_isSauceGroup).isNotEmpty;
                          if (!anySection) {
                            return _groups.where(_isVisibleGroup).toList();
                          }
                          return extras;
                        }(),
                      ),
                      if (!_isPizza &&
                          !_isCalzone &&
                          !_isSalad &&
                          !_isWings &&
                          _groupsWhere(_isDetailsGroup).isEmpty &&
                          _groupsWhere(_isCheeseGroup).isEmpty &&
                          _groupsWhere(_isSauceGroup).isEmpty)
                        ..._buildGroupSection(
                          context,
                          heading: 'Options',
                          groups: _groups,
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Total  \$${_linePrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _valid
                      ? () => Navigator.pop(context, _payload())
                      : null,
                  child: Text('Add  \$${_linePrice.toStringAsFixed(2)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
