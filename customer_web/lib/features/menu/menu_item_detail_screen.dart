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

  /// Item groups + missing structural groups from menu profile templates.
  List<shared.ModifierGroup> get _groupsForUi {
    final existing = item.effectiveModifierGroups;
    final profile = item.effectiveMenuProfile.toLowerCase();

    final needStructural =
        profile == shared.MenuProfile.pizza ||
        profile == shared.MenuProfile.calzone ||
        profile == shared.MenuProfile.sub;
    if (!needStructural) return existing;

    final seeded = shared.MenuProfileTemplates.seedGroups(profile);
    final have = existing.map((g) => g.id.toLowerCase()).toSet();
    const structuralIds = {'crust', 'cook', 'cut'};

    final missing = <shared.ModifierGroup>[];
    for (final g in seeded) {
      if (!structuralIds.contains(g.id.toLowerCase())) continue;
      if (have.contains(g.id.toLowerCase())) continue;
      if (g.options.isEmpty) continue;
      missing.add(g);
    }
    if (missing.isEmpty) return existing;

    final merged = [...missing, ...existing];
    merged.sort((a, b) => (a.sortOrder ?? 999).compareTo(b.sortOrder ?? 999));
    return merged;
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

  @override
  void initState() {
    super.initState();
    final sizes = item.sizes;
    if (sizes != null && sizes.isNotEmpty) {
      _selectedSize = sizes.first.label;
    } else if (item.sizePrices != null && item.sizePrices!.isNotEmpty) {
      _selectedSize = item.sizePrices!.keys.first;
    } else {
      _selectedSize = null;
    }

    _seedTypesFromItem();

    for (final g in _groupsForUi) {
      final defaults = <String>{};
      for (final o in g.options) {
        if (o.defaultSelected) defaults.add(o.id);
      }
      if (defaults.isNotEmpty) {
        _selectedByGroup[g.id] = defaults;
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
    for (final g in _groupsForUi) {
      final selectedIds = _selectedByGroup[g.id] ?? const <String>{};
      if (selectedIds.isEmpty) continue;

      final selectedOpts = g.options
          .where((o) => selectedIds.contains(o.id))
          .toList();

      final freeCount = (g.maxFree != null && g.maxFree! > 0) ? g.maxFree! : 0;
      selectedOpts.sort((a, b) => _optionDelta(b).compareTo(_optionDelta(a)));
      for (var i = 0; i < selectedOpts.length; i++) {
        if (i < freeCount) continue;
        total += _optionDelta(selectedOpts[i]);
      }
    }
    return total;
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

  String? _validateSelections() {
    for (final g in _groupsForUi) {
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

    for (final g in _groupsForUi) {
      final selected = _selectedByGroup[g.id] ?? const <String>{};
      for (final opt in g.options) {
        if (!selected.contains(opt.id)) continue;
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
    final groups = _groupsForUi;
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
          for (final group in groups) ...[
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
            _buildGroupOptions(context, group),
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
