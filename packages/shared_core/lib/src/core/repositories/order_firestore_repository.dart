// packages/shared_core/lib/src/core/repositories/order_firestore_repository.dart
//
// Concrete OrderRepository. Phase A3.2: cart + core order methods.
// Bodies moved from FirestoreServiceImpl (same logic, same paths).
// Authority: docs/slices/bounded-context-repos-v1.md

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import '../models/order.dart';
import '../models/menu_item.dart';
import '../models/customization.dart';
import '../utils/error_logger.dart';
import 'order_repository.dart';

class OrderFirestoreRepository implements OrderRepository {
  OrderFirestoreRepository({firestore.FirebaseFirestore? db})
      : _db = db ?? firestore.FirebaseFirestore.instance;

  final firestore.FirebaseFirestore _db;

  String get _carts => 'carts';
  String get _orders => 'orders';

  firestore.CollectionReference<Map<String, dynamic>> _franchiseCollection(
    String franchiseId,
    String name,
  ) =>
      _db.collection('franchises').doc(franchiseId).collection(name);

  bool _badFranchise(String? franchiseId) =>
      franchiseId == null ||
      franchiseId.isEmpty ||
      franchiseId == 'unknown' ||
      franchiseId == 'default';

  @override
  Stream<Order?> getCart(String userId, {String? franchiseId}) {
    if (userId.isEmpty || _badFranchise(franchiseId)) {
      return Stream.value(null);
    }

    return _franchiseCollection(franchiseId!, _carts)
        .doc(userId)
        .snapshots()
        .map(
      (doc) {
        if (!doc.exists || doc.data() == null) {
          return null;
        }
        final data = {...doc.data()!, 'status': 'cart'};
        return Order.fromFirestore(data, doc.id);
      },
    );
  }

  @override
  Future<void> updateCart(Order cart) async {
    final franchiseId = cart.storeId;
    if (_badFranchise(franchiseId)) return;

    try {
      await _franchiseCollection(franchiseId, _carts).doc(cart.userId).set({
        ...cart.toFirestore(),
        'status': 'cart',
        'updatedAt': firestore.FieldValue.serverTimestamp(),
      }, firestore.SetOptions(merge: true));
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to updateCart',
        source: 'OrderFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'userId': cart.userId},
      );
    }
  }

  @override
  Future<void> addToCart({
    required String userId,
    required String franchiseId,
    required MenuItem menuItem,
    required Map<String, dynamic> customizations,
    required int quantity,
    required double price,
    String? specialInstructions,
  }) async {
    if (_badFranchise(franchiseId)) return;

    try {
      final cartRef = _franchiseCollection(franchiseId, _carts).doc(userId);
      final cartDoc = await cartRef.get();

      Order current;
      if (cartDoc.exists && cartDoc.data() != null) {
        current = Order.fromFirestore(
            {...cartDoc.data()!, 'status': 'cart'}, cartDoc.id);
      } else {
        current = Order(
          id: userId,
          userId: userId,
          storeId: franchiseId,
          items: [],
          subtotal: 0,
          tax: 0,
          deliveryFee: 0,
          discount: 0,
          total: 0,
          deliveryType: 'pickup',
          time: '',
          status: 'cart',
          timestamp: DateTime.now(),
          estimatedTime: 30,
          timestamps: {},
        );
      }

      final newItem = OrderItem(
        menuItemId: menuItem.id,
        name: menuItem.name,
        price: price,
        quantity: quantity,
        customizations: Map<String, dynamic>.from(customizations),
        specialInstructions: specialInstructions,
        image: menuItem.image,
        cartItemKey: '${DateTime.now().microsecondsSinceEpoch}_${menuItem.id}',
      );

      final updatedItems = [...current.items, newItem];
      final newSubtotal =
          updatedItems.fold(0.0, (sum, i) => sum + i.price * i.quantity);

      final updated = current.copyWith(
        items: updatedItems,
        subtotal: newSubtotal,
        total: newSubtotal +
            current.tax +
            current.deliveryFee -
            (current.discount ?? 0.0),
        storeId: franchiseId,
      );

      await updateCart(updated);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to addToCart',
        source: 'OrderFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'userId': userId},
      );
    }
  }

  @override
  Future<void> removeFromCart(String userId, String cartItemKey,
      {String? franchiseId}) async {
    if (_badFranchise(franchiseId)) return;

    try {
      final cart = await getCart(userId, franchiseId: franchiseId).first;
      if (cart == null) return;

      final filtered = cart.items
          .where((i) => (i.cartItemKey ?? i.menuItemId) != cartItemKey)
          .toList();

      final newSub = filtered.fold(0.0, (s, i) => s + i.price * i.quantity);

      await updateCart(cart.copyWith(
        items: filtered,
        subtotal: newSub,
        total: newSub + cart.tax + cart.deliveryFee - cart.discount,
      ));
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to removeFromCart',
        source: 'OrderFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'userId': userId},
      );
    }
  }

  @override
  Stream<int> getCartItemCountStream(String userId, {String? franchiseId}) {
    if (userId.isEmpty || _badFranchise(franchiseId)) {
      return Stream.value(0);
    }

    return getCart(userId, franchiseId: franchiseId)
        .map((c) => c?.items.fold<int>(0, (s, i) => s + i.quantity) ?? 0);
  }

  @override
  Future<void> clearCart(String userId, {String? franchiseId}) async {
    if (franchiseId == null || franchiseId.isEmpty) return;
    await _franchiseCollection(franchiseId, _carts).doc(userId).delete();
  }

  @override
  Future<void> addOrder(Order order) async {
    final fid = order.storeId;
    if (_badFranchise(fid)) return;

    await _franchiseCollection(fid, _orders)
        .doc(order.id)
        .set(order.toFirestore());
  }

  @override
  Stream<List<Order>> getOrdersForUser(String userId,
      {String? franchiseId, int limit = 20}) {
    if (_badFranchise(franchiseId)) {
      return Stream.value(<Order>[]);
    }

    final q = _franchiseCollection(franchiseId!, _orders)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    return q.snapshots().map((s) => s.docs
        .map((d) => Order.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  @override
  Future<void> updateOrderStatus(
      String franchiseId, String orderId, String newStatus) async {
    if (_badFranchise(franchiseId)) return;

    try {
      await _franchiseCollection(franchiseId, _orders).doc(orderId).update({
        'status': newStatus,
        'updatedAt': firestore.FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to updateOrderStatus',
        source: 'OrderFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'orderId': orderId},
      );
    }
  }

  @override
  Future<void> refundOrder(String franchiseId, String orderId,
      {double? amount, String? refundReason}) async {
    if (_badFranchise(franchiseId)) return;

    try {
      await _franchiseCollection(franchiseId, _orders).doc(orderId).update({
        'status': 'Refunded',
        'refundStatus': 'refunded',
        'refundAmount': amount,
        'refundReason': refundReason,
        'updatedAt': firestore.FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to refundOrder',
        source: 'OrderFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'orderId': orderId},
      );
    }
  }

  @override
  Stream<List<Order>> getAllOrdersStream(String franchiseId) {
    if (_badFranchise(franchiseId)) {
      return Stream.value(<Order>[]);
    }

    return _franchiseCollection(franchiseId, _orders)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) =>
                Order.fromFirestore(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  @override
  Stream<List<Order>> getOrders({String? userId, String? franchiseId}) {
    if (userId == null) return Stream.value([]);
    if (_badFranchise(franchiseId)) {
      return Stream.value(<Order>[]);
    }

    final q = _franchiseCollection(franchiseId!, _orders)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);

    return q.snapshots().map((s) => s.docs
        .map((d) => Order.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }
}
