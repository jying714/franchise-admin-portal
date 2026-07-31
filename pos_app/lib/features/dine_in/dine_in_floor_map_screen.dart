import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';

import '../../core/constants/pos_permissions.dart';
import '../../providers/pin_session_provider.dart';
import '../ordering/order_entry_screen.dart';
import '../payments/payment_screen.dart';
import '../session/force_repin_dialog.dart';
import 'table_pick_sheet.dart';
import 'table_status.dart';

/// Full-screen dine-in floor plan. Free = green, seated/other = red.
class DineInFloorMapScreen extends StatefulWidget {
  final String franchiseId;

  const DineInFloorMapScreen({super.key, required this.franchiseId});

  @override
  State<DineInFloorMapScreen> createState() => _DineInFloorMapScreenState();
}

class _DineInFloorMapScreenState extends State<DineInFloorMapScreen> {
  final _posFs = PosFirestoreService();

  Stream<PosTableLayout> _layoutStream() =>
      _posFs.streamTableLayout(widget.franchiseId);

  bool _isFree(PosTableNode t) => t.status.trim().toLowerCase() == 'free';

  Future<Order?> _openOrderForTable(String tableId) async {
    final snap = await FirebaseFirestore.instance
        .collection('franchises')
        .doc(widget.franchiseId)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .limit(80)
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['tableId'] != tableId) continue;
      final order = Order.fromFirestore(data, doc.id);
      if (OrderStatus.isOnOpenBoard(order.status)) return order;
    }
    return null;
  }

  Future<void> _onTableTap(PosTableNode table) async {
    final label = table.label.isNotEmpty ? table.label : table.id;

    if (!_isFree(table)) {
      final order = await _openOrderForTable(table.id);
      if (!mounted) return;
      if (order == null) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(label),
            content: const Text(
              'Table is marked seated but no open order was found.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        return;
      }
      await _showSeatedTableActions(table: table, order: order);
      return;
    }

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Seat $label?'),
        content: Text(
          '${table.seats} seats · Start a dine-in ticket for this table?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open ticket'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderEntryScreen(
          franchiseId: widget.franchiseId,
          orderType: 'dine_in',
          tableId: table.id,
          tableLabel: label,
        ),
      ),
    );
  }

  Future<void> _showSeatedTableActions({
    required PosTableNode table,
    required Order order,
  }) async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    final scheme = Theme.of(context).colorScheme;
    final label = table.label.isNotEmpty ? table.label : table.id;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(label),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${order.userNameDisplay}\n'
                  '${order.status} · \$${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                _MapActionRow(
                  icon: Icons.add_circle_outline,
                  label: 'Add items',
                  enabled: session.hasPermission(PosPermissions.takeOrder),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OrderEntryScreen(
                          franchiseId: widget.franchiseId,
                          orderType: 'dine_in',
                          tableId: table.id,
                          tableLabel: label,
                          existingOrderId: order.id,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _MapActionRow(
                  icon: Icons.swap_horiz,
                  label: 'Move table',
                  enabled:
                      session.hasPermission(PosPermissions.takeOrder) ||
                      session.hasPermission(PosPermissions.managerOverride),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await _moveTable(order: order, fromTable: table);
                  },
                ),
                _MapActionRow(
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
                          closeOutOrder: true,
                        ),
                      ),
                    );
                    if (paid == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Order ${order.id} paid')),
                      );
                    }
                  },
                ),
                _MapActionRow(
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
                    if (!mounted) return;
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Void order?'),
                        content: Text('Void ${order.id} and free $label?'),
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
                      await FirebaseFirestore.instance
                          .collection('franchises')
                          .doc(widget.franchiseId)
                          .collection('orders')
                          .doc(order.id)
                          .set({
                            'status': OrderStatus.cancelled,
                            'timestamps.cancelled': DateTime.now()
                                .toIso8601String(),
                          }, SetOptions(merge: true));
                      await setTableStatus(
                        franchiseId: widget.franchiseId,
                        tableId: table.id,
                        status: 'free',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order voided')),
                        );
                      }
                    }
                  },
                ),
                _MapActionRow(
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
                    if (!mounted) return;
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

  Future<void> _moveTable({
    required Order order,
    required PosTableNode fromTable,
  }) async {
    final pick = await TablePickSheet.show(
      context,
      franchiseId: widget.franchiseId,
    );
    if (pick == null || !mounted) return;
    if (pick.tableId == fromTable.id) return;

    await FirebaseFirestore.instance
        .collection('franchises')
        .doc(widget.franchiseId)
        .collection('orders')
        .doc(order.id)
        .set({
          'tableId': pick.tableId,
          'tableLabel': pick.tableLabel,
        }, SetOptions(merge: true));

    await setTableStatus(
      franchiseId: widget.franchiseId,
      tableId: fromTable.id,
      status: 'free',
    );
    await setTableStatus(
      franchiseId: widget.franchiseId,
      tableId: pick.tableId,
      status: 'seated',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Moved to ${pick.tableLabel}')));
  }

  Future<void> _fallbackList() async {
    final table = await TablePickSheet.show(
      context,
      franchiseId: widget.franchiseId,
    );
    if (table == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderEntryScreen(
          franchiseId: widget.franchiseId,
          orderType: 'dine_in',
          tableId: table.tableId,
          tableLabel: table.tableLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dine-in'),
        actions: [
          // Live stream updates colors; button left as a soft rebuild kick.
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'List tables',
            onPressed: _fallbackList,
            icon: const Icon(Icons.list),
          ),
        ],
      ),
      body: StreamBuilder<PosTableLayout>(
        stream: _layoutStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load table layout',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final layout = snapshot.data!;
          if (layout.tables.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No tables in layout.\n'
                      'Configure franchises/${widget.franchiseId}/config/table_layout',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _fallbackList,
                      child: const Text('Open list picker'),
                    ),
                  ],
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                panEnabled: true,
                scaleEnabled: true,
                boundaryMargin: const EdgeInsets.all(64),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: layout.canvasWidth,
                      height: layout.canvasHeight,
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: Size(layout.canvasWidth, layout.canvasHeight),
                            painter: _GridPainter(
                              lineColor: scheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          ...layout.tables.map((t) {
                            final free = _isFree(t);
                            final color = free
                                ? Colors.green.shade600
                                : Colors.red.shade600;
                            final tableLabel = t.label.isNotEmpty
                                ? t.label
                                : t.id;
                            return Positioned(
                              left: t.x,
                              top: t.y,
                              width: t.width,
                              height: t.height,
                              child: Material(
                                color: color,
                                shape: t.shape == 'round'
                                    ? const CircleBorder()
                                    : RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                elevation: 2,
                                child: InkWell(
                                  customBorder: t.shape == 'round'
                                      ? const CircleBorder()
                                      : RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                  onTap: () => _onTableTap(t),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Text(
                                        tableLabel,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color lineColor;

  _GridPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

class _MapActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool destructive;
  final VoidCallback onTap;

  const _MapActionRow({
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
