// customer_web/lib/features/cart/cart_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import '../checkout/checkout_screen.dart';
import '../auth/sign_in_screen.dart';
import 'line_customization_summary.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../menu/menu_item_detail_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    this.embed = false,
    this.onCheckout,
    this.branded = false,
  });

  /// When true, mounted inside storefront home section (no route pop on close).
  final bool embed;

  /// When set (home embed), Checkout swaps section instead of Navigator.push.
  final VoidCallback? onCheckout;

  /// Modern sheet chrome: rounded cards + qty pill (franchise primary).
  final bool branded;

  Future<void> _editCartLine(
    BuildContext context, {
    required shared.OrderItem line,
    required String franchiseId,
  }) async {
    if (line.cartItemKey == null || line.cartItemKey!.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This line was added before edit support. Remove it and add again.',
            ),
          ),
        );
      }
      return;
    }
    final id = line.menuItemId.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot edit this line')));
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('menu_items')
          .doc(id)
          .get();
      if (!snap.exists || snap.data() == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item no longer available')),
          );
        }
        return;
      }
      final item = shared.MenuItem.fromFirestore(snap.data()!, snap.id);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Material(
                  color: Theme.of(dialogContext).colorScheme.surface,
                  child: MenuItemDetailScreen(
                    item: item,
                    initialQuantity: line.quantity,
                    cartItemKeyToReplace: line.cartItemKey,
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open editor: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Sign in to view your cart'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
                );
              },
              child: const Text('Sign in'),
            ),
          ],
        ),
      );
    }

    final fp = context.watch<shared.FranchiseProvider>();
    final fs = Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseId = fp.currentFranchiseId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: StreamBuilder<shared.Order?>(
            stream: fs.getCart(user.uid, franchiseId: franchiseId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Cart error: ${snapshot.error}'));
              }
              if (!snapshot.hasData &&
                  snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final cart = snapshot.data;
              final items = cart?.items ?? const <shared.OrderItem>[];

              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your cart is empty',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Browse the menu and add items to get started.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          },
                          child: const Text('Continue shopping'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              double subtotal = 0;
              for (final line in items) {
                subtotal += line.price * line.quantity;
              }

              final primary = Theme.of(context).colorScheme.primary;

              Future<void> setQty(int index, int quantity) async {
                final line = items[index];
                if (quantity < 1) return;
                final next = List<shared.OrderItem>.from(items);
                next[index] = line.copyWith(quantity: quantity);
                final sub = next.fold<double>(
                  0,
                  (s, i) => s + i.price * i.quantity,
                );
                await fs.updateCart(
                  cart!.copyWith(
                    items: next,
                    subtotal: sub,
                    total:
                        sub + (cart.tax) + (cart.deliveryFee) - (cart.discount),
                  ),
                );
              }

              Future<void> removeLine(int index) async {
                final line = items[index];
                final key = line.cartItemKey;
                if (key == null || key.isEmpty) {
                  final next = List<shared.OrderItem>.from(items)
                    ..removeAt(index);
                  final sub = next.fold<double>(
                    0,
                    (s, i) => s + i.price * i.quantity,
                  );
                  await fs.updateCart(
                    cart!.copyWith(
                      items: next,
                      subtotal: sub,
                      total:
                          sub +
                          (cart.tax) +
                          (cart.deliveryFee) -
                          (cart.discount),
                    ),
                  );
                  return;
                }
                await fs.removeFromCart(
                  user.uid,
                  key,
                  franchiseId: franchiseId,
                );
              }

              Widget lineTile(int index) {
                final line = items[index];
                final summary = lineCustomizationSummary(line);
                if (!branded) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(line.name),
                    subtitle: Text(
                      [
                        '\$${line.price.toStringAsFixed(2)} each',
                        summary,
                      ].where((s) => s.isNotEmpty).join('\n'),
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editCartLine(
                            context,
                            line: line,
                            franchiseId: franchiseId,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Decrease',
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: line.quantity <= 1
                              ? null
                              : () => setQty(index, line.quantity - 1),
                        ),
                        Text(
                          '${line.quantity}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        IconButton(
                          tooltip: 'Increase',
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setQty(index, line.quantity + 1),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '\$${(line.price * line.quantity).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => removeLine(index),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1A1A1A),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${line.price.toStringAsFixed(2)} each',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: const Color(0xFF6B6B6B),
                                        ),
                                  ),
                                  if (summary.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      summary,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF8A8A8A),
                                            height: 1.3,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              '\$${(line.price * line.quantity).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Decrease',
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: line.quantity <= 1
                                        ? null
                                        : () =>
                                              setQty(index, line.quantity - 1),
                                  ),
                                  Text(
                                    '${line.quantity}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Increase',
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: () =>
                                        setQty(index, line.quantity + 1),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _editCartLine(
                                context,
                                line: line,
                                franchiseId: franchiseId,
                              ),
                              child: const Text('Edit'),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () => removeLine(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => branded
                              ? const SizedBox.shrink()
                              : const Divider(),
                          itemBuilder: (context, index) => lineTile(index),
                        ),
                      ),
                      Material(
                        elevation: branded ? 0 : 4,
                        color: branded ? Colors.white : null,
                        child: Container(
                          decoration: branded
                              ? BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: const Color(0xFFEEEEEE),
                                    ),
                                  ),
                                )
                              : null,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Subtotal',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: branded
                                              ? FontWeight.w700
                                              : null,
                                        ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '\$${subtotal.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: branded ? primary : null,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () {
                                  if (onCheckout != null) {
                                    onCheckout!();
                                    return;
                                  }
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const CheckoutScreen(),
                                    ),
                                  );
                                },
                                style: branded
                                    ? FilledButton.styleFrom(
                                        backgroundColor: primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                        ),
                                      )
                                    : null,
                                child: const Text('Checkout'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
