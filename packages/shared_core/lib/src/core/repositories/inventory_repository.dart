// packages/shared_core/lib/src/core/repositories/inventory_repository.dart
//
// Bounded-context repository for inventory ledger ops.
// Authority: docs/slices/bounded-context-repos-a4-inventory-labor.md (Phase A4)
// Wraps InventoryLedger — does not reimplement decrement/restore logic.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order.dart';

abstract class InventoryRepository {
  Future<void> applyAppendSaleDecrement({
    required FirebaseFirestore db,
    required String franchiseId,
    required String orderId,
    required List<OrderItem> items,
    required String decrementKey,
  });

  Future<void> applySaleDecrement({
    required FirebaseFirestore db,
    required String franchiseId,
    required String orderId,
    required List<OrderItem> items,
  });

  Future<void> applySaleRestore({
    required FirebaseFirestore db,
    required String franchiseId,
    required String orderId,
    required List<OrderItem> items,
    required String restoreKey,
  });
}
