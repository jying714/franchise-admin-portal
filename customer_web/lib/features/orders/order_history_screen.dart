// customer_web/lib/features/orders/order_history_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

import '../../widgets/branding_shell.dart';
import '../auth/sign_in_screen.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    if (user == null) {
      return BrandingShell(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sign in to view orders'),
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
      child: StreamBuilder<List<shared.Order>>(
        stream: fs.getOrdersForUser(user.uid, franchiseId: franchiseId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Orders error: ${snapshot.error}'));
          }
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = (snapshot.data ?? const <shared.Order>[])
              .where((o) => o.status != 'cart')
              .toList();

          if (orders.isEmpty) {
            return const Center(child: Text('No past orders yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final order = orders[index];
              final when = order.timestamp;
              final whenLabel =
                  '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')} '
                  '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
              final itemCount = order.items.fold<int>(
                0,
                (s, i) => s + i.quantity,
              );

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  order.status.isNotEmpty ? order.status : 'Order',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '$whenLabel · $itemCount item(s)'
                  '${order.source != null && order.source!.isNotEmpty ? ' · ${order.source}' : ''}',
                ),
                trailing: Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
