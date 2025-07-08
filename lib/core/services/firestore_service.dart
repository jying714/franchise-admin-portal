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
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import 'package:franchise_admin_portal/core/models/order.dart';
import 'package:franchise_admin_portal/core/models/error_log.dart';

extension ErrorLogsService on FirestoreService {
  /// Fetches paginated, filterable error logs from Firestore.
  Stream<List<ErrorLog>> streamErrorLogs({
    int limit = 50,
    String? severity,
    String? source,
    String? screen,
    DateTime? start,
    DateTime? end,
    String? search,
    bool archived = false, // Show archived logs (default: false)
    bool?
        showResolved, // <-- Accepts null (all), false (unresolved), true (resolved)
  }) {
    print(
        'FirestoreService.streamErrorLogs called with: severity=$severity, source=$source, screen=$screen, start=$start, end=$end, search=$search, archived=$archived, showResolved=$showResolved');
    firestore.Query query = _db.collection('error_logs');

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
    query = query.orderBy('timestamp', descending: true).limit(limit);

    return query.snapshots().map((snap) {
      final logs = snap.docs
          .map((doc) => ErrorLog.tryParse(doc))
          .whereType<ErrorLog>()
          .toList();
      final uniqueSeverities = logs.map((e) => e.severity).toSet();
      print('Severities in Firestore: $uniqueSeverities');
      return logs;
    });
  }
}

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

  // order
  static Order fromFirestore(Map<String, dynamic> data, String id) {
    return Order.fromFirestore(data, id);
  }

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
  Future<List<IngredientMetadata>> getIngredientMetadataByIds(
      List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final snap = await _db
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
      {bool forceRefresh = false}) async {
    final all = await getAllIngredientMetadata(forceRefresh: forceRefresh);
    return {for (final meta in all) meta.id: meta};
  }

  Future<List<Map<String, dynamic>>> fetchIngredientMetadataAsMaps(
      {bool forceRefresh = false}) async {
    final all = await getAllIngredientMetadata(forceRefresh: forceRefresh);
    return all.map((meta) => meta.toMap()).toList();
  }

  void _logFirestoreError(String context, Object e, [StackTrace? stack]) {
    // Optionally implement logging
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

  // --- Orders ---
  Stream<List<Order>> getAllOrdersStream() {
    return firestore.FirebaseFirestore.instance
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Order.fromFirestore(data, doc.id);
            }).toList());
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await firestore.FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({
      'status': newStatus,
      'lastModified': firestore.FieldValue.serverTimestamp(),
    });
  }

  Future<void> refundOrder(String orderId,
      {double? amount, String? refundReason}) async {
    await firestore.FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({
      'refundStatus': 'refunded',
      if (amount != null) 'refundAmount': amount,
      if (refundReason != null) 'refundReason': refundReason,
      'refundedAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitOrderFeedback({
    required String orderId,
    required String userId,
    required String message,
    required int rating,
  }) async {
    final doc =
        firestore.FirebaseFirestore.instance.collection('feedback').doc();
    await doc.set({
      'orderId': orderId,
      'userId': userId,
      'message': message,
      'rating': rating,
      'timestamp': firestore.FieldValue.serverTimestamp(),
    });
  }

  Future<int> getTotalOrdersTodayCount({String? franchiseId}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    var query = firestore.FirebaseFirestore.instance
        .collection('orders')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay);

    if (franchiseId != null) {
      query = query.where('franchiseId', isEqualTo: franchiseId);
    }

    final snapshot = await query.get();
    return snapshot.docs.length;
  }

  // --- MENU ITEMS ---
  Future<void> addMenuItem(MenuItem item, {String? userId}) async {
    assert(item.categoryId.isNotEmpty, 'categoryId must not be empty');
    final doc = _db.collection(_menuItems).doc();
    final data = item.copyWith(id: doc.id).toFirestore();
    data['customizations'] =
        item.customizations.map((c) => c.toFirestore()).toList();
    data['includedIngredients'] = item.includedIngredients ?? [];
    data['optionalAddOns'] = item.optionalAddOns ?? [];
    await doc.set(data);
    await AuditLogService().addLog(
      action: 'add_menu_item',
      userId: userId ?? currentUserId ?? 'unknown',
      details: {'menuItemId': doc.id, 'name': item.name},
    );
  }

  Future<void> updateMenuItem(MenuItem item, {String? userId}) async {
    try {
      final data = item.toFirestore();
      if (item.customizations.isNotEmpty) {
        data['customizations'] =
            item.customizations.map((c) => c.toFirestore()).toList();
      }
      await _db.collection(_menuItems).doc(item.id).update(data);
      await AuditLogService().addLog(
        action: 'update_menu_item',
        userId: userId ?? currentUserId ?? 'unknown',
        details: {'menuItemId': item.id, 'name': item.name},
      );
    } catch (e, stack) {
      _logFirestoreError('updateMenuItem', e, stack);
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String id, {String? userId}) async {
    try {
      await _db.collection(_menuItems).doc(id).delete();
      await AuditLogService().addLog(
        action: 'delete_menu_item',
        userId: userId ?? currentUserId ?? 'unknown',
        details: {'menuItemId': id},
      );
    } catch (e, stack) {
      _logFirestoreError('deleteMenuItem', e, stack);
      rethrow;
    }
  }

  Stream<List<MenuItem>> getMenuItems(
      {String? search, String? sortBy, bool descending = false}) {
    firestore.Query query = _db.collection(_menuItems);
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
    final snapshot = await firestore.FirebaseFirestore.instance
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

  Future<void> logSchemaError({
    required String message,
    String? templateId,
    String? menuItemId,
    String? stackTrace,
    String? userId,
  }) async {
    await firestore.FirebaseFirestore.instance.collection('error_logs').add({
      'timestamp': firestore.FieldValue.serverTimestamp(),
      'message': message,
      if (templateId != null) 'templateId': templateId,
      if (menuItemId != null) 'menuItemId': menuItemId,
      if (userId != null) 'userId': userId,
      if (stackTrace != null) 'stackTrace': stackTrace,
      'source': 'customization_template_resolution'
    });
  }

  Future<void> logError({
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
      await firestore.FirebaseFirestore.instance
          .collection('error_logs')
          .add(data);
    } catch (e, stack) {
      print('[ERROR LOGGING FAILURE] $e\n$stack');
    }
  }

  // Update a log (e.g., mark as resolved, archive, or add a comment)
  Future<void> updateErrorLog(
      String logId, Map<String, dynamic> updates) async {
    await _db.collection('error_logs').doc(logId).update(updates);
  }

// Add a comment to an error log
  Future<void> addCommentToErrorLog(
      String logId, Map<String, dynamic> comment) async {
    await _db.collection('error_logs').doc(logId).update({
      'comments': firestore.FieldValue.arrayUnion([comment]),
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });
  }

// Mark an error log as resolved or archived
  Future<void> setErrorLogStatus(String logId,
      {bool? resolved, bool? archived}) async {
    final updates = <String, dynamic>{};
    if (resolved != null) updates['resolved'] = resolved;
    if (archived != null) updates['archived'] = archived;
    updates['updatedAt'] = firestore.FieldValue.serverTimestamp();
    await _db.collection('error_logs').doc(logId).update(updates);
  }

  Future<void> deleteErrorLog(String logId) async {
    await _db.collection('error_logs').doc(logId).delete();
  }

  Future<MenuItem?> getMenuItemById(String id) async {
    final doc = await _db.collection(_menuItems).doc(id).get();

    if (!doc.exists || doc.data() == null) return null;
    var data = doc.data()!;
    if (data['customizations'] != null && data['customizations'] is! List) {
      data['customizations'] = [];
    }
    return MenuItem.fromFirestore(data, doc.id);
  }

  Future<void> bulkUploadMenuItems(List<MenuItem> items,
      {String? userId}) async {
    final batch = _db.batch();
    for (final item in items) {
      final docRef = _db.collection(_menuItems).doc();
      var data = item.copyWith(id: docRef.id).toFirestore();
      if (item.customizations.isNotEmpty) {
        data['customizations'] =
            item.customizations.map((c) => c.toFirestore()).toList();
      }
      batch.set(docRef, data);
    }
    await batch.commit();
    await AuditLogService().addLog(
      action: 'bulk_upload_menu_items',
      userId: userId ?? currentUserId ?? 'unknown',
      details: {'count': items.length},
    );
  }

  Future<String> exportMenuToCsv() async {
    final snap = await _db.collection(_menuItems).get();
    final items =
        snap.docs.map((d) => MenuItem.fromFirestore(d.data(), d.id)).toList();
    return ExportUtils.menuItemsToCsv(items);
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

  Future<void> bulkUploadPromos(List<Promo> promos, {String? userId}) async {
    final batch = _db.batch();
    for (final promo in promos) {
      final docRef = _db.collection(_promotions).doc();
      batch.set(docRef, promo.copyWith(id: docRef.id).toFirestore());
    }
    await batch.commit();
    await AuditLogService().addLog(
      action: 'bulk_upload_promos',
      userId: userId ?? currentUserId ?? 'unknown',
      details: {'count': promos.length},
    );
  }

  Future<String> exportPromosToCsv() async {
    final promos = await getPromosOnce();
    return ExportUtils.promosToCsv(promos);
  }

  // --- Promotion Aliases for Admin UI Compatibility ---
  Stream<List<Promo>> getPromotions() => getPromos();
  Future<void> deletePromotion(String promoId) => deletePromo(promoId);

  // --- INVENTORY (Admin/Inventory Panel) ---
  Stream<List<Inventory>> getInventory() {
    return _db.collection(_inventory).snapshots().map((snap) =>
        snap.docs.map((d) => Inventory.fromFirestore(d.data(), d.id)).toList());
  }

  Future<void> addInventory(Inventory inventory) async {
    final doc = _db.collection(_inventory).doc();
    await doc.set(inventory.copyWith(id: doc.id).toFirestore());
  }

  Future<void> updateInventory(Inventory inventory) async {
    await _db
        .collection(_inventory)
        .doc(inventory.id)
        .update(inventory.toFirestore());
  }

  Future<void> deleteInventory(String id) async {
    await _db.collection(_inventory).doc(id).delete();
    await AuditLogService().addLog(
      action: 'delete_inventory',
      userId: currentUserId ?? 'unknown',
      details: {'inventoryId': id},
    );
  }

  // --- FEATURE SETTINGS / FEATURE TOGGLES (admin/feature_settings/...) ---
  Future<Map<String, bool>> getFeatureToggles() async {
    final doc = await _db.collection('feature_toggles').doc('global').get();
    if (!doc.exists || doc.data() == null) return {};
    return Map<String, bool>.from(doc.data() as Map<String, dynamic>);
  }

  Future<void> updateFeatureToggle(String key, bool enabled) async {
    await _db
        .collection('feature_toggles')
        .doc('global')
        .set({key: enabled}, firestore.SetOptions(merge: true));
  }

  // --- CATEGORIES ---
  Stream<List<Category>> getCategories(
      {String? search, String? sortBy, bool descending = false}) {
    firestore.Query query = _db.collection(_categories);

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

  Future<void> addCategory(Category category, {String? userId}) async {
    final doc = _db.collection(_categories).doc();
    final categoryWithId = Category(
      id: doc.id,
      name: category.name,
      description: category.description,
      image: category.image,
    );
    await doc.set(categoryWithId.toFirestore());
    await AuditLogService().addLog(
      action: 'add_category',
      userId: userId ?? currentUserId ?? 'unknown',
      details: {'categoryId': doc.id, 'name': category.name},
    );
  }

  Future<void> updateCategory(Category category, {String? userId}) async {
    await _db
        .collection(_categories)
        .doc(category.id)
        .update(category.toFirestore());
    await AuditLogService().addLog(
      action: 'update_category',
      userId: userId ?? currentUserId ?? 'unknown',
      details: {'categoryId': category.id, 'name': category.name},
    );
  }

  Future<void> deleteCategory(String id, {String? userId}) async {
    await _db.collection(_categories).doc(id).delete();
    await AuditLogService().addLog(
      action: 'delete_category',
      userId: userId ?? currentUserId ?? 'unknown',
      details: {'categoryId': id},
    );
  }

  Future<void> bulkUploadCategories(List<Category> categories,
      {String? userId}) async {
    final batch = _db.batch();
    for (final cat in categories) {
      final docRef = _db.collection(_categories).doc();
      final catWithId = Category(
        id: docRef.id,
        name: cat.name,
        description: cat.description,
        image: cat.image,
      );
      batch.set(docRef, catWithId.toFirestore());
    }
    await batch.commit();
    await AuditLogService().addLog(
      action: 'bulk_upload_categories',
      userId: userId ?? currentUserId ?? 'unknown',
      details: {'count': categories.length},
    );
  }

  // --- STAFF USERS MANAGEMENT (Admin/Staff Access Panel) ---
  Stream<List<admin_user.User>> getStaffUsers() {
    return _db
        .collection('users')
        .where('role', whereIn: ['staff', 'manager', 'admin'])
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => admin_user.User.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> addStaffUser({
    required String name,
    required String email,
    String? phone,
    String role = 'staff',
  }) async {
    final docRef = _db.collection('users').doc();
    await docRef.set({
      'id': docRef.id,
      'name': name,
      'email': email,
      'phone': phone ?? '',
      'role': role,
      'createdAt': firestore.FieldValue.serverTimestamp(),
    });
    await AuditLogService().addLog(
      action: 'add_staff_user',
      userId: currentUserId ?? 'unknown',
      details: {
        'staffUserId': docRef.id,
        'name': name,
        'email': email,
        'role': role
      },
    );
  }

  Future<void> removeStaffUser(String staffUserId) async {
    await _db.collection('users').doc(staffUserId).delete();
    await AuditLogService().addLog(
      action: 'remove_staff_user',
      userId: currentUserId ?? 'unknown',
      details: {'staffUserId': staffUserId},
    );
  }

  // --- FEEDBACK MANAGEMENT (Admin/Feedback Management Panel) ---
  Stream<List<feedback_model.FeedbackEntry>> getFeedbackEntries() {
    return _db
        .collection(_feedback)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                feedback_model.FeedbackEntry.fromFirestore(d.data(), d.id))
            .toList());
  }

  Future<void> deleteFeedbackEntry(String id) async {
    await _db.collection(_feedback).doc(id).delete();
    await AuditLogService().addLog(
      action: 'delete_feedback_entry',
      userId: currentUserId ?? 'unknown',
      details: {'feedbackId': id},
    );
  }

  Future<List<feedback_model.FeedbackEntry>> getFeedbackOnce() async {
    final snap = await _db.collection(_feedback).get();
    return snap.docs
        .map((d) => feedback_model.FeedbackEntry.fromFirestore(d.data(), d.id))
        .toList();
  }

  Future<feedback_model.FeedbackEntry?> getFeedbackById(String id) async {
    final doc = await _db.collection(_feedback).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return feedback_model.FeedbackEntry.fromFirestore(doc.data()!, doc.id);
  }

  Future<Map<String, dynamic>?> getFeedbackStatsForPeriod(String period,
      {String? franchiseId}) async {
    final String docId = '${franchiseId ?? "default"}_$period';
    final doc = await _db.collection('analytics_summaries').doc(docId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    return data?['feedbackStats'] ?? {};
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

  Future<void> deleteSupportChat(String chatId) async {
    await _db.collection(_supportChats).doc(chatId).delete();
    await AuditLogService().addLog(
      action: 'delete_support_chat',
      userId: currentUserId ?? 'unknown',
      details: {'chatId': chatId},
    );
  }

  Future<List<Chat>> getAllChats() async {
    final snap = await _db.collection(_supportChats).get();
    return snap.docs.map((d) => Chat.fromFirestore(d.data(), d.id)).toList();
  }

  Stream<List<Chat>> streamAllChats() {
    return _db.collection(_supportChats).snapshots().map((snap) =>
        snap.docs.map((d) => Chat.fromFirestore(d.data(), d.id)).toList());
  }

  Future<void> deleteChat(String chatId) async {
    await _db.collection(_supportChats).doc(chatId).delete();
    await AuditLogService().addLog(
      action: 'delete_chat',
      userId: currentUserId ?? 'unknown',
      details: {'chatId': chatId},
    );
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String role = 'user',
  }) async {
    final messageRef =
        _db.collection(_supportChats).doc(chatId).collection('messages').doc();
    await messageRef.set({
      'senderId': senderId,
      'content': content,
      'timestamp': firestore.FieldValue.serverTimestamp(),
      'status': 'sent',
      'role': role,
    });
    await _db.collection(_supportChats).doc(chatId).set({
      'lastMessage': content,
      'lastMessageAt': firestore.FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'status': 'open',
      'userId': senderId,
    }, firestore.SetOptions(merge: true));
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

  // --- AUDIT LOGS ---
  Stream<List<AuditLog>> getAuditLogs({String? userId, String? action}) {
    firestore.Query query = _db.collection('audit_logs');
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    if (action != null) {
      query = query.where('action', isEqualTo: action);
    }
    return query.orderBy('timestamp', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => AuditLog.fromFirestore(
                  d.data() as Map<String, dynamic>, d.id))
              .toList(),
        );
  }

  // --- ANALYTICS DASHBOARD / EXPORT ---
  Future<AnalyticsSummary?> getAnalyticsSummary(
      {required String period}) async {
    final doc = await _db.collection('analytics_summaries').doc(period).get();
    if (!doc.exists || doc.data() == null) return null;
    return AnalyticsSummary.fromFirestore(doc.data()!, doc.id);
  }

  Future<String> exportAnalyticsToCsv({required String period}) async {
    final summary = await getAnalyticsSummary(period: period);
    if (summary == null) return '';
    return ExportUtils.analyticsSummaryToCsv(summary);
  }

  Future<String> exportMenuCsv() async {
    final snap = await _db.collection(_menuItems).get();
    final items =
        snap.docs.map((d) => MenuItem.fromFirestore(d.data(), d.id)).toList();
    return ExportUtils.menuItemsToCsv(items);
  }

  // --- MENU ONLINE STATUS (stub) ---
  Stream<bool> menuOnlineStatusStream() async* {
    yield true;
  }

  // ===================== DYNAMIC CATEGORY SCHEMA SUPPORT =====================

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

  Future<void> setCategorySchema(
      String categoryId, Map<String, dynamic> schema) async {
    await _db
        .collection('category_schemas')
        .doc(categoryId)
        .set(schema, firestore.SetOptions(merge: true));
  }

  Future<List<String>> getAllCategorySchemaIds() async {
    final snap = await _db.collection('category_schemas').get();
    return snap.docs.map((d) => d.id).toList();
  }

  Future<List<Map<String, dynamic>>> getAllCategorySchemas() async {
    final snapshot = await _db.collection('category_schemas').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> updateMenuItemCustomizations(
      String menuItemId, List<Customization> customizations) async {
    await _db.collection(_menuItems).doc(menuItemId).update({
      'customizations': customizations.map((c) => c.toFirestore()).toList(),
      'lastModified': firestore.FieldValue.serverTimestamp(),
      'lastModifiedBy': currentUserId ?? 'system',
    });
  }

  Future<void> updateMenuItemCustomizationsWithAudit(
      String menuItemId, List<Customization> customizations,
      {String? userId}) async {
    await updateMenuItemCustomizations(menuItemId, customizations);
    await AuditLogService().addLog(
      action: 'update_menu_item_customizations',
      userId: userId ?? currentUserId ?? 'unknown',
      details: {
        'menuItemId': menuItemId,
        'customizationsCount': customizations.length
      },
    );
  }

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

  Stream<List<MenuItem>> getMenuItemsByIds(List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);
    if (ids.length <= 10) {
      return _db
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
            firestore.SetOptions(merge: true),
          );
    }
  }

  Future<Map<String, dynamic>> getCustomizationFeatureToggles() async {
    final doc =
        await _db.collection('config').doc('customization_features').get();
    return doc.exists ? Map<String, dynamic>.from(doc.data()!) : {};
  }

  /// --- USER ---
  Future<void> addAddressForUser(String userId, Address address) async {
    final userRef =
        firestore.FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.update({
      'addresses': firestore.FieldValue.arrayUnion([address.toMap()])
    });
  }

  Future<void> updateAddressForUser(
      String userId, Address updatedAddress) async {
    final userDoc = await firestore.FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (!userDoc.exists) return;
    final data = userDoc.data();
    if (data == null || data['addresses'] == null) return;

    final addresses = List<Map<String, dynamic>>.from(data['addresses']);
    final index = addresses.indexWhere((a) => a['id'] == updatedAddress.id);
    if (index != -1) {
      addresses[index] = updatedAddress.toMap();
      await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'addresses': addresses});
    }
  }

  Future<void> removeAddressForUser(String userId, String addressId) async {
    final userDoc = await firestore.FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (!userDoc.exists) return;

    final data = userDoc.data();
    final addresses = List<Map<String, dynamic>>.from(data?['addresses'] ?? []);
    addresses.removeWhere((a) => a['id'] == addressId);

    await firestore.FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'addresses': addresses});
  }

  Stream<List<MenuItem>> getFavoriteMenuItemsForUser(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return MenuItem.fromMap(data, doc.id);
            }).toList());
  }

  Future<void> addFavoriteMenuItemForUser(
      String userId, Map<String, dynamic> favoriteItem) async {
    await firestore.FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      'favorites': firestore.FieldValue.arrayUnion([favoriteItem])
    });
  }

  Future<void> removeFavoriteMenuItemForUser(
      String userId, String menuItemId) async {
    final doc = await firestore.FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (!doc.exists) return;

    final data = doc.data();
    final List<dynamic> current = List.from(data?['favorites'] ?? []);
    current.removeWhere((f) => f['menuItemId'] == menuItemId);

    await firestore.FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      'favorites': current,
    });
  }

  Future<admin_user.User?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return admin_user.User.fromFirestore(doc.data()!, doc.id);
  }

  Future<void> addUser(admin_user.User user) async {
    await _db.collection('users').doc(user.id).set(user.toFirestore());
  }

  Stream<admin_user.User?> currentUserStream() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data != null) {
        return admin_user.User.fromFirestore(data, doc.id);
      } else {
        return null;
      }
    });
  }

  Stream<admin_user.User?> appUserStream() {
    return fb_auth.FirebaseAuth.instance
        .authStateChanges()
        .asyncExpand((fbUser) {
      if (fbUser == null) return Stream.value(null);
      print('Auth user detected: ${fbUser.uid}');
      return _db.collection('users').doc(fbUser.uid).snapshots().map((snap) {
        print('Firestore doc for ${fbUser.uid}: exists=${snap.exists}');
        if (snap.exists && snap.data() != null) {
          print('User data: ${snap.data()}');
          return admin_user.User.fromFirestore(snap.data()!, snap.id);
        } else {
          print('No user doc found');
          return null;
        }
      });
    });
  }

  Stream<admin_user.User?> userStream(String uid) {
    print('[FirestoreService] userStream($uid) CALLED');
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      print('Firestore doc for $uid: exists=${doc.exists} data=${doc.data()}');
      final data = doc.data();
      if (doc.exists && data != null) {
        try {
          final user = admin_user.User.fromFirestore(data, doc.id);
          print('userStream returning: $user');
          Future.delayed(Duration(milliseconds: 500))
              .then((_) => print('userStream tick $user'));
          return user;
        } catch (e, stack) {
          print('userStream mapping error: $e\n$stack');
          return null;
        }
      } else {
        print('Returning null for $uid');
        return null;
      }
    });
  }

  /// Returns total revenue for today
  Future<double> getTotalRevenueToday() async {
    final now = DateTime.now(); // local
    final localMidnight = DateTime(now.year, now.month, now.day);
    final utcStart = localMidnight.toUtc();
    final utcEnd = utcStart.add(const Duration(days: 1));
    final snapshot = await _db
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
  Future<double> getTotalRevenueForPeriod(String period) async {
    final now = DateTime.now(); // local time (not UTC!)
    late DateTime start, end;

    if (period == 'week') {
      // Start of week (Monday) in local time
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
      end = start.add(const Duration(days: 7));
    } else if (period == 'month') {
      // Start of month in local time
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
}

Stream<admin_user.User?> delayedUserStream(
    FirestoreService firestoreService, String uid) async* {
  print('[delayedUserStream] waiting 1s for Firestore token...');
  await Future.delayed(const Duration(seconds: 1));
  print('[delayedUserStream] subscribing to userStream($uid)...');
  await for (final value in firestoreService.userStream(uid)) {
    print('[delayedUserStream] yielded value: $value');
    yield value;
  }
}
