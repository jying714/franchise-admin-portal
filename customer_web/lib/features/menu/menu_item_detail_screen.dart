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

  double get _unitPrice {
    if (_selectedSize != null) {
      if (item.sizePrices != null &&
          item.sizePrices!.containsKey(_selectedSize)) {
        return item.sizePrices![_selectedSize]!;
      }
      final match = item.sizes?.where((s) => s.label == _selectedSize);
      if (match != null && match.isNotEmpty) {
        return match.first.basePrice;
      }
    }
    return item.price;
  }

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    final fs = Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseId = fp.currentFranchiseId;
    if (!fp.hasValidFranchise) return;

    // Build selected customizations as shared Customization list is Phase 4b;
    // for now pass empty list + record size in specialInstructions if needed.
    final sizeNote = _selectedSize != null ? 'Size: $_selectedSize' : null;

    try {
      await fs.addToCart(
        userId: user.uid,
        franchiseId: franchiseId,
        menuItem: item,
        customizations: const [],
        quantity: _qty,
        price: _unitPrice,
        specialInstructions: sizeNote,
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
                      final delta =
                          opt.upchargeBySize != null &&
                              _selectedSize != null &&
                              opt.upchargeBySize!.containsKey(_selectedSize)
                          ? opt.upchargeBySize![_selectedSize]
                          : opt.upcharge;
                      if (delta != null && delta != 0) {
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
            title: const Text('Line total (base size × qty)'),
            trailing: Text(
              '\$${_linePreview.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text('Modifier upcharges refined in Phase 4b'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signed in — cart write lands in Phase 6'),
                  ),
                );
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
