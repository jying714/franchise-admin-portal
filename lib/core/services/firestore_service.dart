import 'package:franchise_admin_portal/core/models/franchise_info.dart';
import 'package:franchise_admin_portal/core/models/ingredient_metadata.dart';
import 'package:franchise_admin_portal/core/models/address.dart';
import 'dart:collection';
import 'package:franchise_admin_portal/core/models/customization.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:franchise_admin_portal/core/models/message.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:franchise_admin_portal/core/models/menu_item.dart';
import 'package:franchise_admin_portal/core/models/promo.dart';
import 'package:franchise_admin_portal/core/models/banner.dart';
import 'package:franchise_admin_portal/core/models/chat.dart';
import 'package:franchise_admin_portal/core/models/feedback_entry.dart'
    as feedback_model;
import 'package:franchise_admin_portal/core/models/inventory.dart';
import 'package:franchise_admin_portal/core/models/audit_log.dart';
import 'package:franchise_admin_portal/core/services/audit_log_service.dart';
import 'package:franchise_admin_portal/core/models/export_utils.dart';
import 'package:franchise_admin_portal/core/models/analytics_summary.dart';
import 'package:async/async.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as app_user;
import 'package:franchise_admin_portal/core/models/order.dart';
import 'package:franchise_admin_portal/core/models/error_log.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:franchise_admin_portal/core/models/payout.dart';
import 'package:franchise_admin_portal/core/models/report.dart';
import 'package:franchise_admin_portal/core/models/invoice.dart';
import 'package:franchise_admin_portal/core/models/bank_account.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class FirestoreService {
  final firestore.FirebaseFirestore _db = firestore.FirebaseFirestore.instance;
  final fb_auth.FirebaseAuth auth = fb_auth.FirebaseAuth.instance;

  // --- [NEW]: Ingredient Metadata Caching ---
  List<IngredientMetadata>? _cachedIngredientMetadata;
  DateTime? _lastIngredientMetadataFetch;
  String get _ingredientMetadata => 'ingredient_metadata';

  String? get currentUserId => auth.currentUser?.uid;

  // Collection name getters from AppConfig
  String get _menuItems => AppConfig.menuItemsCollection;
  String get _promotions => AppConfig.promotionsCollection;
  String get _banners => AppConfig.bannersCollection;
  String get _supportChats => AppConfig.supportChatsCollection;
  String get _feedback => AppConfig.feedbackCollection;
  String get _inventory => AppConfig.inventoryCollection;
  String get _categories => AppConfig.categoriesCollection;

  final functions = FirebaseFunctions.instance;

  /// Get all ingredient metadata, with in-memory caching.
  Future<List<IngredientMetadata>> getAllIngredientMetadata(String franchiseId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedIngredientMetadata != null &&
        _lastIngredientMetadataFetch != null &&
        DateTime.now().difference(_lastIngredientMetadataFetch!).inMinutes <
            15) {
      return _cachedIngredientMetadata!;
    }
    final snap = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_ingredientMetadata)
        .get();
    final result = snap.docs
        .map((d) => IngredientMetadata.fromMap(d.data()))
        .toList(growable: false);
    _cachedIngredientMetadata = result;
    _lastIngredientMetadataFetch = DateTime.now();
    return result;
  }

  /// Get ingredient metadata by ID.
  Future<List<IngredientMetadata>> getIngredientMetadataByIds(
      String franchiseId, List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final snap = await _db
          .collection('franchises')
          .doc(franchiseId)
          .collection(_ingredientMetadata)
          .where(firestore.FieldPath.documentId, whereIn: ids)
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
      String franchiseId,
      {bool forceRefresh = false}) async {
    final all =
        await getAllIngredientMetadata(franchiseId, forceRefresh: forceRefresh);
    return {for (final meta in all) meta.id: meta};
  }

  Future<List<Map<String, dynamic>>> fetchIngredientMetadataAsMaps(
      String franchiseId,
      {bool forceRefresh = false}) async {
    final all =
        await getAllIngredientMetadata(franchiseId, forceRefresh: forceRefresh);
    return all.map((meta) => meta.toMap()).toList();
  }

  /// Given a list of ingredient IDs, return the unique set of allergens present.
  Future<List<String>> getAllergensForIngredientIds(
      String franchiseId, List<String>? ingredientIds) async {
    if (ingredientIds == null || ingredientIds.isEmpty) return [];
    final metaMap = await getIngredientMetadataMap(franchiseId);
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

  Future<List<String>> getAllergensForCustomizations(
      String franchiseId, List<Customization> customizations) async {
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
    return getAllergensForIngredientIds(franchiseId, ingredientIds);
  }

  // === USERS (GLOBAL, INDUSTRY STANDARD) ===

  /// Add a user at top-level `/users`
  Future<void> addUser(app_user.User user) async {
    await _db.collection('users').doc(user.id).set(
          user.toFirestore(),
          firestore.SetOptions(merge: true),
        );
  }

  /// Get a user from top-level `/users`
  Future<app_user.User?> getUser(String userId) async {
    print('[FirestoreService] getUser called with userId=$userId');
    final doc = await _db.collection('users').doc(userId).get();
    print(
        '[FirestoreService] getUser Firestore response: exists=${doc.exists}, data=${doc.data()}');
    if (!doc.exists) {
      print('[FirestoreService] getUser: No user found for $userId');
      return null;
    }
    final user = app_user.User.fromFirestore(doc.data()!, doc.id);
    print(
        '[FirestoreService] getUser: Created User model: email=${user.email}, roles=${user.roles}, isActive=${user.status == "active"}, id=${user.id}');
    return user;
  }

  /// Update a user at top-level `/users`
  Future<void> updateUser(app_user.User user) async {
    await _db.collection('users').doc(user.id).update(user.toFirestore());
  }

  /// Delete a user from top-level `/users`
  Future<void> deleteUser(String userId) async {
    await _db.collection('users').doc(userId).delete();
  }

  /// Stream a single user from top-level `/users`
  Stream<app_user.User?> userStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      final data = doc.data();
      return data != null ? app_user.User.fromFirestore(data, doc.id) : null;
    });
  }

  /// Stream all users (optionally filtered by franchiseId)
  Stream<List<app_user.User>> allUsers({String? franchiseId}) {
    firestore.Query query = _db.collection('users');
    if (franchiseId != null) {
      query = query.where('franchiseIds', arrayContains: franchiseId);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((doc) {
          final data = doc.data();
          if (data != null) {
            return app_user.User.fromFirestore(
                data as Map<String, dynamic>, doc.id);
          } else {
            return null;
          }
        })
        .where((user) => user != null)
        .cast<app_user.User>()
        .toList());
  }

  // === USER ADDRESSES ===

  /// Add an address to `/users/{uid}/addresses/{addressId}`
  Future<void> addAddressForUser(String userId, Address address) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(address.id)
        .set(address.toFirestore());
  }

  /// Update an address
  Future<void> updateAddressForUser(String userId, Address address) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(address.id)
        .update(address.toFirestore());
  }

  /// Remove an address
  Future<void> removeAddressForUser(String userId, String addressId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  /// Get all addresses for user
  Future<List<Address>> getAddressesForUser(String userId) async {
    final snap =
        await _db.collection('users').doc(userId).collection('addresses').get();
    return snap.docs
        .map((doc) => Address.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // === FRANCHISE PROFILE SUBCOLLECTIONS ===

  /// Get a user's profile for a specific franchise
  Future<Map<String, dynamic>?> getFranchiseProfile(
      String userId, String franchiseId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('franchise_profiles')
        .doc(franchiseId)
        .get();
    return doc.exists ? doc.data() : null;
  }

  /// Set or update a user's franchise profile
  Future<void> setFranchiseProfile(
      String userId, String franchiseId, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('franchise_profiles')
        .doc(franchiseId)
        .set(data, firestore.SetOptions(merge: true));
  }

  /// Stream a user's franchise profile
  Stream<Map<String, dynamic>?> franchiseProfileStream(
      String userId, String franchiseId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('franchise_profiles')
        .doc(franchiseId)
        .snapshots()
        .map((doc) => doc.data());
  }

  /// Get favorites for user at a franchise
  Stream<List<String>> favoritesMenuItemIdsStream(
      String userId, String franchiseId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('franchise_profiles')
        .doc(franchiseId)
        .snapshots()
        .map((doc) =>
            List<String>.from(doc.data()?['favoritesMenuItemIds'] ?? []));
  }

  Future<List<String>> getFavoritesMenuItemIds(
      String userId, String franchiseId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('franchise_profiles')
        .doc(franchiseId)
        .get();
    if (!doc.exists) return [];
    final data = doc.data();
    return List<String>.from(data?['favoritesMenuItemIds'] ?? []);
  }

  /// Add a favorite menu item for user at a franchise
  Future<void> addFavoriteMenuItem(
      String userId, String franchiseId, String menuItemId) async {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('franchise_profiles')
        .doc(franchiseId);
    await docRef.set({
      'favoritesMenuItemIds': firestore.FieldValue.arrayUnion([menuItemId])
    }, firestore.SetOptions(merge: true));
  }

  /// Remove a favorite menu item for user at a franchise
  Future<void> removeFavoriteMenuItem(
      String userId, String franchiseId, String menuItemId) async {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('franchise_profiles')
        .doc(franchiseId);
    await docRef.set({
      'favoritesMenuItemIds': firestore.FieldValue.arrayRemove([menuItemId])
    }, firestore.SetOptions(merge: true));
  }

  /// Get loyalty info for user at a franchise
  Future<Map<String, dynamic>?> getLoyaltyForUser(
      String userId, String franchiseId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('franchise_profiles')
        .doc(franchiseId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data();
    return data?['loyalty'];
  }

  /// Add or update loyalty info for user at a franchise
  Future<void> setLoyaltyForUser(
      String userId, String franchiseId, Map<String, dynamic> loyalty) async {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('franchise_profiles')
        .doc(franchiseId);
    await docRef.set({'loyalty': loyalty}, firestore.SetOptions(merge: true));
  }

  // Order methods
  /// Update order status for a specific order in a franchise
  Future<void> updateOrderStatus(
      String franchiseId, String orderId, String newStatus) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .doc(orderId)
        .update({
      'status': newStatus,
      'lastModified': firestore.FieldValue.serverTimestamp(),
    });
  }

  /// Refund an order, with optional amount and reason
  Future<void> refundOrder(String franchiseId, String orderId,
      {double? amount, String? refundReason}) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .doc(orderId)
        .update({
      'refundStatus': 'refunded',
      if (amount != null) 'refundAmount': amount,
      if (refundReason != null) 'refundReason': refundReason,
      'refundedAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  /// Stream all orders for a franchise, ordered by latest first
  Stream<List<Order>> getAllOrdersStream(String franchiseId) {
    return _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Order.fromFirestore(data, doc.id);
            }).toList());
  }

  // More per-franchise user data methods (orders, scheduled_orders, etc.) can be added here...

  // === FEATURE TOGGLES ===

  /// Get global feature toggles (for all franchises)
  Future<Map<String, dynamic>> getGlobalFeatureToggles() async {
    final doc = await _db.collection('config').doc('features').get();
    return doc.exists ? Map<String, dynamic>.from(doc.data()!) : {};
  }

  /// Get franchise-specific feature toggles
  Future<Map<String, dynamic>> getFranchiseFeatureToggles(
      String franchiseId) async {
    final doc = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('config')
        .doc('features')
        .get();
    return doc.exists ? Map<String, dynamic>.from(doc.data()!) : {};
  }

  /// Set franchise feature toggles
  Future<void> setFranchiseFeatureToggles(
      String franchiseId, Map<String, dynamic> toggles) async {
    final docRef = _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('config')
        .doc('features');
    await docRef.set(toggles, firestore.SetOptions(merge: true));
  }

  /// Stream franchise feature toggles
  Stream<Map<String, dynamic>> streamFranchiseFeatureToggles(
      String franchiseId) {
    final docRef = _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('config')
        .doc('features');
    return docRef.snapshots().map((doc) => doc.data() ?? {});
  }

  /// Updates a single toggle value in the franchise's config/features doc.
  Future<void> updateFeatureToggle(
      String franchiseId, String key, dynamic value) async {
    final docRef = _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('config')
        .doc('features');
    await docRef.set({key: value}, firestore.SetOptions(merge: true));
  }

  // === ERROR LOGS (AUDIT-READY, INDUSTRY STANDARD) ===

  // Add an error log (global/platform-wide error)
  Future<void> addErrorLogGlobal(ErrorLog log) async {
    await _db.collection('error_logs').add(log.toFirestore());
  }

  // Update a global error log
  Future<void> updateErrorLogGlobal(
      String logId, Map<String, dynamic> updates) async {
    await _db.collection('error_logs').doc(logId).update(updates);
  }

  // Get a global error log by ID
  Future<ErrorLog?> getErrorLogGlobal(String logId) async {
    final doc = await _db.collection('error_logs').doc(logId).get();
    if (!doc.exists) return null;
    return ErrorLog.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Stream all global error logs (optionally filtered)
  Stream<List<ErrorLog>> errorLogsStreamGlobal({
    String? franchiseId,
    String? userId,
    String? severity,
    String? status,
    String? platform,
  }) {
    firestore.Query query = _db.collection('error_logs');
    if (franchiseId != null)
      query = query.where('franchiseId', isEqualTo: franchiseId);
    if (userId != null) query = query.where('userId', isEqualTo: userId);
    if (severity != null) query = query.where('severity', isEqualTo: severity);
    if (status != null) query = query.where('status', isEqualTo: status);
    if (platform != null) query = query.where('platform', isEqualTo: platform);
    return query.orderBy('timestamp', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((doc) =>
                  ErrorLog.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  Stream<List<ErrorLog>> streamErrorLogs(
    String franchiseId, {
    int limit = 50,
    String? severity,
    String? source,
    String? screen,
    DateTime? start,
    DateTime? end,
    String? search, // (not used directly unless you add full-text support)
    bool archived = false,
    bool? showResolved, // null = all, false = unresolved, true = resolved
  }) {
    firestore.Query query = _db
        .collection('error_logs')
        .where('franchiseId', isEqualTo: franchiseId);

    if (severity != null &&
        severity.isNotEmpty &&
        severity != 'null' &&
        severity != 'all') {
      query = query.where('severity', isEqualTo: severity);
    }
    if (source != null && source.isNotEmpty) {
      query = query.where('source', isEqualTo: source);
    }
    if (screen != null && screen.isNotEmpty) {
      query = query.where('screen', isEqualTo: screen);
    }

    // Filter by archived status
    query = query.where('archived', isEqualTo: archived);

    // Only filter by resolved if showResolved is NOT null
    if (showResolved != null) {
      query = query.where('resolved', isEqualTo: showResolved);
    }

    if (start != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: firestore.Timestamp.fromDate(start));
    }
    if (end != null) {
      query = query.where('timestamp',
          isLessThan: firestore.Timestamp.fromDate(end));
    }

    // Order and limit
    query = query.orderBy('timestamp', descending: true).limit(limit);

    return query.snapshots().map((snap) => snap.docs
        .map((doc) =>
            ErrorLog.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<void> deleteErrorLogGlobal(String logId) async {
    await _db.collection('error_logs').doc(logId).delete();
  }

  // Add an error log (franchise-specific)
  Future<void> addErrorLogFranchise(String franchiseId, ErrorLog log) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('error_logs')
        .add(log.toFirestore());
  }

  // Update a franchise error log
  Future<void> updateErrorLogFranchise(
      String franchiseId, String logId, Map<String, dynamic> updates) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('error_logs')
        .doc(logId)
        .update(updates);
  }

  // Get a franchise error log by ID
  Future<ErrorLog?> getErrorLogFranchise(
      String franchiseId, String logId) async {
    final doc = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('error_logs')
        .doc(logId)
        .get();
    if (!doc.exists) return null;
    return ErrorLog.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Stream all franchise error logs (optionally filtered)
  Stream<List<ErrorLog>> errorLogsStreamFranchise(
    String franchiseId, {
    String? userId,
    String? severity,
    String? status,
    String? platform,
  }) {
    firestore.Query query = _db
        .collection('error_logs')
        .where('franchiseId', isEqualTo: franchiseId);
    if (userId != null) query = query.where('userId', isEqualTo: userId);
    if (severity != null) query = query.where('severity', isEqualTo: severity);
    if (status != null) query = query.where('status', isEqualTo: status);
    if (platform != null) query = query.where('platform', isEqualTo: platform);
    return query.orderBy('timestamp', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((doc) =>
                  ErrorLog.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  Future<void> deleteErrorLogFranchise(String franchiseId, String logId) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('error_logs')
        .doc(logId)
        .delete();
  }

  /// Log schema error (template/menu-specific error)
  Future<void> logSchemaError(
    String franchiseId, {
    required String message,
    String? templateId,
    String? menuItemId,
    String? stackTrace,
    String? userId,
  }) async {
    await ErrorLogger.log(
      message: message,
      stack: stackTrace,
      source: 'customization_template_resolution',
      contextData: {
        'franchiseId': franchiseId,
        if (templateId != null) 'templateId': templateId,
        if (menuItemId != null) 'menuItemId': menuItemId,
        if (userId != null) 'userId': userId,
      },
    );
  }

  /// Generic error logger (franchise-scoped, supports all error types)
  Future<void> logError(
    String? franchiseId, {
    required String message,
    required String source,
    String? userId,
    String? screen,
    String? stackTrace,
    String? errorType,
    String? severity,
    Map<String, dynamic>? contextData,
    Map<String, dynamic>? deviceInfo,
    String? assignedTo,
  }) async {
    print('Logging error for franchiseId=$franchiseId, message=$message');
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
        if (assignedTo != null) 'assignedTo': assignedTo,
        'timestamp': firestore.FieldValue.serverTimestamp(),
        'resolved': false,
        'archived': false,
        'comments': <Map<String, dynamic>>[],
      };
      await _db.collection('error_logs').add({
        ...data,
        'franchiseId': franchiseId,
      });
    } catch (e, stack) {
      print('[ERROR LOGGING FAILURE] $e\n$stack');
    }
  }

  // Update a log (mark as resolved/archived or add a comment)
  Future<void> updateErrorLog(
      String franchiseId, String logId, Map<String, dynamic> updates) async {
    await _db.collection('error_logs').doc(logId).update(updates);
  }

  // Add a comment to an error log
  Future<void> addCommentToErrorLog(
      String franchiseId, String logId, Map<String, dynamic> comment) async {
    await _db.collection('error_logs').doc(logId).update({
      'comments': firestore.FieldValue.arrayUnion([comment]),
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  // Mark an error log as resolved or archived
  Future<void> setErrorLogStatus(String franchiseId, String logId,
      {bool? resolved, bool? archived}) async {
    final updates = <String, dynamic>{};
    if (resolved != null) updates['resolved'] = resolved;
    if (archived != null) updates['archived'] = archived;
    updates['updatedAt'] = firestore.FieldValue.serverTimestamp();
    await _db.collection('error_logs').doc(logId).update(updates);
  }

  Future<void> deleteErrorLog(String franchiseId, String logId) async {
    await _db.collection('error_logs').doc(logId).delete();
  }

  // === AUDIT LOGS (ROOT AND FRANCHISE SCOPE) ===

  /// Add a log to top-level `/audit_logs`
  Future<void> addAuditLogGlobal(AuditLog log) async {
    await _db.collection('audit_logs').add(log.toFirestore());
  }

  /// Get a single audit log by ID (top-level)
  Future<AuditLog?> getAuditLogGlobal(String logId) async {
    final doc = await _db.collection('audit_logs').doc(logId).get();
    if (!doc.exists) return null;
    return AuditLog.fromFirestore(doc.data()!, doc.id);
  }

  /// Stream audit logs (optionally filtered by franchiseId/userId/type)
  Stream<List<AuditLog>> auditLogsStreamGlobal(
      {String? franchiseId, String? userId, String? action}) {
    firestore.Query query =
        _db.collection('audit_logs').orderBy('timestamp', descending: true);
    if (franchiseId != null) {
      query = query.where('franchiseId', isEqualTo: franchiseId);
    }
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    if (action != null) {
      query = query.where('action', isEqualTo: action);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((doc) {
          final data = doc.data();
          if (data != null) {
            return AuditLog.fromFirestore(data as Map<String, dynamic>, doc.id);
          } else {
            return null;
          }
        })
        .where((log) => log != null)
        .cast<AuditLog>()
        .toList());
  }

  // Add a log to franchise-specific `/franchises/{franchiseId}/audit_logs`
  // Add an audit log to the root-level audit_logs collection
  Future<void> addAuditLogFranchise(String franchiseId, AuditLog log) async {
    final data = log.toFirestore();
    data['franchiseId'] = franchiseId;
    await _db.collection('audit_logs').add(data);
  }

// Get a single audit log from the root collection by ID
  Future<AuditLog?> getAuditLogFranchise(
      String franchiseId, String logId) async {
    final doc = await _db.collection('audit_logs').doc(logId).get();
    if (!doc.exists) return null;
    // Optionally, you can check that doc.data()?['franchiseId'] == franchiseId if you want to enforce scoping here.
    return AuditLog.fromFirestore(doc.data()!, doc.id);
  }

// Stream audit logs from the root collection, filtered by franchiseId (and optionally userId/action)
  Stream<List<AuditLog>> auditLogsStreamFranchise(
    String franchiseId, {
    String? userId,
    String? action,
  }) {
    firestore.Query query = _db
        .collection('audit_logs')
        .where('franchiseId', isEqualTo: franchiseId)
        .orderBy('timestamp', descending: true);
    if (userId != null) query = query.where('userId', isEqualTo: userId);
    if (action != null) query = query.where('action', isEqualTo: action);
    return query.snapshots().map((snap) => snap.docs
        .map((doc) =>
            AuditLog.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // --- STAFF/ADMIN USERS MANAGEMENT (FOR HQ/FRANCHISE DASHBOARDS) ---

  /// Get all users with staff/admin roles for a franchise
  Stream<List<app_user.User>> getStaffUsers(String franchiseId) {
    return _db
        .collection('users')
        .where('franchiseIds', arrayContains: franchiseId)
        .where('roles',
            arrayContainsAny: ['staff', 'manager', 'admin', 'hq_owner'])
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => app_user.User.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Add a staff/admin user (invite or onboarding logic should use this)
  Future<void> addStaffUser({
    required String name,
    required String email,
    String? phone,
    required List<String> roles,
    required List<String> franchiseIds,
  }) async {
    final docRef = _db.collection('users').doc();
    await docRef.set({
      'id': docRef.id,
      'name': name,
      'email': email,
      'phone': phone ?? '',
      'roles': roles,
      'franchiseIds': franchiseIds,
      'createdAt': firestore.FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  /// Remove a staff user by userId (sets isActive to false for soft delete)
  Future<void> removeStaffUser(String userId) async {
    await _db.collection('users').doc(userId).update({'isActive': false});
  }

  /// Invite logic (optional): Add to an "invites" collection, then create user on accept...

  // === FRANCHISE & BUSINESS LOGIC HELPERS ===

  Future<List<FranchiseInfo>> fetchFranchiseList() async {
    final snapshot = await _db.collection('franchises').get();
    return snapshot.docs.map((doc) {
      return FranchiseInfo.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  Future<List<FranchiseInfo>> getFranchises() async {
    final query = await _db.collection('franchises').get();
    return query.docs
        .map((doc) => FranchiseInfo.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // --- PAYOUTS ---

  Future<void> addOrUpdatePayout(Payout payout) async {
    await _db
        .collection('payouts')
        .doc(payout.id)
        .set(payout.toFirestore(), firestore.SetOptions(merge: true));
  }

  Future<Payout?> getPayoutById(String id) async {
    final doc = await _db.collection('payouts').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Payout.fromFirestore(doc.data()!, doc.id);
  }

  Future<void> deletePayout(String id) async {
    await _db.collection('payouts').doc(id).delete();
  }

  Stream<List<Payout>> payoutsStream({String? franchiseId, String? status}) {
    firestore.Query query = _db.collection('payouts');
    if (franchiseId != null) {
      query = query.where('franchiseId', isEqualTo: franchiseId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((doc) =>
            Payout.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // --- INVOICES ---

  Future<void> addOrUpdateInvoice(Invoice invoice) async {
    await _db
        .collection('invoices')
        .doc(invoice.id)
        .set(invoice.toFirestore(), firestore.SetOptions(merge: true));
  }

  Future<Invoice?> getInvoiceById(String id) async {
    final doc = await _db.collection('invoices').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Invoice.fromFirestore(doc.data()!, doc.id);
  }

  Future<void> deleteInvoice(String id) async {
    await _db.collection('invoices').doc(id).delete();
  }

  Stream<List<Invoice>> invoicesStream({String? franchiseId, String? status}) {
    firestore.Query query = _db.collection('invoices');
    if (franchiseId != null) {
      query = query.where('franchiseId', isEqualTo: franchiseId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((doc) =>
            Invoice.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // dunning in invoices
  Future<void> updateInvoiceDunningState(
      String invoiceId, String dunningState) async {
    await firestore.FirebaseFirestore.instance
        .collection('invoices')
        .doc(invoiceId)
        .update({
      'dunning_state': dunningState,
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  /// Add an overdue reminder to the invoice (atomic arrayUnion)
  Future<void> addInvoiceOverdueReminder(
      String invoiceId, Map<String, dynamic> reminder) async {
    await firestore.FirebaseFirestore.instance
        .collection('invoices')
        .doc(invoiceId)
        .update({
      'overdue_reminders': firestore.FieldValue.arrayUnion([reminder]),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  /// Set or update a payment plan object for an invoice
  Future<void> setInvoicePaymentPlan(
      String invoiceId, Map<String, dynamic> paymentPlan) async {
    await firestore.FirebaseFirestore.instance
        .collection('invoices')
        .doc(invoiceId)
        .update({
      'payment_plan': paymentPlan,
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  /// Add an escalation event/history entry (atomic arrayUnion)
  Future<void> addInvoiceEscalationEvent(
      String invoiceId, Map<String, dynamic> escalationEvent) async {
    await firestore.FirebaseFirestore.instance
        .collection('invoices')
        .doc(invoiceId)
        .update({
      'escalation_history': firestore.FieldValue.arrayUnion([escalationEvent]),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  /// Fetch dunning workflow fields for an invoice
  Future<Map<String, dynamic>?> getInvoiceWorkflowFields(
      String invoiceId) async {
    final doc = await firestore.FirebaseFirestore.instance
        .collection('invoices')
        .doc(invoiceId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return {
      'dunning_state': data['dunning_state'],
      'overdue_reminders': data['overdue_reminders'],
      'payment_plan': data['payment_plan'],
      'escalation_history': data['escalation_history'],
    };
  }

  /// Remove payment plan from invoice (if canceled or paid in full)
  Future<void> removeInvoicePaymentPlan(String invoiceId) async {
    await firestore.FirebaseFirestore.instance
        .collection('invoices')
        .doc(invoiceId)
        .update({
      'payment_plan': firestore.FieldValue.delete(),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  // --- REPORTS ---

  Future<void> addOrUpdateReport(Report report) async {
    await _db
        .collection('reports')
        .doc(report.id)
        .set(report.toFirestore(), firestore.SetOptions(merge: true));
  }

  Future<Report?> getReportById(String id) async {
    final doc = await _db.collection('reports').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Report.fromFirestore(doc.data()!, doc.id);
  }

  Future<void> deleteReport(String id) async {
    await _db.collection('reports').doc(id).delete();
  }

  Stream<List<Report>> reportsStream({String? franchiseId, String? type}) {
    firestore.Query query = _db.collection('reports');
    if (franchiseId != null) {
      query = query.where('franchiseId', isEqualTo: franchiseId);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((doc) =>
            Report.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
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
  Stream<List<Chat>> getSupportChats(String franchiseId) {
    return _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_supportChats)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Chat.fromFirestore(d.data(), d.id)).toList());
  }

  Future<void> deleteSupportChat(String franchiseId, String chatId) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_supportChats)
        .doc(chatId)
        .delete();
    await addAuditLogFranchise(
      franchiseId,
      AuditLog(
        id: '', // Leave blank if your Firestore assigns an ID, or generate one if needed
        action: 'delete_support_chat',
        userId: currentUserId ?? 'unknown',
        targetType: 'support_chat',
        targetId: chatId,
        details: 'Support chat deleted: $chatId', // Must be a String, not a Map
        timestamp: DateTime.now(),
        // userEmail and ipAddress optional
      ),
    );
  }

  Future<List<Chat>> getAllChats(String franchiseId) async {
    final snap = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_supportChats)
        .get();
    return snap.docs.map((d) => Chat.fromFirestore(d.data(), d.id)).toList();
  }

  Stream<List<Chat>> streamAllChats(String franchiseId) {
    return _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_supportChats)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Chat.fromFirestore(d.data(), d.id)).toList());
  }

  Future<void> deleteChat(String franchiseId, String chatId) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_supportChats)
        .doc(chatId)
        .delete();
    await addAuditLogFranchise(
      franchiseId,
      AuditLog(
        id: '', // Firestore will auto-assign; leave blank or generate if needed
        action: 'delete_chat',
        userId: currentUserId ?? 'unknown',
        targetType: 'chat',
        targetId: chatId,
        details: null, // Or add a string if you want details
        timestamp: DateTime.now(),
        userEmail: null, // Or supply if available
        ipAddress: null, // Or supply if available
      ),
    );
  }

  Future<void> sendMessage(
    String franchiseId, {
    required String chatId,
    required String senderId,
    required String content,
    String role = 'user',
  }) async {
    final messageRef = _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_supportChats)
        .doc(chatId)
        .collection('messages')
        .doc();
    await messageRef.set({
      'senderId': senderId,
      'content': content,
      'timestamp': firestore.FieldValue.serverTimestamp(),
      'status': 'sent',
      'role': role,
    });
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_supportChats)
        .doc(chatId)
        .set({
      'lastMessage': content,
      'lastMessageAt': firestore.FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'status': 'open',
      'userId': senderId,
    }, firestore.SetOptions(merge: true));
  }

  Future<void> sendSupportReply({
    required String franchiseId,
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    await sendMessage(
      franchiseId,
      chatId: chatId,
      senderId: senderId,
      content: content,
      role: 'support',
    );
  }

  Stream<List<Message>> streamChatMessages(String franchiseId, String chatId) {
    return _db
        .collection('franchises')
        .doc(franchiseId)
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

  // --- BANK ACCOUNTS ---

  Future<void> addOrUpdateBankAccount(BankAccount account) async {
    await _db
        .collection('bank_accounts')
        .doc(account.id)
        .set(account.toFirestore(), firestore.SetOptions(merge: true));
  }

  Future<BankAccount?> getBankAccountById(String id) async {
    final doc = await _db.collection('bank_accounts').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return BankAccount.fromFirestore(doc.data()!, doc.id);
  }

  Future<void> deleteBankAccount(String id) async {
    await _db.collection('bank_accounts').doc(id).delete();
  }

  Stream<List<BankAccount>> bankAccountsStream({String? franchiseId}) {
    firestore.Query query = _db.collection('bank_accounts');
    if (franchiseId != null) {
      query = query.where('franchiseId', isEqualTo: franchiseId);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((doc) => BankAccount.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // --- ANALYTICS SUMMARY / EXPORT ---

  Future<AnalyticsSummary?> getAnalyticsSummary(String franchiseId,
      {required String period}) async {
    final doc = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('analytics_summaries')
        .doc(period)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return AnalyticsSummary.fromFirestore(doc.data()!, doc.id);
  }

  Future<String> exportAnalyticsToCsv(String franchiseId,
      {required String period}) async {
    final summary = await getAnalyticsSummary(franchiseId, period: period);
    if (summary == null) return '';
    return ExportUtils.analyticsSummaryToCsv(summary);
  }

  /// Returns total revenue for today
  Future<double> getTotalRevenueToday(String franchiseId) async {
    final now = DateTime.now();
    final localMidnight = DateTime(now.year, now.month, now.day);
    final utcStart = localMidnight.toUtc();
    final utcEnd = utcStart.add(const Duration(days: 1));
    final snapshot = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .where('timestamp',
            isGreaterThanOrEqualTo: firestore.Timestamp.fromDate(utcStart))
        .where('timestamp', isLessThan: firestore.Timestamp.fromDate(utcEnd))
        .get();
    double total = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final double amount = (data['total'] is int)
          ? (data['total'] as int).toDouble()
          : (data['total'] ?? 0.0) as double;
      total += amount;
    }
    return total;
  }

  /// Returns total revenue for a given period: 'week' or 'month'
  Future<double> getTotalRevenueForPeriod(
      String franchiseId, String period) async {
    final now = DateTime.now();
    late DateTime start, end;
    if (period == 'week') {
      // Start of week (Monday)
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
      end = start.add(const Duration(days: 7));
    } else if (period == 'month') {
      // Start of month
      start = DateTime(now.year, now.month, 1);
      end = (now.month < 12)
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(now.year + 1, 1, 1);
    } else {
      throw ArgumentError('Invalid period: $period');
    }
    // Convert local period boundaries to UTC for the Firestore query
    final utcStart = start.toUtc();
    final utcEnd = end.toUtc();

    final snapshot = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .where('timestamp',
            isGreaterThanOrEqualTo: firestore.Timestamp.fromDate(utcStart))
        .where('timestamp', isLessThan: firestore.Timestamp.fromDate(utcEnd))
        .get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final double amount = (data['total'] is int)
          ? (data['total'] as int).toDouble()
          : (data['total'] ?? 0.0) as double;
      total += amount;
    }
    return total;
  }

  /// Get the total number of orders for today for a franchise
  Future<int> getTotalOrdersTodayCount({required String franchiseId}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .get();

    return snapshot.docs.length;
  }

  // --- UTILITIES ---

  void _logFirestoreError(String context, Object e, [StackTrace? stack]) {
    // Optional: Implement platform logging here
    print('[FirestoreService][$context] Error: $e');
    if (stack != null) print(stack);
  }

  // --- MENU ITEMS ---
  Future<void> addMenuItem(String franchiseId, MenuItem item,
      {String? userId}) async {
    assert(item.categoryId.isNotEmpty, 'categoryId must not be empty');
    final doc = _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_menuItems)
        .doc();
    final data = item.copyWith(id: doc.id).toFirestore();
    data['customizations'] =
        item.customizations.map((c) => c.toFirestore()).toList();
    data['includedIngredients'] = item.includedIngredients ?? [];
    data['optionalAddOns'] = item.optionalAddOns ?? [];
    await doc.set(data);
    await AuditLogService().addLog(
      franchiseId: franchiseId,
      action: 'add_menu_item',
      userId: userId ?? currentUserId ?? 'unknown',
      details: {'menuItemId': doc.id, 'name': item.name},
    );
  }

  Future<void> updateMenuItem(String franchiseId, MenuItem item,
      {String? userId}) async {
    try {
      final data = item.toFirestore();
      if (item.customizations.isNotEmpty) {
        data['customizations'] =
            item.customizations.map((c) => c.toFirestore()).toList();
      }
      await _db
          .collection('franchises')
          .doc(franchiseId)
          .collection(_menuItems)
          .doc(item.id)
          .update(data);
      await AuditLogService().addLog(
        franchiseId: franchiseId,
        action: 'update_menu_item',
        userId: userId ?? currentUserId ?? 'unknown',
        details: {'menuItemId': item.id, 'name': item.name},
      );
    } catch (e, stack) {
      _logFirestoreError('updateMenuItem', e, stack);
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String franchiseId, String id,
      {String? userId}) async {
    try {
      await _db
          .collection('franchises')
          .doc(franchiseId)
          .collection(_menuItems)
          .doc(id)
          .delete();
      await AuditLogService().addLog(
        franchiseId: franchiseId,
        action: 'delete_menu_item',
        userId: userId ?? currentUserId ?? 'unknown',
        details: {'menuItemId': id},
      );
    } catch (e, stack) {
      _logFirestoreError('deleteMenuItem', e, stack);
      rethrow;
    }
  }

  Stream<List<MenuItem>> getMenuItems(String franchiseId,
      {String? search, String? sortBy, bool descending = false}) {
    firestore.Query query =
        _db.collection('franchises').doc(franchiseId).collection(_menuItems);
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

  Future<List<MenuItem>> getMenuItemsOnce(
    String franchiseId,
  ) async {
    final snap = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_menuItems)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      if (data['customizations'] == null || data['customizations'] is! List) {
        data['customizations'] = [];
      }
      return MenuItem.fromFirestore(data, d.id);
    }).toList();
  }

  // get categories
  Stream<List<Category>> getCategories(String franchiseId,
      {String? search, String? sortBy, bool descending = false}) {
    firestore.Query query =
        _db.collection('franchises').doc(franchiseId).collection(_categories);

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

  Future<void> addCategory(String franchiseId, Category category,
      {String? userId}) async {
    final doc = _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_categories)
        .doc();
    final categoryWithId = Category(
      id: doc.id,
      name: category.name,
      description: category.description,
      image: category.image,
      // Add other fields if your model has them!
    );
    await doc.set(categoryWithId.toFirestore());
    // Optionally log this action for auditing:
    // await AuditLogService().addLog(...);
  }

  Future<void> updateCategory(String franchiseId, Category category,
      {String? userId}) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_categories)
        .doc(category.id)
        .update(category.toFirestore());
    // Optionally log this action for auditing:
    // await AuditLogService().addLog(...);
  }

  Future<void> deleteCategory(String franchiseId, String id,
      {String? userId}) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_categories)
        .doc(id)
        .delete();
    // Optionally log this action for auditing:
    // await AuditLogService().addLog(...);
  }

  // get categories schema
  /// Get a category schema by franchise and categoryId
  Future<Map<String, dynamic>?> getCategorySchema(
      String franchiseId, String categoryId) async {
    try {
      final doc = await _db
          .collection('franchises')
          .doc(franchiseId)
          .collection('category_schemas')
          .doc(categoryId)
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e, stack) {
      _logFirestoreError('getCategorySchema', e, stack);
      return null;
    }
  }

  /// Get all category schema IDs for a franchise
  Future<List<String>> getAllCategorySchemaIds(String franchiseId) async {
    final snap = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('category_schemas')
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  /// Get all customization templates from Firestore.
  Future<Map<String, dynamic>> getCustomizationTemplates(
    String franchiseId,
  ) async {
    try {
      final snap = await _db
          .collection('franchises')
          .doc(franchiseId)
          .collection('customization_templates')
          .get();
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

  Future<List<Map<String, dynamic>>> fetchCustomizationTemplatesAsMaps(
    String franchiseId,
  ) async {
    final snapshot = await firestore.FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('customization_templates')
        .get();

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
      String franchiseId, String templateId) async {
    try {
      final doc = await _db
          .collection('franchises')
          .doc(franchiseId)
          .collection('customization_templates')
          .doc(templateId)
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e, stack) {
      _logFirestoreError('getCustomizationTemplate', e, stack);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> resolveCustomizations(
      String franchiseId, List<dynamic> rawCustomizations) async {
    final List<Map<String, dynamic>> resolved = [];

    for (final entry in rawCustomizations) {
      if (entry is Map<String, dynamic> && entry.containsKey('templateRef')) {
        final templateId = entry['templateRef'];
        try {
          final template =
              await getCustomizationTemplate(franchiseId, templateId);
          if (template != null) {
            resolved.add(template);
          }
        } catch (e) {
          await logSchemaError(
            franchiseId,
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

  Future<void> updateMenuItemCustomizations(String franchiseId,
      String menuItemId, List<Customization> customizations) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_menuItems)
        .doc(menuItemId)
        .update({
      'customizations': customizations.map((c) => c.toFirestore()).toList(),
      'lastModified': firestore.FieldValue.serverTimestamp(),
      'lastModifiedBy': currentUserId ?? 'system',
    });
  }

  Future<void> updateMenuItemCustomizationsWithAudit(
      String franchiseId, String menuItemId, List<Customization> customizations,
      {String? userId}) async {
    await updateMenuItemCustomizations(franchiseId, menuItemId, customizations);
    await AuditLogService().addLog(
      franchiseId: franchiseId,
      action: 'update_menu_item_customizations',
      userId: userId ?? currentUserId ?? 'unknown',
      details: {
        'menuItemId': menuItemId,
        'customizationsCount': customizations.length
      },
    );
  }

  Future<List<Customization>> getMenuItemCustomizations(
      String franchiseId, String menuItemId) async {
    final doc = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_menuItems)
        .doc(menuItemId)
        .get();
    if (!doc.exists || doc.data() == null) return [];
    final data = doc.data()!;
    if (data['customizations'] == null) return [];
    return (data['customizations'] as List<dynamic>)
        .map((e) => Customization.fromFirestore(Map<String, dynamic>.from(e)))
        .toList();
  }

  Stream<List<MenuItem>> getMenuItemsByIds(
      String franchiseId, List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);
    if (ids.length <= 10) {
      return _db
          .collection('franchises')
          .doc(franchiseId)
          .collection(_menuItems)
          .where(firestore.FieldPath.documentId, whereIn: ids)
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
            .collection('franchises')
            .doc(franchiseId)
            .collection(_menuItems)
            .where(firestore.FieldPath.documentId, whereIn: batchIds)
            .snapshots()
            .map((snap) => snap.docs
                .map((d) => MenuItem.fromFirestore(d.data(), d.id))
                .toList()));
      }
      return StreamZip(batches)
          .map((listOfLists) => listOfLists.expand((x) => x).toList());
    }
  }

  List<Customization> getCustomizationGroups(MenuItem item) {
    return item.customizations.where((c) => c.isGroup).toList();
  }

  List<Customization> getPreselectedCustomizations(MenuItem item) {
    List<Customization> flatten(List<Customization> list) {
      return list
          .expand(
              (c) => c.isGroup && c.options != null ? flatten(c.options!) : [c])
          .toList();
    }

    return flatten(item.customizations).where((c) => c.isDefault).toList();
  }

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

  // Inventory
  /// Add an inventory record for a franchise
  Future<void> addInventory(String franchiseId, Inventory inventory) async {
    final doc = _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_inventory)
        .doc();
    await doc.set(inventory.copyWith(id: doc.id).toFirestore());
  }

  /// Update an inventory record
  Future<void> updateInventory(String franchiseId, Inventory inventory) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_inventory)
        .doc(inventory.id)
        .update(inventory.toFirestore());
  }

  /// Delete an inventory record
  Future<void> deleteInventory(String franchiseId, String id) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_inventory)
        .doc(id)
        .delete();
  }

  /// Get a stream of inventory transactions for a franchise
  Stream<List<Inventory>> getInventory(String franchiseId) {
    return _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_inventory)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Inventory.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// get cashflow for a franchise
  /// Returns the most recent cash flow forecast for a franchise (or null if none)
  Future<Map<String, dynamic>?> getCashFlowForecast(String franchiseId) async {
    final snap = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(
            'cash_flow_forecasts') // Or adjust collection name as needed
        .orderBy('period', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }

  /// get franchise analytics summary
  Future<Map<String, dynamic>> getFranchiseAnalyticsSummary(
      String franchiseId) async {
    final snap = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('analytics_summaries')
        .orderBy('period', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return {};
    return snap.docs.first.data();
  }

  /// get outstanding invoices
  Future<double> getOutstandingInvoices(String franchiseId) async {
    final snap = await _db
        .collection('invoices')
        .where('franchiseId', isEqualTo: franchiseId)
        .where('status', isEqualTo: 'sent')
        .get();

    double total = 0.0;
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['paid_at'] == null) {
        total += (data['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  /// get last payout
  Future<Map<String, dynamic>> getLastPayout(String franchiseId) async {
    final snap = await _db
        .collection('payouts')
        .where('franchiseId', isEqualTo: franchiseId)
        .orderBy('scheduled_at', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return {};
    final data = snap.docs.first.data();
    return {
      'amount': data['amount'],
      'date': data['scheduled_at']?.toDate()?.toIso8601String(),
    };
  }

  // Promo methods
  Future<void> addPromo(String franchiseId, Promo promo) async => _db
      .collection('franchises')
      .doc(franchiseId)
      .collection('promotions')
      .doc(promo.id)
      .set(promo.toFirestore());

  Stream<List<Promo>> getPromos(String franchiseId) {
    return _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('promotions')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Promo.fromFirestore(d.data(), d.id)).toList());
  }

  Future<void> updatePromo(String franchiseId, Promo promo) async => _db
      .collection('franchises')
      .doc(franchiseId)
      .collection('promotions')
      .doc(promo.id)
      .update(promo.toFirestore());

  Future<void> deletePromo(String franchiseId, String promoId) async => _db
      .collection('franchises')
      .doc(franchiseId)
      .collection('promotions')
      .doc(promoId)
      .delete();

  // Feedback methods
  Stream<List<feedback_model.FeedbackEntry>> getFeedbackEntries(
      String franchiseId) {
    return _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_feedback)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                feedback_model.FeedbackEntry.fromFirestore(d.data(), d.id))
            .toList());
  }

  Future<void> deleteFeedbackEntry(String franchiseId, String id) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_feedback)
        .doc(id)
        .delete();
    // Optional: log this with audit if you want
  }

  // support_requests
  /// Adds a new support request
  Future<firestore.DocumentReference> addSupportRequest(
      Map<String, dynamic> data) async {
    final now = firestore.FieldValue.serverTimestamp();
    data['created_at'] ??= now;
    data['updated_at'] ??= now;
    return await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .add(data);
  }

  /// Updates an existing support request
  Future<void> updateSupportRequest(
      String requestId, Map<String, dynamic> updates) async {
    updates['updated_at'] = firestore.FieldValue.serverTimestamp();
    await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .update(updates);
  }

  /// Get a support request by ID
  Future<Map<String, dynamic>?> getSupportRequestById(String requestId) async {
    final doc = await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  /// Stream support requests, optionally filtered by franchise/location/status/type
  Stream<List<Map<String, dynamic>>> supportRequestsStream({
    String? franchiseId,
    String? locationId,
    String? status,
    String? type,
    String? assignedTo,
    String? openedBy,
    int limit = 50,
  }) {
    firestore.Query query =
        firestore.FirebaseFirestore.instance.collection('support_requests');
    if (franchiseId != null) {
      query = query.where('franchiseId', isEqualTo: franchiseId);
    }
    if (locationId != null) {
      query = query.where('locationId', isEqualTo: locationId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    if (assignedTo != null) {
      query = query.where('assigned_to', isEqualTo: assignedTo);
    }
    if (openedBy != null) {
      query = query.where('opened_by', isEqualTo: openedBy);
    }
    query = query.orderBy('created_at', descending: true).limit(limit);

    return query.snapshots().map((snap) =>
        snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  /// Append a message to a support request (atomic arrayUnion)
  Future<void> addMessageToSupportRequest(
      String requestId, Map<String, dynamic> message) async {
    await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .update({
      'messages': firestore.FieldValue.arrayUnion([message]),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  /// Delete a support request
  Future<void> deleteSupportRequest(String requestId) async {
    await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .delete();
  }

  /// Add a support note (internal only, atomic arrayUnion)
  Future<void> addSupportNote(
      String requestId, Map<String, dynamic> note) async {
    await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .update({
      'support_notes': firestore.FieldValue.arrayUnion([note]),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  /// Set or update ticket type taxonomy (e.g., 'billing', 'technical', etc.)
  Future<void> updateSupportType(String requestId, String type) async {
    await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .update({
      'type': type,
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  /// Link entities (e.g., invoiceId, paymentId) to a ticket
  Future<void> linkEntitiesToSupportRequest(String requestId,
      {String? invoiceId, String? paymentId}) async {
    final update = <String, dynamic>{};
    if (invoiceId != null) update['invoiceId'] = invoiceId;
    if (paymentId != null) update['paymentId'] = paymentId;
    update['updated_at'] = firestore.FieldValue.serverTimestamp();

    await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .update(update);
  }

  /// Update ticket status (with audit fields, e.g., close or escalate)
  Future<void> updateSupportRequestStatus(
    String requestId, {
    required String status, // e.g. 'resolved', 'closed', etc.
    String? lastUpdatedBy,
    String? resolutionNotes,
  }) async {
    final update = <String, dynamic>{
      'status': status,
      'updated_at': firestore.FieldValue.serverTimestamp(),
    };
    if (lastUpdatedBy != null) update['last_updated_by'] = lastUpdatedBy;
    if (resolutionNotes != null) update['resolution_notes'] = resolutionNotes;
    if (status == 'closed' || status == 'resolved') {
      update['closed_at'] = firestore.FieldValue.serverTimestamp();
    }
    await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .update(update);
  }

  /// Get all support notes for a request
  Future<List<Map<String, dynamic>>> getSupportNotes(String requestId) async {
    final doc = await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .get();
    if (!doc.exists) return [];
    final data = doc.data()!;
    final notes = data['support_notes'] as List<dynamic>? ?? [];
    return notes.cast<Map<String, dynamic>>();
  }

  /// Filter/stream tickets by type or status (for taxonomy/reporting)
  Stream<List<Map<String, dynamic>>> supportRequestsByTypeOrStatus({
    String? type,
    String? status,
    int limit = 50,
  }) {
    var query = firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snap) =>
        snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  // tax_reports
  Future<firestore.DocumentReference> addTaxReport(
      Map<String, dynamic> data) async {
    final now = firestore.FieldValue.serverTimestamp();
    data['created_at'] ??= now;
    data['updated_at'] ??= now;
    return await firestore.FirebaseFirestore.instance
        .collection('tax_reports')
        .add(data);
  }

  /// Update an existing tax report by ID
  Future<void> updateTaxReport(
      String reportId, Map<String, dynamic> updates) async {
    updates['updated_at'] = firestore.FieldValue.serverTimestamp();
    await firestore.FirebaseFirestore.instance
        .collection('tax_reports')
        .doc(reportId)
        .update(updates);
  }

  /// Get a tax report by ID
  Future<Map<String, dynamic>?> getTaxReportById(String reportId) async {
    final doc = await firestore.FirebaseFirestore.instance
        .collection('tax_reports')
        .doc(reportId)
        .get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  /// Stream tax reports, with filters
  Stream<List<Map<String, dynamic>>> taxReportsStream({
    String? franchiseId,
    String? brandId,
    String? reportType, // e.g., "sales_tax"
    String? status, // e.g., "filed", "pending"
    String? taxAuthority,
    DateTime? filedAfter,
    DateTime? filedBefore,
    int limit = 100,
  }) {
    var query = firestore.FirebaseFirestore.instance
        .collection('tax_reports')
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (franchiseId != null) {
      query = query.where('franchiseId', isEqualTo: franchiseId);
    }
    if (brandId != null) {
      query = query.where('brandId', isEqualTo: brandId);
    }
    if (reportType != null) {
      query = query.where('report_type', isEqualTo: reportType);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (taxAuthority != null) {
      query = query.where('tax_authority', isEqualTo: taxAuthority);
    }
    if (filedAfter != null) {
      query =
          query.where('date_filed', isGreaterThanOrEqualTo: filedAfter.toUtc());
    }
    if (filedBefore != null) {
      query =
          query.where('date_filed', isLessThanOrEqualTo: filedBefore.toUtc());
    }

    return query.snapshots().map((snap) =>
        snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  /// Delete a tax report by ID
  Future<void> deleteTaxReport(String reportId) async {
    await firestore.FirebaseFirestore.instance
        .collection('tax_reports')
        .doc(reportId)
        .delete();
  }

  /// Add a reminder to a tax report (atomic arrayUnion)
  Future<void> addTaxReportReminder(
      String reportId, Map<String, dynamic> reminder) async {
    await firestore.FirebaseFirestore.instance
        .collection('tax_reports')
        .doc(reportId)
        .update({
      'reminders_sent': firestore.FieldValue.arrayUnion([reminder]),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  /// Attach a file to a tax report (atomic arrayUnion)
  Future<void> addTaxReportAttachment(
      String reportId, Map<String, dynamic> attachment) async {
    await firestore.FirebaseFirestore.instance
        .collection('tax_reports')
        .doc(reportId)
        .update({
      'attached_files': firestore.FieldValue.arrayUnion([attachment]),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }
}

// Helper: Delayed user stream
Stream<app_user.User?> delayedUserStream(
    FirestoreService fs, String uid) async* {
  print('[delayedUserStream] Waiting to fetch user $uid');
  await Future.delayed(const Duration(seconds: 1));
  print('[delayedUserStream] Fetching user $uid from Firestore');
  final user = await fs.getUser(uid);
  print('[delayedUserStream] Got user: $user');
  yield user;
}
