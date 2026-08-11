// packages/shared_core/lib/src/core/repositories/inventory_firestore_repository.dart
//
// Thin adapter over InventoryLedger static API. Zero behavior change.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order.dart';
import '../services/inventory_ledger.dart';
import 'inventory_repository.dart';

class InventoryFirestoreRepository implements InventoryRepository {
  const InventoryFirestoreRepository();

  @override
  Future<void> applyAppendSaleDecrement({
    required FirebaseFirestore db,
    required String franchiseId,
    required String orderId,
    required List<OrderItem> items,
    required String decrementKey,
  }) {
    return InventoryLedger.applyAppendSaleDecrement(
      db: db,
      franchiseId: franchiseId,
      orderId: orderId,
      items: items,
      decrementKey: decrementKey,
    );
  }

  @override
  Future<void> applySaleDecrement({
    required FirebaseFirestore db,
    required String franchiseId,
    required String orderId,
    required List<OrderItem> items,
  }) {
    return InventoryLedger.applySaleDecrement(
      db: db,
      franchiseId: franchiseId,
      orderId: orderId,
      items: items,
    );
  }

  @override
  Future<void> applySaleRestore({
    required FirebaseFirestore db,
    required String franchiseId,
    required String orderId,
    required List<OrderItem> items,
    required String restoreKey,
  }) {
    return InventoryLedger.applySaleRestore(
      db: db,
      franchiseId: franchiseId,
      orderId: orderId,
      items: items,
      restoreKey: restoreKey,
    );
  }
}
