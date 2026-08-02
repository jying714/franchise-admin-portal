// customer_web/lib/features/cart/cart_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import '../checkout/checkout_screen.dart';
import '../../widgets/branding_shell.dart';
import '../auth/sign_in_screen.dart';

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
            return const Center(child: Text('Your cart is empty'));
          }

          double subtotal = 0;
          for (final line in items) {
            subtotal += line.price * line.quantity;
          }

          return Column(
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
                        '\$${line.price.toStringAsFixed(2)} each'
                        '${line.specialInstructions != null && line.specialInstructions!.isNotEmpty ? ' · ${line.specialInstructions}' : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('×${line.quantity}'),
                          const SizedBox(width: 8),
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
                                // Fallback: clear line via updateCart
                                final next = List<shared.OrderItem>.from(items)
                                  ..removeAt(index);
                                await fs.updateCart(
                                  cart!.copyWith(items: next),
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
          );
        },
      ),
    );
  }
}
