import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';

import '../../../core/constants/pos_permissions.dart';
import '../../../providers/pin_session_provider.dart';
import '../../session/force_repin_dialog.dart';
import '../order_line_ops.dart';

/// Large order workspace (P-OD-1 / P-OD-2).
/// Streams the order doc so voids update in place without closing.
class OrderDetailDialog extends StatelessWidget {
  final String franchiseId;
  final Order initialOrder;
  final String typeLabel;
  final String sourceLabel;
  final bool isClosed;

  /// Cash / Card / Split — from order doc `paymentMethod` (closed board).
  final String? paymentMethodLabel;

  /// Built from the **live** order each snapshot (pay amount, etc.).
  final List<Widget> Function(BuildContext context, Order liveOrder)?
  actionsBuilder;

  const OrderDetailDialog({
    super.key,
    required this.franchiseId,
    required this.initialOrder,
    required this.typeLabel,
    required this.sourceLabel,
    required this.isClosed,
    this.paymentMethodLabel,
    this.actionsBuilder,
  });

  static Future<void> show({
    required BuildContext context,
    required String franchiseId,
    required Order order,
    required String typeLabel,
    required String sourceLabel,
    required bool isClosed,
    String? paymentMethodLabel,
    List<Widget> Function(BuildContext context, Order liveOrder)?
    actionsBuilder,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => OrderDetailDialog(
        franchiseId: franchiseId,
        initialOrder: order,
        typeLabel: typeLabel,
        sourceLabel: sourceLabel,
        isClosed: isClosed,
        paymentMethodLabel: paymentMethodLabel,
        actionsBuilder: actionsBuilder,
      ),
    );
  }

  Stream<Order> _orderStream() {
    return FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .doc(initialOrder.id)
        .snapshots()
        .map((snap) {
          if (!snap.exists || snap.data() == null) {
            return initialOrder;
          }
          return Order.fromFirestore(snap.data()!, snap.id);
        });
  }

  static List<String> formatCustomizationLines(OrderItem item) {
    final out = <String>[];
    final c = item.customizations;
    if (c.isEmpty) return out;

    void addLabeled(String label, dynamic raw) {
      if (raw == null) return;
      if (raw is String && raw.trim().isNotEmpty) {
        out.add('$label: ${raw.trim()}');
        return;
      }
      if (raw is List && raw.isNotEmpty) {
        final parts = raw
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) out.add('$label: ${parts.join(', ')}');
        return;
      }
      if (raw is Map && raw.isNotEmpty) {
        final parts = <String>[];
        raw.forEach((k, v) {
          final ks = k.toString().trim();
          if (ks.isEmpty) return;
          if (v == true) {
            parts.add(ks);
          } else if (v != null && v.toString().trim().isNotEmpty) {
            parts.add('$ks: ${v.toString().trim()}');
          }
        });
        if (parts.isNotEmpty) out.add('$label: ${parts.join(', ')}');
      }
    }

    final size = item.size?.trim();
    if (size != null && size.isNotEmpty) {
      out.add('Size: $size');
    } else {
      addLabeled('Size', c['size']);
    }

    for (final key in ['Cook', 'cook', 'Crust', 'crust', 'Cut', 'cut']) {
      if (c.containsKey(key)) {
        final label = key[0].toUpperCase() + key.substring(1).toLowerCase();
        addLabeled(label, c[key]);
      }
    }

    addLabeled('Add-ons', c['selectedAddOns']);
    addLabeled('Ingredients', c['currentIngredients']);
    addLabeled('Cheeses', c['cheeses']);
    addLabeled('Sauces', c['sauces']);
    addLabeled('Dressings', c['dressings']);
    addLabeled('Sauce', c['sauce']);

    const skip = {
      'size',
      'Cook',
      'cook',
      'Crust',
      'crust',
      'Cut',
      'cut',
      'selectedAddOns',
      'currentIngredients',
      'cheeses',
      'sauces',
      'dressings',
      'sauce',
      'ingredientOptions',
      'cheeseOptions',
      'groupSelections',
      'voidedAddOns',
      'addonPrices',
    };
    c.forEach((k, v) {
      if (skip.contains(k)) return;
      if (v == null) return;
      if (v is bool) {
        if (v) out.add(k.toString());
        return;
      }
      if (v is String && v.trim().isNotEmpty) {
        out.add('$k: ${v.trim()}');
        return;
      }
      if (v is List && v.isNotEmpty) {
        out.add(
          '$k: ${v.map((e) => e.toString()).where((s) => s.isNotEmpty).join(', ')}',
        );
      }
    });

    return out;
  }

  static Set<String> nestedAddOnIds(OrderItem item) {
    final nestedIds = <String>{};
    final c = item.customizations;

    void takeList(dynamic raw) {
      if (raw is! List) return;
      for (final e in raw) {
        final s = e.toString().trim();
        if (s.isNotEmpty) nestedIds.add(s);
      }
    }

    takeList(c['selectedAddOns']);
    takeList(c['currentIngredients']);

    const skip = {
      'voidedAddOns',
      'addonPrices',
      'selectedAddOns',
      'currentIngredients',
      'size',
      'ingredientOptions',
      'cheeseOptions',
    };

    c.forEach((key, value) {
      if (skip.contains(key)) return;
      // POS: groupId -> [optionId, ...]
      takeList(value);
      // groupSelections-style maps
      if (value is Map) {
        value.forEach((_, v) => takeList(v));
      }
    });

    // Already voided add-ons should not appear as actionable
    final voided = c['voidedAddOns'];
    if (voided is List) {
      for (final e in voided) {
        nestedIds.remove(e.toString().trim());
      }
    }

    return nestedIds;
  }

  Future<bool> _ensureVoidPin(BuildContext context, String reason) async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    if (!session.hasPermission(PosPermissions.voidItem) &&
        !session.hasPermission(PosPermissions.voidOrder) &&
        !session.hasPermission(PosPermissions.managerOverride)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No void permission on this PIN')),
        );
      }
      return false;
    }
    if (session.requiresFreshPinFor(PosPermissions.voidItem) ||
        session.requiresFreshPinFor(PosPermissions.voidOrder)) {
      final pinned = await ForceRepinDialog.show(
        context,
        franchiseId: franchiseId,
        reasonLabel: reason,
      );
      return pinned == true;
    }
    return true;
  }

  Future<void> _onLineTapped(
    BuildContext context,
    Order liveOrder,
    int lineIndex,
  ) async {
    if (isClosed) return;
    if (lineIndex < 0 || lineIndex >= liveOrder.items.length) return;
    final item = liveOrder.items[lineIndex];
    if (!item.isActive) return;

    // Always open breakdown: qty + nested modifiers/add-ons.
    await showDialog<void>(
      context: context,
      builder: (ctx) => _LineBreakdownDialog(
        item: item,
        onVoidQty: (qty) async {
          Navigator.pop(ctx);
          await _applyPartialLineStatus(
            context,
            liveOrder,
            lineIndex,
            qty: qty,
            status: 'voided',
          );
        },
        onCompQty: (qty) async {
          Navigator.pop(ctx);
          await _applyPartialLineStatus(
            context,
            liveOrder,
            lineIndex,
            qty: qty,
            status: 'comped',
          );
        },
        onVoidAddOn: (addOnId) async {
          // Keep breakdown open so multiple add-ons can be voided.
          return _confirmAndVoidAddOn(
            context,
            liveOrder.id,
            lineIndex,
            addOnId,
          );
        },
      ),
    );
  }

  Future<void> _applyPartialLineStatus(
    BuildContext context,
    Order liveOrder,
    int lineIndex, {
    required int qty,
    required String status,
  }) async {
    if (lineIndex < 0 || lineIndex >= liveOrder.items.length) return;
    final item = liveOrder.items[lineIndex];
    if (!item.isActive) return;

    final label = status == 'voided' ? 'Void' : 'Comp';
    final okPin = await _ensureVoidPin(
      context,
      '$label ${qty}× ${item.name} on ${liveOrder.id}',
    );
    if (!okPin || !context.mounted) return;

    final session = Provider.of<PinSessionProvider>(context, listen: false);
    final now = DateTime.now().toIso8601String();

    final next = OrderLineOps.splitQuantityStatus(
      items: liveOrder.items,
      lineIndex: lineIndex,
      qty: qty,
      status: status,
      nowIso: now,
      staffId: session.staff?.id,
    );

    final priced = OrderLineOps.reprice(
      items: next,
      priorSubtotal: liveOrder.subtotal,
      priorTax: liveOrder.tax,
      discount: liveOrder.discount,
      deliveryFee: liveOrder.deliveryFee,
    );

    await OrderLineOps.writeItemsAndTotals(
      franchiseId: franchiseId,
      orderId: liveOrder.id,
      items: next,
      subtotal: priced.subtotal,
      tax: priced.tax,
      total: priced.total,
    );

    if (status == 'voided') {
      final restoredLine = OrderItem(
        menuItemId: item.menuItemId,
        name: item.name,
        price: item.price,
        quantity: qty.clamp(1, item.quantity),
        customizations: item.customizations,
      );
      final restoreKey =
          'void|${liveOrder.id}|${item.cartItemKey ?? lineIndex}|$qty|$now';
      try {
        await const InventoryFirestoreRepository().applySaleRestore(
          db: FirebaseFirestore.instance,
          franchiseId: franchiseId,
          orderId: liveOrder.id,
          items: [restoredLine],
          restoreKey: restoreKey,
        );
      } catch (e) {
        debugPrint('[POS] inventory restore skipped: $e');
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label ${qty}× ${item.name}')));
    }
  }

  /// Returns true if the add-on was voided (for breakdown UI to refresh).
  Future<bool> _confirmAndVoidAddOn(
    BuildContext context,
    String orderId,
    int lineIndex,
    String addOnId,
  ) async {
    if (isClosed) return false;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void add-on?'),
        content: Text(
          'Remove “$addOnId” from this line?\n\n'
          'Price reduces only when addonPrices[$addOnId] is present.',
        ),
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
    if (confirm != true || !context.mounted) return false;

    final okPin = await _ensureVoidPin(
      context,
      'Void add-on $addOnId on order $orderId',
    );
    if (!okPin || !context.mounted) return false;

    // Always read latest so sequential voids do not clobber each other.
    final snap = await FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .doc(orderId)
        .get();
    if (!snap.exists || snap.data() == null) return false;

    final latest = Order.fromFirestore(snap.data()!, snap.id);
    if (lineIndex < 0 || lineIndex >= latest.items.length) return false;
    final item = latest.items[lineIndex];
    if (!item.isActive) return false;

    final next = List<OrderItem>.from(latest.items);
    next[lineIndex] = OrderLineOps.removeNestedAddOn(item, addOnId);

    final priced = OrderLineOps.reprice(
      items: next,
      priorSubtotal: latest.subtotal,
      priorTax: latest.tax,
      discount: latest.discount,
      deliveryFee: latest.deliveryFee,
    );

    await OrderLineOps.writeItemsAndTotals(
      franchiseId: franchiseId,
      orderId: latest.id,
      items: next,
      subtotal: priced.subtotal,
      tax: priced.tax,
      total: priced.total,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed $addOnId from ${item.name}')),
      );
    }
    return true;
  }

  Future<void> _onClosedLineTapped(
    BuildContext context,
    Order liveOrder,
    int lineIndex,
  ) async {
    if (!isClosed) return;
    if (lineIndex < 0 || lineIndex >= liveOrder.items.length) return;
    final item = liveOrder.items[lineIndex];
    if (!item.isActive) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => _LineRefundDialog(
        item: item,
        onRefundQty: (qty) async {
          Navigator.pop(ctx);
          await _applyLineRefund(context, liveOrder.id, lineIndex, qty: qty);
        },
      ),
    );
  }

  Future<void> _applyLineRefund(
    BuildContext context,
    String orderId,
    int lineIndex, {
    required int qty,
  }) async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    if (!session.hasPermission(PosPermissions.refund) &&
        !session.hasPermission(PosPermissions.managerOverride)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No refund permission on this PIN')),
        );
      }
      return;
    }
    if (!session.hasPermission(PosPermissions.openDrawer)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Line refund cash requires open_drawer'),
          ),
        );
      }
      return;
    }

    if (session.requiresFreshPinFor(PosPermissions.refund)) {
      final pinned = await ForceRepinDialog.show(
        context,
        franchiseId: franchiseId,
        reasonLabel: 'Refund line on $orderId',
      );
      if (pinned != true) return;
    }
    if (!context.mounted) return;

    // Latest order — sequential refunds must not clobber.
    final snap = await FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .doc(orderId)
        .get();
    if (!snap.exists || snap.data() == null) return;
    final latest = Order.fromFirestore(snap.data()!, snap.id);
    final raw = snap.data()!;
    if (lineIndex < 0 || lineIndex >= latest.items.length) return;
    final item = latest.items[lineIndex];
    if (!item.isActive) return;

    final q = qty.clamp(1, item.quantity);
    final refundSlice = double.parse((item.price * q).toStringAsFixed(2));

    final now = DateTime.now().toIso8601String();
    final next = OrderLineOps.splitQuantityStatus(
      items: latest.items,
      lineIndex: lineIndex,
      qty: q,
      status: 'voided',
      nowIso: now,
      staffId: session.staff?.id,
    );
    // Mark reason as refund (split helper sets pos_line_void*)
    final adjusted = <OrderItem>[];
    for (final line in next) {
      if (line.isVoided &&
          (line.voidReason == 'pos_line_void' ||
              line.voidReason == 'pos_line_void_partial')) {
        adjusted.add(line.copyWith(voidReason: 'pos_line_refund'));
      } else {
        adjusted.add(line);
      }
    }

    final priced = OrderLineOps.reprice(
      items: adjusted,
      priorSubtotal: latest.subtotal,
      priorTax: latest.tax,
      discount: latest.discount,
      deliveryFee: latest.deliveryFee,
    );

    final priorRefund = (raw['refundAmount'] is num)
        ? (raw['refundAmount'] as num).toDouble()
        : 0.0;
    final newRefundTotal = double.parse(
      (priorRefund + refundSlice).toStringAsFixed(2),
    );

    await FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .doc(orderId)
        .set({
          'items': adjusted.map((e) => e.toMap()).toList(),
          'subtotal': priced.subtotal,
          'tax': priced.tax,
          'total': priced.total,
          'refundAmount': newRefundTotal,
          'refundMethod': 'cash',
          'refundedAt': now,
          if (session.staff?.id != null) 'refundedByStaffId': session.staff!.id,
          if (session.staff?.name != null)
            'refundedByStaffName': session.staff!.name,
          'timestamps.line_refunded': now,
          'timestamps.line_adjusted': now,
          // Full refund only when no active charge left
          if (priced.total <= 0.001) ...{
            'refunded': true,
            'refundStatus': 'refunded',
            'status': OrderStatus.cancelled,
            'timestamps.refunded': now,
            'timestamps.cancelled': now,
          },
        }, SetOptions(merge: true));

    final restoreKey =
        'refund|$orderId|${item.cartItemKey ?? lineIndex}|$q|$now';
    try {
      await const InventoryFirestoreRepository().applySaleRestore(
        db: FirebaseFirestore.instance,
        franchiseId: franchiseId,
        orderId: orderId,
        items: [
          OrderItem(
            menuItemId: item.menuItemId,
            name: item.name,
            price: item.price,
            quantity: q,
            customizations: item.customizations,
          ),
        ],
        restoreKey: restoreKey,
      );
    } catch (e) {
      debugPrint('[POS] inventory restore skipped: $e');
    }

    // ignore: avoid_print
    print(
      '[POS] cash drawer kick (mock) — line refund $orderId '
      '\$${refundSlice.toStringAsFixed(2)}',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Refunded ${q}× ${item.name} · \$${refundSlice.toStringAsFixed(2)} cash',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxH = MediaQuery.of(context).size.height * 0.85;
    final maxW = MediaQuery.of(context).size.width * 0.92;
    final dialogW = maxW.clamp(320.0, 720.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogW,
          maxHeight: maxH,
          minWidth: 320,
        ),
        child: StreamBuilder<Order>(
          stream: _orderStream(),
          initialData: initialOrder,
          builder: (context, snapshot) {
            final order = snapshot.data ?? initialOrder;
            final actions = actionsBuilder?.call(context, order) ?? const [];

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.userNameDisplay,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isClosed)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Chip(
                            label: const Text('CLOSED'),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    () {
                      final pay = paymentMethodLabel?.trim();
                      final payPart =
                          (pay != null && pay.isNotEmpty && pay != '—')
                          ? ' · ${pay.toUpperCase()}'
                          : '';
                      return '${order.status} · \$${order.total.toStringAsFixed(2)} · '
                          '$typeLabel · $sourceLabel$payPart';
                    }(),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  if (order.id.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        order.id,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      isClosed
                          ? 'Tap a line to refund qty (manager PIN)'
                          : 'Tap a line to void/comp qty or nested add-ons',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: order.items.isEmpty
                        ? Center(
                            child: Text(
                              'No line items on this order',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: order.items.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            itemBuilder: (context, index) {
                              final item = order.items[index];
                              final mods = formatCustomizationLines(item);
                              final lineTotal = item.effectiveLineTotal;
                              final muted = !item.isActive;
                              final textColor = muted
                                  ? scheme.onSurface.withValues(alpha: 0.45)
                                  : scheme.onSurface;

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  // Tap line body → void-line confirm (open only)
                                  onTap: item.isActive
                                      ? () => isClosed
                                            ? _onClosedLineTapped(
                                                context,
                                                order,
                                                index,
                                              )
                                            : _onLineTapped(
                                                context,
                                                order,
                                                index,
                                              )
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 4,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${item.quantity}×',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: textColor,
                                                decoration: item.isVoided
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                item.isComped
                                                    ? '${item.name} (COMP)'
                                                    : item.isVoided
                                                    ? '${item.name} (VOID)'
                                                    : item.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                  decoration: item.isVoided
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '\$${lineTotal.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: textColor,
                                                decoration: item.isVoided
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (item.isActive &&
                                            (item.price != item.totalPrice ||
                                                item.quantity > 1))
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 28,
                                              top: 2,
                                            ),
                                            child: Text(
                                              '\$${item.price.toStringAsFixed(2)} each',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        for (final line in mods)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 28,
                                              top: 2,
                                            ),
                                            child: Text(
                                              line,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  _TotalsRow(label: 'Subtotal', value: order.subtotal),
                  if (order.discount > 0)
                    _TotalsRow(label: 'Discount', value: -order.discount),
                  if (order.deliveryFee > 0)
                    _TotalsRow(label: 'Delivery', value: order.deliveryFee),
                  _TotalsRow(label: 'Tax', value: order.tax),
                  _TotalsRow(
                    label: 'Total',
                    value: order.total,
                    emphasize: true,
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 4),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxH * 0.28),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: actions,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasize;

  const _TotalsRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)
        : const TextStyle(fontSize: 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('\$${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}

/// Expand line: pick qty to void/comp + void each nested modifier/add-on.
class _LineBreakdownDialog extends StatefulWidget {
  final OrderItem item;
  final Future<void> Function(int qty) onVoidQty;
  final Future<void> Function(int qty) onCompQty;

  /// Return true when void succeeded so the list can drop that add-on.
  final Future<bool> Function(String addOnId) onVoidAddOn;

  const _LineBreakdownDialog({
    required this.item,
    required this.onVoidQty,
    required this.onCompQty,
    required this.onVoidAddOn,
  });

  @override
  State<_LineBreakdownDialog> createState() => _LineBreakdownDialogState();
}

class _LineBreakdownDialogState extends State<_LineBreakdownDialog> {
  late int _qty;
  late List<String> _nested;

  @override
  void initState() {
    super.initState();
    _qty = 1;
    _nested = OrderDetailDialog.nestedAddOnIds(widget.item).toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final scheme = Theme.of(context).colorScheme;
    final maxQty = item.quantity;

    return AlertDialog(
      title: Text(item.name),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Unit \$${item.price.toStringAsFixed(2)} · '
                'Line \$${item.totalPrice.toStringAsFixed(2)} · '
                'Qty on ticket: $maxQty',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'Quantity to void / comp',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: _qty > 1
                        ? () => setState(() => _qty -= 1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_qty',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: _qty < maxQty
                        ? () => setState(() => _qty += 1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  const Spacer(),
                  Text(
                    _qty >= maxQty ? 'Entire line' : 'Partial',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => widget.onCompQty(_qty),
                      child: Text('Comp $_qty'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => widget.onVoidQty(_qty),
                      child: Text('Void $_qty'),
                    ),
                  ),
                ],
              ),
              if (_nested.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  'Modifiers / add-ons',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Void removes that option. Dialog stays open until Close.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                for (final id in _nested)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(id),
                    trailing: TextButton(
                      onPressed: () async {
                        final ok = await widget.onVoidAddOn(id);
                        if (ok && mounted) {
                          setState(() => _nested.remove(id));
                        }
                      },
                      child: Text(
                        'Void',
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _LineRefundDialog extends StatefulWidget {
  final OrderItem item;
  final Future<void> Function(int qty) onRefundQty;

  const _LineRefundDialog({required this.item, required this.onRefundQty});

  @override
  State<_LineRefundDialog> createState() => _LineRefundDialogState();
}

class _LineRefundDialogState extends State<_LineRefundDialog> {
  late int _qty;

  @override
  void initState() {
    super.initState();
    _qty = 1;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final scheme = Theme.of(context).colorScheme;
    final maxQty = item.quantity;
    final slice = item.price * _qty;

    return AlertDialog(
      title: Text('Refund · ${item.name}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Unit \$${item.price.toStringAsFixed(2)} · '
              'Qty on ticket: $maxQty',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              'Quantity to refund',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _qty > 1 ? () => setState(() => _qty -= 1) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_qty',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: _qty < maxQty
                      ? () => setState(() => _qty += 1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const Spacer(),
                Text(
                  '\$${slice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => widget.onRefundQty(_qty),
              child: Text('Refund $_qty (cash)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
