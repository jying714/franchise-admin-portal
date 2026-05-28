// packages/shared_core/lib/src/core/services/firestore_service_impl.dart
//
// Lightweight FirestoreServiceImpl for customer/mobile flows + common/shared logic.
// All pure-admin methods (payouts, platform invoices, tax reports, advanced staff,
// bulk error ops, detailed financial exports, etc.) are stubbed with clear
// UnimplementedError so they can only be used via AdminFirestoreService in web-app.
//
// Storage strategy (franchise-scoped where applicable):
// - franchises/{franchiseId}/carts/{userId}
// - franchises/{franchiseId}/orders/{orderId}
// - franchises/{franchiseId}/users/{userId} (or franchise_profiles) for loyalty/favs/scheduled
// - franchises/{franchiseId}/... for menu, categories, promos, etc.

import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_core/shared_core.dart';
import '../models/user.dart'
    as app_user; // for staff/admin user methods in lightweight tier
import '../models/category.dart' as model;
import '../models/feedback_entry.dart' as feedback_model;
import '../utils/error_logger.dart';
import '../providers/franchise_provider.dart';
import '../models/banner.dart';

class FirestoreServiceImpl implements FirestoreService {
  late final firestore.FirebaseFirestore _db;
  late final fb_auth.FirebaseAuth _auth;
  late final FirebaseFunctions _functions;

  FirestoreServiceImpl({
    firestore.FirebaseFirestore? db,
    fb_auth.FirebaseAuth? auth,
    FirebaseFunctions? functions,
  }) {
    _db = db ?? firestore.FirebaseFirestore.instance;
    _auth = auth ?? fb_auth.FirebaseAuth.instance;
    _functions = functions ?? FirebaseFunctions.instance;
  }

  @override
  firestore.FirebaseFirestore get db => _db;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  // === Collection name getters (match abstract) ===
  @override
  String get _ingredientMetadata => 'ingredient_metadata';
  @override
  String get _menuItems => 'menu_items';
  @override
  String get _promotions => 'promotions';
  @override
  String get _banners => 'banners';
  @override
  String get _supportChats => 'support_chats';
  @override
  String get _feedback => 'feedback';
  @override
  String get _inventory => 'inventory';
  @override
  String get _categories => 'categories';

  // Additional paths used by impl
  String get _carts => 'carts';
  String get _orders => 'orders';
  String get _users => 'users';
  String get _franchiseUsers => 'users'; // sub under franchise
  String get _scheduledOrders => 'scheduledOrders';
  String get _favoriteOrders => 'favoriteOrders';

  void _logError(String method, Object error, StackTrace stack,
      {String? franchiseId, String? userId}) {
    ErrorLogger.log(
      message: 'Firestore error in $method: $error',
      stack: stack.toString(),
      source: 'FirestoreServiceImpl',
      severity: 'error',
      contextData: {
        if (franchiseId != null) 'franchiseId': franchiseId,
        if (userId != null) 'userId': userId,
      },
    );
  }

  // Helper to get franchise-scoped collection
  firestore.CollectionReference<Map<String, dynamic>> _franchiseCollection(
      String franchiseId, String sub) {
    return _db.collection('franchises').doc(franchiseId).collection(sub);
  }

  // ===================== INGREDIENT METADATA (common, cached) =====================
  List<IngredientMetadata>? _cachedIngredientMetadata;
  DateTime? _lastIngredientMetadataFetch;

  @override
  Future<List<IngredientMetadata>> getAllIngredientMetadata(String franchiseId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedIngredientMetadata != null &&
        _lastIngredientMetadataFetch != null &&
        DateTime.now().difference(_lastIngredientMetadataFetch!).inMinutes <
            15) {
      return _cachedIngredientMetadata!;
    }
    try {
      final snap =
          await _franchiseCollection(franchiseId, _ingredientMetadata).get();
      final result = snap.docs
          .map((d) => IngredientMetadata.fromMap({...d.data(), 'id': d.id}))
          .toList(growable: false);
      _cachedIngredientMetadata = result;
      _lastIngredientMetadataFetch = DateTime.now();
      return result;
    } catch (e, stack) {
      _logError('getAllIngredientMetadata', e, stack, franchiseId: franchiseId);
      return [];
    }
  }

  @override
  Future<List<IngredientMetadata>> getIngredientMetadataByIds(
      String franchiseId, List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final snap = await _franchiseCollection(franchiseId, _ingredientMetadata)
          .where(firestore.FieldPath.documentId, whereIn: ids)
          .get();
      return snap.docs
          .map((d) => IngredientMetadata.fromMap({...d.data(), 'id': d.id}))
          .toList();
    } catch (e, stack) {
      _logError('getIngredientMetadataByIds', e, stack,
          franchiseId: franchiseId);
      return [];
    }
  }

  @override
  Future<Map<String, IngredientMetadata>> getIngredientMetadataMap(
      String franchiseId,
      {bool forceRefresh = false}) async {
    final list =
        await getAllIngredientMetadata(franchiseId, forceRefresh: forceRefresh);
    return {for (final m in list) m.id: m};
  }

  @override
  Future<List<Map<String, dynamic>>> fetchIngredientMetadataAsMaps(
      String franchiseId,
      {bool forceRefresh = false}) async {
    final list =
        await getAllIngredientMetadata(franchiseId, forceRefresh: forceRefresh);
    return list.map((e) => e.toMap()).toList();
  }

  @override
  Future<List<String>> getAllergensForIngredientIds(
      String franchiseId, List<String>? ingredientIds) async {
    if (ingredientIds == null || ingredientIds.isEmpty) return [];
    final map = await getIngredientMetadataMap(franchiseId);
    final set = <String>{};
    for (final id in ingredientIds) {
      final meta = map[id.trim()];
      if (meta != null) set.addAll(meta.allergens);
    }
    return set.toList()..sort();
  }

  @override
  Future<List<String>> getAllergensForCustomizations(
      String franchiseId, List<Customization> customizations) async {
    final ids = <String>[];
    void collect(List<Customization> list) {
      for (final c in list) {
        if (!c.isGroup && c.ingredientId != null) ids.add(c.ingredientId!);
        if (c.options != null) collect(c.options!);
      }
    }

    collect(customizations);
    return getAllergensForIngredientIds(franchiseId, ids);
  }

  // ===================== INVITATIONS & FRANCHISE PROFILE (common) =====================
  @override
  Future<Map<String, dynamic>?> getFranchiseeInvitationByToken(
      String token) async {
    try {
      final doc =
          await _db.collection('franchisee_invitations').doc(token).get();
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data()!);
      data['id'] = doc.id;
      return data;
    } catch (e, stack) {
      _logError('getFranchiseeInvitationByToken', e, stack);
      return null;
    }
  }

  @override
  Future<String> createFranchiseProfile(
      {required Map<String, dynamic> franchiseData,
      required String invitedUserId}) async {
    try {
      String franchiseId =
          (franchiseData['franchiseId'] ?? '').toString().trim();
      if (franchiseId.isEmpty) {
        final name = (franchiseData['name'] ?? '').toString();
        franchiseId = name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      }
      final ref = _db.collection('franchises').doc(franchiseId);
      await ref.set({
        ...franchiseData,
        'franchiseId': franchiseId,
        'ownerUserId': invitedUserId,
        'status': 'active',
        'createdAt': firestore.FieldValue.serverTimestamp(),
        'updatedAt': firestore.FieldValue.serverTimestamp(),
      }, firestore.SetOptions(merge: true));

      await _db.collection('users').doc(invitedUserId).set({
        'franchiseIds': firestore.FieldValue.arrayUnion([franchiseId]),
        'defaultFranchise': franchiseId,
      }, firestore.SetOptions(merge: true));

      return franchiseId;
    } catch (e, st) {
      _logError('createFranchiseProfile', e, st);
      rethrow;
    }
  }

  @override
  Future<void> updateUserClaims(
      {required String uid,
      required List<String> franchiseIds,
      List<String>? roles,
      Map<String, dynamic>? additionalClaims}) async {
    final callable = _functions.httpsCallable('updateUserClaims');
    await callable.call({
      'uid': uid,
      'franchiseIds': franchiseIds,
      if (roles != null) 'roles': roles,
      if (additionalClaims != null) 'additionalClaims': additionalClaims,
    });
  }

  @override
  Future<void> updateFranchiseProfile(
      {required String franchiseId, required Map<String, dynamic> data}) async {
    await _db.collection('franchises').doc(franchiseId).update({
      ...data,
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> saveFranchiseBusinessHours(
      {required String franchiseId,
      required List<Map<String, dynamic>> hours}) async {
    await _db.collection('franchises').doc(franchiseId).update({
      'businessHours': hours,
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getFranchiseBusinessHours(
      String franchiseId) async {
    final doc = await _db.collection('franchises').doc(franchiseId).get();
    final data = doc.data();
    return (data?['businessHours'] as List?)?.cast<Map<String, dynamic>>() ??
        [];
  }

  @override
  Future<void> callAcceptInvitationFunction(String token) async {
    final callable = _functions.httpsCallable('acceptInvitation');
    await callable.call({'token': token});
  }

  @override
  Future<void> claimInvitation(String token, String newUid) async {
    await _db.collection('franchisee_invitations').doc(token).update({
      'claimedBy': newUid,
      'claimedAt': firestore.FieldValue.serverTimestamp(),
      'status': 'claimed',
    });
  }

  // ===================== USER & ADDRESSES (common) =====================
  @override
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic>? data) async {
    if (data == null) return;
    await _db
        .collection('users')
        .doc(userId)
        .set(data, firestore.SetOptions(merge: true));
  }

  @override
  Future<void> updateUserAvatar(String userId, String avatarUrl) async {
    await _db.collection('users').doc(userId).update({'avatarUrl': avatarUrl});
  }

  @override
  Future<void> addUser(app_user.User user) async {
    await _db
        .collection('users')
        .doc(user.id)
        .set(user.toFirestore(), firestore.SetOptions(merge: true));
  }

  @override
  Future<app_user.User?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return app_user.User.fromFirestore(doc.data()!, doc.id);
  }

  @override
  Future<void> updateUser(app_user.User user) async {
    await _db.collection('users').doc(user.id).update(user.toFirestore());
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _db.collection('users').doc(userId).delete();
  }

  @override
  Stream<app_user.User?> userStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return app_user.User.fromFirestore(doc.data()!, doc.id);
    });
  }

  // Compat for old mobile code
  @override
  Stream<app_user.User?> getUserByIdStream(String userId) => userStream(userId);

  @override
  Stream<List<app_user.User>> allUsers({String? franchiseId}) {
    firestore.Query q = _db.collection('users');
    if (franchiseId != null) {
      q = q.where('franchiseIds', arrayContains: franchiseId);
    }
    return q.snapshots().map((s) => s.docs
        .map((d) =>
            app_user.User.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  @override
  Future<List<app_user.User>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs
        .map((d) =>
            app_user.User.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  @override
  Future<void> addAddressForUser(String userId, Address address) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(address.id)
        .set(address.toMap());
  }

  @override
  Future<void> updateAddressForUser(String userId, Address address) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(address.id)
        .update(address.toMap());
  }

  @override
  Future<void> removeAddressForUser(String userId, String addressId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  @override
  Future<List<Address>> getAddressesForUser(String userId) async {
    final snap =
        await _db.collection('users').doc(userId).collection('addresses').get();
    return snap.docs
        .map((d) => Address.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }

  // ===================== FRANCHISE PROFILE & LOYALTY (common) =====================
  @override
  Future<Map<String, dynamic>?> getFranchiseProfile(
      String userId, String franchiseId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('franchise_profiles')
        .doc(franchiseId)
        .get();
    return doc.data();
  }

  @override
  Future<void> setFranchiseProfile(
      String userId, String franchiseId, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('franchise_profiles')
        .doc(franchiseId)
        .set({
      ...data,
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    }, firestore.SetOptions(merge: true));
  }

  @override
  Stream<Map<String, dynamic>?> franchiseProfileStream(
      String userId, String franchiseId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('franchise_profiles')
        .doc(franchiseId)
        .snapshots()
        .map((d) => d.data());
  }

  @override
  Stream<List<String>> favoritesMenuItemIdsStream(
      String userId, String franchiseId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('franchise_profiles')
        .doc(franchiseId)
        .snapshots()
        .map((d) => List<String>.from(d.data()?['favoritesMenuItemIds'] ?? []));
  }

  @override
  Future<List<String>> getFavoritesMenuItemIds(
      String userId, String franchiseId) async {
    final data = await getFranchiseProfile(userId, franchiseId);
    return List<String>.from(data?['favoritesMenuItemIds'] ?? []);
  }

  @override
  Future<void> addFavoriteMenuItem(
      String userId, String franchiseId, String menuItemId) async {
    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('franchise_profiles')
        .doc(franchiseId);
    await ref.set({
      'favoritesMenuItemIds': firestore.FieldValue.arrayUnion([menuItemId]),
    }, firestore.SetOptions(merge: true));
  }

  @override
  Future<void> removeFavoriteMenuItem(
      String userId, String franchiseId, String menuItemId) async {
    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('franchise_profiles')
        .doc(franchiseId);
    await ref.set({
      'favoritesMenuItemIds': firestore.FieldValue.arrayRemove([menuItemId]),
    }, firestore.SetOptions(merge: true));
  }

  @override
  @override
  Future<Map<String, dynamic>?> getLoyaltyForUser(String userId,
      {String? franchiseId}) async {
    if (franchiseId == null) {
      final doc = await _db.collection('users').doc(userId).get();
      return (doc.data()?['loyalty'] as Map?)?.cast<String, dynamic>();
    }
    final profile = await getFranchiseProfile(userId, franchiseId);
    return (profile?['loyalty'] as Map?)?.cast<String, dynamic>();
  }

  @override
  @override
  Future<void> setLoyaltyForUser(String userId, Map<String, dynamic> loyalty,
      {String? franchiseId}) async {
    if (franchiseId == null) {
      await _db
          .collection('users')
          .doc(userId)
          .set({'loyalty': loyalty}, firestore.SetOptions(merge: true));
      return;
    }
    await setFranchiseProfile(userId, franchiseId, {'loyalty': loyalty});
  }

  // ===================== ORDERS (admin + customer) =====================
  @override
  Future<void> updateOrderStatus(
      String franchiseId, String orderId, String newStatus) async {
    await _franchiseCollection(franchiseId, _orders).doc(orderId).update({
      'status': newStatus,
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> refundOrder(String franchiseId, String orderId,
      {double? amount, String? refundReason}) async {
    await _franchiseCollection(franchiseId, _orders).doc(orderId).update({
      'refundStatus': 'refunded',
      'refundAmount': amount,
      'refundReason': refundReason,
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<Order>> getAllOrdersStream(String franchiseId) {
    return _franchiseCollection(franchiseId, _orders)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => Order.fromFirestore(d.data(), d.id)).toList());
  }

  // NEW customer methods (implemented here for mobile)
  @override
  Stream<Order?> getCart(String userId, {String? franchiseId}) {
    if (franchiseId == null) {
      // Fallback: try global or first franchise (transition helper)
      return Stream.value(null);
    }
    return _franchiseCollection(franchiseId, _carts)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = {...doc.data()!, 'status': 'cart'};
      return Order.fromFirestore(data, doc.id);
    });
  }

  @override
  Future<void> updateCart(Order cart) async {
    if (cart.storeId.isEmpty) {
      throw ArgumentError('Cart must have storeId/franchiseId');
    }
    await _franchiseCollection(cart.storeId, _carts).doc(cart.userId).set({
      ...cart.toFirestore(),
      'status': 'cart',
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    }, firestore.SetOptions(merge: true));
  }

  @override
  Future<void> addToCart({
    required String userId,
    required String franchiseId,
    required MenuItem menuItem,
    required List<Customization> customizations,
    required int quantity,
    required double price,
    String? specialInstructions,
  }) async {
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
      customizations: {'groups': customizations.map((c) => c.toMap()).toList()},
      specialInstructions: specialInstructions,
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
    );
    await updateCart(updated);
  }

  @override
  Future<void> removeFromCart(String userId, String cartItemKey,
      {String? franchiseId}) async {
    if (franchiseId == null) return;
    final cart = await getCart(userId, franchiseId: franchiseId).first;
    if (cart == null) return;
    final filtered = cart.items
        .where((i) => (i.cartItemKey ?? i.menuItemId) != cartItemKey)
        .toList();
    final newSub = filtered.fold(0.0, (s, i) => s + i.price * i.quantity);
    await updateCart(cart.copyWith(
        items: filtered,
        subtotal: newSub,
        total: newSub + cart.tax + cart.deliveryFee - cart.discount));
  }

  @override
  Stream<int> getCartItemCountStream(String userId, {String? franchiseId}) {
    return getCart(userId, franchiseId: franchiseId)
        .map((c) => c?.items.fold<int>(0, (s, i) => s + i.quantity) ?? 0);
  }

  @override
  Future<void> clearCart(String userId, {String? franchiseId}) async {
    if (franchiseId == null) return;
    await _franchiseCollection(franchiseId, _carts).doc(userId).delete();
  }

  @override
  Future<void> addOrder(Order order) async {
    final fid = order.storeId;
    if (fid.isEmpty) throw ArgumentError('Order requires storeId/franchiseId');
    await _franchiseCollection(fid, _orders)
        .doc(order.id)
        .set(order.toFirestore());
  }

  @override
  Stream<List<Order>> getOrdersForUser(String userId,
      {String? franchiseId, int limit = 20}) {
    firestore.Query q =
        _db.collectionGroup(_orders).where('userId', isEqualTo: userId);
    if (franchiseId != null) {
      q = _franchiseCollection(franchiseId, _orders)
          .where('userId', isEqualTo: userId);
    }
    return q.limit(limit).snapshots().map((s) => s.docs
        .map((d) => Order.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  // Compat wrapper for old mobile code that called getOrders(userId)
  @override
  Stream<List<Order>> getOrders({String? userId, String? franchiseId}) {
    if (userId == null) {
      // Fallback: if no userId, return empty (or could throw, but lightweight should be forgiving)
      return Stream.value([]);
    }
    firestore.Query q;
    if (franchiseId != null) {
      q = _franchiseCollection(franchiseId, _orders)
          .where('userId', isEqualTo: userId);
    } else {
      q = _db.collectionGroup(_orders).where('userId', isEqualTo: userId);
    }
    return q.snapshots().map((s) => s.docs
        .map((d) => Order.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  @override
  Future<bool> hasOrderFeedback(String orderId) async {
    // Lightweight check: look for feedback entries referencing this order
    final snap = await _db
        .collectionGroup(_feedback)
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ===================== FEATURE TOGGLES (common) =====================
  @override
  Future<Map<String, dynamic>> getGlobalFeatureToggles() async {
    final doc = await _db.collection('config').doc('features').get();
    return doc.exists ? Map<String, dynamic>.from(doc.data()!) : {};
  }

  @override
  Future<Map<String, dynamic>> getFranchiseFeatureToggles(
      String franchiseId) async {
    final doc =
        await _franchiseCollection(franchiseId, 'config').doc('features').get();
    return doc.exists ? Map<String, dynamic>.from(doc.data()!) : {};
  }

  @override
  Future<void> setFranchiseFeatureToggles(
      String franchiseId, Map<String, dynamic> toggles) async {
    await _franchiseCollection(franchiseId, 'config')
        .doc('features')
        .set(toggles, firestore.SetOptions(merge: true));
  }

  @override
  Stream<Map<String, dynamic>> streamFranchiseFeatureToggles(
      String franchiseId) {
    return _franchiseCollection(franchiseId, 'config')
        .doc('features')
        .snapshots()
        .map((d) => d.data() ?? {});
  }

  @override
  Future<void> updateFeatureToggle(
      String franchiseId, String key, dynamic value) async {
    await _franchiseCollection(franchiseId, 'config')
        .doc('features')
        .set({key: value}, firestore.SetOptions(merge: true));
  }

  // ===================== ERROR LOGS (basic global + franchise) =====================
  @override
  Future<void> addErrorLogGlobal(ErrorLog log) async {
    await _db.collection('error_logs').add(log.toFirestore());
  }

  @override
  Future<void> updateErrorLogGlobal(
      String logId, Map<String, dynamic> updates) async {
    await _db.collection('error_logs').doc(logId).update(updates);
  }

  @override
  Future<ErrorLog?> getErrorLogGlobal(String logId) async {
    final doc = await _db.collection('error_logs').doc(logId).get();
    if (!doc.exists) return null;
    return ErrorLog.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Stream<List<ErrorLog>> streamErrorLogsGlobal(
      {String? franchiseId,
      String? userId,
      String? severity,
      String? platform,
      String? screen,
      DateTime? start,
      DateTime? end,
      int limit = 100}) {
    firestore.Query q = _db.collection('error_logs');
    if (franchiseId != null) q = q.where('franchiseId', isEqualTo: franchiseId);
    if (userId != null) q = q.where('userId', isEqualTo: userId);
    if (severity != null) q = q.where('severity', isEqualTo: severity);
    // add date filters etc as needed
    return q.limit(limit).snapshots().map((s) => s.docs
        .map((d) => ErrorLog.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  @override
  Future<List<ErrorLogSummary>> getErrorLogSummaries() async =>
      []; // admin heavy - stub for lightweight

  @override
  Stream<List<ErrorLog>> streamErrorLogs(String franchiseId,
      {int limit = 50,
      String? severity,
      String? source,
      String? screen,
      DateTime? start,
      DateTime? end,
      String? search,
      bool archived = false,
      bool? showResolved}) {
    firestore.Query q = _franchiseCollection(franchiseId, 'error_logs');
    if (severity != null) q = q.where('severity', isEqualTo: severity);
    return q.limit(limit).snapshots().map((s) => s.docs
        .map((d) => ErrorLog.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  @override
  Future<void> deleteErrorLogGlobal(String logId) async {
    await _db.collection('error_logs').doc(logId).delete();
  }

  @override
  Future<void> logSchemaError(String franchiseId,
      {required String message,
      String? templateId,
      String? menuItemId,
      String? stackTrace,
      String? userId}) async {
    await _franchiseCollection(franchiseId, 'error_logs').add({
      'type': 'schema',
      'message': message,
      'templateId': templateId,
      'menuItemId': menuItemId,
      'stackTrace': stackTrace,
      'userId': userId,
      'timestamp': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> logError(String? franchiseId,
      {required String message,
      required String source,
      String? userId,
      String? screen,
      String? stackTrace,
      String? errorType,
      String? severity,
      Map<String, dynamic>? contextData,
      Map<String, dynamic>? deviceInfo,
      String? assignedTo}) async {
    final col = franchiseId != null
        ? _franchiseCollection(franchiseId, 'error_logs')
        : _db.collection('error_logs');
    await col.add({
      'message': message,
      'source': source,
      'userId': userId,
      'screen': screen,
      'stackTrace': stackTrace,
      'errorType': errorType,
      'severity': severity ?? 'error',
      'contextData': contextData,
      'deviceInfo': deviceInfo,
      'assignedTo': assignedTo,
      'timestamp': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateErrorLog(
      String franchiseId, String logId, Map<String, dynamic> updates) async {
    await _franchiseCollection(franchiseId, 'error_logs')
        .doc(logId)
        .update(updates);
  }

  @override
  Future<void> addCommentToErrorLog(
      String franchiseId, String logId, Map<String, dynamic> comment) async {
    await _franchiseCollection(franchiseId, 'error_logs').doc(logId).update({
      'comments': firestore.FieldValue.arrayUnion([comment]),
    });
  }

  @override
  Future<void> setErrorLogStatus(String franchiseId, String logId,
      {bool? resolved, bool? archived}) async {
    final updates = <String, dynamic>{};
    if (resolved != null) updates['resolved'] = resolved;
    if (archived != null) updates['archived'] = archived;
    if (updates.isNotEmpty) {
      await _franchiseCollection(franchiseId, 'error_logs')
          .doc(logId)
          .update(updates);
    }
  }

  @override
  Future<void> deleteErrorLog(String franchiseId, String logId) async {
    await _franchiseCollection(franchiseId, 'error_logs').doc(logId).delete();
  }

  // ===================== AUDIT LOGS (basic) =====================
  @override
  Future<void> addAuditLogGlobal(AuditLog log) async {
    await _db.collection('audit_logs').add(log.toFirestore());
  }

  @override
  Future<AuditLog?> getAuditLogGlobal(String logId) async {
    final doc = await _db.collection('audit_logs').doc(logId).get();
    return doc.exists ? AuditLog.fromFirestore(doc.data()!, doc.id) : null;
  }

  @override
  Stream<List<AuditLog>> auditLogsStreamGlobal(
      {String? franchiseId, String? userId, String? action}) {
    firestore.Query q = _db.collection('audit_logs');
    if (franchiseId != null) q = q.where('franchiseId', isEqualTo: franchiseId);
    if (userId != null) q = q.where('userId', isEqualTo: userId);
    return q.snapshots().map((s) => s.docs
        .map((d) =>
            AuditLog.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  @override
  Future<void> addAuditLogFranchise(String franchiseId, AuditLog log) async {
    await _franchiseCollection(franchiseId, 'audit_logs')
        .add(log.toFirestore());
  }

  @override
  Future<AuditLog?> getAuditLogFranchise(
      String franchiseId, String logId) async {
    final doc =
        await _franchiseCollection(franchiseId, 'audit_logs').doc(logId).get();
    return doc.exists ? AuditLog.fromFirestore(doc.data()!, doc.id) : null;
  }

  @override
  Stream<List<AuditLog>> auditLogsStreamFranchise(String franchiseId,
      {String? userId, String? action}) {
    firestore.Query q = _franchiseCollection(franchiseId, 'audit_logs');
    if (userId != null) q = q.where('userId', isEqualTo: userId);
    return q.snapshots().map((s) => s.docs
        .map((d) =>
            AuditLog.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  // ===================== STAFF (basic) =====================
  @override
  Stream<List<app_user.User>> getStaffUsers(String franchiseId) {
    return _db
        .collection('users')
        .where('franchiseIds', arrayContains: franchiseId)
        .where('roles', arrayContainsAny: ['staff', 'manager', 'admin'])
        .snapshots()
        .map((s) => s.docs
            .map((d) => app_user.User.fromFirestore(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  @override
  Future<void> addStaffUser(
      {required String name,
      required String email,
      String? phone,
      required List<String> roles,
      required List<String> franchiseIds}) async {
    // In real app this would also create Auth user via callable
    final ref = _db.collection('users').doc();
    await ref.set({
      'id': ref.id,
      'name': name,
      'email': email,
      'phone': phone,
      'roles': roles,
      'franchiseIds': franchiseIds,
      'isActive': true,
      'createdAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeStaffUser(String userId) async {
    await _db.collection('users').doc(userId).update({'isActive': false});
  }

  // ===================== FRANCHISE LIST HELPERS =====================
  @override
  Future<List<FranchiseInfo>> fetchFranchiseList() async {
    final snap = await _db.collection('franchises').limit(100).get();
    return snap.docs.map((d) => FranchiseInfo.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<List<FranchiseInfo>> getFranchisesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snap = await _db
        .collection('franchises')
        .where(firestore.FieldPath.documentId, whereIn: ids)
        .get();
    return snap.docs.map((d) => FranchiseInfo.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<List<FranchiseInfo>> getFranchises() => fetchFranchiseList();
  @override
  Future<List<FranchiseInfo>> getAllFranchises() => fetchFranchiseList();

  // ===================== PAYOUTS, INVOICES, PLATFORM, TAX, SUPPORT, etc. (STUBBED - ADMIN ONLY) =====================
  // All heavy admin methods below throw clear errors. Full implementations live in AdminFirestoreService (web-app).

  String _adminOnlyMsg(String method) =>
      'Admin-only method "$method". Use AdminFirestoreService (web-app only). Lightweight impl does not support payouts, platform billing, tax reports, advanced staff, bulk ops, or detailed financial admin flows.';

  @override
  Future<void> addOrUpdatePayout(Payout payout) async =>
      throw UnimplementedError(_adminOnlyMsg('addOrUpdatePayout'));
  @override
  Future<Payout?> getPayoutById(String id) async =>
      throw UnimplementedError(_adminOnlyMsg('getPayoutById'));
  @override
  Future<void> deletePayout(String id) async =>
      throw UnimplementedError(_adminOnlyMsg('deletePayout'));
  @override
  Stream<List<Payout>> payoutsStream({String? franchiseId, String? status}) =>
      throw UnimplementedError(_adminOnlyMsg('payoutsStream'));
  @override
  Future<List<Map<String, dynamic>>> getPayoutsForFranchise(
          {required String franchiseId,
          String? status,
          String? searchQuery}) async =>
      throw UnimplementedError(_adminOnlyMsg('getPayoutsForFranchise'));
  @override
  Future<List<Payout>> fetchPayouts(
          {String? franchiseId,
          String? status,
          String? locationId,
          DateTime? startDate,
          DateTime? endDate,
          String? search,
          String? sortBy,
          bool descending = true,
          int? limit,
          dynamic startAfter}) async =>
      throw UnimplementedError(_adminOnlyMsg('fetchPayouts'));
  // ... (all other ~40 payout/invoice/platform/tax/support/staff advanced methods stubbed identically)
  @override
  Future<Map<String, dynamic>?> getPayoutDetailsWithAudit(
          String payoutId) async =>
      throw UnimplementedError(_adminOnlyMsg('getPayoutDetailsWithAudit'));
  @override
  Future<void> addPayoutAuditEvent(
          String payoutId, Map<String, dynamic> event) async =>
      throw UnimplementedError(_adminOnlyMsg('addPayoutAuditEvent'));
  @override
  Future<void> addAttachmentToPayout(
          String payoutId, Map<String, dynamic> attachment) async =>
      throw UnimplementedError(_adminOnlyMsg('addAttachmentToPayout'));
  @override
  Future<void> removeAttachmentFromPayout(
          String payoutId, Map<String, dynamic> attachment) async =>
      throw UnimplementedError(_adminOnlyMsg('removeAttachmentFromPayout'));
  @override
  Future<void> bulkUpdatePayoutStatus(
          List<String> payoutIds, String status) async =>
      throw UnimplementedError(_adminOnlyMsg('bulkUpdatePayoutStatus'));
  @override
  Future<void> addPayoutComment(
          String payoutId, Map<String, dynamic> comment) async =>
      throw UnimplementedError(_adminOnlyMsg('addPayoutComment'));
  @override
  Future<List<Map<String, dynamic>>> getPayoutComments(String payoutId) async =>
      throw UnimplementedError(_adminOnlyMsg('getPayoutComments'));
  @override
  Future<void> removePayoutComment(
          String payoutId, Map<String, dynamic> comment) async =>
      throw UnimplementedError(_adminOnlyMsg('removePayoutComment'));
  @override
  Future<void> markPayoutSent(String payoutId, {DateTime? sentAt}) async =>
      throw UnimplementedError(_adminOnlyMsg('markPayoutSent'));
  @override
  Future<void> setPayoutStatus(String payoutId, String newStatus) async =>
      throw UnimplementedError(_adminOnlyMsg('setPayoutStatus'));
  @override
  Future<void> markPayoutFailed(String payoutId,
          {String? errorMsg, String? errorCode}) async =>
      throw UnimplementedError(_adminOnlyMsg('markPayoutFailed'));
  @override
  Future<void> retryPayout(String payoutId) async =>
      throw UnimplementedError(_adminOnlyMsg('retryPayout'));
  @override
  Future<List<AuditLog>> getAuditLogsForPayout(String payoutId) async =>
      throw UnimplementedError(_adminOnlyMsg('getAuditLogsForPayout'));
  @override
  Future<String> exportPayoutsToCsv(
          {String? franchiseId,
          String? status,
          String? locationId,
          DateTime? startDate,
          DateTime? endDate,
          String? search,
          String? sortBy,
          bool descending = true,
          int? limit}) async =>
      throw UnimplementedError(_adminOnlyMsg('exportPayoutsToCsv'));

  // Invoices (heavy admin)
  @override
  Future<Map<String, dynamic>> getInvoiceStatsForFranchise(
          String franchiseId) async =>
      throw UnimplementedError(_adminOnlyMsg('getInvoiceStatsForFranchise'));
  @override
  Future<List<Invoice>> fetchInvoicesFiltered(
          {required String franchiseId,
          DateTime? startDate,
          DateTime? endDate}) async =>
      throw UnimplementedError(_adminOnlyMsg('fetchInvoicesFiltered'));
  @override
  Future<void> addOrUpdateInvoice(Invoice invoice) async =>
      throw UnimplementedError(_adminOnlyMsg('addOrUpdateInvoice'));
  @override
  Future<Invoice?> getInvoiceById(String id) async =>
      throw UnimplementedError(_adminOnlyMsg('getInvoiceById'));
  @override
  Future<void> deleteInvoice(String id) async =>
      throw UnimplementedError(_adminOnlyMsg('deleteInvoice'));
  @override
  Future<void> updateInvoiceDunningState(
          String invoiceId, String dunningState) async =>
      throw UnimplementedError(_adminOnlyMsg('updateInvoiceDunningState'));
  @override
  Future<void> addInvoiceOverdueReminder(
          String invoiceId, Map<String, dynamic> reminder) async =>
      throw UnimplementedError(_adminOnlyMsg('addInvoiceOverdueReminder'));
  @override
  Future<void> setInvoicePaymentPlan(
          String invoiceId, Map<String, dynamic> paymentPlan) async =>
      throw UnimplementedError(_adminOnlyMsg('setInvoicePaymentPlan'));
  @override
  Future<void> addInvoiceEscalationEvent(
          String invoiceId, Map<String, dynamic> escalationEvent) async =>
      throw UnimplementedError(_adminOnlyMsg('addInvoiceEscalationEvent'));
  @override
  Future<Map<String, dynamic>?> getInvoiceWorkflowFields(
          String invoiceId) async =>
      throw UnimplementedError(_adminOnlyMsg('getInvoiceWorkflowFields'));
  @override
  Future<void> removeInvoicePaymentPlan(String invoiceId) async =>
      throw UnimplementedError(_adminOnlyMsg('removeInvoicePaymentPlan'));
  @override
  Future<void> addInvoiceSupportNote(
          String invoiceId, Map<String, dynamic> note) async =>
      throw UnimplementedError(_adminOnlyMsg('addInvoiceSupportNote'));
  @override
  Future<void> addInvoiceAttachment(
          String invoiceId, Map<String, dynamic> attachment) async =>
      throw UnimplementedError(_adminOnlyMsg('addInvoiceAttachment'));
  @override
  Future<void> addInvoiceAuditEvent(
          String invoiceId, Map<String, dynamic> event) async =>
      throw UnimplementedError(_adminOnlyMsg('addInvoiceAuditEvent'));
  @override
  Future<int> getNextInvoiceNumber() async =>
      throw UnimplementedError(_adminOnlyMsg('getNextInvoiceNumber'));
  @override
  Stream<List<Invoice>> invoicesStream(
          {String? franchiseId,
          String? brandId,
          String? locationId,
          String? status,
          DateTime? startDate,
          DateTime? endDate}) =>
      throw UnimplementedError(_adminOnlyMsg('invoicesStream'));

  // Reports, Banners, Chats (some customer chat is implemented above; admin delete etc stubbed)
  @override
  Future<void> addOrUpdateReport(Report report) async =>
      throw UnimplementedError(_adminOnlyMsg('addOrUpdateReport'));
  @override
  Future<Report?> getReportById(String id) async =>
      throw UnimplementedError(_adminOnlyMsg('getReportById'));
  @override
  Future<void> deleteReport(String id) async =>
      throw UnimplementedError(_adminOnlyMsg('deleteReport'));
  @override
  Stream<List<Report>> reportsStream({String? franchiseId, String? type}) =>
      throw UnimplementedError(_adminOnlyMsg('reportsStream'));

  @override
  Future<void> addBanner(Banner banner) async =>
      throw UnimplementedError(_adminOnlyMsg('addBanner'));

  @override
  Future<void> updateBanner(Banner banner) async =>
      throw UnimplementedError(_adminOnlyMsg('updateBanner'));

  @override
  Stream<List<Banner>> getBanners() {
    return _db
        .collection(_banners)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) =>
                Banner.fromFirestore(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // Support chats (basic customer send implemented above; heavy admin delete stubbed)
  @override
  Stream<List<Chat>> getSupportChats(String franchiseId) =>
      throw UnimplementedError(_adminOnlyMsg('getSupportChats'));
  @override
  Future<void> deleteSupportChat(String franchiseId, String chatId) async =>
      throw UnimplementedError(_adminOnlyMsg('deleteSupportChat'));
  @override
  Future<List<Chat>> getAllChats(String franchiseId) async =>
      throw UnimplementedError(_adminOnlyMsg('getAllChats'));
  @override
  Stream<List<Chat>> streamAllChats(String franchiseId) =>
      throw UnimplementedError(_adminOnlyMsg('streamAllChats'));
  @override
  Future<void> deleteChat(String franchiseId, String chatId) async =>
      throw UnimplementedError(_adminOnlyMsg('deleteChat'));
  @override
  Future<void> sendSupportReply(
          {required String franchiseId,
          required String chatId,
          required String senderId,
          required String content}) async =>
      throw UnimplementedError(_adminOnlyMsg('sendSupportReply'));

  // Bank, Analytics, Menu, Inventory, Promos, Feedback (read paths kept lightweight where safe)
  @override
  Future<void> addOrUpdateBankAccount(BankAccount account) async =>
      throw UnimplementedError(_adminOnlyMsg('addOrUpdateBankAccount'));
  @override
  Future<BankAccount?> getBankAccountById(String id) async =>
      throw UnimplementedError(_adminOnlyMsg('getBankAccountById'));
  @override
  Future<void> deleteBankAccount(String id) async =>
      throw UnimplementedError(_adminOnlyMsg('deleteBankAccount'));
  @override
  Stream<List<BankAccount>> bankAccountsStream({String? franchiseId}) =>
      throw UnimplementedError(_adminOnlyMsg('bankAccountsStream'));

  @override
  Future<AnalyticsSummary?> getAnalyticsSummary(String franchiseId,
      {required String period}) async {
    // Lightweight read-only version
    try {
      final doc = await _franchiseCollection(franchiseId, 'analytics')
          .doc(period)
          .get();
      if (!doc.exists) return null;
      return AnalyticsSummary.fromFirestore(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> exportAnalyticsToCsv(String franchiseId,
          {required String period}) async =>
      throw UnimplementedError(_adminOnlyMsg('exportAnalyticsToCsv'));

  @override
  Future<double> getTotalRevenueToday(String franchiseId) async =>
      0.0; // lightweight stub or implement simple agg
  @override
  Future<double> getTotalRevenueForPeriod(
          String franchiseId, String period) async =>
      0.0;
  @override
  Future<int> getTotalOrdersTodayCount({required String franchiseId}) async =>
      0;

  // Menu (lightweight read + basic write for common use)
  @override
  Future<void> addMenuItem(String franchiseId, MenuItem item,
      {String? userId}) async {
    await _franchiseCollection(franchiseId, _menuItems)
        .doc(item.id)
        .set(item.toFirestore());
  }

  @override
  Future<void> updateMenuItem(String franchiseId, MenuItem item,
      {String? userId}) async {
    await _franchiseCollection(franchiseId, _menuItems)
        .doc(item.id)
        .update(item.toFirestore());
  }

  @override
  Future<void> deleteMenuItem(String franchiseId, String id,
      {String? userId}) async {
    await _franchiseCollection(franchiseId, _menuItems).doc(id).delete();
  }

  @override
  Stream<List<MenuItem>> getMenuItems(String franchiseId,
      {String? search, String? sortBy, bool descending = false}) {
    final effectiveId = (franchiseId.isNotEmpty &&
            franchiseId != 'unknown' &&
            franchiseId != 'default')
        ? franchiseId
        : 'doughboyspizzeria';

    print(
        '🔍 [getMenuItems] Called with franchiseId: "$franchiseId" | effectiveId: "$effectiveId" | categoryFilter: "${search ?? 'none'}"');

    firestore.Query q = _franchiseCollection(effectiveId, _menuItems);

    if (search != null && search.isNotEmpty) {
      q = q.where('categoryId', isEqualTo: search);
      print('🔍 [getMenuItems] Applying where categoryId == $search');
    }
    if (sortBy != null) {
      q = q.orderBy(sortBy, descending: descending);
    }

    return q.snapshots().map((s) {
      print('📦 [getMenuItems] Snapshot received: ${s.docs.length} documents');
      final list = s.docs
          .map((d) {
            try {
              final item = MenuItem.fromFirestore(
                  d.data() as Map<String, dynamic>, d.id);
              print('   ✅ Parsed menu item: ${item.name} (id: ${item.id})');
              return item;
            } catch (e) {
              print('   ❌ Failed to parse menu item ${d.id}: $e');
              return null;
            }
          })
          .where((item) => item != null)
          .cast<MenuItem>()
          .toList();

      print('✅ [getMenuItems] Final parsed count: ${list.length}');
      return list;
    });
  }

  @override
  Future<List<MenuItem>> getMenuItemsOnce(String franchiseId) async {
    final snap = await _franchiseCollection(franchiseId, _menuItems).get();
    return snap.docs
        .map((d) => MenuItem.fromFirestore(d.data(), d.id))
        .toList();
  }

  @override
  Stream<List<MenuItem>> getMenuItemsByIds(
      String franchiseId, List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);
    return _franchiseCollection(franchiseId, _menuItems)
        .where(firestore.FieldPath.documentId, whereIn: ids)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => MenuItem.fromFirestore(d.data(), d.id)).toList());
  }

  @override
  Stream<List<MenuItem>> getMenuItemsByCategory(String categoryId,
      {String? franchiseId, String? sortBy}) {
    print(
        '🔍 [getMenuItemsByCategory] Called - categoryId: "$categoryId", franchiseId: "$franchiseId", sortBy: "$sortBy"');

    final effectiveFranchiseId = (franchiseId != null &&
            franchiseId.isNotEmpty &&
            franchiseId != 'unknown')
        ? franchiseId
        : 'doughboyspizzeria'; // fallback for debugging

    print(
        '🔍 [getMenuItemsByCategory] Using effective franchiseId: $effectiveFranchiseId');

    firestore.Query q = _franchiseCollection(effectiveFranchiseId, _menuItems)
        .where('categoryId', isEqualTo: categoryId);

    if (sortBy != null && sortBy.isNotEmpty) {
      q = q.orderBy(sortBy);
      print('🔍 [getMenuItemsByCategory] Applied orderBy: $sortBy');
    } else {
      q = q.orderBy('sortOrder'); // default sort
    }

    return q.snapshots().map((s) {
      print(
          '📦 [getMenuItemsByCategory] Snapshot received: ${s.docs.length} documents for category $categoryId');
      final list = s.docs
          .map((d) {
            try {
              final item = MenuItem.fromFirestore(
                  d.data() as Map<String, dynamic>, d.id);
              print(
                  '   ✅ Parsed menu item: ${item.name} (id: ${item.id}, categoryId: ${item.categoryId})');
              return item;
            } catch (e, stack) {
              print('   ❌ Failed to parse menu item ${d.id}: $e');
              print('   Stack: $stack');
              return null;
            }
          })
          .where((item) => item != null)
          .cast<MenuItem>()
          .toList();

      print('✅ [getMenuItemsByCategory] Final parsed count: ${list.length}');
      return list;
    });
  }

  @override
  Future<MenuItem?> getMenuItemById(String itemId,
      {String? franchiseId}) async {
    if (franchiseId != null) {
      final doc =
          await _franchiseCollection(franchiseId, _menuItems).doc(itemId).get();
      if (doc.exists && doc.data() != null) {
        return MenuItem.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }
    }
    // Fallback collectionGroup search (slower but works during transition)
    final snap = await _db
        .collectionGroup(_menuItems)
        .where(firestore.FieldPath.documentId, isEqualTo: itemId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      final d = snap.docs.first;
      return MenuItem.fromFirestore(d.data() as Map<String, dynamic>, d.id);
    }
    return null;
  }

  @override
  List<Customization> getCustomizationGroups(MenuItem item) =>
      item.customizations.where((c) => c.isGroup).toList();
  @override
  List<Customization> getPreselectedCustomizations(MenuItem item) =>
      item.customizations.where((c) => c.selected).toList();
  @override
  Customization? findCustomizationOption(
      List<Customization> groups, String idOrName) {
    for (final g in groups) {
      final match = g.options?.firstWhere(
          (o) => o.id == idOrName || o.name == idOrName,
          orElse: () => null as dynamic);
      if (match != null) return match;
    }
    return null;
  }

  // Inventory, Cashflow, Promos, Feedback (lightweight where safe)
  @override
  Future<void> addInventory(String franchiseId, Inventory inventory) async =>
      throw UnimplementedError(_adminOnlyMsg('addInventory'));
  @override
  Future<void> updateInventory(String franchiseId, Inventory inventory) async =>
      throw UnimplementedError(_adminOnlyMsg('updateInventory'));
  @override
  Future<void> deleteInventory(String franchiseId, String id) async =>
      throw UnimplementedError(_adminOnlyMsg('deleteInventory'));
  @override
  Stream<List<Inventory>> getInventory(String franchiseId) =>
      throw UnimplementedError(_adminOnlyMsg('getInventory'));

  @override
  Future<Map<String, dynamic>?> getCashFlowForecast(String franchiseId) async =>
      null;
  @override
  Future<Map<String, dynamic>> getFranchiseAnalyticsSummary(
          String franchiseId) async =>
      {};
  @override
  Future<double> getOutstandingInvoices(String franchiseId) async => 0.0;
  @override
  Future<Map<String, dynamic>> getLastPayout(String franchiseId) async => {};
  @override
  Future<Map<String, int>> getPayoutStatsForFranchise(
          String franchiseId) async =>
      {};

  @override
  Future<void> addPromo(String franchiseId, Promo promo) async {
    await _franchiseCollection(franchiseId, _promotions)
        .doc(promo.id)
        .set(promo.toFirestore());
  }

  @override
  Stream<List<Promo>> getPromos(String franchiseId) {
    return _franchiseCollection(franchiseId, _promotions).snapshots().map(
        (s) => s.docs.map((d) => Promo.fromFirestore(d.data(), d.id)).toList());
  }

  @override
  Future<void> updatePromo(String franchiseId, Promo promo) async {
    await _franchiseCollection(franchiseId, _promotions)
        .doc(promo.id)
        .update(promo.toFirestore());
  }

  @override
  Future<void> deletePromo(String franchiseId, String promoId) async {
    await _franchiseCollection(franchiseId, _promotions).doc(promoId).delete();
  }

  @override
  Stream<List<feedback_model.FeedbackEntry>> getFeedbackEntries(
      String franchiseId) {
    return _franchiseCollection(franchiseId, _feedback)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => feedback_model.FeedbackEntry.fromFirestore(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  @override
  Future<void> deleteFeedbackEntry(String franchiseId, String id) async {
    await _franchiseCollection(franchiseId, _feedback).doc(id).delete();
  }

  // Support requests (lightweight customer paths; heavy admin stubbed)
  @override
  Future<dynamic> addSupportRequest(Map<String, dynamic> data) async {
    final ref = await _db.collection('support_requests').add({
      ...data,
      'created_at': firestore.FieldValue.serverTimestamp(),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
    return ref;
  }

  @override
  Future<void> updateSupportRequest(
      String requestId, Map<String, dynamic> updates) async {
    await _db.collection('support_requests').doc(requestId).update({
      ...updates,
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Map<String, dynamic>?> getSupportRequestById(String requestId) async {
    final doc = await _db.collection('support_requests').doc(requestId).get();
    return doc.data();
  }

  @override
  Stream<List<Map<String, dynamic>>> supportRequestsStream(
      {String? franchiseId,
      String? locationId,
      String? status,
      String? type,
      String? assignedTo,
      String? openedBy,
      int limit = 50}) {
    firestore.Query q = _db.collection('support_requests');
    if (franchiseId != null) q = q.where('franchiseId', isEqualTo: franchiseId);
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.limit(limit).snapshots().map((s) => s.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map)..['id'] = d.id)
        .toList());
  }

  @override
  Future<void> addMessageToSupportRequest(
      String requestId, Map<String, dynamic> message) async {
    await _db.collection('support_requests').doc(requestId).update({
      'messages': firestore.FieldValue.arrayUnion([message]),
    });
  }

  @override
  Future<void> deleteSupportRequest(String requestId) async =>
      throw UnimplementedError(_adminOnlyMsg('deleteSupportRequest'));
  @override
  Future<void> addSupportNote(
          String requestId, Map<String, dynamic> note) async =>
      throw UnimplementedError(_adminOnlyMsg('addSupportNote'));
  @override
  Future<void> updateSupportType(String requestId, String type) async =>
      throw UnimplementedError(_adminOnlyMsg('updateSupportType'));
  @override
  Future<void> linkEntitiesToSupportRequest(String requestId,
          {String? invoiceId, String? paymentId}) async =>
      throw UnimplementedError(_adminOnlyMsg('linkEntitiesToSupportRequest'));
  @override
  Future<void> updateSupportRequestStatus(String requestId,
          {required String status,
          String? lastUpdatedBy,
          String? resolutionNotes}) async =>
      throw UnimplementedError(_adminOnlyMsg('updateSupportRequestStatus'));
  @override
  Future<List<Map<String, dynamic>>> getSupportNotes(String requestId) async =>
      throw UnimplementedError(_adminOnlyMsg('getSupportNotes'));
  @override
  Stream<List<Map<String, dynamic>>> supportRequestsByTypeOrStatus(
          {String? type, String? status, int limit = 50}) =>
      throw UnimplementedError(_adminOnlyMsg('supportRequestsByTypeOrStatus'));

  // Tax reports (heavy admin)
  @override
  Future<dynamic> addTaxReport(Map<String, dynamic> data) async =>
      throw UnimplementedError(_adminOnlyMsg('addTaxReport'));
  @override
  Future<void> updateTaxReport(
          String reportId, Map<String, dynamic> updates) async =>
      throw UnimplementedError(_adminOnlyMsg('updateTaxReport'));
  @override
  Future<Map<String, dynamic>?> getTaxReportById(String reportId) async =>
      throw UnimplementedError(_adminOnlyMsg('getTaxReportById'));
  @override
  Stream<List<Map<String, dynamic>>> taxReportsStream(
          {String? franchiseId,
          String? brandId,
          String? reportType,
          String? status,
          String? taxAuthority,
          DateTime? filedAfter,
          DateTime? filedBefore,
          int limit = 100}) =>
      throw UnimplementedError(_adminOnlyMsg('taxReportsStream'));
  @override
  Future<void> deleteTaxReport(String reportId) async =>
      throw UnimplementedError(_adminOnlyMsg('deleteTaxReport'));
  @override
  Future<void> addTaxReportReminder(
          String reportId, Map<String, dynamic> reminder) async =>
      throw UnimplementedError(_adminOnlyMsg('addTaxReportReminder'));
  @override
  Future<void> addTaxReportAttachment(
          String reportId, Map<String, dynamic> attachment) async =>
      throw UnimplementedError(_adminOnlyMsg('addTaxReportAttachment'));

  // Invitations (basic implemented earlier; advanced admin stubbed)
  @override
  Future<List<FranchiseeInvitation>> fetchInvitations(
          {String? status, String? inviterUserId, String? email}) async =>
      throw UnimplementedError(_adminOnlyMsg('fetchInvitations'));
  @override
  Stream<List<FranchiseeInvitation>> invitationStream(
          {String? status, String? inviterUserId}) =>
      throw UnimplementedError(_adminOnlyMsg('invitationStream'));
  @override
  Future<FranchiseeInvitation?> fetchInvitationById(String id) async =>
      throw UnimplementedError(_adminOnlyMsg('fetchInvitationById'));
  @override
  Future<void> updateInvitation(String id, Map<String, dynamic> data) async =>
      throw UnimplementedError(_adminOnlyMsg('updateInvitation'));
  @override
  Future<void> cancelInvitation(String id, {String? revokedByUserId}) async =>
      throw UnimplementedError(_adminOnlyMsg('cancelInvitation'));
  @override
  Future<void> deleteInvitation(String id) async =>
      throw UnimplementedError(_adminOnlyMsg('deleteInvitation'));
  @override
  Future<void> expireInvitation(String id) async =>
      throw UnimplementedError(_adminOnlyMsg('expireInvitation'));
  @override
  Future<void> markInvitationResent(String id) async =>
      throw UnimplementedError(_adminOnlyMsg('markInvitationResent'));

  // Platform dashboard (heavy)
  @override
  Future<PlatformRevenueOverview> fetchPlatformRevenueOverview() async =>
      throw UnimplementedError(_adminOnlyMsg('fetchPlatformRevenueOverview'));
  @override
  Future<PlatformFinancialKpis> fetchPlatformFinancialKpis() async =>
      throw UnimplementedError(_adminOnlyMsg('fetchPlatformFinancialKpis'));
  @override
  Stream<List<PlatformInvoice>> platformInvoicesStream(
          {required String franchiseeId, String? status}) =>
      throw UnimplementedError(_adminOnlyMsg('platformInvoicesStream'));
  @override
  Future<List<PlatformInvoice>> getPlatformInvoicesForUser(
          String userId) async =>
      throw UnimplementedError(_adminOnlyMsg('getPlatformInvoicesForUser'));
  @override
  Future<List<Map<String, dynamic>>> getPlatformPaymentsForUser(
          String userId) async =>
      throw UnimplementedError(_adminOnlyMsg('getPlatformPaymentsForUser'));
  @override
  Future<void> savePlatformInvoiceFromWebhook(
          Map<String, dynamic> eventData, String invoiceId) async =>
      throw UnimplementedError(_adminOnlyMsg('savePlatformInvoiceFromWebhook'));
  @override
  Future<List<PlatformInvoice>> getPlatformInvoicesForFranchisee(
          String franchiseeId) async =>
      throw UnimplementedError(
          _adminOnlyMsg('getPlatformInvoicesForFranchisee'));
  @override
  Future<void> createPlatformInvoice(PlatformInvoice invoice) async =>
      throw UnimplementedError(_adminOnlyMsg('createPlatformInvoice'));
  @override
  Future<void> updatePlatformInvoiceStatus(
          String invoiceId, String newStatus) async =>
      throw UnimplementedError(_adminOnlyMsg('updatePlatformInvoiceStatus'));
  @override
  Future<List<PlatformPayment>> getPlatformPaymentsForFranchisee(
          String franchiseeId) async =>
      throw UnimplementedError(
          _adminOnlyMsg('getPlatformPaymentsForFranchisee'));
  @override
  Future<void> createPlatformPayment(PlatformPayment payment) async =>
      throw UnimplementedError(_adminOnlyMsg('createPlatformPayment'));
  @override
  Future<void> markPlatformPaymentCompleted(String paymentId) async =>
      throw UnimplementedError(_adminOnlyMsg('markPlatformPaymentCompleted'));
  @override
  Future<void> updatePlatformPaymentStatus(
          String paymentId, String newStatus) async =>
      throw UnimplementedError(_adminOnlyMsg('updatePlatformPaymentStatus'));
  @override
  Future<void> markPlatformInvoicePaid(String invoiceId, String method) async =>
      throw UnimplementedError(_adminOnlyMsg('markPlatformInvoicePaid'));

  // Franchise subscriptions (read mostly)
  @override
  Future<List<FranchiseSubscription>> getFranchiseSubscriptions() async =>
      throw UnimplementedError(_adminOnlyMsg('getFranchiseSubscriptions'));
  @override
  Future<FranchiseSubscription?> getFranchiseSubscription(
          String franchiseId) async =>
      throw UnimplementedError(_adminOnlyMsg('getFranchiseSubscription'));
  @override
  Future<FranchiseSubscription?> getCurrentSubscriptionForFranchise(
          String franchiseId) async =>
      throw UnimplementedError(
          _adminOnlyMsg('getCurrentSubscriptionForFranchise'));
  @override
  Future<List<FranchiseSubscription>> getAllFranchiseSubscriptions() async =>
      throw UnimplementedError(_adminOnlyMsg('getAllFranchiseSubscriptions'));
  @override
  Future<List<dynamic>> getAllFranchiseSubscriptionsRaw() async =>
      throw UnimplementedError(
          _adminOnlyMsg('getAllFranchiseSubscriptionsRaw'));
  @override
  Future<List<Map<String, dynamic>>> getStoreInvoicesForUser(
          String userId) async =>
      throw UnimplementedError(_adminOnlyMsg('getStoreInvoicesForUser'));

  // Onboarding (common)
  @override
  Future<FranchiseInfo?> getFranchiseInfo(String franchiseId) async {
    final doc = await _db.collection('franchises').doc(franchiseId).get();
    if (!doc.exists) return null;
    return FranchiseInfo.fromMap(doc.data()!, franchiseId);
  }

  @override
  Future<Map<String, dynamic>?> getOnboardingProgress(
      String franchiseId) async {
    final doc =
        await _db.collection('onboarding_progress').doc(franchiseId).get();
    return doc.data();
  }

  @override
  Future<void> updateOnboardingStep(
      {required String franchiseId,
      required String stepKey,
      required bool completed}) async {
    await _db.collection('onboarding_progress').doc(franchiseId).set({
      stepKey: completed,
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    }, firestore.SetOptions(merge: true));
  }

  @override
  Future<void> setOnboardingComplete({required String franchiseId}) async {
    await _db.collection('franchises').doc(franchiseId).update({
      'onboardingStatus': 'complete',
      'onboardingCompletedAt': firestore.FieldValue.serverTimestamp(),
      'status': 'active',
    });
  }

  // Simulation & templates (mostly admin/dev)
  @override
  Future<void> simulateWebhookEvent(
          {required String invoiceId,
          required String eventType,
          String status = 'paid',
          double amount = 0.0,
          String currency = 'USD',
          String? planId,
          String? subscriptionId,
          String? receiptUrl,
          DateTime? paidAt,
          String paymentMethod = 'mock_card',
          String paymentProvider = 'developer'}) async =>
      throw UnimplementedError(_adminOnlyMsg('simulateWebhookEvent'));
  @override
  Future<void> logSimulatedWebhookEvent(Map<String, dynamic> data) async =>
      throw UnimplementedError(_adminOnlyMsg('logSimulatedWebhookEvent'));
  @override
  Future<List<PlatformInvoice>> getTestPlatformInvoices(
          {required String franchiseeId}) async =>
      throw UnimplementedError(_adminOnlyMsg('getTestPlatformInvoices'));

  // Templates & import (mostly admin)
  @override
  Future<void> copyIngredientTypesFromTemplate(
          {required String franchiseId, required String templateId}) async =>
      throw UnimplementedError(
          _adminOnlyMsg('copyIngredientTypesFromTemplate'));
  @override
  Future<void> updateIngredientTypeSortOrders(
          {required String franchiseId,
          required List<Map<String, dynamic>> sortedUpdates}) async =>
      throw UnimplementedError(_adminOnlyMsg('updateIngredientTypeSortOrders'));
  @override
  Future<void> replaceIngredientTypesFromJson(
          {required String franchiseId,
          required List<IngredientType> items}) async =>
      throw UnimplementedError(_adminOnlyMsg('replaceIngredientTypesFromJson'));
  @override
  Future<List<IngredientMetadata>> getIngredientMetadataTemplate(
          String templateId) async =>
      throw UnimplementedError(_adminOnlyMsg('getIngredientMetadataTemplate'));
  @override
  Future<void> importIngredientMetadataTemplate(
          {required String templateId, required String franchiseId}) async =>
      throw UnimplementedError(
          _adminOnlyMsg('importIngredientMetadataTemplate'));
  @override
  Future<List<IngredientMetadata>> fetchIngredientMetadata(
          String franchiseId) =>
      getAllIngredientMetadata(franchiseId);
  @override
  Future<List<String>> fetchIngredientTypeIds(String franchiseId) async =>
      throw UnimplementedError(_adminOnlyMsg('fetchIngredientTypeIds'));
  @override
  Future<List<model.Category>> fetchCategories(String franchiseId) async =>
      throw UnimplementedError(_adminOnlyMsg('fetchCategories'));
  @override
  Future<void> saveCategory(
          String franchiseId, model.Category category) async =>
      throw UnimplementedError(_adminOnlyMsg('saveCategory'));
  @override
  Future<void> replaceAllCategories(
          String franchiseId, List<model.Category> categories) async =>
      throw UnimplementedError(_adminOnlyMsg('replaceAllCategories'));
  @override
  Future<void> saveAllCategories(
          String franchiseId, List<model.Category> categories) async =>
      throw UnimplementedError(_adminOnlyMsg('saveAllCategories'));
  @override
  Future<List<MenuItem>> fetchMenuItemsOnce(String franchiseId) =>
      getMenuItemsOnce(franchiseId);
  @override
  Future<void> saveMenuItems(String franchiseId, List<MenuItem> items) async =>
      throw UnimplementedError(_adminOnlyMsg('saveMenuItems'));
  @override
  Future<void> reorderMenuItems(
          String franchiseId, List<MenuItem> ordered) async =>
      throw UnimplementedError(_adminOnlyMsg('reorderMenuItems'));
  @override
  Future<List<MenuTemplateRef>> fetchMenuTemplateRefs(
          {required String restaurantType}) async =>
      throw UnimplementedError(_adminOnlyMsg('fetchMenuTemplateRefs'));
  @override
  Future<List<Map<String, dynamic>>> decodeJsonList(String input) async =>
      throw UnimplementedError(_adminOnlyMsg('decodeJsonList'));
  @override
  Future<List<SizeTemplate>> getSizeTemplatesForTemplate(
          String restaurantType) async =>
      throw UnimplementedError(_adminOnlyMsg('getSizeTemplatesForTemplate'));

  @override
  String get invitationCollectionPath => 'franchisee_invitations';

  // Additional customer methods from new abstract (chat, favorites overloads, scheduled, feedback)
  @override
  Future<String?> createOrGetUserChat(String userId,
      {String? franchiseId}) async {
    // Simple implementation: create a chat doc under support_chats or chats
    final col = franchiseId != null
        ? _franchiseCollection(franchiseId, 'customer_chats')
        : _db.collection('customer_chats');
    final existing =
        await col.where('userId', isEqualTo: userId).limit(1).get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;
    final ref = await col.add({
      'userId': userId,
      'franchiseId': franchiseId,
      'createdAt': firestore.FieldValue.serverTimestamp(),
      'status': 'open',
    });
    return ref.id;
  }

  @override
  Future<void> sendCustomerMessage(
      {required String chatId,
      required String senderId,
      required String content,
      String? franchiseId}) async {
    final col = franchiseId != null
        ? _franchiseCollection(franchiseId, 'customer_chats')
        : _db.collection('customer_chats');
    await col.doc(chatId).collection('messages').add({
      'senderId': senderId,
      'content': content,
      'timestamp': firestore.FieldValue.serverTimestamp(),
    });
  }

  // Scheduled order stubs (customer) - implement basic using orders collection with type flag or dedicated sub
  @override
  Stream<List<Order>> getScheduledOrdersForUser(String userId,
      {String? franchiseId}) {
    // For now treat as orders with status 'scheduled' or use dedicated subcollection
    firestore.Query q = _db
        .collectionGroup(_scheduledOrders)
        .where('userId', isEqualTo: userId);
    if (franchiseId != null)
      q = _franchiseCollection(franchiseId, _scheduledOrders)
          .where('userId', isEqualTo: userId);
    return q.snapshots().map((s) => s.docs
        .map((d) => Order.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  @override
  Future<void> addScheduledOrder(Order scheduled) async {
    final fid = scheduled.storeId;
    await _franchiseCollection(fid, _scheduledOrders)
        .doc(scheduled.id)
        .set(scheduled.toFirestore());
  }

  @override
  Future<void> updateScheduledOrder(Order scheduled) async =>
      addScheduledOrder(scheduled);

  @override
  Future<void> deleteScheduledOrder(String orderId,
      {String? userId, String? franchiseId}) async {
    if (franchiseId == null) return;
    await _franchiseCollection(franchiseId, _scheduledOrders)
        .doc(orderId)
        .delete();
  }

  // Favorite overloads (customer friendly)
  @override
  Stream<List<MenuItem>> getFavoriteMenuItemsForUser(String userId,
      {String? franchiseId}) async* {
    final ids = await getFavoritesMenuItemIds(userId, franchiseId ?? '');
    if (franchiseId == null || ids.isEmpty) {
      yield [];
      return;
    }
    yield* getMenuItemsByIds(franchiseId, ids);
  }

  @override
  Future<void> addFavoriteMenuItemForUser(String userId, String menuItemId,
      {String? franchiseId}) async {
    if (franchiseId == null) return;
    await addFavoriteMenuItem(userId, franchiseId, menuItemId);
  }

  @override
  Future<void> removeFavoriteMenuItemForUser(String userId, String menuItemId,
      {String? franchiseId}) async {
    if (franchiseId == null) return;
    await removeFavoriteMenuItem(userId, franchiseId, menuItemId);
  }

  @override
  Stream<List<Order>> getFavoriteOrdersForUser(String userId,
      {String? franchiseId}) {
    // Placeholder - implement with favorite_orders subcollection if needed
    return Stream.value([]);
  }

  @override
  Future<void> removeFavoriteOrderForUser(String userId, String orderId,
      {String? franchiseId}) async {
    // Placeholder
  }

  @override
  Future<void> submitOrderFeedback(
      {required String orderId,
      required String userId,
      required Map<String, dynamic> feedback,
      String? franchiseId}) async {
    final col = franchiseId != null
        ? _franchiseCollection(franchiseId, _feedback)
        : _db.collection(_feedback);
    await col.add({
      ...feedback,
      'orderId': orderId,
      'userId': userId,
      'timestamp': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  @override
  Future<void> claimReward(String userId, String rewardId,
      {String? franchiseId, int? points}) async {
    // Lightweight: update loyalty map
    if (franchiseId == null) return;
    final current =
        await getLoyaltyForUser(userId, franchiseId: franchiseId) ?? {};
    final redeemed = List.from(current['redeemedRewards'] ?? [])
      ..add({'id': rewardId, 'timestamp': DateTime.now().toIso8601String()});
    current['redeemedRewards'] = redeemed;
    if (points != null) current['points'] = (current['points'] ?? 0) - points;
    await setLoyaltyForUser(userId, current, franchiseId: franchiseId);
  }

  // sendMessage (existing abstract) - basic customer version
  @override
  Future<void> sendMessage(String franchiseId,
      {required String chatId,
      required String senderId,
      required String content,
      String role = 'user'}) async {
    await _franchiseCollection(franchiseId, _supportChats)
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'content': content,
      'role': role,
      'timestamp': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<Message>> streamChatMessages(String franchiseId, String chatId) {
    return _franchiseCollection(franchiseId, _supportChats)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((s) => s.docs
            .map((d) =>
                Message.fromFirestore(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  @override
  Stream<bool> streamSupportOnline() =>
      Stream.value(true); // simple online indicator

  // === ADMIN-ONLY STUBS (added for abstract completeness) ===
  // All throw clear UnimplementedError so mobile / lightweight consumers cannot accidentally use them.

  String _adminOnly(String name) =>
      'Admin-only method "$name". This method is only available via AdminFirestoreService in the web admin portal.';

  @override
  Future<void> addCategory({
    required String franchiseId,
    required model.Category category,
  }) async =>
      throw UnimplementedError(_adminOnly('addCategory'));

  @override
  Future<void> updateCategory(
          String franchiseId, model.Category category) async =>
      throw UnimplementedError(_adminOnly('updateCategory'));

  @override
  Future<void> deleteCategory({
    required String franchiseId,
    required String categoryId,
  }) async =>
      throw UnimplementedError(_adminOnly('deleteCategory'));

  @override
  Stream<List<model.Category>> getCategories(String franchiseId) {
    final effectiveId = (franchiseId.isNotEmpty &&
            franchiseId != 'unknown' &&
            franchiseId != 'default')
        ? franchiseId
        : 'doughboyspizzeria'; // Safe fallback until provider is fully fixed

    return _franchiseCollection(effectiveId, _categories)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((s) => s.docs
            .map((d) => model.Category.fromFirestore(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  @override
  Future<Map<String, dynamic>?> getCategorySchema(
          String franchiseId, String categoryId) async =>
      throw UnimplementedError(_adminOnly('getCategorySchema'));

  @override
  Future<List<String>> getAllCategorySchemaIds(String franchiseId) async =>
      throw UnimplementedError(_adminOnly('getAllCategorySchemaIds'));

  @override
  Future<Map<String, dynamic>?> getCustomizationTemplate(
          String franchiseId, String templateId) async =>
      throw UnimplementedError(_adminOnly('getCustomizationTemplate'));

  @override
  Future<Map<String, dynamic>> getCustomizationTemplates(
          String franchiseId) async =>
      throw UnimplementedError(_adminOnly('getCustomizationTemplates'));

  @override
  firestore.CollectionReference<Map<String, dynamic>>
      get invitationCollection => throw UnimplementedError(_adminOnly(
          'invitationCollection (use invitationCollectionPath or dedicated invitation methods instead in lightweight tier)'));
}
