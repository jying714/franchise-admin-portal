import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:shared_core/shared_core.dart';

/// P-OD-2: void line / void nested add-on and reprice order totals.
class OrderLineOps {
  OrderLineOps._();

  static double activeSubtotal(List<OrderItem> items) {
    var sum = 0.0;
    for (final i in items) {
      sum += i.effectiveLineTotal;
    }
    return sum;
  }

  /// Recompute tax proportional to prior tax/subtotal ratio when possible.
  static ({double subtotal, double tax, double total}) reprice({
    required List<OrderItem> items,
    required double priorSubtotal,
    required double priorTax,
    required double discount,
    required double deliveryFee,
  }) {
    final sub = activeSubtotal(items);
    double tax;
    if (priorSubtotal > 0.0001) {
      tax = priorTax * (sub / priorSubtotal);
    } else {
      tax = 0.0;
    }
    if (tax < 0) tax = 0;
    final total = sub - discount + tax + deliveryFee;
    return (
      subtotal: double.parse(sub.toStringAsFixed(2)),
      tax: double.parse(tax.toStringAsFixed(2)),
      total: double.parse(total.toStringAsFixed(2)),
    );
  }

  static Future<void> writeItemsAndTotals({
    required String franchiseId,
    required String orderId,
    required List<OrderItem> items,
    required double subtotal,
    required double tax,
    required double total,
  }) async {
    await FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .doc(orderId)
        .set({
          'items': items.map((e) => e.toMap()).toList(),
          'subtotal': subtotal,
          'tax': tax,
          'total': total,
          'timestamps.line_adjusted': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
  }

  /// B1: strip [addOnId] from any list-valued customization key
  /// (POS group maps, selectedAddOns, currentIngredients, etc.).
  static OrderItem removeNestedAddOn(OrderItem item, String addOnId) {
    final c = Map<String, dynamic>.from(item.customizations);
    final want = addOnId.trim();
    if (want.isEmpty) return item;

    bool stripList(String key) {
      final raw = c[key];
      if (raw is! List) return false;
      final next = raw
          .where((e) => e.toString().trim() != want)
          .toList(growable: false);
      if (next.length == raw.length) return false;
      c[key] = next;
      return true;
    }

    // Known mobile keys
    stripList('selectedAddOns');
    stripList('currentIngredients');

    // POS modifier shape: { groupId: [optionId, ...], ... }
    for (final key in c.keys.toList()) {
      if (key == 'voidedAddOns' ||
          key == 'addonPrices' ||
          key == 'selectedAddOns' ||
          key == 'currentIngredients') {
        continue;
      }
      stripList(key);
    }

    final voided = <String>[
      ...((c['voidedAddOns'] is List)
          ? (c['voidedAddOns'] as List).map((e) => e.toString().trim())
          : const <String>[]),
      want,
    ];
    c['voidedAddOns'] = voided.where((s) => s.isNotEmpty).toSet().toList();

    double newPrice = item.price;
    final prices = c['addonPrices'];
    if (prices is Map && prices[want] != null) {
      final p = (prices[want] is num)
          ? (prices[want] as num).toDouble()
          : double.tryParse(prices[want].toString()) ?? 0.0;
      newPrice = (item.price - p).clamp(0.0, double.infinity);
      final nextPrices = Map<String, dynamic>.from(prices);
      nextPrices.remove(want);
      c['addonPrices'] = nextPrices;
    }

    return item.copyWith(customizations: c, price: newPrice);
  }

  /// Split [voidQty] off an active line into a voided/comped sibling line.
  /// Returns updated items list (may grow by 1).
  static List<OrderItem> splitQuantityStatus({
    required List<OrderItem> items,
    required int lineIndex,
    required int qty,
    required String status, // voided | comped
    required String nowIso,
    String? staffId,
  }) {
    if (lineIndex < 0 || lineIndex >= items.length) return items;
    final item = items[lineIndex];
    if (!item.isActive) return items;
    final q = qty.clamp(1, item.quantity);
    final next = List<OrderItem>.from(items);

    if (q >= item.quantity) {
      // Whole line
      if (status == 'voided') {
        next[lineIndex] = item.copyWith(
          lineStatus: 'voided',
          voidedAt: nowIso,
          voidedByStaffId: staffId,
          voidReason: 'pos_line_void',
        );
      } else {
        next[lineIndex] = item.copyWith(
          lineStatus: 'comped',
          compedAt: nowIso,
          compReason: 'pos_line_comp',
          voidedByStaffId: staffId,
        );
      }
      return next;
    }

    // Keep remainder active; append status line for q units
    next[lineIndex] = item.copyWith(quantity: item.quantity - q);
    final split = item.copyWith(
      quantity: q,
      cartItemKey: item.cartItemKey == null
          ? null
          : '${item.cartItemKey}_$status$nowIso',
      lineStatus: status,
      voidedAt: status == 'voided' ? nowIso : item.voidedAt,
      voidedByStaffId: staffId,
      voidReason: status == 'voided'
          ? 'pos_line_void_partial'
          : item.voidReason,
      compedAt: status == 'comped' ? nowIso : item.compedAt,
      compReason: status == 'comped'
          ? 'pos_line_comp_partial'
          : item.compReason,
    );
    next.insert(lineIndex + 1, split);
    return next;
  }
}
