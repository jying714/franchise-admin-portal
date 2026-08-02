import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';
import '../../core/constants/pos_permissions.dart';
import '../../providers/pin_session_provider.dart';
import '../session/force_repin_dialog.dart';
import '../dine_in/table_status.dart';
import 'widgets/order_detail_dialog.dart';
import '../../services/print_service.dart';

enum _OrderTypeFilter { all, dineIn, carryOut, delivery }

enum _DateRangePreset { today, last7, lastMonth, custom }

class ClosedOrdersScreen extends StatefulWidget {
  final String franchiseId;

  const ClosedOrdersScreen({super.key, required this.franchiseId});

  @override
  State<ClosedOrdersScreen> createState() => _ClosedOrdersScreenState();
}

class _ClosedOrdersScreenState extends State<ClosedOrdersScreen> {
  _OrderTypeFilter _filter = _OrderTypeFilter.all;
  _DateRangePreset _rangePreset = _DateRangePreset.today;
  DateTime? _customStart;
  DateTime? _customEnd;

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _docsStream() {
    return FirebaseFirestore.instance
        .collection('franchises')
        .doc(widget.franchiseId)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs);
  }

  bool _isPaid(Order order, Map<String, dynamic> raw) {
    final tsPaid = order.timestamps['paid'];
    if (tsPaid != null && tsPaid.toString().isNotEmpty) return true;
    final paidAt = raw['paidAt'];
    if (paidAt != null && paidAt.toString().isNotEmpty) return true;
    // POS cash close-out is terminal completed/delivered with a total.
    final s = order.status.trim().toLowerCase();
    if (s == OrderStatus.completed || s == OrderStatus.delivered) return true;
    return false;
  }

  bool _isRefunded(Order order, Map<String, dynamic> raw) {
    if (raw['refunded'] == true) return true;
    final amount = raw['refundAmount'];
    if (amount is num && amount > 0) return true;
    final rs = (order.refundStatus ?? raw['refundStatus'] as String? ?? '')
        .trim()
        .toLowerCase();
    return rs == 'refunded' || rs == 'full';
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

  String _paymentMethodLabel(Map<String, dynamic> raw) {
    final m = (raw['paymentMethod'] as String?)?.trim().toLowerCase() ?? '';
    if (m.isEmpty) {
      // Fallback: tenders array from PaymentScreen
      final tenders = raw['tenders'];
      if (tenders is List && tenders.isNotEmpty) {
        final methods = <String>{};
        for (final t in tenders) {
          if (t is Map && t['method'] != null) {
            methods.add(t['method'].toString().trim().toLowerCase());
          }
        }
        if (methods.length > 1) return 'Split';
        if (methods.contains('card')) return 'Card';
        if (methods.contains('cash')) return 'Cash';
      }
      return '—';
    }
    if (m == 'card') return 'Card';
    if (m == 'cash') return 'Cash';
    if (m == 'split') return 'Split';
    return m[0].toUpperCase() + m.substring(1);
  }

  Color _paymentMethodColor(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    switch (label.toLowerCase()) {
      case 'card':
        return scheme.primary;
      case 'cash':
        return scheme.tertiary;
      case 'split':
        return scheme.secondary;
      default:
        return scheme.outline;
    }
  }

  Color _sourceColor(BuildContext context, String source) {
    final scheme = Theme.of(context).colorScheme;
    switch (source.trim().toLowerCase()) {
      case 'pos':
        return scheme.primary;
      case 'web':
        return scheme.tertiary;
      case 'mobile':
      default:
        return scheme.secondary;
    }
  }

  String _sourceLabel(Order order) {
    final s = order.source.trim().toLowerCase();
    if (s.isEmpty) return 'mobile';
    return s;
  }

  bool _matchesType(Order order) {
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

  /// Inclusive local-day bounds for the active preset.
  (DateTime start, DateTime end) _rangeBounds() {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    switch (_rangePreset) {
      case _DateRangePreset.today:
        final start = DateTime(now.year, now.month, now.day);
        return (start, endOfToday);
      case _DateRangePreset.last7:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        return (start, endOfToday);
      case _DateRangePreset.lastMonth:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
        return (start, endOfToday);
      case _DateRangePreset.custom:
        final s = _customStart ?? DateTime(now.year, now.month, now.day);
        final e = _customEnd ?? endOfToday;
        final start = DateTime(s.year, s.month, s.day);
        final end = DateTime(e.year, e.month, e.day, 23, 59, 59, 999);
        return (start, end);
    }
  }

  bool _matchesDate(Order order) {
    final (start, end) = _rangeBounds();
    final t = order.timestamp;
    return !t.isBefore(start) && !t.isAfter(end);
  }

  String _rangeButtonLabel() {
    switch (_rangePreset) {
      case _DateRangePreset.today:
        return 'Today';
      case _DateRangePreset.last7:
        return 'Last 7 days';
      case _DateRangePreset.lastMonth:
        return 'Last month';
      case _DateRangePreset.custom:
        if (_customStart != null && _customEnd != null) {
          String fmt(DateTime d) =>
              '${d.month}/${d.day}/${d.year.toString().substring(2)}';
          return '${fmt(_customStart!)}–${fmt(_customEnd!)}';
        }
        return 'Custom';
    }
  }

  Future<void> _openDateRangeMenu() async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    final position = (box != null && overlay != null)
        ? RelativeRect.fromRect(
            Rect.fromPoints(
              box.localToGlobal(
                Offset(box.size.width - 8, 56),
                ancestor: overlay,
              ),
              box.localToGlobal(
                box.size.bottomRight(Offset.zero),
                ancestor: overlay,
              ),
            ),
            Offset.zero & overlay.size,
          )
        : const RelativeRect.fromLTRB(16, 80, 16, 16);

    final picked = await showMenu<_DateRangePreset>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem(value: _DateRangePreset.today, child: Text('Today')),
        PopupMenuItem(
          value: _DateRangePreset.last7,
          child: Text('Last 7 days'),
        ),
        PopupMenuItem(
          value: _DateRangePreset.lastMonth,
          child: Text('Last month'),
        ),
        PopupMenuItem(
          value: _DateRangePreset.custom,
          child: Text('Custom date range'),
        ),
      ],
    );
    if (picked == null || !mounted) return;

    if (picked == _DateRangePreset.custom) {
      await _pickCustomRange();
      return;
    }
    setState(() {
      _rangePreset = picked;
      _customStart = null;
      _customEnd = null;
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    DateTime start = _customStart ?? DateTime(now.year, now.month, now.day);
    DateTime end = _customEnd ?? DateTime(now.year, now.month, now.day);

    final result = await showDialog<(DateTime, DateTime)>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Custom date range'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Start'),
                      subtitle: Text(
                        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: start,
                          firstDate: DateTime(now.year - 2),
                          lastDate: endOfDay(now),
                        );
                        if (d != null) {
                          setLocal(() {
                            start = d;
                            if (end.isBefore(start)) end = start;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('End'),
                      subtitle: Text(
                        '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: end.isBefore(start) ? start : end,
                          firstDate: start,
                          lastDate: endOfDay(now),
                        );
                        if (d != null) setLocal(() => end = d);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, (start, end)),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;
    setState(() {
      _rangePreset = _DateRangePreset.custom;
      _customStart = result.$1;
      _customEnd = result.$2;
    });
  }

  /// Local calendar end-of-day helper for pickers.
  static DateTime endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  Future<void> _showActions(
    BuildContext context,
    Order order,
    Map<String, dynamic> raw,
  ) async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    final scheme = Theme.of(context).colorScheme;
    final paid = _isPaid(order, raw);
    final refunded = _isRefunded(order, raw);
    final canRefundPerm = session.hasPermission(PosPermissions.refund);
    final canRefund = paid && !refunded && canRefundPerm;

    await OrderDetailDialog.show(
      context: context,
      franchiseId: widget.franchiseId,
      order: order,
      typeLabel: _typeLabel(_normalizeType(order)),
      sourceLabel: _sourceLabel(order),
      isClosed: true,
      paymentMethodLabel: _paymentMethodLabel(raw),
      actionsBuilder: (ctx, liveOrder) {
        final scheme = Theme.of(ctx).colorScheme;
        final paid = _isPaid(liveOrder, raw);
        final refunded = _isRefunded(liveOrder, raw);
        final canRefundPerm = session.hasPermission(PosPermissions.refund);
        final canRefund = paid && !refunded && canRefundPerm;

        return <Widget>[
          _ClosedActionRow(
            icon: Icons.receipt_long_outlined,
            label: 'Print guest check',
            color: scheme.onSurface,
            onTap: () async {
              final ok = await const PrintService().printCustomerReceipt(
                order: liveOrder,
                amountTendered: liveOrder.total,
                changeDue: 0,
                paymentMethod: refunded ? 'REFUNDED' : 'CLOSED',
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
          _ClosedActionRow(
            icon: Icons.print_outlined,
            label: 'Reprint kitchen ticket',
            color: scheme.onSurface,
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
          _ClosedActionRow(
            icon: Icons.replay,
            label: 'Refund',
            color: canRefund
                ? scheme.error
                : scheme.onSurface.withValues(alpha: 0.38),
            onTap: () async {
              Navigator.pop(ctx);
              if (!paid) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order is not paid — cannot refund'),
                    ),
                  );
                }
                return;
              }
              if (refunded) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order already refunded')),
                  );
                }
                return;
              }
              if (!canRefundPerm) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No refund permission on this PIN'),
                    ),
                  );
                }
                return;
              }
              await _runRefund(context, liveOrder);
            },
          ),
        ];
      },
    );
  }

  Future<void> _runRefund(BuildContext context, Order order) async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);

    if (session.requiresFreshPinFor(PosPermissions.refund)) {
      final pinned = await ForceRepinDialog.show(
        context,
        franchiseId: widget.franchiseId,
        reasonLabel: 'Refund order ${order.id}',
      );
      if (pinned != true) return;
    }

    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refund order?'),
        content: Text(
          'Refund \$${order.total.toStringAsFixed(2)} cash for ${order.id}?\n\n'
          'Skeleton: full cash refund only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Refund cash'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _refundCash(order);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Refunded \$${order.total.toStringAsFixed(2)} cash · ${order.id}',
        ),
      ),
    );
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
          'status': OrderStatus.cancelled,
          'refunded': true,
          'refundStatus': 'refunded',
          'refundAmount': order.total,
          'refundMethod': 'cash',
          'refundedAt': now.toIso8601String(),
          if (staffId != null) 'refundedByStaffId': staffId,
          if (staffName != null) 'refundedByStaffName': staffName,
          'timestamps.refunded': now.toIso8601String(),
          'timestamps.cancelled': now.toIso8601String(),
        }, SetOptions(merge: true));

    // ignore: avoid_print
    print(
      '[POS] cash drawer kick (mock) — refund ${order.id} '
      '\$${order.total.toStringAsFixed(2)}',
    );

    final t = _normalizeType(order);
    if (t == 'dine_in') {
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
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Closed orders')),
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
                    onTap: () => setState(() => _filter = _OrderTypeFilter.all),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterButton(
                    label: 'Dine-in',
                    selected: _filter == _OrderTypeFilter.dineIn,
                    onTap: () =>
                        setState(() => _filter = _OrderTypeFilter.dineIn),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterButton(
                    label: 'Carry-out',
                    selected: _filter == _OrderTypeFilter.carryOut,
                    onTap: () =>
                        setState(() => _filter = _OrderTypeFilter.carryOut),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterButton(
                    label: 'Delivery',
                    selected: _filter == _OrderTypeFilter.delivery,
                    onTap: () =>
                        setState(() => _filter = _OrderTypeFilter.delivery),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: _openDateRangeMenu,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.date_range,
                            size: 18,
                            color: scheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _rangeButtonLabel(),
                            style: TextStyle(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              stream: _docsStream(),
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

                final rows = <({Order order, Map<String, dynamic> raw})>[];
                for (final doc in snapshot.data!) {
                  final raw = doc.data();
                  final order = Order.fromFirestore(raw, doc.id);
                  if (!OrderStatus.isTerminal(order.status)) continue;
                  if (!_matchesType(order)) continue;
                  if (!_matchesDate(order)) continue;
                  rows.add((order: order, raw: raw));
                }

                if (rows.isEmpty) {
                  return Center(
                    child: Text(
                      'No closed orders',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final order = row.order;
                    final refunded = _isRefunded(order, row.raw);
                    final payLabel = _paymentMethodLabel(row.raw);
                    final sourceLabel = _sourceLabel(order);
                    return Card(
                      child: ListTile(
                        title: Text(order.userNameDisplay),
                        subtitle: Text(
                          '${order.status} · ${_typeLabel(_normalizeType(order))} · '
                          '\$${order.total.toStringAsFixed(2)}'
                          '${refunded ? ' · REFUNDED' : ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        trailing: Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(
                              label: Text(
                                sourceLabel.toUpperCase(),
                                style: TextStyle(
                                  color: scheme.onPrimary,
                                  fontSize: 11,
                                ),
                              ),
                              backgroundColor: _sourceColor(
                                context,
                                sourceLabel,
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            if (payLabel != '—')
                              Chip(
                                label: Text(
                                  payLabel.toUpperCase(),
                                  style: TextStyle(
                                    color: scheme.onPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                                backgroundColor: _paymentMethodColor(
                                  context,
                                  payLabel,
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        onTap: () => _showActions(context, order, row.raw),
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
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
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
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClosedActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ClosedActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
