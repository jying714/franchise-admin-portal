// customer_web/lib/features/menu/menu_item_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
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

  shared.MenuItem get item => widget.item;

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

    for (final g in item.effectiveModifierGroups) {
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
    for (final g in item.effectiveModifierGroups) {
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

  String? _validateSelections() {
    for (final g in item.effectiveModifierGroups) {
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

    for (final g in item.effectiveModifierGroups) {
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
    final groups = item.effectiveModifierGroups;
    final sizes = _sizeLabels;

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
