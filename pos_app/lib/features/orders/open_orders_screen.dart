import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';
import '../delivery/driver_assign_sheet.dart';
import '../../core/constants/pos_permissions.dart';
import '../../providers/pin_session_provider.dart';
import '../payments/payment_screen.dart';
import '../session/force_repin_dialog.dart';
import '../dine_in/table_status.dart';

enum _OrderTypeFilter { all, dineIn, carryOut, delivery }

class OpenOrdersScreen extends StatefulWidget {
  final String franchiseId;

  const OpenOrdersScreen({super.key, required this.franchiseId});

  @override
  State<OpenOrdersScreen> createState() => _OpenOrdersScreenState();
}

class _OpenOrdersScreenState extends State<OpenOrdersScreen> {
  late _OrderTypeFilter _filter;
  late final bool _driverLocked;

  @override
  void initState() {
    super.initState();
    final role =
        Provider.of<PinSessionProvider>(
          context,
          listen: false,
        ).staff?.role.trim().toLowerCase() ??
        '';
    _driverLocked = role == 'driver';
    _filter = _driverLocked ? _OrderTypeFilter.delivery : _OrderTypeFilter.all;
  }

  Stream<List<Order>> _ordersStream() {
    return FirebaseFirestore.instance
        .collection('franchises')
        .doc(widget.franchiseId)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((d) => Order.fromFirestore(d.data(), d.id))
              .where((o) => OrderStatus.isOnOpenBoard(o.status))
              .toList();
        });
  }

  String _normalizeType(Order order) {
    final t = order.deliveryType.trim().toLowerCase();
    if (t == 'dine_in' || t == 'dine-in' || t == 'dinein') return 'dine_in';
    if (t == 'delivery') return 'delivery';
    if (t == 'carryout' ||
        t == 'carry-out' ||
        t == 'carry_out' ||
        t == 'takeout') {
      return 'carryout';
    }
    return t.isEmpty ? 'carryout' : t;
  }

  String _typeLabel(String normalized) {
    switch (normalized) {
      case 'dine_in':
        return 'Dine-in';
      case 'delivery':
        return 'Delivery';
      case 'carryout':
        return 'Carry-out';
      default:
        return normalized;
    }
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.pendingTill:
        return 'Pending till';
      case OrderStatus.sentToKitchen:
        return 'Sent to kitchen';
      case OrderStatus.open:
        return 'Open';
      case OrderStatus.ready:
        return 'Ready';
      default:
        return status;
    }
  }

  bool _matchesFilter(Order order) {
    if (_filter == _OrderTypeFilter.all) return true;
    final t = _normalizeType(order);
    switch (_filter) {
      case _OrderTypeFilter.dineIn:
        return t == 'dine_in';
      case _OrderTypeFilter.carryOut:
        return t == 'carryout';
      case _OrderTypeFilter.delivery:
        return t == 'delivery';
      case _OrderTypeFilter.all:
        return true;
    }
  }

  String _rowSubtitle(Order order, String typeLabel) {
    final parts = <String>[
      typeLabel,
      _statusLabel(order.status),
      '\$${order.total.toStringAsFixed(2)}',
    ];
    if (_normalizeType(order) == 'delivery') {
      final addr = order.deliveryAddress;
      if (addr != null && addr.street.trim().isNotEmpty) {
        parts.add(addr.street.trim());
      }
    }
    // tableLabel is merge-only today; show via timestamps/name fallback later.
    // Prefer deliveryAddress-style once Order maps tableLabel.
    return parts.join(' · ');
  }

  Future<void> _showOrderActions(BuildContext context, Order order) async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    final scheme = Theme.of(context).colorScheme;
    final isDelivery = _normalizeType(order) == 'delivery';
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
                  '${order.status} · \$${order.total.toStringAsFixed(2)} · '
                  '${_typeLabel(_normalizeType(order))} · ${_sourceLabel(order)}',
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
                          franchiseId: widget.franchiseId,
                          orderId: order.id,
                          amountDue: order.total,
                          closeOutOrder: !isDelivery,
                          statusWhenPaid: OrderStatus.sentToKitchen,
                          allowedMethods: isDelivery
                              ? const {'card'}
                              : const {'cash', 'split', 'card'},
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

                    if (session.requiresFreshPinFor(PosPermissions.voidOrder)) {
                      final pinned = await ForceRepinDialog.show(
                        context,
                        franchiseId: widget.franchiseId,
                        reasonLabel: 'Void order ${order.id}',
                      );
                      if (pinned != true) return;
                    }

                    if (!context.mounted) return;
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
                      if (_normalizeType(order) == 'dine_in') {
                        try {
                          final snap = await FirebaseFirestore.instance
                              .collection('franchises')
                              .doc(widget.franchiseId)
                              .collection('orders')
                              .doc(order.id)
                              .get();
                          final tableId = snap.data()?['tableId'] as String?;
                          if (tableId != null && tableId.isNotEmpty) {
                            await setTableStatus(
                              franchiseId: widget.franchiseId,
                              tableId: tableId,
                              status: 'free',
                            );
                          }
                        } catch (_) {}
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order voided')),
                        );
                      }
                    }
                  },
                ),
                if (isDelivery)
                  _ActionRow(
                    icon: Icons.delivery_dining,
                    label: 'Assign / deliver',
                    enabled:
                        (session.staff?.role.trim().toLowerCase() ==
                            'driver') ||
                        session.hasPermission(PosPermissions.takeOrder) ||
                        session.hasPermission(PosPermissions.managerOverride),
                    onTap: () async {
                      Navigator.pop(dialogContext);
                      final ok = await DriverAssignSheet.show(
                        context,
                        franchiseId: widget.franchiseId,
                        orderId: order.id,
                      );
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Driver assigned')),
                        );
                      }
                    },
                  ),
                if (isDelivery)
                  _ActionRow(
                    icon: Icons.home_outlined,
                    label: 'Mark delivered',
                    enabled:
                        (session.staff?.role.trim().toLowerCase() ==
                            'driver') ||
                        session.hasPermission(PosPermissions.takeOrder) ||
                        session.hasPermission(PosPermissions.managerOverride),
                    onTap: () async {
                      Navigator.pop(dialogContext);
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Mark delivered?'),
                          content: Text(
                            'Close delivery ${order.id}'
                            '${order.userNameDisplay.isNotEmpty ? ' for ${order.userNameDisplay}' : ''}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delivered'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        final paid = _isPaid(order);
                        if (paid) {
                          await _updateStatus(order.id, OrderStatus.delivered);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Marked delivered')),
                            );
                          }
                        } else {
                          // COD: food delivered, cash still owed to till
                          await _updateStatus(
                            order.id,
                            OrderStatus.pendingTill,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Delivered — close till when cash is in drawer',
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                if (isDelivery &&
                    order.status.trim().toLowerCase() ==
                        OrderStatus.pendingTill)
                  _ActionRow(
                    icon: Icons.point_of_sale,
                    label: 'Close till (cash)',
                    enabled:
                        session.hasPermission(PosPermissions.takePayment) &&
                        session.hasPermission(PosPermissions.openDrawer),
                    onTap: () async {
                      Navigator.pop(dialogContext);
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Close till?'),
                          content: Text(
                            'Record \$${order.total.toStringAsFixed(2)} cash '
                            'into the till for ${order.id}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Cash in till'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await _closeTillCash(order);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Till closed — delivery complete'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                _ActionRow(
                  icon: Icons.replay,
                  label: 'Refund',
                  enabled: session.hasPermission(PosPermissions.refund),
                  onTap: () async {
                    Navigator.pop(dialogContext);

                    if (session.requiresFreshPinFor(PosPermissions.refund)) {
                      final pinned = await ForceRepinDialog.show(
                        context,
                        franchiseId: widget.franchiseId,
                        reasonLabel: 'Refund order ${order.id}',
                      );
                      if (pinned != true) return;
                    }

                    if (!context.mounted) return;
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

  bool _isPaid(Order order) {
    final paidAt = order.timestamps['paid'];
    if (paidAt != null && paidAt.toString().isNotEmpty) return true;
    // Fall back: prepaid write paths set timestamps.paid
    return false;
  }

  Future<void> _updateStatus(String orderId, String status) async {
    await FirebaseFirestore.instance
        .collection('franchises')
        .doc(widget.franchiseId)
        .collection('orders')
        .doc(orderId)
        .set({
          'status': status,
          'timestamps.$status': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
  }

  Future<void> _closeTillCash(Order order) async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    if (!session.hasPermission(PosPermissions.takePayment) ||
        !session.hasPermission(PosPermissions.openDrawer)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Till close needs take_payment + open_drawer'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    await FirebaseFirestore.instance
        .collection('franchises')
        .doc(widget.franchiseId)
        .collection('orders')
        .doc(order.id)
        .set({
          'status': OrderStatus.delivered,
          'paymentMethod': 'cash',
          'amountTendered': order.total,
          'changeDue': 0,
          'amountDueAtPay': order.total,
          'paidAt': now.toIso8601String(),
          'tillClosedAt': now.toIso8601String(),
          'timestamps.paid': now.toIso8601String(),
          'timestamps.delivered': now.toIso8601String(),
          'timestamps.till_closed': now.toIso8601String(),
        }, SetOptions(merge: true));

    // ignore: avoid_print
    print('[POS] cash drawer kick (mock) — delivery till close ${order.id}');
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: _FilterButton(
                    label: 'All',
                    selected: _filter == _OrderTypeFilter.all,
                    enabled: !_driverLocked,
                    onTap: () => setState(() => _filter = _OrderTypeFilter.all),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterButton(
                    label: 'Dine-in',
                    selected: _filter == _OrderTypeFilter.dineIn,
                    enabled: !_driverLocked,
                    onTap: () =>
                        setState(() => _filter = _OrderTypeFilter.dineIn),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterButton(
                    label: 'Carry-out',
                    selected: _filter == _OrderTypeFilter.carryOut,
                    enabled: !_driverLocked,
                    onTap: () =>
                        setState(() => _filter = _OrderTypeFilter.carryOut),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterButton(
                    label: 'Delivery',
                    selected: _filter == _OrderTypeFilter.delivery,
                    enabled: true,
                    onTap: () =>
                        setState(() => _filter = _OrderTypeFilter.delivery),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Order>>(
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

                final orders = snapshot.data!
                    .where(_matchesFilter)
                    .toList(growable: false);

                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      'No open orders',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final source = _sourceLabel(order);
                    final typeLabel = _typeLabel(_normalizeType(order));
                    return Card(
                      child: ListTile(
                        title: Text(
                          order.userNameDisplay,
                          style: TextStyle(color: scheme.onSurface),
                        ),
                        subtitle: Text(
                          _rowSubtitle(order, typeLabel),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        trailing: Chip(
                          label: Text(
                            source.toUpperCase(),
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontSize: 11,
                            ),
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
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = !enabled
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.45)
        : selected
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final fg = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : selected
        ? scheme.onPrimary
        : scheme.onSurface;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontWeight: selected && enabled
                  ? FontWeight.w600
                  : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
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
