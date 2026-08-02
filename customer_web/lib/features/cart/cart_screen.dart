// customer_web/lib/features/cart/cart_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import '../checkout/checkout_screen.dart';
import '../../widgets/branding_shell.dart';
import '../auth/sign_in_screen.dart';

String _lineCustomizationSummary(shared.OrderItem line) {
  final raw = line.customizations;
  if (raw == null || raw.isEmpty) {
    final si = line.specialInstructions;
    if (si != null && si.isNotEmpty) return si;
    return '';
  }

  final groups = raw['groups'];
  if (groups is! List || groups.isEmpty) {
    final si = line.specialInstructions;
    if (si != null && si.isNotEmpty) return si;
    return '';
  }

  final parts = <String>[];
  for (final e in groups) {
    if (e is! Map) continue;
    final m = Map<String, dynamic>.from(e);
    final name = (m['name'] ?? '').toString();
    if (name.isEmpty) continue;
    final group = (m['group'] ?? '').toString();
    final price = (m['price'] is num) ? (m['price'] as num).toDouble() : 0.0;
    final label = group.isNotEmpty ? '$group: $name' : name;
    if (price > 0) {
      parts.add('$label (+\$${price.toStringAsFixed(2)})');
    } else {
      parts.add(label);
    }
  }
  return parts.join(' · ');
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    if (user == null) {
      return BrandingShell(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sign in to view your cart'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SignInScreen(),
                    ),
                  );
                },
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final fp = context.watch<shared.FranchiseProvider>();
    final fs = Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseId = fp.currentFranchiseId;

    return BrandingShell(
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final line = items[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(line.name),
                          subtitle: Text(
                            [
                              '\$${line.price.toStringAsFixed(2)} each',
                              _lineCustomizationSummary(line),
                            ].where((s) => s.isNotEmpty).join('\n'),
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Decrease',
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: line.quantity <= 1
                                    ? null
                                    : () async {
                                        final next =
                                            List<shared.OrderItem>.from(items);
                                        final q = line.quantity - 1;
                                        next[index] = line.copyWith(
                                          quantity: q,
                                        );
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
                                      },
                              ),
                              Text(
                                '${line.quantity}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              IconButton(
                                tooltip: 'Increase',
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () async {
                                  final next = List<shared.OrderItem>.from(
                                    items,
                                  );
                                  next[index] = line.copyWith(
                                    quantity: line.quantity + 1,
                                  );
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
                                },
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '\$${(line.price * line.quantity).toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              IconButton(
                                tooltip: 'Remove',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final key = line.cartItemKey;
                                  if (key == null || key.isEmpty) {
                                    final next = List<shared.OrderItem>.from(
                                      items,
                                    )..removeAt(index);
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
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Material(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Subtotal',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Spacer(),
                              Text(
                                '\$${subtotal.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const CheckoutScreen(),
                                ),
                              );
                            },
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
    );
  }
}
