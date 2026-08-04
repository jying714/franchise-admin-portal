import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';

/// Franchise-scoped on-hand decrement for tracked menu items only.
/// Idempotent per order via `inventoryDecremented` on the order doc (INV I4).
class InventoryLedger {
  InventoryLedger._();

  /// Call once after tender/paid is committed.
  /// Untracked items are skipped. Never goes below 0.
  static Future<void> applySaleDecrement({
    required FirebaseFirestore db,
    required String franchiseId,
    required String orderId,
    required List<OrderItem> items,
  }) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        orderId.isEmpty ||
        items.isEmpty) {
      return;
    }

    final orderRef = db
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .doc(orderId);

    await db.runTransaction((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) return;
      final orderData = orderSnap.data();
      if (orderData == null) return;
      if (orderData['inventoryDecremented'] == true) return;

      // Aggregate qty by menuItemId (same item on multiple lines).
      final qtyById = <String, int>{};
      for (final line in items) {
        final id = line.menuItemId.trim();
        if (id.isEmpty) continue;
        final q = line.quantity;
        if (q <= 0) continue;
        qtyById[id] = (qtyById[id] ?? 0) + q;
      }

      for (final entry in qtyById.entries) {
        final menuRef = db
            .collection('franchises')
            .doc(franchiseId)
            .collection('menu_items')
            .doc(entry.key);
        final menuSnap = await tx.get(menuRef);
        if (!menuSnap.exists) continue;
        final data = menuSnap.data();
        if (data == null) continue;
        if (data['inventoryTracked'] != true) continue;

        final current = (data['stockCount'] as num?)?.toInt() ?? 0;
        final next = current - entry.value;
        tx.update(menuRef, {
          'stockCount': next < 0 ? 0 : next,
        });
      }

      tx.set(
        orderRef,
        {
          'inventoryDecremented': true,
          'inventoryDecrementedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  /// Restore on-hand for void/refund lines after a prior sale decrement.
  /// Idempotent via order field `inventoryRestoredKeys` (array of restoreKey).
  static Future<void> applySaleRestore({
    required FirebaseFirestore db,
    required String franchiseId,
    required String orderId,
    required List<OrderItem> items,
    required String restoreKey,
  }) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        orderId.isEmpty ||
        items.isEmpty ||
        restoreKey.trim().isEmpty) {
      return;
    }

    final orderRef = db
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .doc(orderId);

    await db.runTransaction((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) return;
      final orderData = orderSnap.data();
      if (orderData == null) return;

      // Only reverse stock if this order actually decremented on pay.
      if (orderData['inventoryDecremented'] != true) return;

      final priorKeys = <String>[];
      final rawKeys = orderData['inventoryRestoredKeys'];
      if (rawKeys is List) {
        for (final k in rawKeys) {
          final s = k.toString().trim();
          if (s.isNotEmpty) priorKeys.add(s);
        }
      }
      if (priorKeys.contains(restoreKey)) return;

      final qtyById = <String, int>{};
      for (final line in items) {
        final id = line.menuItemId.trim();
        if (id.isEmpty) continue;
        final q = line.quantity;
        if (q <= 0) continue;
        qtyById[id] = (qtyById[id] ?? 0) + q;
      }
      if (qtyById.isEmpty) return;

      for (final entry in qtyById.entries) {
        final menuRef = db
            .collection('franchises')
            .doc(franchiseId)
            .collection('menu_items')
            .doc(entry.key);
        final menuSnap = await tx.get(menuRef);
        if (!menuSnap.exists) continue;
        final data = menuSnap.data();
        if (data == null) continue;
        if (data['inventoryTracked'] != true) continue;

        final current = (data['stockCount'] as num?)?.toInt() ?? 0;
        tx.update(menuRef, {
          'stockCount': current + entry.value,
        });
      }

      tx.set(
        orderRef,
        {
          'inventoryRestoredKeys': FieldValue.arrayUnion([restoreKey]),
          'inventoryRestoredAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}
