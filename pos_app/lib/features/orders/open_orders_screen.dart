import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../payments/payment_screen.dart';
import '../../core/constants/pos_permissions.dart';
import '../../providers/pin_session_provider.dart';
import 'package:provider/provider.dart';

class OpenOrdersScreen extends StatelessWidget {
  final String franchiseId;

  const OpenOrdersScreen({super.key, required this.franchiseId});

  Stream<List<Order>> _ordersStream() {
    // Prefer franchise-scoped orders collection used by the rest of the platform.
    // Path: franchises/{id}/orders
    return FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => Order.fromFirestore(d.data(), d.id))
              .where((o) => OrderStatus.isOnOpenBoard(o.status))
              .toList();
          return list;
        });
  }

  Future<void> _showOrderActions(BuildContext context, Order order) async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    final scheme = Theme.of(context).colorScheme;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(order.userNameDisplay),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${order.status} · \$${order.total.toStringAsFixed(2)} · ${_sourceLabel(order)}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                _ActionRow(
                  icon: Icons.payments_outlined,
                  label: 'Take payment',
                  enabled: session.hasPermission(PosPermissions.takePayment),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    final paid = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => PaymentScreen(
                          franchiseId: franchiseId,
                          orderId: order.id,
                          amountDue: order.total,
                        ),
                      ),
                    );
                    if (paid == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Order ${order.id} paid')),
                      );
                    }
                  },
                ),
                _ActionRow(
                  icon: Icons.check_circle_outline,
                  label: 'Mark ready',
                  enabled: session.hasPermission(PosPermissions.takeOrder),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await _updateStatus(order.id, OrderStatus.ready);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked ready')),
                      );
                    }
                  },
                ),
                _ActionRow(
                  icon: Icons.undo,
                  label: 'Void order',
                  enabled: session.hasPermission(PosPermissions.voidOrder),
                  destructive: true,
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Void order?'),
                        content: Text('Void ${order.id}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Void'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await _updateStatus(order.id, OrderStatus.cancelled);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order voided')),
                        );
                      }
                    }
                  },
                ),
                _ActionRow(
                  icon: Icons.replay,
                  label: 'Refund',
                  enabled: session.hasPermission(PosPermissions.refund),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Refund — implement with payment records',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateStatus(String orderId, String status) async {
    await FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .doc(orderId)
        .set({
          'status': status,
          'timestamps.$status': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
  }

  String _sourceLabel(Order order) {
    final s = order.source.trim().toLowerCase();
    if (s.isEmpty) return 'mobile';
    return s;
  }

  Color _sourceColor(BuildContext context, String source) {
    final scheme = Theme.of(context).colorScheme;
    switch (source) {
      case 'pos':
        return scheme.primary;
      case 'web':
        return scheme.tertiary;
      case 'mobile':
      default:
        return scheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Open orders')),
      body: StreamBuilder<List<Order>>(
        stream: _ordersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load orders.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return Center(
              child: Text(
                'No open orders',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final order = orders[index];
              final source = _sourceLabel(order);
              return Card(
                child: ListTile(
                  title: Text(
                    order.userNameDisplay,
                    style: TextStyle(color: scheme.onSurface),
                  ),
                  subtitle: Text(
                    '${order.status} · \$${order.total.toStringAsFixed(2)} · ${order.deliveryType}',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  trailing: Chip(
                    label: Text(
                      source.toUpperCase(),
                      style: TextStyle(color: scheme.onPrimary, fontSize: 11),
                    ),
                    backgroundColor: _sourceColor(context, source),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  onTap: () => _showOrderActions(context, order),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool destructive;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : destructive
        ? scheme.error
        : scheme.onSurface;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(color: color, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
