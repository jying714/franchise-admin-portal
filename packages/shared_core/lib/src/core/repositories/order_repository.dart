// packages/shared_core/lib/src/core/repositories/order_repository.dart
//
// Bounded-context repository for orders + cart (Order-as-cart).
// Authority: docs/slices/bounded-context-repos-v1.md (Phase A3)
// Does not replace FirestoreService; call sites migrate gradually.

import '../models/order.dart'; // adjust if Order path differs

abstract class OrderRepository {
  // --- Cart (status == 'cart') ---
  Future<Order?> getCart(String franchiseId, String userId);
  Future<void> updateCart(String franchiseId, String userId, Order cart);
  Future<void> addToCart(
    String franchiseId,
    String userId,
    Map<String, dynamic> line, {
    String? menuItemId,
  });
  Future<void> removeFromCart(
    String franchiseId,
    String userId,
    String lineId,
  );
  Future<void> clearCart(String franchiseId, String userId);
  Stream<int> getCartItemCountStream(String franchiseId, String userId);

  // --- Orders ---
  Future<void> addOrder(String franchiseId, Order order);
  Future<void> updateOrderStatus(
    String franchiseId,
    String orderId,
    String status, {
    Map<String, dynamic>? extra,
  });
  Stream<List<Order>> getOrdersForUser(String franchiseId, String userId);
  Stream<List<Order>> getAllOrdersStream(String franchiseId);
}
