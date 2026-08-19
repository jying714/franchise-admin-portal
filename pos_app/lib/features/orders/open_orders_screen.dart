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
import '../../services/print_service.dart';
import 'widgets/order_detail_dialog.dart';
import '../ordering/order_entry_screen.dart';
import '../../services/drawer_service.dart';

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

  /// Pilot: one mock kitchen ticket per order id per station session.
  final Set<String> _kitchenTicketPrintedIds = <String>{};

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

  bool _isOnlineSource(Order order) {
    final s = order.source.trim().toLowerCase();
    return s == 'mobile' || s == 'web';
  }

  Future<void> _maybeAutoKitchenTicket(List<Order> orders) async {
    for (final order in orders) {
      if (_kitchenTicketPrintedIds.contains(order.id)) continue;
      if (!_isOnlineSource(order)) continue;
      if (order.status.trim().toLowerCase() != OrderStatus.sentToKitchen) {
        continue;
      }

      _kitchenTicketPrintedIds.add(order.id);
      try {
        final snap = await FirebaseFirestore.instance
            .collection('franchises')
            .doc(widget.franchiseId)
            .collection('orders')
            .doc(order.id)
            .get();
        final tableLabel = snap.data()?['tableLabel'] as String?;
        await const PrintService().printKitchenTicket(
          order: order,
          tableLabel: tableLabel,
          isAppend: false,
        );
        // ignore: avoid_print
        print('[POS] auto kitchen ticket (online) ${order.id}');
      } catch (e) {
        // Allow retry on next snapshot if print failed before commit to set.
        _kitchenTicketPrintedIds.remove(order.id);
        debugPrint('[POS] auto kitchen ticket failed ${order.id}: $e');
      }
    }
  }

  Future<void> _showOrderActions(BuildContext context, Order order) async {
    final isDelivery = _normalizeType(order) == 'delivery';

    await OrderDetailDialog.show(
      context: context,
      franchiseId: widget.franchiseId,
      order: order,
      typeLabel: _typeLabel(_normalizeType(order)),
      sourceLabel: _sourceLabel(order),
      isClosed: false,
      actionsBuilder: (ctx, liveOrder) {
        final session = Provider.of<PinSessionProvider>(ctx, listen: false);
        return <Widget>[
          _ActionRow(
            icon: Icons.add_circle_outline,
            label: 'Add item',
            enabled: session.hasPermission(PosPermissions.takeOrder),
            onTap: () async {
              // Keep order detail open underneath; stream will refresh lines.
              final type = _normalizeType(liveOrder);
              await Navigator.of(context, rootNavigator: true).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => OrderEntryScreen(
                    franchiseId: widget.franchiseId,
                    orderType: type,
                    existingOrderId: liveOrder.id,
                  ),
                ),
              );
            },
          ),
          _ActionRow(
            icon: Icons.receipt_long_outlined,
            label: 'Print guest check',
            enabled: true,
            onTap: () async {
              // Detail stays open
              final ok = await const PrintService().printCustomerReceipt(
                order: liveOrder,
                amountTendered: 0,
                changeDue: 0,
                paymentMethod: 'CHECK',
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Guest check printed (mock) · ${liveOrder.id}'
                        : 'Guest check print failed',
                  ),
                ),
              );
            },
          ),
          _ActionRow(
            icon: Icons.print_outlined,
            label: 'Reprint kitchen ticket',
            enabled: session.hasPermission(PosPermissions.takeOrder),
            onTap: () async {
              String? tableLabel;
              try {
                final snap = await FirebaseFirestore.instance
                    .collection('franchises')
                    .doc(widget.franchiseId)
                    .collection('orders')
                    .doc(liveOrder.id)
                    .get();
                tableLabel = snap.data()?['tableLabel'] as String?;
              } catch (_) {}
              final ok = await const PrintService().printKitchenTicket(
                order: liveOrder,
                tableLabel: tableLabel,
                isAppend: false,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Kitchen ticket reprinted (mock) · ${liveOrder.id}'
                        : 'Kitchen ticket print failed',
                  ),
                ),
              );
            },
          ),
          // Delivery: cash close-out only after return (pending_till).
          // Non-delivery: normal take payment.
          if (!isDelivery ||
              liveOrder.status.trim().toLowerCase() == OrderStatus.pendingTill)
            _ActionRow(
              icon: Icons.payments_outlined,
              label: isDelivery ? 'Close out (cash)' : 'Take payment',
              enabled:
                  session.hasPermission(PosPermissions.takePayment) &&
                  (isDelivery
                      ? session.hasPermission(PosPermissions.openDrawer)
                      : true),
              onTap: () async {
                Navigator.pop(ctx);

                final isDriver =
                    session.staff?.role.trim().toLowerCase() == 'driver';
                final canOverride = session.hasPermission(
                  PosPermissions.managerOverride,
                );

                Set<String> methods;
                if (!isDelivery) {
                  methods = const {'cash', 'split', 'card'};
                } else if (canOverride && !isDriver) {
                  methods = const {'cash', 'split', 'card'};
                } else {
                  methods = const {'cash'};
                }

                final paid = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => PaymentScreen(
                      franchiseId: widget.franchiseId,
                      orderId: liveOrder.id,
                      amountDue: liveOrder.total,
                      closeOutOrder: true,
                      statusWhenPaid: isDelivery
                          ? OrderStatus.delivered
                          : OrderStatus.sentToKitchen,
                      allowedMethods: methods,
                    ),
                  ),
                );
                if (paid == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isDelivery
                            ? 'Delivery ${liveOrder.id} closed (cash)'
                            : 'Order ${liveOrder.id} paid',
                      ),
                    ),
                  );
                }
              },
            ),
          _ActionRow(
            icon: Icons.soup_kitchen_outlined,
            label: 'Send to kitchen',
            enabled: session.hasPermission(PosPermissions.takeOrder),
            onTap: () async {
              Navigator.pop(ctx);
              await _sendToKitchen(liveOrder);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Order ${liveOrder.id} sent to kitchen · ticket (mock)',
                    ),
                  ),
                );
              }
            },
          ),
          _ActionRow(
            icon: Icons.check_circle_outline,
            label: 'Mark ready',
            enabled: session.hasPermission(PosPermissions.takeOrder),
            onTap: () async {
              Navigator.pop(ctx);
              await _updateStatus(liveOrder.id, OrderStatus.ready);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Marked ready')));
              }
            },
          ),
          _ActionRow(
            icon: Icons.undo,
            label: 'Void order',
            enabled: session.hasPermission(PosPermissions.voidOrder),
            destructive: true,
            onTap: () async {
              Navigator.pop(ctx);

              if (session.requiresFreshPinFor(PosPermissions.voidOrder)) {
                final pinned = await ForceRepinDialog.show(
                  context,
                  franchiseId: widget.franchiseId,
                  reasonLabel: 'Void order ${liveOrder.id}',
                );
                if (pinned != true) return;
              }

              if (!context.mounted) return;
              final ok = await showDialog<bool>(
                context: context,
                builder: (dCtx) => AlertDialog(
                  title: const Text('Void order?'),
                  content: Text('Void ${liveOrder.id}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dCtx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dCtx, true),
                      child: const Text('Void'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await _updateStatus(liveOrder.id, OrderStatus.cancelled);
                if (PrintService.kitchenHasTicket(liveOrder.status)) {
                  try {
                    await const PrintService().printKitchenVoid(
                      order: liveOrder,
                    );
                  } catch (e) {
                    debugPrint('[POS] kitchen VOID on order void skipped: $e');
                  }
                }
                if (_normalizeType(liveOrder) == 'dine_in') {
                  try {
                    final snap = await FirebaseFirestore.instance
                        .collection('franchises')
                        .doc(widget.franchiseId)
                        .collection('orders')
                        .doc(liveOrder.id)
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Order voided')));
                }
              }
            },
          ),
          if (isDelivery &&
              liveOrder.status.trim().toLowerCase() !=
                  OrderStatus.outForDelivery &&
              liveOrder.status.trim().toLowerCase() != OrderStatus.pendingTill)
            _ActionRow(
              icon: Icons.delivery_dining,
              label: session.staff?.role.trim().toLowerCase() == 'driver'
                  ? 'Accept & deliver'
                  : 'Assign driver',
              enabled:
                  (session.staff?.role.trim().toLowerCase() == 'driver') ||
                  session.hasPermission(PosPermissions.takeOrder) ||
                  session.hasPermission(PosPermissions.managerOverride),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await DriverAssignSheet.show(
                  context,
                  franchiseId: widget.franchiseId,
                  orderId: liveOrder.id,
                );
                if (ok && context.mounted) {
                  final asDriver =
                      Provider.of<PinSessionProvider>(
                        context,
                        listen: false,
                      ).staff?.role.trim().toLowerCase() ==
                      'driver';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        asDriver
                            ? 'In route — order ${liveOrder.id}'
                            : 'Driver assigned — in route',
                      ),
                    ),
                  );
                }
              },
            ),
          if (isDelivery &&
              liveOrder.status.trim().toLowerCase() ==
                  OrderStatus.outForDelivery)
            _ActionRow(
              icon: Icons.home_outlined,
              label: 'Returned (mark delivered)',
              enabled:
                  (session.staff?.role.trim().toLowerCase() == 'driver') ||
                  session.hasPermission(PosPermissions.takeOrder) ||
                  session.hasPermission(PosPermissions.managerOverride),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('Mark delivered?'),
                    content: Text(
                      'Close delivery ${liveOrder.id}'
                      '${liveOrder.userNameDisplay.isNotEmpty ? ' for ${liveOrder.userNameDisplay}' : ''}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dCtx, true),
                        child: const Text('Delivered'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  final paid = _isPaid(liveOrder);
                  if (paid) {
                    await _updateStatus(liveOrder.id, OrderStatus.delivered);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked delivered')),
                      );
                    }
                  } else {
                    await _updateStatus(liveOrder.id, OrderStatus.pendingTill);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Returned — use Close out (cash) to finish',
                          ),
                        ),
                      );
                    }
                  }
                }
              },
            ),

          _ActionRow(
            icon: Icons.replay,
            label: 'Refund',
            enabled: session.hasPermission(PosPermissions.refund),
            destructive: true,
            onTap: () async {
              Navigator.pop(ctx);

              if (!_isPaid(liveOrder)) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Order is not paid — use Void instead of Refund',
                    ),
                  ),
                );
                return;
              }

              if (session.requiresFreshPinFor(PosPermissions.refund)) {
                final pinned = await ForceRepinDialog.show(
                  context,
                  franchiseId: widget.franchiseId,
                  reasonLabel: 'Refund order ${liveOrder.id}',
                );
                if (pinned != true) return;
              }

              if (!context.mounted) return;
              final ok = await showDialog<bool>(
                context: context,
                builder: (dCtx) => AlertDialog(
                  title: const Text('Refund order?'),
                  content: Text(
                    'Refund \$${liveOrder.total.toStringAsFixed(2)} cash '
                    'for ${liveOrder.id}?\n\n'
                    'Skeleton: full cash refund only. '
                    'Card reverse comes with Terminal.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dCtx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dCtx, true),
                      child: const Text('Refund cash'),
                    ),
                  ],
                ),
              );
              if (ok != true) return;

              await _refundCash(liveOrder);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Refunded \$${liveOrder.total.toStringAsFixed(2)} cash · ${liveOrder.id}',
                  ),
                ),
              );
            },
          ),
        ];
      },
    );
  }

  bool _isPaid(Order order) {
    final paidAt = order.timestamps['paid'];
    if (paidAt != null && paidAt.toString().isNotEmpty) return true;
    // Fall back: prepaid write paths set timestamps.paid
    return false;
  }

  Future<void> _sendToKitchen(Order order) async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    if (!session.hasPermission(PosPermissions.takeOrder)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No take_order permission')));
      return;
    }

    await _updateStatus(order.id, OrderStatus.sentToKitchen);

    try {
      // tableLabel is POS merge-only; read raw if present
      final snap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(widget.franchiseId)
          .collection('orders')
          .doc(order.id)
          .get();
      final tableLabel = snap.data()?['tableLabel'] as String?;

      await const PrintService().printKitchenTicket(
        order: order,
        tableLabel: tableLabel,
        isAppend: false,
      );
    } catch (e) {
      // Status already updated — print must not roll it back.
      debugPrint('[POS] kitchen ticket on board send skipped: $e');
    }
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

  Future<void> _refundCash(Order order) async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    if (!session.hasPermission(PosPermissions.refund)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No refund permission')));
      return;
    }
    if (!session.hasPermission(PosPermissions.openDrawer)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refund cash requires open_drawer permission'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final staffId = session.staff?.id;
    final staffName = session.staff?.name;

    await FirebaseFirestore.instance
        .collection('franchises')
        .doc(widget.franchiseId)
        .collection('orders')
        .doc(order.id)
        .set({
          // Terminal — leaves open board (same family as void).
          'status': OrderStatus.cancelled,
          'refunded': true,
          'refundAmount': order.total,
          'refundMethod': 'cash',
          'refundedAt': now.toIso8601String(),
          if (staffId != null) 'refundedByStaffId': staffId,
          if (staffName != null) 'refundedByStaffName': staffName,
          'timestamps.refunded': now.toIso8601String(),
          'timestamps.cancelled': now.toIso8601String(),
        }, SetOptions(merge: true));

    await const DrawerService().openDrawer(
      reason: 'refund ${order.id} \$${order.total.toStringAsFixed(2)}',
    );

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
      } catch (_) {
        // Refund already committed.
      }
    }
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

                // Online intake: mobile/web already sent_to_kitchen → ticket once.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _maybeAutoKitchenTicket(snapshot.data ?? const <Order>[]);
                });

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
