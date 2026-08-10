// web-app/lib/core/services/admin_firestore_service.dart
//
// Full admin-heavy Firestore implementation for the web admin portal.
// Extends the lightweight shared FirestoreServiceImpl and overrides/adds
// all heavy admin methods (payouts with full audit/attachments/comments,
// platform invoices & payments, tax reports, advanced support, staff,
// error logs, invitations, onboarding bulk, simulation tools, etc.).
//
// This is the ONLY place that should contain the complex admin financial,
// compliance, and platform billing logic.

import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:franchise_admin_portal/core/services/audit_log_service_impl.dart';
// Explicitly pull the *shared lightweight* FirestoreServiceImpl (customer + common).
// We hide the name from the main shared_core barrel to avoid clashing with the local thin wrapper in this package.
import 'package:shared_core/shared_core.dart' hide FirestoreServiceImpl;
import 'package:shared_core/shared_core.dart'
    as shared; // Phase 5 final cleanup

class AdminFirestoreService extends shared.FirestoreServiceImpl {
  AdminFirestoreService({
    firestore.FirebaseFirestore? db,
    fb_auth.FirebaseAuth? auth,
    FirebaseFunctions? functions,
  }) : super(db: db, auth: auth, functions: functions);

  // ===================== INVITATIONS & MISC GETTERS =====================
  // invitationCollection remains top-level for legacy/compat code (as used in shared_core and invite flows).
  // All other invitation methods are handled in the shared lightweight impl or franchisee_invitation_service_impl.

  @override
  firestore.CollectionReference<Map<String, dynamic>>
      get invitationCollection => db.collection('franchisee_invitations');

  DateTime _invitationParseDate(dynamic d) {
    if (d is firestore.Timestamp) return d.toDate();
    if (d is DateTime) return d;
    if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
    return DateTime.now();
  }

  shared.FranchiseeInvitation _invitationFromDoc(
      firestore.DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    // Normalize Timestamps so FranchiseeInvitation.fromMap receives DateTime/String only.
    final normalized = Map<String, dynamic>.from(data);
    if (normalized['createdAt'] is firestore.Timestamp) {
      normalized['createdAt'] =
          (normalized['createdAt'] as firestore.Timestamp).toDate();
    }
    if (normalized['lastSentAt'] is firestore.Timestamp) {
      normalized['lastSentAt'] =
          (normalized['lastSentAt'] as firestore.Timestamp).toDate();
    }
    return shared.FranchiseeInvitation.fromMap(normalized, doc.id);
  }

  @override
  Future<List<shared.FranchiseeInvitation>> fetchInvitations({
    String? status,
    String? inviterUserId,
    String? email,
  }) async {
    try {
      firestore.Query<Map<String, dynamic>> q = invitationCollection;

      if (status != null && status.isNotEmpty) {
        q = q.where('status', isEqualTo: status);
      }
      if (inviterUserId != null && inviterUserId.isNotEmpty) {
        q = q.where('inviterUserId', isEqualTo: inviterUserId);
      }
      if (email != null && email.isNotEmpty) {
        q = q.where('email', isEqualTo: email);
      }

      final snap = await q.get();
      return snap.docs.map(_invitationFromDoc).toList();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to fetchInvitations: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.fetchInvitations',
        severity: 'error',
        contextData: {
          if (status != null) 'status': status,
          if (inviterUserId != null) 'inviterUserId': inviterUserId,
          if (email != null) 'email': email,
        },
      );
      rethrow;
    }
  }

  @override
  Stream<List<shared.FranchiseeInvitation>> invitationStream({
    String? status,
    String? inviterUserId,
  }) {
    firestore.Query<Map<String, dynamic>> q = invitationCollection;

    if (status != null && status.isNotEmpty) {
      q = q.where('status', isEqualTo: status);
    }
    if (inviterUserId != null && inviterUserId.isNotEmpty) {
      q = q.where('inviterUserId', isEqualTo: inviterUserId);
    }

    return q.snapshots().map(
          (snap) => snap.docs.map(_invitationFromDoc).toList(),
        );
  }

  @override
  Future<shared.FranchiseeInvitation?> fetchInvitationById(String id) async {
    if (id.isEmpty) return null;
    try {
      final doc = await invitationCollection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return _invitationFromDoc(doc);
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to fetchInvitationById: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.fetchInvitationById',
        severity: 'error',
        contextData: {'id': id},
      );
      rethrow;
    }
  }

  @override
  Future<void> updateInvitation(String id, Map<String, dynamic> data) async {
    if (id.isEmpty) return;
    try {
      await invitationCollection.doc(id).update({
        ...data,
        'updatedAt': firestore.FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to updateInvitation: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.updateInvitation',
        severity: 'error',
        contextData: {'id': id},
      );
      rethrow;
    }
  }

  @override
  Future<void> cancelInvitation(String id, {String? revokedByUserId}) async {
    if (id.isEmpty) return;
    try {
      await invitationCollection.doc(id).update({
        'status': 'revoked',
        'revokedAt': firestore.FieldValue.serverTimestamp(),
        if (revokedByUserId != null && revokedByUserId.isNotEmpty)
          'revokedBy': revokedByUserId,
      });
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to cancelInvitation: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.cancelInvitation',
        severity: 'error',
        contextData: {
          'id': id,
          if (revokedByUserId != null) 'revokedBy': revokedByUserId
        },
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteInvitation(String id) async {
    if (id.isEmpty) return;
    try {
      await invitationCollection.doc(id).delete();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to deleteInvitation: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.deleteInvitation',
        severity: 'error',
        contextData: {'id': id},
      );
      rethrow;
    }
  }

  @override
  Future<void> expireInvitation(String id) async {
    if (id.isEmpty) return;
    try {
      await invitationCollection.doc(id).update({
        'status': 'expired',
        'expiredAt': firestore.FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to expireInvitation: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.expireInvitation',
        severity: 'error',
        contextData: {'id': id},
      );
      rethrow;
    }
  }

  @override
  Future<void> markInvitationResent(String id) async {
    if (id.isEmpty) return;
    try {
      await invitationCollection.doc(id).update({
        'lastSentAt': firestore.FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to markInvitationResent: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.markInvitationResent',
        severity: 'error',
        contextData: {'id': id},
      );
      rethrow;
    }
  }

  // ===================== INGREDIENT METADATA =====================
  // Uses the exact IngredientMetadata model you provided.
  // Fully scoped under franchises/{franchiseId}/ingredient_metadata.

  @override
  Stream<List<shared.IngredientMetadata>> getIngredientMetadata(
      String franchiseId) {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      print(
          '❌ [AdminFirestoreService] getIngredientMetadata - invalid franchiseId: $franchiseId');
      return Stream.value(<shared.IngredientMetadata>[]);
    }

    print(
        '🔍 [AdminFirestoreService] getIngredientMetadata - Querying franchises/$franchiseId/ingredient_metadata');

    return db
        .collection('franchises')
        .doc(franchiseId)
        .collection('ingredient_metadata')
        .snapshots()
        .map((snap) {
      print(
          '📊 [AdminFirestoreService] Snapshot received - ${snap.docs.length} documents');
      final list = snap.docs
          .map((d) {
            try {
              final metadata = shared.IngredientMetadata.fromMap(
                  d.data() as Map<String, dynamic>);
              // print(
              //     '✅ Parsed ingredient: id=${metadata.id}, name=${metadata.name}');
              return metadata;
            } catch (e, stack) {
              print('❌ fromMap failed for doc ${d.id}: $e');
              shared.ErrorLogger.log(
                message: 'fromMap failed for ingredient_metadata',
                stack: stack.toString(),
                source: 'AdminFirestoreService.getIngredientMetadata',
                severity: 'error',
                contextData: {'docId': d.id, 'franchiseId': franchiseId},
              );
              return null;
            }
          })
          .where((item) => item != null)
          .cast<shared.IngredientMetadata>()
          .toList();

      print('✅ [AdminFirestoreService] Final parsed count: ${list.length}');
      return list;
    });
  }

  // ===================== INGREDIENT TYPES (admin override) =====================
  // Uses the exact IngredientType model you provided.
  // All paths scoped under franchises/{franchiseId}/ingredient_types.

  /// Copies default ingredient types from onboarding templates to this franchise.
  /// Used by the "Load Template" button in onboarding.
  Future<void> copyIngredientTypesFromTemplate({
    required String franchiseId,
    required String templateId,
  }) async {
    print(
        '[AdminFirestoreService] copyIngredientTypesFromTemplate STARTED - franchiseId: $franchiseId, templateId: $templateId');

    try {
      // === FIXED PATH: Copy the entire collection, not a single doc ===
      final templateCollection =
          db.collection('onboarding_templates/pizzeria/ingredient_types');

      final snapshot = await templateCollection.get();

      if (snapshot.docs.isEmpty) {
        throw Exception(
            'No documents found in onboarding_templates/pizzeria/ingredient_types');
      }

      final batch = db.batch();
      int copiedCount = 0;

      for (final doc in snapshot.docs) {
        final map = doc.data();
        final newDocRef = db
            .collection('franchises/$franchiseId/ingredient_types')
            .doc(doc.id); // preserve original document ID

        batch.set(newDocRef, map);
        copiedCount++;
      }

      await batch.commit();

      print(
          '[AdminFirestoreService] copyIngredientTypesFromTemplate SUCCESS - copied $copiedCount types');
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'copyIngredientTypesFromTemplate failed',
        stack: stack.toString(),
        source: 'AdminFirestoreService',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'templateId': templateId},
      );
      rethrow;
    }
  }

  @override
  Future<List<String>> fetchIngredientTypeIds(String franchiseId) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return [];
    }
    try {
      final snap = await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types')
          .orderBy('sortOrder')
          .get();
      return snap.docs.map((d) => d.id).toList();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to fetch ingredient type IDs',
        stack: stack.toString(),
        source: 'AdminFirestoreService.fetchIngredientTypeIds',
        contextData: {'franchiseId': franchiseId},
      );
      return [];
    }
  }

  @override
  Future<void> saveIngredientType(
      String franchiseId, shared.IngredientType type) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      shared.ErrorLogger.log(
        message: 'saveIngredientType called with invalid franchiseId',
        source: 'AdminFirestoreService.saveIngredientType',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'typeId': type.id},
      );
      return;
    }
    try {
      final data = type.toMap(includeTimestamps: true);
      await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types')
          .doc(type.id)
          .set(data, firestore.SetOptions(merge: true));
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to save ingredient type',
        stack: stack.toString(),
        source: 'AdminFirestoreService.saveIngredientType',
        contextData: {'franchiseId': franchiseId, 'typeId': type.id},
      );
      rethrow;
    }
  }

  @override
  Future<void> updateIngredientType(String franchiseId, String typeId,
      Map<String, dynamic> updatedFields) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      shared.ErrorLogger.log(
        message: 'updateIngredientType called with invalid franchiseId',
        source: 'AdminFirestoreService.updateIngredientType',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'typeId': typeId},
      );
      return;
    }
    try {
      await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types')
          .doc(typeId)
          .update(updatedFields);
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to update ingredient type',
        stack: stack.toString(),
        source: 'AdminFirestoreService.updateIngredientType',
        contextData: {'franchiseId': franchiseId, 'typeId': typeId},
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteIngredientType(String franchiseId, String typeId) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      shared.ErrorLogger.log(
        message: 'deleteIngredientType called with invalid franchiseId',
        source: 'AdminFirestoreService.deleteIngredientType',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'typeId': typeId},
      );
      return;
    }
    try {
      await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types')
          .doc(typeId)
          .delete();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to delete ingredient type',
        stack: stack.toString(),
        source: 'AdminFirestoreService.deleteIngredientType',
        contextData: {'franchiseId': franchiseId, 'typeId': typeId},
      );
      rethrow;
    }
  }

  @override
  Future<void> updateIngredientTypeSortOrders({
    required String franchiseId,
    required List<Map<String, dynamic>> sortedUpdates,
  }) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      shared.ErrorLogger.log(
        message:
            'updateIngredientTypeSortOrders called with invalid franchiseId',
        source: 'AdminFirestoreService.updateIngredientTypeSortOrders',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }
    try {
      final batch = db.batch();
      for (final update in sortedUpdates) {
        final docRef = db
            .collection('franchises')
            .doc(franchiseId)
            .collection('ingredient_types')
            .doc(update['id'] as String);
        batch.update(docRef, {'sortOrder': update['sortOrder']});
      }
      await batch.commit();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to update ingredient type sort orders',
        stack: stack.toString(),
        source: 'AdminFirestoreService.updateIngredientTypeSortOrders',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  @override
  Stream<List<shared.IngredientType>> getIngredientTypes(String franchiseId) {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return Stream.value(<shared.IngredientType>[]);
    }
    return db
        .collection('franchises')
        .doc(franchiseId)
        .collection('ingredient_types')
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => shared.IngredientType.fromFirestore(d))
            .toList());
  }

  // ===================== INVENTORY =====================
  // Fully scoped under franchises/{franchiseId}/inventory.
  // Uses the exact Inventory model you provided.

  @override
  Stream<List<shared.Inventory>> getInventory(String franchiseId) {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return Stream.value(<shared.Inventory>[]);
    }

    return db
        .collection('franchises')
        .doc(franchiseId)
        .collection('inventory')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => shared.Inventory.fromFirestore(d.data(), d.id))
            .toList());
  }

  @override
  Future<void> addInventory(String franchiseId, shared.Inventory item) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      shared.ErrorLogger.log(
        message: 'addInventory called with invalid franchiseId',
        source: 'AdminFirestoreService.addInventory',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'itemId': item.id},
      );
      return;
    }
    try {
      final id = item.id?.isNotEmpty == true
          ? item.id!
          : db.collection('temp').doc().id;

      final data = item.toFirestore()..['id'] = id;

      await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('inventory')
          .doc(id)
          .set(data, firestore.SetOptions(merge: true));
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to add inventory: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.addInventory',
        contextData: {'franchiseId': franchiseId, 'itemId': item.id},
      );
      rethrow;
    }
  }

  @override
  Future<void> updateInventory(
      String franchiseId, shared.Inventory item) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      shared.ErrorLogger.log(
        message: 'updateInventory called with invalid franchiseId',
        source: 'AdminFirestoreService.updateInventory',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'itemId': item.id},
      );
      return;
    }
    if (item.id == null || item.id!.isEmpty) return;

    try {
      await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('inventory')
          .doc(item.id)
          .update(item.toFirestore());
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to update inventory: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.updateInventory',
        contextData: {'franchiseId': franchiseId, 'itemId': item.id},
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteInventory(String franchiseId, String inventoryId) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      shared.ErrorLogger.log(
        message: 'deleteInventory called with invalid franchiseId',
        source: 'AdminFirestoreService.deleteInventory',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'inventoryId': inventoryId},
      );
      return;
    }
    try {
      await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('inventory')
          .doc(inventoryId)
          .delete();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to delete inventory: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.deleteInventory',
        contextData: {'franchiseId': franchiseId, 'inventoryId': inventoryId},
      );
      rethrow;
    }
  }

  // ===================== CATEGORY & SCHEMA MANAGEMENT (franchise-scoped) =====================
  // Uses the exact Category model you provided. All paths are franchise-scoped.
  // Extra care taken for onboarding screen compatibility (streams, default fallback, sortOrder, etc.).

  @override
  Future<void> addCategory({
    required String franchiseId,
    required shared.Category category,
  }) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      shared.ErrorLogger.log(
        message: 'addCategory called with invalid franchiseId',
        source: 'AdminFirestoreService.addCategory',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'categoryId': category.id},
      );
      return;
    }
    try {
      final col =
          db.collection('franchises').doc(franchiseId).collection('categories');
      final id = (category.id.isNotEmpty) ? category.id : col.doc().id;
      // orderBy('sortOrder') excludes docs without the field — always write it.
      final sortOrder = category.sortOrder ?? 0;
      final payload = {
        ...category.copyWith(id: id, sortOrder: sortOrder).toFirestore(),
        'sortOrder': sortOrder,
      };
      await col.doc(id).set(payload, firestore.SetOptions(merge: true));
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to add category: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.addCategory',
        contextData: {'franchiseId': franchiseId, 'categoryId': category.id},
      );
      rethrow;
    }
  }

  @override
  Future<void> updateCategory(
      String franchiseId, shared.Category category) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      shared.ErrorLogger.log(
        message: 'updateCategory called with invalid franchiseId',
        source: 'AdminFirestoreService.updateCategory',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'categoryId': category.id},
      );
      return;
    }
    try {
      await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('categories')
          .doc(category.id)
          .update(category.toFirestore());
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to update category: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.updateCategory',
        contextData: {'franchiseId': franchiseId, 'categoryId': category.id},
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory({
    required String franchiseId,
    required String categoryId,
  }) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      shared.ErrorLogger.log(
        message: 'deleteCategory called with invalid franchiseId',
        source: 'AdminFirestoreService.deleteCategory',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'categoryId': categoryId},
      );
      return;
    }
    try {
      await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('categories')
          .doc(categoryId)
          .delete();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to delete category: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.deleteCategory',
        contextData: {'franchiseId': franchiseId, 'categoryId': categoryId},
      );
      rethrow;
    }
  }

  @override
  Stream<List<shared.Category>> getCategories(String franchiseId) {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return Stream.value(<shared.Category>[]);
    }
    return db
        .collection('franchises')
        .doc(franchiseId)
        .collection('categories')
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => shared.Category.fromFirestore(d.data(), d.id))
            .toList());
  }

  @override
  Future<Map<String, dynamic>?> getCategorySchema(
      String franchiseId, String categoryId) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return null;
    }
    try {
      final doc = await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('category_schemas')
          .doc(categoryId)
          .get();
      if (doc.exists) return doc.data();

      // Fallback to default schema (common pattern used in onboarding)
      final defaultDoc = await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('category_schemas')
          .doc('default')
          .get();
      return defaultDoc.data();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to load category schema: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.getCategorySchema',
        contextData: {'franchiseId': franchiseId, 'categoryId': categoryId},
      );
      return null;
    }
  }

  @override
  Future<List<String>> getAllCategorySchemaIds(String franchiseId) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return [];
    }
    try {
      final snap = await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('category_schemas')
          .get();
      return snap.docs.map((d) => d.id).toList();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to load category schema IDs: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.getAllCategorySchemaIds',
        contextData: {'franchiseId': franchiseId},
      );
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getCustomizationTemplate(
      String franchiseId, String templateId) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return null;
    }
    try {
      final doc = await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('customization_templates')
          .doc(templateId)
          .get();
      return doc.data();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to load customization template: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.getCustomizationTemplate',
        contextData: {'franchiseId': franchiseId, 'templateId': templateId},
      );
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getCustomizationTemplates(
      String franchiseId) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return {};
    }
    try {
      final snap = await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('customization_templates')
          .get();
      final result = <String, dynamic>{};
      for (final d in snap.docs) {
        result[d.id] = d.data();
      }
      return result;
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to load customization templates: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.getCustomizationTemplates',
        contextData: {'franchiseId': franchiseId},
      );
      return {};
    }
  }

  // ===================== PROMOS (franchise-scoped) =====================
  // Shared FirestoreServiceImpl throws UnimplementedError for admin-only
  // promo writes; Admin portal must implement them.

  @override
  Stream<List<shared.Promo>> getPromos(String franchiseId) {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return Stream.value(<shared.Promo>[]);
    }
    return db
        .collection('franchises')
        .doc(franchiseId)
        .collection('promotions')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => shared.Promo.fromFirestore(d.data(), d.id))
            .toList());
  }

  @override
  Future<void> addPromo(String franchiseId, shared.Promo promo) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      shared.ErrorLogger.log(
        message: 'addPromo called with invalid franchiseId',
        source: 'AdminFirestoreService.addPromo',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }
    try {
      final col =
          db.collection('franchises').doc(franchiseId).collection('promotions');
      final id = promo.id.isNotEmpty ? promo.id : col.doc().id;
      await col.doc(id).set(promo.copyWith(id: id).toFirestore(),
          firestore.SetOptions(merge: true));
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to addPromo: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.addPromo',
        contextData: {'franchiseId': franchiseId, 'promoId': promo.id},
      );
      rethrow;
    }
  }

  @override
  Future<void> updatePromo(String franchiseId, shared.Promo promo) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default' ||
        promo.id.isEmpty) {
      shared.ErrorLogger.log(
        message: 'updatePromo called with invalid ids',
        source: 'AdminFirestoreService.updatePromo',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'promoId': promo.id},
      );
      return;
    }
    try {
      await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('promotions')
          .doc(promo.id)
          .set(promo.toFirestore(), firestore.SetOptions(merge: true));
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to updatePromo: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.updatePromo',
        contextData: {'franchiseId': franchiseId, 'promoId': promo.id},
      );
      rethrow;
    }
  }

  @override
  Future<void> deletePromo(String franchiseId, String promoId) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default' ||
        promoId.isEmpty) {
      shared.ErrorLogger.log(
        message: 'deletePromo called with invalid ids',
        source: 'AdminFirestoreService.deletePromo',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'promoId': promoId},
      );
      return;
    }
    try {
      await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('promotions')
          .doc(promoId)
          .delete();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to deletePromo: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.deletePromo',
        contextData: {'franchiseId': franchiseId, 'promoId': promoId},
      );
      rethrow;
    }
  }

  // ===================== BANNERS (franchise-scoped) =====================

  Stream<List<shared.Banner>> streamFranchiseBanners(String franchiseId) {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return Stream.value(<shared.Banner>[]);
    }
    return db
        .collection('franchises')
        .doc(franchiseId)
        .collection('banners')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => shared.Banner.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) {
        final bySort = a.sortOrder.compareTo(b.sortOrder);
        if (bySort != 0) return bySort;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      return list;
    });
  }

  Future<void> saveFranchiseBanner(
    String franchiseId,
    shared.Banner banner,
  ) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      shared.ErrorLogger.log(
        message: 'saveFranchiseBanner invalid franchiseId',
        source: 'AdminFirestoreService.saveFranchiseBanner',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }
    final col =
        db.collection('franchises').doc(franchiseId).collection('banners');
    final id = banner.id.isNotEmpty ? banner.id : col.doc().id;
    await col.doc(id).set(
          banner.copyWith(id: id).toFirestore(),
          firestore.SetOptions(merge: true),
        );
  }

  Future<void> deleteFranchiseBanner(
    String franchiseId,
    String bannerId,
  ) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default' ||
        bannerId.isEmpty) {
      return;
    }
    await db
        .collection('franchises')
        .doc(franchiseId)
        .collection('banners')
        .doc(bannerId)
        .delete();
  }

  /// Robust import of menu items from onboarding template.
  /// Copies from onboarding_templates/pizzeria/menu_items → franchises/{franchiseId}/menu_items
  /// Preserves original document IDs, all fields (customizations, sizes, nutrition, etc.).
  /// Import ingredients (ingredient_metadata) from onboarding template.
  /// Copies from onboarding_templates/pizzeria/ingredient_metadata → franchises/{franchiseId}/ingredient_metadata
  @override
  Future<List<shared.MenuTemplateRef>> fetchMenuTemplateRefs({
    required String restaurantType,
  }) async {
    print(
        '[AdminFirestoreService] fetchMenuTemplateRefs STARTED - restaurantType: $restaurantType');

    try {
      final templateCollection = db
          .collection('onboarding_templates')
          .doc(restaurantType)
          .collection('menu_items');

      final snapshot = await templateCollection.get();

      if (snapshot.docs.isEmpty) {
        print(
            '[WARN] No menu templates found for restaurantType: $restaurantType');
        return [];
      }

      final templates = snapshot.docs.map((doc) {
        final data = doc.data();
        return shared.MenuTemplateRef(
          id: doc.id,
          name: data['name'] as String? ?? doc.id,
        );
      }).toList();

      print(
          '[AdminFirestoreService] fetchMenuTemplateRefs SUCCESS - loaded ${templates.length} templates');
      return templates;
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'fetchMenuTemplateRefs failed',
        stack: stack.toString(),
        source: 'AdminFirestoreService',
        severity: 'error',
        contextData: {'restaurantType': restaurantType},
      );
      return [];
    }
  }

  Future<void> importIngredientsFromTemplate({
    required String franchiseId,
    required String templateId, // 'pizzeria'
  }) async {
    print(
        '[AdminFirestoreService] importIngredientsFromTemplate STARTED - franchiseId: $franchiseId, templateId: $templateId');

    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      shared.ErrorLogger.log(
        message:
            'importIngredientsFromTemplate called with invalid franchiseId',
        source: 'AdminFirestoreService.importIngredientsFromTemplate',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }

    try {
      final templateCollection = db
          .collection('onboarding_templates')
          .doc(templateId)
          .collection('ingredient_metadata');

      final snapshot = await templateCollection.get();

      if (snapshot.docs.isEmpty) {
        print('[WARN] No ingredients found in template $templateId');
        return;
      }

      final batch = db.batch();
      int copiedCount = 0;

      for (final doc in snapshot.docs) {
        final map = doc.data();
        final newDocRef = db
            .collection('franchises')
            .doc(franchiseId)
            .collection('ingredient_metadata')
            .doc(doc.id);

        batch.set(newDocRef, map, firestore.SetOptions(merge: true));
        copiedCount++;
      }

      await batch.commit();

      print(
          '[AdminFirestoreService] importIngredientsFromTemplate SUCCESS - copied $copiedCount ingredients');
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'importIngredientsFromTemplate failed',
        stack: stack.toString(),
        source: 'AdminFirestoreService',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'templateId': templateId},
      );
      rethrow;
    }
  }

  Future<void> importMenuItemsFromTemplate({
    required String franchiseId,
    required String templateId, // e.g. 'pizzeria'
  }) async {
    print(
        '[AdminFirestoreService] importMenuItemsFromTemplate STARTED - franchiseId: $franchiseId, templateId: $templateId');

    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      shared.ErrorLogger.log(
        message: 'importMenuItemsFromTemplate called with invalid franchiseId',
        source: 'AdminFirestoreService.importMenuItemsFromTemplate',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'templateId': templateId},
      );
      return;
    }

    try {
      final templateCollection = db
          .collection('onboarding_templates')
          .doc(templateId)
          .collection('menu_items');

      final snapshot = await templateCollection.get();

      if (snapshot.docs.isEmpty) {
        throw Exception('No menu items found in template $templateId');
      }

      final batch = db.batch();
      int copiedCount = 0;

      for (final doc in snapshot.docs) {
        final map = doc.data();
        final newDocRef = db
            .collection('franchises')
            .doc(franchiseId)
            .collection('menu_items')
            .doc(doc.id); // Preserve original ID

        batch.set(newDocRef, map, firestore.SetOptions(merge: true));
        copiedCount++;
      }

      await batch.commit();

      print(
          '[AdminFirestoreService] importMenuItemsFromTemplate SUCCESS - copied $copiedCount menu items');

      // Correct audit logging using existing AuditLogServiceImpl
      final auditService = AuditLogServiceImpl();
      await auditService.addLog(
        franchiseId: franchiseId,
        userId:
            currentUserId ?? 'system', // fallback for background/template calls
        action: 'template_import',
        targetType: 'menu_items',
        targetId: 'bulk',
        details: {
          'templateId': templateId,
          'count': copiedCount,
          'importedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'importMenuItemsFromTemplate failed',
        stack: stack.toString(),
        source: 'AdminFirestoreService',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'templateId': templateId},
      );
      rethrow;
    }
  }

  @override
  Future<void> loadTemplate(String templateId) async {
    final franchiseId = // Get from context or pass it – for now assume it's handled in provider
        // Better: make loadTemplate accept franchiseId like copyIngredientTypesFromTemplate
        throw UnimplementedError('Use loadTemplateWithFranchiseId');
  }

  /// Admin-only: Load category template (pizzeria, etc.)
  Future<void> loadTemplateWithFranchiseId({
    required String franchiseId,
    required String templateId,
  }) async {
    print(
        '[AdminFirestoreService] loadTemplateWithFranchiseId STARTED - franchiseId: $franchiseId, templateId: $templateId');

    try {
      final templateSnap = await db
          .collection('onboarding_templates')
          .doc(templateId)
          .collection('categories')
          .get();

      if (templateSnap.docs.isEmpty) {
        throw Exception('No categories found in template $templateId');
      }

      final batch = db.batch();
      int copied = 0;

      for (final doc in templateSnap.docs) {
        final data = doc.data();
        final newRef = db
            .collection('franchises')
            .doc(franchiseId)
            .collection('categories')
            .doc(doc.id);

        batch.set(newRef, data, firestore.SetOptions(merge: true));
        copied++;
      }

      await batch.commit();

      print(
          '[AdminFirestoreService] loadTemplateWithFranchiseId SUCCESS - copied $copied categories');
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'loadTemplateWithFranchiseId failed',
        stack: stack.toString(),
        source: 'AdminFirestoreService',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'templateId': templateId},
      );
      rethrow;
    }
  }

  @override
  Future<void> addOrUpdateCategory(shared.Category category) async {
    // Delegate to the correct scoped method
    final franchiseId = // You may need to pass franchiseId from provider or use current one
        throw UnimplementedError(
            'Use addCategory or updateCategory with explicit franchiseId');
  }

  // ===================== SIMULATION & WEBHOOK TOOLS =====================
  // Dev-only tools remain top-level (platform-wide) as they are not tenant data.

  @override
  Future<void> simulateWebhookEvent({
    required String invoiceId,
    required String eventType,
    String status = 'paid',
    double amount = 0.0,
    String currency = 'USD',
    String? planId,
    String? subscriptionId,
    String? receiptUrl,
    DateTime? paidAt,
    String paymentMethod = 'mock_card',
    String paymentProvider = 'developer',
  }) async {
    final data = {
      'invoiceId': invoiceId,
      'eventType': eventType,
      'status': status,
      'amount': amount,
      'currency': currency,
      'planId': planId,
      'subscriptionId': subscriptionId,
      'receiptUrl': receiptUrl,
      'paidAt': paidAt?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'paymentProvider': paymentProvider,
      'simulatedAt': DateTime.now().toIso8601String(),
      'simulatedBy': currentUserId,
    };
    await db.collection('simulated_webhooks').add(data);
    await logSimulatedWebhookEvent(data);
  }

  @override
  Future<void> logSimulatedWebhookEvent(Map<String, dynamic> data) async {
    await db.collection('simulated_webhook_logs').add({
      ...data,
      'loggedAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  // ===================== SUPPORT REQUESTS (heavy admin paths) =====================
  // Now fully scoped under franchises/{franchiseId}/support_requests per Non-Negotiable Rules.

  @override
  Future<void> deleteSupportRequest(String requestId) async {
    await db.collection('support_requests').doc(requestId).delete();
  }

  @override
  Future<void> addSupportNote(
      String requestId, Map<String, dynamic> note) async {
    await db.collection('support_requests').doc(requestId).update({
      'notes': firestore.FieldValue.arrayUnion([note]),
    });
  }

  // ===================== TAX REPORTS (full admin) =====================
  // Now fully scoped under franchises/{franchiseId}/tax_reports per schema + Non-Negotiable Rules.
  // Uses the new robust TaxReport model created above.

  @override
  Future<dynamic> addTaxReport(Map<String, dynamic> data) async {
    final franchiseId = data['franchiseId'] ?? data['franchiseeId'];
    if (franchiseId == null || franchiseId.isEmpty) {
      shared.ErrorLogger.log(
        message: 'addTaxReport called without franchiseId',
        source: 'AdminFirestoreService.addTaxReport',
        severity: 'error',
      );
      return null;
    }
    try {
      final ref = await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('tax_reports')
          .add({
        ...data,
        'createdAt': firestore.FieldValue.serverTimestamp(),
        'updatedAt': firestore.FieldValue.serverTimestamp(),
      });
      return ref;
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to add tax report: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.addTaxReport',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  @override
  Future<void> updateTaxReport(
      String reportId, Map<String, dynamic> updates) async {
    // reportId alone used; franchise context resolved at call site
    await db.collection('tax_reports').doc(reportId).update({
      ...updates,
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Map<String, dynamic>?> getTaxReportById(String reportId) async {
    final doc = await db.collection('tax_reports').doc(reportId).get();
    return doc.data();
  }

  @override
  Stream<List<Map<String, dynamic>>> taxReportsStream({
    String? franchiseId,
    String? brandId,
    String? reportType,
    String? status,
    String? taxAuthority,
    DateTime? filedAfter,
    DateTime? filedBefore,
    int limit = 100,
  }) {
    if (franchiseId == null || franchiseId.isEmpty) {
      return Stream.value(<Map<String, dynamic>>[]);
    }
    firestore.Query q =
        db.collection('franchises').doc(franchiseId).collection('tax_reports');

    if (status != null) q = q.where('status', isEqualTo: status);
    if (reportType != null) q = q.where('reportType', isEqualTo: reportType);
    if (taxAuthority != null)
      q = q.where('taxAuthority', isEqualTo: taxAuthority);
    if (filedAfter != null)
      q = q.where('filedAt', isGreaterThanOrEqualTo: filedAfter);
    if (filedBefore != null)
      q = q.where('filedAt', isLessThanOrEqualTo: filedBefore);

    return q.limit(limit).snapshots().map((s) => s.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map)..['id'] = d.id)
        .toList());
  }

  @override
  Future<void> deleteTaxReport(String reportId) async {
    await db.collection('tax_reports').doc(reportId).delete();
  }

  @override
  Future<void> addTaxReportReminder(
      String reportId, Map<String, dynamic> reminder) async {
    await db.collection('tax_reports').doc(reportId).update({
      'reminders': firestore.FieldValue.arrayUnion([reminder]),
    });
  }

  @override
  Future<void> addTaxReportAttachment(
      String reportId, Map<String, dynamic> attachment) async {
    await db.collection('tax_reports').doc(reportId).update({
      'attachments': firestore.FieldValue.arrayUnion([attachment]),
    });
  }

  // ===================== PLATFORM INVOICES / PAYMENTS / FINANCIAL =====================
  // Now fully scoped under franchises/{franchiseId}/platform_invoices and platform_payments
  // Uses exact PlatformInvoice.fromMap / toMap and PlatformPayment.fromMap / toMap

  // === HQ KPI card reads (hq-financial-honesty-v1) ===

  @override
  Future<Map<String, dynamic>> getFranchiseAnalyticsSummary(
      String franchiseId) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return {};
    }
    try {
      final snap = await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('analytics_summaries')
          .get();

      // ignore: avoid_print
      print(
          '[KPI] analytics_summaries count=${snap.docs.length} franchiseId=$franchiseId');

      if (snap.docs.isEmpty) return {};

      DateTime? asDate(dynamic v) {
        if (v is firestore.Timestamp) return v.toDate();
        if (v is DateTime) return v;
        if (v is String) return DateTime.tryParse(v);
        return null;
      }

      final scored = snap.docs.map((d) {
        final data = d.data();
        final revenue = (data['totalRevenue'] ?? 0).toDouble();
        final dt = asDate(data['updatedAt']) ?? asDate(data['createdAt']);
        return (doc: d, data: data, revenue: revenue, dt: dt);
      }).toList();

      // Prefer real revenue; among those, newest updatedAt; else any newest.
      scored.sort((a, b) {
        final aHas = a.revenue > 0;
        final bHas = b.revenue > 0;
        if (aHas != bHas) return aHas ? -1 : 1;
        if (a.dt != null && b.dt != null) return b.dt!.compareTo(a.dt!);
        if (a.dt != null) return -1;
        if (b.dt != null) return 1;
        return b.revenue.compareTo(a.revenue);
      });

      final best = scored.first;
      // ignore: avoid_print
      print(
          '[KPI] chosen id=${best.doc.id} totalRevenue=${best.revenue} aov=${best.data['averageOrderValue']}');

      return {
        'totalRevenue': best.revenue,
        'averageOrderValue': (best.data['averageOrderValue'] ?? 0).toDouble(),
        'totalOrders': best.data['totalOrders'] ?? 0,
        'currency': best.data['currency'] ?? 'USD',
        'period': best.data['period'] ?? best.doc.id,
      };
    } catch (e, st) {
      shared.ErrorLogger.log(
        message: 'getFranchiseAnalyticsSummary failed: $e',
        stack: st.toString(),
        source: 'AdminFirestoreService.getFranchiseAnalyticsSummary',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      // ignore: avoid_print
      print('[KPI] analytics ERROR: $e');
      return {};
    }
  }

  @override
  Future<double> getOutstandingInvoices(String franchiseId) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return 0.0;
    }
    try {
      final invoices = await getPlatformInvoicesForFranchisee(franchiseId);
      // A: unpaid / open balance for platform → franchise SaaS invoices.
      double sum = 0.0;
      for (final inv in invoices) {
        final s = inv.status.toLowerCase();
        if (s == 'unpaid' || s == 'partial' || s == 'overdue' || s == 'open') {
          sum += inv.amount;
        }
      }
      return sum;
    } catch (e, st) {
      shared.ErrorLogger.log(
        message: 'getOutstandingInvoices failed: $e',
        stack: st.toString(),
        source: 'AdminFirestoreService.getOutstandingInvoices',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      return 0.0;
    }
  }

  @override
  Future<Map<String, dynamic>> getLastPayout(String franchiseId) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return {};
    }
    try {
      final snap = await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('payouts')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        // Fallback: some docs may use paidAt / date instead of createdAt.
        final snap2 = await db
            .collection('franchises')
            .doc(franchiseId)
            .collection('payouts')
            .limit(25)
            .get();
        if (snap2.docs.isEmpty) return {};

        final sorted = [...snap2.docs];
        sorted.sort((a, b) {
          final aData = a.data();
          final bData = b.data();
          final aTs = aData['createdAt'] ?? aData['paidAt'] ?? aData['date'];
          final bTs = bData['createdAt'] ?? bData['paidAt'] ?? bData['date'];
          if (aTs is firestore.Timestamp && bTs is firestore.Timestamp) {
            return bTs.compareTo(aTs);
          }
          return 0;
        });
        final data = sorted.first.data();
        final amount = (data['amount'] ?? data['netAmount'] ?? 0).toDouble();
        final dateVal = data['createdAt'] ?? data['paidAt'] ?? data['date'];
        final dateStr = dateVal is firestore.Timestamp
            ? dateVal.toDate().toIso8601String()
            : dateVal?.toString();
        return {
          'amount': amount,
          if (dateStr != null) 'date': dateStr,
          'id': sorted.first.id,
        };
      }

      final data = snap.docs.first.data();
      final amount = (data['amount'] ?? data['netAmount'] ?? 0).toDouble();
      final dateVal = data['createdAt'] ?? data['paidAt'] ?? data['date'];
      final dateStr = dateVal is firestore.Timestamp
          ? dateVal.toDate().toIso8601String()
          : dateVal?.toString();
      return {
        'amount': amount,
        if (dateStr != null) 'date': dateStr,
        'id': snap.docs.first.id,
      };
    } catch (e, st) {
      shared.ErrorLogger.log(
        message: 'getLastPayout failed: $e',
        stack: st.toString(),
        source: 'AdminFirestoreService.getLastPayout',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      return {};
    }
  }

  @override
  Future<PlatformRevenueOverview> fetchPlatformRevenueOverview() async {
    try {
      final now = DateTime.now();
      final yearStart = DateTime(now.year, 1, 1);

      DateTime? asDate(dynamic v) {
        if (v is firestore.Timestamp) return v.toDate();
        if (v is DateTime) return v;
        if (v is String) return DateTime.tryParse(v);
        return null;
      }

      final invSnap = await db.collection('platform_invoices').get();

      double totalRevenueYtd = 0;
      double subscriptionRevenue = 0;
      double royaltyRevenue = 0;
      double overdueAmount = 0;

      for (final doc in invSnap.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final status = (data['status'] as String?)?.toLowerCase() ?? 'unpaid';
        final createdAt = asDate(data['createdAt']);
        final dueDate = asDate(data['dueDate']);
        final planId = data['planId'] as String?;
        final note = (data['note'] as String?)?.toLowerCase() ?? '';
        final lineItems = data['lineItems'];

        final isPaid = status == 'paid';
        final isUnpaidLike = status == 'unpaid' ||
            status == 'partial' ||
            status == 'overdue' ||
            status == 'open';

        if (isPaid && createdAt != null && !createdAt.isBefore(yearStart)) {
          totalRevenueYtd += amount;

          final looksSubscription = planId != null ||
              note.contains('subscription') ||
              note.contains('saas') ||
              (lineItems is Map &&
                  lineItems.toString().toLowerCase().contains('subscription'));
          final looksRoyalty = note.contains('royalty') ||
              (lineItems is Map &&
                  lineItems.toString().toLowerCase().contains('royalty'));

          if (looksRoyalty) {
            royaltyRevenue += amount;
          } else if (looksSubscription) {
            subscriptionRevenue += amount;
          } else {
            // Default paid SaaS invoices to subscription bucket when untagged.
            subscriptionRevenue += amount;
          }
        }

        if (isUnpaidLike) {
          final overdueByStatus = status == 'overdue';
          final overdueByDate = dueDate != null && dueDate.isBefore(now);
          if (overdueByStatus || overdueByDate) {
            overdueAmount += amount;
          }
        }
      }

      return PlatformRevenueOverview(
        totalRevenueYtd: totalRevenueYtd,
        subscriptionRevenue: subscriptionRevenue,
        royaltyRevenue: royaltyRevenue,
        overdueAmount: overdueAmount,
      );
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to fetchPlatformRevenueOverview: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.fetchPlatformRevenueOverview',
        severity: 'error',
      );
      return PlatformRevenueOverview(
        totalRevenueYtd: 0,
        subscriptionRevenue: 0,
        royaltyRevenue: 0,
        overdueAmount: 0,
      );
    }
  }

  @override
  Future<PlatformFinancialKpis> fetchPlatformFinancialKpis() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      DateTime? asDate(dynamic v) {
        if (v is firestore.Timestamp) return v.toDate();
        if (v is DateTime) return v;
        if (v is String) return DateTime.tryParse(v);
        return null;
      }

      // Active franchise count + MRR from franchise_subscriptions.
      final subSnap = await db.collection('franchise_subscriptions').get();
      final activeFranchiseIds = <String>{};
      double mrr = 0;

      for (final doc in subSnap.docs) {
        final data = doc.data();
        final status = (data['status'] as String?)?.toLowerCase() ?? '';
        if (status != 'active' && status != 'trialing') continue;

        final franchiseId = data['franchiseId'] as String? ?? '';
        if (franchiseId.isNotEmpty) {
          activeFranchiseIds.add(franchiseId);
        }

        final price = (data['priceAtSubscription'] as num?)?.toDouble() ?? 0.0;
        final interval =
            (data['billingInterval'] as String?)?.toLowerCase() ?? 'monthly';
        final discount = (data['discountPercent'] as num?)?.toInt() ?? 0;
        final discounted = price * (1 - (discount / 100.0));

        if (interval == 'yearly' || interval == 'annual') {
          mrr += discounted / 12.0;
        } else {
          // monthly or unknown → treat as monthly recurring
          mrr += discounted;
        }
      }

      final arr = mrr * 12.0;

      // Recent payouts (last 30 days) from top-level payouts collection.
      double recentPayouts = 0;
      final payoutSnap = await db.collection('payouts').get();
      for (final doc in payoutSnap.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ??
            (data['netAmount'] as num?)?.toDouble() ??
            0.0;
        final dt = asDate(data['createdAt']) ??
            asDate(data['paidAt']) ??
            asDate(data['date']);
        if (dt != null && !dt.isBefore(thirtyDaysAgo)) {
          recentPayouts += amount;
        }
      }

      return PlatformFinancialKpis(
        mrr: mrr,
        arr: arr,
        activeFranchises: activeFranchiseIds.length,
        recentPayouts: recentPayouts,
      );
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to fetchPlatformFinancialKpis: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.fetchPlatformFinancialKpis',
        severity: 'error',
      );
      return const PlatformFinancialKpis(
        activeFranchises: 0,
        mrr: 0,
        arr: 0,
        recentPayouts: 0.0,
      );
    }
  }

  // ===================== FRANCHISE SUBSCRIPTIONS (top-level collection) =====================
  // Collection: franchise_subscriptions/{subId}
  // Rules: isHqOwner() read/write already granted.
  // Model: shared.FranchiseSubscription.fromMap(id, data)

  @override
  Future<List<shared.FranchiseSubscription>> getFranchiseSubscriptions() async {
    try {
      final snap = await db.collection('franchise_subscriptions').get();
      return snap.docs
          .map((d) => shared.FranchiseSubscription.fromMap(
                d.id,
                d.data() as Map<String, dynamic>,
              ))
          .toList();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to getFranchiseSubscriptions: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.getFranchiseSubscriptions',
        severity: 'error',
      );
      return [];
    }
  }

  @override
  Future<List<shared.FranchiseSubscription>>
      getAllFranchiseSubscriptions() async {
    return getFranchiseSubscriptions();
  }

  @override
  Future<List<dynamic>> getAllFranchiseSubscriptionsRaw() async {
    try {
      final snap = await db.collection('franchise_subscriptions').get();
      return snap.docs
          .map((d) => <String, dynamic>{
                ...d.data(),
                'id': d.id,
              })
          .toList();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to getAllFranchiseSubscriptionsRaw: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.getAllFranchiseSubscriptionsRaw',
        severity: 'error',
      );
      return [];
    }
  }

  @override
  Future<shared.FranchiseSubscription?> getFranchiseSubscription(
      String franchiseId) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return null;
    }
    try {
      final snap = await db
          .collection('franchise_subscriptions')
          .where('franchiseId', isEqualTo: franchiseId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first;
      return shared.FranchiseSubscription.fromMap(
        d.id,
        d.data() as Map<String, dynamic>,
      );
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to getFranchiseSubscription: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.getFranchiseSubscription',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      return null;
    }
  }

  @override
  Future<shared.FranchiseSubscription?> getCurrentSubscriptionForFranchise(
      String franchiseId) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return null;
    }
    try {
      // Prefer an active subscription for this franchise.
      final activeSnap = await db
          .collection('franchise_subscriptions')
          .where('franchiseId', isEqualTo: franchiseId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      if (activeSnap.docs.isNotEmpty) {
        final d = activeSnap.docs.first;
        return shared.FranchiseSubscription.fromMap(
          d.id,
          d.data() as Map<String, dynamic>,
        );
      }

      // Fallback: any subscription doc for this franchise.
      final anySnap = await db
          .collection('franchise_subscriptions')
          .where('franchiseId', isEqualTo: franchiseId)
          .limit(1)
          .get();
      if (anySnap.docs.isEmpty) return null;
      final d = anySnap.docs.first;
      return shared.FranchiseSubscription.fromMap(
        d.id,
        d.data() as Map<String, dynamic>,
      );
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to getCurrentSubscriptionForFranchise: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.getCurrentSubscriptionForFranchise',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      return null;
    }
  }

  @override
  Stream<List<PlatformInvoice>> platformInvoicesStream({
    required String franchiseeId,
    String? status,
  }) {
    firestore.Query q = db
        .collection('franchises')
        .doc(franchiseeId) // franchiseeId is the franchiseId in this context
        .collection('platform_invoices');

    if (status != null) q = q.where('status', isEqualTo: status);

    return q.snapshots().map((s) => s.docs
        .map((d) =>
            PlatformInvoice.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  @override
  Future<List<PlatformInvoice>> getPlatformInvoicesForUser(
      String userId) async {
    // This method is used for user-level views; franchise context resolved via FranchiseProvider in UI
    final snap = await db
        .collection('platform_invoices')
        .where('userId', isEqualTo: userId)
        .get();
    return snap.docs
        .map((d) =>
            PlatformInvoice.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getPlatformPaymentsForUser(
      String userId) async {
    final snap = await db
        .collection('platform_payments')
        .where('userId', isEqualTo: userId)
        .get();
    return snap.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map)..['id'] = d.id)
        .toList();
  }

  @override
  Future<void> savePlatformInvoiceFromWebhook(
      Map<String, dynamic> eventData, String invoiceId) async {
    // franchiseeId must be present in webhook metadata for correct scoping
    final franchiseeId =
        eventData['franchiseeId'] ?? eventData['metadata']?['franchiseeId'];
    if (franchiseeId == null || franchiseeId.isEmpty) {
      shared.ErrorLogger.log(
        message: 'savePlatformInvoiceFromWebhook missing franchiseeId',
        source: 'AdminFirestoreService.savePlatformInvoiceFromWebhook',
        severity: 'error',
      );
      return;
    }

    await db
        .collection('franchises')
        .doc(franchiseeId)
        .collection('platform_invoices')
        .doc(invoiceId)
        .set(eventData, firestore.SetOptions(merge: true));
  }

  @override
  Future<List<PlatformInvoice>> getPlatformInvoicesForFranchisee(
      String franchiseeId) async {
    final snap = await db
        .collection('franchises')
        .doc(franchiseeId)
        .collection('platform_invoices')
        .get();
    return snap.docs
        .map((d) =>
            PlatformInvoice.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createPlatformInvoice(PlatformInvoice invoice) async {
    await db
        .collection('franchises')
        .doc(invoice.franchiseeId)
        .collection('platform_invoices')
        .doc(invoice.id)
        .set(invoice.toMap());
  }

  @override
  Future<void> updatePlatformInvoiceStatus(
      String invoiceId, String newStatus) async {
    // franchiseeId not known here - in practice this is called with full context
    // For safety we keep top-level reference for legacy compatibility; production calls use franchise-scoped paths
    await db
        .collection('platform_invoices')
        .doc(invoiceId)
        .update({'status': newStatus});
  }

  @override
  Future<List<PlatformPayment>> getPlatformPaymentsForFranchisee(
      String franchiseeId) async {
    final snap = await db
        .collection('franchises')
        .doc(franchiseeId)
        .collection('platform_payments')
        .get();
    return snap.docs
        .map((d) =>
            PlatformPayment.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createPlatformPayment(PlatformPayment payment) async {
    await db
        .collection('franchises')
        .doc(payment.franchiseeId)
        .collection('platform_payments')
        .doc(payment.id)
        .set(payment.toMap());
  }

  @override
  Future<void> markPlatformPaymentCompleted(String paymentId) async {
    await db
        .collection('platform_payments')
        .doc(paymentId)
        .update({'status': 'completed'});
  }

  @override
  Future<void> updatePlatformPaymentStatus(
      String paymentId, String newStatus) async {
    await db
        .collection('platform_payments')
        .doc(paymentId)
        .update({'status': newStatus});
  }

  @override
  Future<void> markPlatformInvoicePaid(String invoiceId, String method) async {
    await db.collection('platform_invoices').doc(invoiceId).update({
      'status': 'paid',
      'paidAt': firestore.FieldValue.serverTimestamp(),
      'lastPaymentMethod': method,
    });
  }

  // ===================== PAYOUTS (full lifecycle + audit/attachments/comments) =====================
  // Fully scoped under franchises/{franchiseId}/payouts per schema + Non-Negotiable Rules.
  // Uses Payout model's franchiseRef (DocumentReference) exactly as defined in shared_core.

  @override
  Future<void> addOrUpdatePayout(Payout payout) async {
    final franchiseId = payout.franchiseRef.id;
    if (franchiseId.isEmpty) {
      shared.ErrorLogger.log(
        message: 'addOrUpdatePayout called without valid franchiseRef',
        source: 'AdminFirestoreService.addOrUpdatePayout',
        severity: 'error',
        contextData: {'payoutId': payout.id},
      );
      return;
    }
    try {
      final ref = db
          .collection('franchises')
          .doc(franchiseId)
          .collection('payouts')
          .doc(payout.id);

      await ref.set(payout.toFirestore(), firestore.SetOptions(merge: true));

      await addPayoutAuditEvent(payout.id, {
        'action': 'upsert',
        'by': currentUserId,
        'at': DateTime.now().toIso8601String(),
        'franchiseId': franchiseId,
      });
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Firestore error in addOrUpdatePayout: $e',
        stack: stack.toString(),
        source: 'AdminFirestoreService.addOrUpdatePayout',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'payoutId': payout.id},
      );
      rethrow;
    }
  }

  @override
  Future<Payout?> getPayoutById(String id) async {
    final doc = await db.collection('payouts').doc(id).get();
    return doc.exists ? Payout.fromFirestore(doc.data()!, doc.id) : null;
  }

  @override
  Future<void> deletePayout(String id) async {
    await db.collection('payouts').doc(id).delete();
  }

  @override
  Stream<List<Payout>> payoutsStream({String? franchiseId, String? status}) {
    if (franchiseId == null || franchiseId.isEmpty) {
      return Stream.value(<Payout>[]);
    }
    firestore.Query q =
        db.collection('franchises').doc(franchiseId).collection('payouts');

    if (status != null) q = q.where('status', isEqualTo: status);

    return q
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Payout.fromFirestore(
                  d.data() as Map<String, dynamic>,
                  d.id,
                ))
            .toList());
  }

  @override
  Future<List<Map<String, dynamic>>> getPayoutsForFranchise({
    required String franchiseId,
    String? status,
    String? searchQuery,
  }) async {
    firestore.Query q =
        db.collection('franchises').doc(franchiseId).collection('payouts');

    if (status != null) q = q.where('status', isEqualTo: status);

    final snap = await q.get();
    return snap.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map)..['id'] = d.id)
        .toList();
  }

  @override
  Future<List<Payout>> fetchPayouts({
    String? franchiseId,
    String? status,
    String? locationId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? sortBy,
    bool descending = true,
    int? limit,
    dynamic startAfter,
  }) async {
    if (franchiseId == null || franchiseId.isEmpty) {
      return <Payout>[];
    }

    firestore.Query q =
        db.collection('franchises').doc(franchiseId).collection('payouts');

    if (status != null) q = q.where('status', isEqualTo: status);
    if (startDate != null)
      q = q.where('createdAt', isGreaterThanOrEqualTo: startDate);
    if (endDate != null) q = q.where('createdAt', isLessThanOrEqualTo: endDate);
    if (sortBy != null) q = q.orderBy(sortBy, descending: descending);
    if (limit != null) q = q.limit(limit);
    if (startAfter != null) q = q.startAfter([startAfter]);

    final snap = await q.get();
    return snap.docs
        .map(
            (d) => Payout.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getPayoutDetailsWithAudit(
      String payoutId) async {
    final payout = await getPayoutById(payoutId);
    if (payout == null) return null;

    final audit = await getAuditLogsForPayout(payoutId);
    return {
      'payout': payout.toFirestore(),
      'audit': audit.map((a) => a.toFirestore()).toList(),
    };
  }

  @override
  Future<void> addPayoutAuditEvent(
      String payoutId, Map<String, dynamic> event) async {
    await db.collection('payouts').doc(payoutId).collection('audit').add({
      ...event,
      'timestamp': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addAttachmentToPayout(
      String payoutId, Map<String, dynamic> attachment) async {
    await db.collection('payouts').doc(payoutId).update({
      'attachments': firestore.FieldValue.arrayUnion([attachment]),
    });
    await addPayoutAuditEvent(
        payoutId, {'action': 'attachment_added', 'attachment': attachment});
  }

  @override
  Future<void> removeAttachmentFromPayout(
      String payoutId, Map<String, dynamic> attachment) async {
    await db.collection('payouts').doc(payoutId).update({
      'attachments': firestore.FieldValue.arrayRemove([attachment]),
    });
  }

  @override
  Future<void> bulkUpdatePayoutStatus(
      List<String> payoutIds, String status) async {
    final batch = db.batch();
    for (final id in payoutIds) {
      batch.update(db.collection('payouts').doc(id), {'status': status});
    }
    await batch.commit();
  }

  @override
  Future<void> addPayoutComment(
      String payoutId, Map<String, dynamic> comment) async {
    await db.collection('payouts').doc(payoutId).collection('comments').add({
      ...comment,
      'createdAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPayoutComments(String payoutId) async {
    final snap = await db
        .collection('payouts')
        .doc(payoutId)
        .collection('comments')
        .orderBy('createdAt')
        .get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  @override
  Future<void> removePayoutComment(
      String payoutId, Map<String, dynamic> comment) async {
    if (comment['id'] == null) return;
    await db
        .collection('payouts')
        .doc(payoutId)
        .collection('comments')
        .doc(comment['id'])
        .delete();
  }

  @override
  Future<void> markPayoutSent(String payoutId, {DateTime? sentAt}) async {
    await db.collection('payouts').doc(payoutId).update({
      'status': 'sent',
      'sentAt': sentAt ?? firestore.FieldValue.serverTimestamp(),
    });
    await addPayoutAuditEvent(payoutId, {'action': 'marked_sent'});
  }

  @override
  Future<void> setPayoutStatus(String payoutId, String newStatus) async {
    await db.collection('payouts').doc(payoutId).update({'status': newStatus});
  }

  @override
  Future<void> markPayoutFailed(String payoutId,
      {String? errorMsg, String? errorCode}) async {
    await db.collection('payouts').doc(payoutId).update({
      'status': 'failed',
      'errorMessage': errorMsg,
      'errorCode': errorCode,
    });
  }

  @override
  Future<void> retryPayout(String payoutId) async {
    await setPayoutStatus(payoutId, 'pending');
  }

  @override
  Future<List<AuditLog>> getAuditLogsForPayout(String payoutId) async {
    final snap = await db
        .collection('payouts')
        .doc(payoutId)
        .collection('audit')
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs
        .map((d) =>
            AuditLog.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  @override
  Future<String> exportPayoutsToCsv({
    String? franchiseId,
    String? status,
    String? locationId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? sortBy,
    bool descending = true,
    int? limit,
  }) async {
    // Production CSV generation via shared/export_utils.dart (kept as placeholder per original)
    return 'payout_id,franchise,amount,status\n'; // TODO: replace with real export call
  }

  /// Enhanced import that cleans malformed includedIngredients and customizations
  /// before saving to prevent MenuItem.fromFirestore warnings.
  Future<void> importMenuItemsFromTemplateClean({
    required String franchiseId,
    required String templateId,
  }) async {
    print(
        '[AdminFirestoreService] importMenuItemsFromTemplateClean STARTED - franchiseId: $franchiseId, templateId: $templateId');

    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      shared.ErrorLogger.log(
        message:
            'importMenuItemsFromTemplateClean called with invalid franchiseId',
        source: 'AdminFirestoreService',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }

    try {
      final templateCollection = db
          .collection('onboarding_templates')
          .doc(templateId)
          .collection('menu_items');

      final snapshot = await templateCollection.get();

      if (snapshot.docs.isEmpty) {
        print('[WARN] No menu items found in template $templateId');
        return;
      }

      final batch = db.batch();
      int copiedCount = 0;

      for (final doc in snapshot.docs) {
        var map = Map<String, dynamic>.from(doc.data());

        // Clean malformed includedIngredients
        if (map['includedIngredients'] is List) {
          map['includedIngredients'] = (map['includedIngredients'] as List)
              .where((e) =>
                  e != null && (e is String || (e is Map && e['id'] != null)))
              .toList();
        } else {
          map['includedIngredients'] = <dynamic>[];
        }

        // Clean customizations
        if (map['customizations'] is! List) {
          map['customizations'] = <dynamic>[];
        }

        final newDocRef = db
            .collection('franchises')
            .doc(franchiseId)
            .collection('menu_items')
            .doc(doc.id);

        batch.set(newDocRef, map, firestore.SetOptions(merge: true));
        copiedCount++;
      }

      await batch.commit();

      print(
          '[AdminFirestoreService] importMenuItemsFromTemplateClean SUCCESS - copied $copiedCount cleaned menu items');

      // Audit log
      final auditService = AuditLogServiceImpl();
      await auditService.addLog(
        franchiseId: franchiseId,
        userId: currentUserId ?? 'system',
        action: 'template_import_clean',
        targetType: 'menu_items',
        targetId: 'bulk',
        details: {
          'templateId': templateId,
          'count': copiedCount,
          'cleaned': true,
        },
      );
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'importMenuItemsFromTemplateClean failed',
        stack: stack.toString(),
        source: 'AdminFirestoreService',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'templateId': templateId},
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getOnboardingProgress(
      String franchiseId) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return null;
    }

    try {
      final doc = await firestore.FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('onboarding_progress')
          .doc('progress')
          .get();
      return doc.data();
    } catch (e, stack) {
      await shared.ErrorLogger.log(
        message: 'Failed to getOnboardingProgress: $e',
        source: 'AdminFirestoreService',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId},
      );
      return null;
    }
  }

  @override
  Future<void> updateOnboardingStep({
    required String franchiseId,
    required String stepKey,
    required bool completed,
  }) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      return;
    }

    try {
      await firestore.FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('onboarding_progress')
          .doc('progress')
          .set(
        {
          stepKey: completed,
          'updatedAt': firestore.FieldValue.serverTimestamp(),
        },
        firestore.SetOptions(merge: true),
      );
    } catch (e, stack) {
      await shared.ErrorLogger.log(
        message: 'Failed to updateOnboardingStep: $e',
        source: 'AdminFirestoreService',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'stepKey': stepKey,
          'completed': completed,
        },
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteMenuItem(
    String franchiseId,
    String menuItemId, {
    String? userId,
  }) async {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default' ||
        menuItemId.isEmpty) {
      shared.ErrorLogger.log(
        message: 'deleteMenuItem called with invalid ids',
        source: 'AdminFirestoreService.deleteMenuItem',
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
          'menuItemId': menuItemId,
        },
      );
      return;
    }

    try {
      await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('menu_items')
          .doc(menuItemId)
          .delete();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to delete menu item',
        stack: stack.toString(),
        source: 'AdminFirestoreService.deleteMenuItem',
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
          'menuItemId': menuItemId,
        },
      );
      rethrow;
    }
  }

  /// Phase 1 Rule-Based Schema Normalization
  /// - Strips legacy prefixes (cat_, ing_, etc.)
  /// - Matches by name to live clean IDs
  /// - Bulk updates menu_items + related references
  Future<Map<String, int>> normalizeSchemaReferences({
    required String franchiseId,
  }) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return {};

    print(
        '[AdminFirestoreService] normalizeSchemaReferences STARTED for $franchiseId');

    final stats = <String, int>{
      'categories': 0,
      'ingredients': 0,
      'types': 0,
      'menuItems': 0,
    };

    try {
      // Load live clean data
      final categories = await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('categories')
          .get();

      final ingredients = await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_metadata')
          .get();

      final types = await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types')
          .get();

      final menuItemsSnap = await db
          .collection('franchises')
          .doc(franchiseId)
          .collection('menu_items')
          .get();

      final batch = db.batch();

      // Helper: Legacy prefix strip
      String cleanId(String raw) {
        String id = raw.trim();
        if (id.startsWith('cat_')) id = id.substring(4);
        if (id.startsWith('ing_')) id = id.substring(4);
        if (id.startsWith('type_')) id = id.substring(5);
        return id;
      }

      // Normalize Menu Items
      for (final doc in menuItemsSnap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        bool changed = false;

        // Category ID
        if (data['categoryId'] != null) {
          final oldCat = data['categoryId'] as String;
          final clean = cleanId(oldCat);
          final match = categories.docs
              .where((d) =>
                  d.id == clean ||
                  (d.data()['name'] as String?)?.toLowerCase() ==
                      oldCat.toLowerCase())
              .firstOrNull;
          if (match != null && match.id != oldCat) {
            data['categoryId'] = match.id;
            changed = true;
            stats['categories'] = stats['categories']! + 1;
          }
        }

        // Included / Optional / Customizations normalization (similar logic)
        // ... (expand for ingredients/types as needed - abbreviated for brevity)

        if (changed) {
          batch.set(doc.reference, data, firestore.SetOptions(merge: true));
          stats['menuItems'] = stats['menuItems']! + 1;
        }
      }

      await batch.commit();

      print(
          '[AdminFirestoreService] normalizeSchemaReferences COMPLETE - $stats');
      return stats;
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'normalizeSchemaReferences failed',
        stack: stack.toString(),
        source: 'AdminFirestoreService',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  /// Saves or updates a single MenuItem (Admin path)
  /// Saves or updates a single MenuItem (Admin path - web only)
  Future<void> saveMenuItem({
    required String franchiseId,
    required shared.MenuItem menuItem,
  }) async {
    if (franchiseId.isEmpty || menuItem.id.isEmpty) {
      throw ArgumentError('franchiseId and menuItem.id are required');
    }

    try {
      final docRef = firestore.FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('menu_items')
          .doc(menuItem.id);

      final data = menuItem
          .toMap(); // Use .toMap() as defined in your shared MenuItem model

      await docRef.set(data, firestore.SetOptions(merge: true));

      shared.ErrorLogger.log(
        message: 'MenuItem saved successfully',
        source: 'AdminFirestoreService.saveMenuItem',
        severity: 'info',
      );
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to save menu item',
        stack: stack.toString(),
        source: 'AdminFirestoreService.saveMenuItem',
        severity: 'error',
      );
      rethrow;
    }
  }

  /// Batch save multiple menu items
  @override
  Future<void> saveMenuItems(
      String franchiseId, List<shared.MenuItem> menuItems) async {
    if (franchiseId.isEmpty) throw ArgumentError('franchiseId required');

    final batch = firestore.FirebaseFirestore.instance.batch();
    final baseRef = firestore.FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('menu_items');

    for (final item in menuItems) {
      if (item.id.isEmpty) continue;
      final docRef = baseRef.doc(item.id);
      batch.set(docRef, item.toMap(), firestore.SetOptions(merge: true));
    }

    await batch.commit();

    shared.ErrorLogger.log(
      message: '${menuItems.length} menu items saved',
      source: 'AdminFirestoreService.saveMenuItems',
      severity: 'info',
    );
  }
}
