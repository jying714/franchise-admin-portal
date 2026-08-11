// packages/shared_core/lib/src/core/repositories/order_repository.dart
//
// Bounded-context repository for cart + orders (Order-as-cart).
// Authority: docs/slices/bounded-context-repos-v1.md (Phase A3)
// Signatures mirror FirestoreService — zero behavior change.

import '../models/order.dart';
import '../models/menu_item.dart';
import '../models/customization.dart';

abstract class OrderRepository {
  // --- Cart ---
  Stream<Order?> getCart(String userId, {String? franchiseId});

  Future<void> updateCart(Order cart);

  Future<void> addToCart({
    required String userId,
    required String franchiseId,
    required MenuItem menuItem,
    required List<Customization> customizations,
    required int quantity,
    required double price,
    String? specialInstructions,
  });

  Future<void> removeFromCart(String userId, String cartItemKey,
      {String? franchiseId});

  Stream<int> getCartItemCountStream(String userId, {String? franchiseId});

  Future<void> clearCart(String userId, {String? franchiseId});

  // --- Orders ---
  Future<void> addOrder(Order order);

  Stream<List<Order>> getOrdersForUser(String userId,
      {String? franchiseId, int limit = 20});

  Future<void> updateOrderStatus(
      String franchiseId, String orderId, String newStatus);

  Future<void> refundOrder(String franchiseId, String orderId,
      {double? amount, String? refundReason});

  Stream<List<Order>> getAllOrdersStream(String franchiseId);

  Stream<List<Order>> getOrders({String? userId, String? franchiseId});
}
