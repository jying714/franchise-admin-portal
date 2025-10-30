import 'package:franchise_mobile_app/core/models/ingredient_metadata.dart';
import 'dart:collection';
// ignore_for_file: unused_import, unnecessary_cast
import 'package:franchise_mobile_app/core/models/customization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:franchise_mobile_app/config/app_config.dart';
import 'package:franchise_mobile_app/core/models/message.dart';
import 'package:franchise_mobile_app/core/models/loyalty.dart';
import 'package:franchise_mobile_app/core/models/category.dart';
import 'package:franchise_mobile_app/core/models/favorite_order.dart';
import 'package:franchise_mobile_app/core/models/menu_item.dart';
import 'package:franchise_mobile_app/core/models/order.dart' as order_model;
import 'package:franchise_mobile_app/core/models/user.dart' as user_model;
import 'package:franchise_mobile_app/core/models/promo.dart';
import 'package:franchise_mobile_app/core/models/banner.dart';
import 'package:franchise_mobile_app/core/models/chat.dart';
import 'package:franchise_mobile_app/core/models/feedback_entry.dart'
    as feedback_model;
import 'package:franchise_mobile_app/core/models/address.dart';
import 'package:franchise_mobile_app/core/models/scheduled_order.dart';
import 'package:async/async.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // --- [NEW]: Ingredient Metadata Caching ---
  List<IngredientMetadata>? _cachedIngredientMetadata;
  DateTime? _lastIngredientMetadataFetch;

  // Collection name
  String get _ingredientMetadata => 'ingredient_metadata';

  String? get currentUserId => auth.currentUser?.uid;

  // Collection name getters from AppConfig
  String get _users => AppConfig.usersCollection;
  String get _menuItems => AppConfig.menuItemsCollection;
  String get _orders => AppConfig.ordersCollection;
  String get _cart => AppConfig.cartCollection;
  String get _promotions => AppConfig.promotionsCollection;
  String get _banners => AppConfig.bannersCollection;
  String get _supportChats => AppConfig.supportChatsCollection;
  String get _feedback => AppConfig.feedbackCollection;
  String get _inventory => AppConfig.inventoryCollection;
  String get _categories => AppConfig.categoriesCollection;
  String get _addressesSubcollection => AppConfig.addressesSubcollection;
  String get _favoriteOrdersSubcollection =>
      AppConfig.favoriteOrdersSubcollection;
  String get _scheduledOrders => AppConfig.scheduledOrdersCollection;

  /// Get all ingredient metadata, with in-memory caching.
  Future<List<IngredientMetadata>> getAllIngredientMetadata(
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedIngredientMetadata != null &&
        _lastIngredientMetadataFetch != null &&
        DateTime.now().difference(_lastIngredientMetadataFetch!).inMinutes <
            15) {
      return _cachedIngredientMetadata!;
    }
    final snap = await _db.collection(_ingredientMetadata).get();
    final result = snap.docs
        .map((d) => IngredientMetadata.fromMap(d.data()))
        .toList(growable: false);
    _cachedIngredientMetadata = result;
    _lastIngredientMetadataFetch = DateTime.now();
    return result;
  }

  /// Get ingredient metadata by ID.
  /// Get ingredient metadata for a list of IDs.
  Future<List<IngredientMetadata>> getIngredientMetadataByIds(
      List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final snap = await _db
          .collection(_ingredientMetadata)
          .where(FieldPath.documentId, whereIn: ids)
          .get();
      return snap.docs
          .map((d) => IngredientMetadata.fromMap(d.data()))
          .toList(growable: false);
    } catch (e, stack) {
      _logFirestoreError('getIngredientMetadataByIds', e, stack);
      return [];
    }
  }

  /// Get all ingredient metadata as a map for fast lookups.
  Future<Map<String, IngredientMetadata>> getIngredientMetadataMap(
      {bool forceRefresh = false}) async {
    final all = await getAllIngredientMetadata(forceRefresh: forceRefresh);
    return {for (final meta in all) meta.id: meta};
  }

  Future<List<Map<String, dynamic>>> fetchIngredientMetadataAsMaps(
      {bool forceRefresh = false}) async {
    final all = await getAllIngredientMetadata(forceRefresh: forceRefresh);
    return all.map((meta) => meta.toMap()).toList();
  }

  // --- [NEW]: Robust Firestore error logging utility ---
  void _logFirestoreError(String context, Object e, [StackTrace? stack]) {
    //print('[FirestoreService] $context ERROR: $e\n$stack');
  }

  /// Given a list of ingredient IDs, return the unique set of allergens present.
  Future<List<String>> getAllergensForIngredientIds(
      List<String>? ingredientIds) async {
    if (ingredientIds == null || ingredientIds.isEmpty) return [];
    final metaMap = await getIngredientMetadataMap();
    final allergens = <String>{};
    for (final rawId in ingredientIds) {
      final id = rawId.trim();
      final meta = metaMap[id];
      if (meta != null && meta.allergens.isNotEmpty) {
        allergens.addAll(meta.allergens);
      }
    }
    return allergens.toList()..sort();
  }

  // Aggregate Allergens for Customizations

  Future<List<String>> getAllergensForCustomizations(
      List<Customization> customizations) async {
    final ingredientIds = <String>[];
    void collectIds(List<Customization> list) {
      for (final c in list) {
        if (!c.isGroup && c.ingredientId != null) {
          ingredientIds.add(c.ingredientId!);
        }
        if (c.options != null) {
          collectIds(c.options!);
        }
      }
    }

    collectIds(customizations);
    return getAllergensForIngredientIds(ingredientIds);
  }

  // --- [NEW]: Utility: Check if current user is admin/manager ---
  Future<bool> currentUserIsAdmin() async {
    final userId = currentUserId;
    if (userId == null) return false;
    final user = await getUser(userId);
    return user != null && (user.role == 'admin' || user.role == 'manager');
  }

  // --- USER PROFILE / ONBOARDING FIX ---
  Future<void> ensureUserProfile(User firebaseUser) async {
    final ref = _db.collection(_users).doc(firebaseUser.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'id': firebaseUser.uid,
        'name': firebaseUser.displayName ?? '',
        'email': firebaseUser.email,
        'phoneNumber': firebaseUser.phoneNumber ?? '',
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'completeProfile': false,
      });
    } else if (!(snap.data()?.containsKey('role') ?? false)) {
      await ref.update({'role': 'customer'});
    }
  }

  // --- USERS ---
  Future<void> addUser(user_model.User user) async {
    final ref = _db.collection(_users).doc(user.id);
    final snap = await ref.get();
    if (!snap.exists) {
      final data = user.toFirestore();
      data['role'] = data['role'] ?? 'customer';
      data['completeProfile'] = user.completeProfile ?? false;
      await ref.set(data);
    }
  }

  Future<user_model.User?> getUser(String id) async {
    final doc = await _db.collection(_users).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    if (!data.containsKey('role')) data['role'] = 'customer';
    if (!data.containsKey('completeProfile')) data['completeProfile'] = false;
    return user_model.User.fromFirestore(data, id);
  }

  // --- [PATCH]: Defensive update for updateUser ---
  Future<void> updateUser(user_model.User user) async {
    try {
      await _db
          .collection(_users)
          .doc(user.id)
          .set(user.toFirestore(), SetOptions(merge: true));
    } catch (e, stack) {
      _logFirestoreError('updateUser', e, stack);
      rethrow;
    }
  }

  // --- LOYALTY ---
  Future<void> claimReward(String uid, LoyaltyReward reward) async {
    final userRef = _db.collection(_users).doc(uid);
    final snap = await userRef.get();
    if (!snap.exists || snap.data() == null) {
      throw Exception('User not found');
    }
    final data = snap.data()!;
    final loyaltyMap = Map<String, dynamic>.from(data['loyalty'] as Map);
    final loyalty = Loyalty.fromMap(loyaltyMap);

    if (loyalty.points < reward.requiredPoints) {
      throw Exception('Insufficient points');
    }

    final now = DateTime.now();
    final claimedReward = LoyaltyReward(
      name: reward.name,
      requiredPoints: reward.requiredPoints,
      claimed: true,
      timestamp: now,
      claimedAt: now,
    );
    final updatedPoints = loyalty.points - reward.requiredPoints;
    final updatedRewards = List<LoyaltyReward>.from(loyalty.redeemedRewards)
      ..add(claimedReward);

    final updatedLoyalty = loyalty.copyWith(
      points: updatedPoints,
      redeemedRewards: updatedRewards,
      lastRedeemed: now,
    );

    await userRef.update({'loyalty': updatedLoyalty.toMap()});
  }

  // --- MENU ITEMS ---
  Stream<List<MenuItem>> getMenuItems(
      {String? search, String? sortBy, bool descending = false}) {
    Query query = _db.collection(_menuItems);
    if (search != null && search.trim().isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: search)
          .where('name', isLessThan: '${search}z');
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      query = query.orderBy(sortBy, descending: descending);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((d) =>
            MenuItem.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  Future<List<MenuItem>> getMenuItemsOnce() async {
    final snap = await _db.collection(_menuItems).get();
    return snap.docs.map((d) {
      final data = d.data();
      if (data['customizations'] == null || data['customizations'] is! List) {
        data['customizations'] = [];
      }
      return MenuItem.fromFirestore(data, d.id);
    }).toList();
  }

  /// Get all customization templates from Firestore.
  Future<Map<String, dynamic>> getCustomizationTemplates() async {
    try {
      final snap = await _db.collection('customization_templates').get();
      final result = <String, dynamic>{};
      for (final doc in snap.docs) {
        result[doc.id] = doc.data();
      }
      return result;
    } catch (e, stack) {
      _logFirestoreError('getCustomizationTemplates', e, stack);
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> fetchCustomizationTemplatesAsMaps() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('customization_templates')
        .get();

    // Each document's data as Map<String, dynamic> with doc id as 'templateId'
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'templateId': doc.id,
      };
    }).toList();
  }

  /// Get a single customization template by its ID.
  Future<Map<String, dynamic>?> getCustomizationTemplate(
      String templateId) async {
    try {
      final doc =
          await _db.collection('customization_templates').doc(templateId).get();
      return doc.exists ? doc.data() : null;
    } catch (e, stack) {
      _logFirestoreError('getCustomizationTemplate', e, stack);
      return null;
    }
  }

  // --- Resolve customizations from fetching templates ---

  Future<List<Map<String, dynamic>>> resolveCustomizations(
      List<dynamic> rawCustomizations) async {
    final List<Map<String, dynamic>> resolved = [];

    for (final entry in rawCustomizations) {
      if (entry is Map<String, dynamic> && entry.containsKey('templateRef')) {
        final templateId = entry['templateRef'];
        try {
          final template = await getCustomizationTemplate(templateId);
          if (template != null) {
            resolved.add(template);
          }
        } catch (e) {
          // Optionally log error or fallback
          await logSchemaError(
            message: 'Failed to load template',
            templateId: templateId,
            stackTrace: e.toString(),
          );
        }
      } else if (entry is Map<String, dynamic>) {
        resolved.add(entry);
      }
    }

    return resolved;
  }

  // --- log schema error in database ---
  Future<void> logSchemaError({
    required String message,
    String? templateId,
    String? menuItemId,
    String? stackTrace,
    String? userId,
  }) async {
    await FirebaseFirestore.instance.collection('error_logs').add({
      'timestamp': FieldValue.serverTimestamp(),
      'message': message,
      if (templateId != null) 'templateId': templateId,
      if (menuItemId != null) 'menuItemId': menuItemId,
      if (userId != null) 'userId': userId,
      if (stackTrace != null) 'stackTrace': stackTrace,
      'source': 'customization_template_resolution'
    });
  }

  /// Logs any app error to Firestore error_logs with full context.
  Future<void> logError({
    required String message,
    required String source,
    String? userId,
    String? screen,
    String? stackTrace,
    String? errorType,
    String? severity, // info, warning, error, critical
    Map<String, dynamic>?
        contextData, // for arbitrary details (period, orderId, etc)
    Map<String, dynamic>? deviceInfo, // if available from client/app
  }) async {
    try {
      final data = <String, dynamic>{
        'message': message,
        'source': source,
        if (userId != null) 'userId': userId,
        if (screen != null) 'screen': screen,
        if (stackTrace != null) 'stackTrace': stackTrace,
        if (errorType != null) 'errorType': errorType,
        if (severity != null) 'severity': severity,
        if (contextData != null && contextData.isNotEmpty)
          'contextData': contextData,
        if (deviceInfo != null && deviceInfo.isNotEmpty)
          'deviceInfo': deviceInfo,
        'timestamp': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('error_logs').add(data);
    } catch (e, stack) {
      // As a fallback, print to console or use your file logger
      print('[ERROR LOGGING FAILURE] $e\n$stack');
    }
  }

  Future<MenuItem?> getMenuItemById(String id) async {
    //print("[DEBUG] getMenuItemById CALLED WITH: $id");
    final doc = await _db.collection(_menuItems).doc(id).get();

    if (!doc.exists || doc.data() == null) return null;
    var data = doc.data()!;
    // Defensive for customizations field
    if (data['customizations'] != null && data['customizations'] is! List) {
      data['customizations'] = [];
    }
    return MenuItem.fromFirestore(data, doc.id);
  }

  // --- PROMOTIONS ---
  Future<void> addPromo(Promo promo) async =>
      _db.collection(_promotions).doc(promo.id).set(promo.toFirestore());

  Future<void> updatePromo(Promo promo) async =>
      _db.collection(_promotions).doc(promo.id).update(promo.toFirestore());

  Future<void> deletePromo(String promoId) async =>
      _db.collection(_promotions).doc(promoId).delete();

  Stream<List<Promo>> getPromos() =>
      _db.collection(_promotions).snapshots().map((snap) =>
          snap.docs.map((d) => Promo.fromFirestore(d.data(), d.id)).toList());

  Future<List<Promo>> getPromosOnce() async {
    final snap = await _db.collection(_promotions).get();
    return snap.docs.map((d) => Promo.fromFirestore(d.data(), d.id)).toList();
  }

  // --- Promotion Aliases for Admin UI Compatibility ---
  Stream<List<Promo>> getPromotions() => getPromos();
  Future<void> deletePromotion(String promoId) => deletePromo(promoId);

  // --- ORDERS ---
  Future<void> addOrder(order_model.Order order) async {
    final data = order.toFirestore();
    data['franchiseId'] =
        'default'; // <-- Always set franchiseId for new orders
    await _db.collection(_orders).doc(order.id).set(data);
  }

  Future<void> updateOrder(order_model.Order order) async =>
      _db.collection(_orders).doc(order.id).update(order.toFirestore());

  Stream<List<order_model.Order>> getOrders(String userId) => _db
      .collection(_orders)
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => order_model.Order.fromFirestore(d.data(), d.id))
          .toList());

  Future<order_model.Order?> getOrderById(String orderId) async {
    final doc = await _db.collection(_orders).doc(orderId).get();
    if (!doc.exists || doc.data() == null) return null;
    return order_model.Order.fromFirestore(doc.data()!, doc.id);
  }

  // --- CART ---
  Stream<order_model.Order?> getCart(String userId) => _db
      .collection(_cart)
      .doc(userId)
      .snapshots()
      .map((snap) => snap.exists && snap.data() != null
          ? order_model.Order.fromFirestore(snap.data()!, snap.id)
          : null);

  Future<void> updateCart(order_model.Order cart) async =>
      _db.collection(_cart).doc(cart.userId).set(cart.toFirestore());

  Future<void> clearCart(String userId) async =>
      _db.collection(_cart).doc(userId).delete();

// --- [PATCH]: Defensive cart add ---
  Future<void> addToCart({
    required String userId,
    required MenuItem menuItem,
    required Map<String, dynamic> customizations,
    required int quantity,
    required double price,
    required double deliveryFee,
    required double discount,
    required String deliveryType,
    required String time,
    required Timestamp timestamp,
    required int estimatedTime,
    Address? deliveryAddress,
    String? specialInstructions,
  }) async {
    print('[DEBUG] addToCart called');
    print('  userId: $userId');
    print('  menuItem: ${menuItem.toMap()}');
    print('  customizations: $customizations');
    print('  quantity: $quantity');
    print('  price: $price');
    print('  deliveryFee: $deliveryFee');
    print('  discount: $discount');
    print('  deliveryType: $deliveryType');
    print('  time: $time');
    print('  timestamp: $timestamp');
    print('  estimatedTime: $estimatedTime');
    print('  deliveryAddress: ${deliveryAddress?.toMap()}');
    print('  specialInstructions: $specialInstructions');
    try {
      final cartDoc = _db.collection(_cart).doc(userId);
      final cartSnap = await cartDoc.get();
      order_model.Order cart;
      if (cartSnap.exists && cartSnap.data() != null) {
        cart = order_model.Order.fromFirestore(cartSnap.data()!, cartSnap.id);
      } else {
        cart = order_model.Order(
          id: userId,
          userId: userId,
          items: [],
          subtotal: 0.0,
          tax: 0.0,
          total: 0.0,
          status: 'Cart',
          timestamps: {},
          deliveryFee: deliveryFee,
          discount: discount,
          deliveryType: deliveryType,
          time: time,
          timestamp: timestamp.toDate(),
          estimatedTime: estimatedTime,
          address: deliveryAddress,
        );
      }
      print('[DEBUG] Existing cart loaded: ${cart.toFirestore()}');
      final cartItemKey = DateTime.now().millisecondsSinceEpoch.toString();

      final newItem = order_model.OrderItem(
        menuItemId: menuItem.id,
        name: menuItem.name,
        image: menuItem.image,
        price: price,
        quantity: quantity,
        customizations: customizations,
        deliveryFee: deliveryFee,
        discount: discount,
        deliveryType: deliveryType,
        time: time,
        timestamp: timestamp.toDate(),
        estimatedTime: estimatedTime,
        cartItemKey: cartItemKey,
        // Add these two lines if your OrderItem model supports them:
        // address: deliveryAddress,
        // specialInstructions: specialInstructions,
      );
      print('[DEBUG] newItem constructed: ${newItem.toMap()}');
      final updatedItems = List<order_model.OrderItem>.from(cart.items)
        ..add(newItem);

      double subtotal = 0.0;
      for (final item in updatedItems) {
        subtotal += (item.price * item.quantity);
      }

      final updatedCart = cart.copyWith(
        items: updatedItems,
        subtotal: subtotal,
        tax: subtotal * 0.0925,
        total: subtotal * 1.0925,
        status: 'Cart',
        deliveryFee: deliveryFee,
        discount: discount,
        deliveryType: deliveryType,
        time: time,
        timestamp: timestamp.toDate(),
        estimatedTime: estimatedTime,
        address: deliveryAddress, // <--- Add/update here too
      );
      print('[DEBUG] updatedCart to be saved: ${updatedCart.toFirestore()}');
      await cartDoc.set(updatedCart.toFirestore(), SetOptions(merge: true));
    } catch (e, stack) {
      _logFirestoreError('addToCart', e, stack);
      rethrow;
    }
  }

  Stream<int> getCartItemCountStream(String? userId) {
    if (userId == null) return Stream.value(0);
    return getCart(userId).map((order) {
      if (order == null || order.items == null) return 0;
      return order.items
          .fold<int>(0, (sum, item) => sum + (item.quantity ?? 0));
    });
  }

  // --- ADDRESSES ---
  Stream<List<Address>> getAddressesForUser(String userId) => _db
          .collection(_users)
          .doc(userId)
          .collection(_addressesSubcollection)
          .snapshots()
          .map((snap) {
        //print('SNAPSHOT DOCS COUNT: ${snap.docs.length}');
        return snap.docs.map((d) => Address.fromMap(d.data())).toList();
      });

  // --- [PATCH]: Return doc ID for addAddressForUser ---
  Future<String> addAddressForUser(String userId, Address address) async {
    final docRef = await _db
        .collection(_users)
        .doc(userId)
        .collection(_addressesSubcollection)
        .add(address.toMap());
    return docRef.id;
  }

  // --- Remove address
  Future<void> removeAddressForUser(String userId, Address address) async {
    final col =
        _db.collection(_users).doc(userId).collection(_addressesSubcollection);
    final query = await col
        .where('label', isEqualTo: address.label)
        .where('street', isEqualTo: address.street)
        .where('zip', isEqualTo: address.zip)
        .limit(1)
        .get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  // --- Update address for user
  Future<void> updateAddressForUser(
      String userId, Address updatedAddress) async {
    final col =
        _db.collection(_users).doc(userId).collection(_addressesSubcollection);
    final query = await col
        .where('label', isEqualTo: updatedAddress.label)
        .where('street', isEqualTo: updatedAddress.street)
        .where('zip', isEqualTo: updatedAddress.zip)
        .limit(1)
        .get();
    for (var doc in query.docs) {
      await doc.reference.update(updatedAddress.toMap());
    }
  }

  // --- BANNERS ---
  Future<void> addBanner(Banner banner) async =>
      _db.collection(_banners).doc(banner.id).set(banner.toFirestore());

  Future<void> updateBanner(Banner banner) async =>
      _db.collection(_banners).doc(banner.id).update(banner.toFirestore());

  Stream<List<Banner>> getBanners() => _db.collection(_banners).snapshots().map(
        (snap) =>
            snap.docs.map((d) => Banner.fromFirestore(d.data(), d.id)).toList(),
      );

  // --- CHAT SUPPORT / CHAT MANAGEMENT ---
  Stream<List<Chat>> getSupportChats() {
    return _db
        .collection(_supportChats)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Chat.fromFirestore(d.data(), d.id)).toList());
  }

  Future<List<Chat>> getAllChats() async {
    final snap = await _db.collection(_supportChats).get();
    return snap.docs.map((d) => Chat.fromFirestore(d.data(), d.id)).toList();
  }

  Stream<List<Chat>> streamAllChats() {
    return _db.collection(_supportChats).snapshots().map((snap) =>
        snap.docs.map((d) => Chat.fromFirestore(d.data(), d.id)).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String role = 'user',
  }) async {
    print('SENDING MESSAGE to $chatId, content: $content');
    final messageRef =
        _db.collection(_supportChats).doc(chatId).collection('messages').doc();
    await messageRef.set({
      'senderId': senderId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'role': role,
    });
    await _db.collection(_supportChats).doc(chatId).set({
      'lastMessage': content,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'status': 'open',
      'userId': senderId,
    }, SetOptions(merge: true));
  }

  Future<void> sendSupportReply({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    await sendMessage(
      chatId: chatId,
      senderId: senderId,
      content: content,
      role: 'support',
    );
  }

  Stream<List<Message>> streamChatMessages(String chatId) {
    return _db
        .collection(_supportChats)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Message.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Stream<bool> streamSupportOnline() {
    return _db
        .collection('app_meta')
        .doc('support_status')
        .snapshots()
        .map((doc) => doc.data()?['online'] == true);
  }

  Future<String> createOrGetUserChat() async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');
    final docRef = _db.collection(_supportChats).doc(uid);
    final doc = await docRef.get();
    if (doc.exists) {
      return docRef.id;
    } else {
      await docRef.set({
        'userId': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
      });
      return docRef.id;
    }
  }

  // --- FEEDBACK MANAGEMENT ---

  Future<void> submitOrderFeedback({
    required String userId,
    required String orderId,
    required feedback_model.FeedbackEntry feedback,
  }) async {
    final ref = _db.collection(_feedback).doc(feedback.id);
    await ref.set({
      ...feedback.toFirestore(),
      'orderId': orderId,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _db.collection(_orders).doc(orderId).update({
      'feedbackId': feedback.id,
      'hasFeedback': true,
    });
  }

  Future<bool> hasOrderFeedback(String orderId) async {
    final query = await FirebaseFirestore.instance
        .collection('feedback')
        .where('orderId', isEqualTo: orderId)
        .where('feedbackMode',
            isEqualTo: 'orderExperience') // only order feedback
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // --- CATEGORIES ---
  Stream<List<Category>> getCategories(
      {String? search, String? sortBy, bool descending = false}) {
    Query query = _db.collection(_categories);

    if (search != null && search.trim().isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: search)
          .where('name', isLessThan: '${search}z');
    }

    if (sortBy != null && sortBy.isNotEmpty) {
      query = query.orderBy(sortBy, descending: descending);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) =>
            Category.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  // --- FAVORITE ORDERS ---
  Stream<List<FavoriteOrder>> getFavoriteOrdersForUser(String userId) => _db
      .collection(_users)
      .doc(userId)
      .collection(_favoriteOrdersSubcollection)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => FavoriteOrder.fromMap(d.data())).toList());

  Future<void> removeFavoriteOrderForUser(
      String userId, FavoriteOrder order) async {
    final col = _db
        .collection(_users)
        .doc(userId)
        .collection(_favoriteOrdersSubcollection);
    final query = await col.where('name', isEqualTo: order.name).limit(1).get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  // --- FAVORITE MENU ITEMS ---
  static const int maxFavoriteMenuItemsLookup = 10;

  Stream<List<MenuItem>> getFavoriteMenuItemsForUser(String userId) async* {
    await for (final doc in _db.collection(_users).doc(userId).snapshots()) {
      final data = doc.data();
      if (data == null || data['favoritesMenuItemIds'] == null) {
        yield [];
        continue;
      }
      final List<dynamic> ids = data['favoritesMenuItemIds'];
      if (ids.isEmpty) {
        yield [];
        continue;
      }
      if (ids.length <= maxFavoriteMenuItemsLookup) {
        final query = await _db
            .collection(_menuItems)
            .where(FieldPath.documentId, whereIn: ids)
            .get();
        yield query.docs
            .map((d) => MenuItem.fromFirestore(d.data(), d.id))
            .toList();
      } else {
        final results = <MenuItem>[];
        for (var id in ids) {
          final itemDoc = await _db.collection(_menuItems).doc(id).get();
          if (itemDoc.exists && itemDoc.data() != null) {
            results.add(MenuItem.fromFirestore(itemDoc.data()!, itemDoc.id));
          }
        }
        yield results;
      }
    }
  }

  Future<void> addFavoriteMenuItemForUser(
          String userId, String menuItemId) async =>
      _db.collection(_users).doc(userId).update({
        'favoritesMenuItemIds': FieldValue.arrayUnion([menuItemId])
      });

  Future<void> removeFavoriteMenuItemForUser(
          String userId, String menuItemId) async =>
      _db.collection(_users).doc(userId).update({
        'favoritesMenuItemIds': FieldValue.arrayRemove([menuItemId])
      });

  Future<void> clearFavoritesMenuItemsForUser(String userId) async =>
      _db.collection(_users).doc(userId).update({'favoritesMenuItemIds': []});

  // --- ORDER TRACKING ---
  Stream<order_model.Order?> trackOrder(String orderId) => _db
      .collection(_orders)
      .doc(orderId)
      .snapshots()
      .map((snap) => snap.exists && snap.data() != null
          ? order_model.Order.fromFirestore(snap.data()!, snap.id)
          : null);

  // --- SCHEDULED ORDERS ---
  Stream<List<ScheduledOrder>> getScheduledOrdersForUser(String userId) => _db
      .collection(_scheduledOrders)
      .where('userId', isEqualTo: userId)
      .orderBy('nextRun')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => ScheduledOrder.fromFirestore(d.data(), d.id))
          .toList());

  Future<void> addScheduledOrder(ScheduledOrder order) async =>
      _db.collection(_scheduledOrders).doc(order.id).set(order.toFirestore());

  Future<void> updateScheduledOrder(ScheduledOrder order) async => _db
      .collection(_scheduledOrders)
      .doc(order.id)
      .update(order.toFirestore());

  Future<void> deleteScheduledOrder(String orderId) async =>
      _db.collection(_scheduledOrders).doc(orderId).delete();

  // --- MENU ONLINE STATUS (stub) ---
  Stream<bool> menuOnlineStatusStream() async* {
    yield true;
  }

  /// Stream a user document by Firebase Auth UID
  Stream<user_model.User?> getUserByIdStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists
            ? user_model.User.fromFirestore({
                ...doc.data()!,
                if (!doc.data()!.containsKey('completeProfile'))
                  'completeProfile': false, // Defensive, legacy
              }, doc.id)
            : null);
  }

  /// [PATCH]: Log and validate order status update (client-safe)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final validStatuses = [
        'Cart',
        'Pending',
        'In Progress',
        'Ready',
        'Out for Delivery',
        'Delivered',
        'Completed',
        'Cancelled',
        'Refunded',
      ];

      if (!validStatuses.contains(newStatus)) {
        throw Exception('Invalid status: $newStatus');
      }

      await _db.collection(_orders).doc(orderId).update({'status': newStatus});

      // Optional: simple local debug log (replaces AuditLogService)
      print(
        '[FirestoreService] Updated order $orderId to status: $newStatus',
      );
    } catch (e, stack) {
      _logFirestoreError('updateOrderStatus', e, stack);
      rethrow;
    }
  }

  /// add refund order
  Future<void> refundOrder(String orderId, double amount) async {
    await _db.collection(_orders).doc(orderId).update({
      'status': 'Refunded',
      'refundAmount': amount,
      'refundTimestamp': FieldValue.serverTimestamp(),
    });
  }

  /// getAllOrdersStream
  Stream<List<order_model.Order>> getAllOrdersStream() {
    return _db
        .collection(_orders)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => order_model.Order.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// get menu items by category
  Stream<List<MenuItem>> getMenuItemsByCategory(String categoryId,
      {String? sortBy, bool descending = false}) {
    //print('[DEBUG] Loading categoryId: $categoryId');

    Query<Map<String, dynamic>> query =
        _db.collection(_menuItems).where('categoryId', isEqualTo: categoryId);

    if (sortBy != null && sortBy.isNotEmpty) {
      query = query.orderBy(sortBy, descending: descending);
    }

    return query.snapshots().map((snap) => snap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['customizations'] != null &&
              data['customizations'] is! List) {
            data['customizations'] = [];
          }
          return MenuItem.fromFirestore(data, doc.id);
        }).toList());
  }

  // ===================== DYNAMIC CATEGORY SCHEMA SUPPORT =====================

  /// Get schema metadata for a specific category (from category_schemas/{id}).
  Future<Map<String, dynamic>?> getCategorySchema(String categoryId) async {
    try {
      final doc =
          await _db.collection('category_schemas').doc(categoryId).get();
      return doc.exists ? doc.data() : null;
    } catch (e, stack) {
      _logFirestoreError('getCategorySchema', e, stack);
      return null;
    }
  }

// Add or update a category schema (admin use)
  Future<void> setCategorySchema(
      String categoryId, Map<String, dynamic> schema) async {
    await _db
        .collection('category_schemas')
        .doc(categoryId)
        .set(schema, SetOptions(merge: true));
  }

// List all available category schemas
  Future<List<String>> getAllCategorySchemaIds() async {
    final snap = await _db.collection('category_schemas').get();
    return snap.docs.map((d) => d.id).toList();
  }

  // --- Get all category schemas ---
  Future<List<Map<String, dynamic>>> getAllCategorySchemas() async {
    final snapshot = await _db.collection('category_schemas').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Include document ID for selection
      return data;
    }).toList();
  }

  /// updateMenuItemCustomizations
  Future<void> updateMenuItemCustomizations(
      String menuItemId, List<Customization> customizations) async {
    await _db.collection(_menuItems).doc(menuItemId).update({
      'customizations': customizations.map((c) => c.toFirestore()).toList(),
      'lastModified': FieldValue.serverTimestamp(),
      'lastModifiedBy': currentUserId ?? 'system',
    });
  }

  /// get menu customizations
  Future<List<Customization>> getMenuItemCustomizations(
      String menuItemId) async {
    final doc = await _db.collection(_menuItems).doc(menuItemId).get();
    if (!doc.exists || doc.data() == null) return [];
    final data = doc.data()!;
    if (data['customizations'] == null) return [];
    return (data['customizations'] as List<dynamic>)
        .map((e) => Customization.fromFirestore(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Get menu items by IDs
  Stream<List<MenuItem>> getMenuItemsByIds(List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);
    if (ids.length <= 10) {
      return _db
          .collection(_menuItems)
          .where(FieldPath.documentId, whereIn: ids)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => MenuItem.fromFirestore(d.data(), d.id))
              .toList());
    } else {
      final batches = <Stream<List<MenuItem>>>[];
      for (var i = 0; i < ids.length; i += 10) {
        final batchIds =
            ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
        batches.add(_db
            .collection(_menuItems)
            .where(FieldPath.documentId, whereIn: batchIds)
            .snapshots()
            .map((snap) => snap.docs
                .map((d) => MenuItem.fromFirestore(d.data(), d.id))
                .toList()));
      }
      return StreamZip(batches)
          .map((listOfLists) => listOfLists.expand((x) => x).toList());
    }
  }

  // --- Get visible customization groups for a menu item ---
  List<Customization> getCustomizationGroups(MenuItem item) {
    return item.customizations.where((c) => c.isGroup).toList();
  }

  // --- Get "included ingredients" for a menu item (preselected by default) ---
  List<Customization> getPreselectedCustomizations(MenuItem item) {
    List<Customization> flatten(List<Customization> list) {
      return list
          .expand(
              (c) => c.isGroup && c.options != null ? flatten(c.options!) : [c])
          .toList();
    }

    return flatten(item.customizations).where((c) => c.isDefault).toList();
  }

  // --- find customization option
  Customization? findCustomizationOption(
      List<Customization> groups, String idOrName) {
    for (final group in groups) {
      if (group.id == idOrName || group.name == idOrName) return group;
      if (group.options != null) {
        final found = findCustomizationOption(group.options!, idOrName);
        if (found != null) return found;
      }
    }
    return null;
  }

  // --- update customization feature toggles
  Future<void> updateCustomizationFeatureToggles({
    String? groupId,
    String? optionId,
    bool? allowExtra,
    bool? allowDouble,
    int? includedToppings,
    int? maxToppings,
    List<String>? allowedExtraDoubleToppings,
  }) async {
    final updates = <String, dynamic>{};
    if (allowExtra != null) updates['allowExtra'] = allowExtra;
    if (allowDouble != null) updates['allowDouble'] = allowDouble;
    if (includedToppings != null)
      updates['includedToppings'] = includedToppings;
    if (maxToppings != null) updates['maxToppings'] = maxToppings;
    if (allowedExtraDoubleToppings != null)
      updates['allowedExtraDoubleToppings'] = allowedExtraDoubleToppings;
    if (groupId != null) updates['groupId'] = groupId;
    if (optionId != null) updates['optionId'] = optionId;
    if (updates.isNotEmpty) {
      await _db.collection('config').doc('customization_features').set(
            updates,
            SetOptions(merge: true),
          );
    }
  }

  Future<Map<String, dynamic>> getCustomizationFeatureToggles() async {
    final doc =
        await _db.collection('config').doc('customization_features').get();
    return doc.exists ? Map<String, dynamic>.from(doc.data()!) : {};
  }
}
