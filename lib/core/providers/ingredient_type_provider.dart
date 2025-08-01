import 'package:flutter/foundation.dart';
import 'package:franchise_admin_portal/core/models/ingredient_type_model.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'dart:convert';
import 'package:franchise_admin_portal/core/models/ingredient_metadata.dart';

class IngredientTypeProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  String franchiseId = '';

  bool _loading = false;
  String? _error;

  List<IngredientType> get ingredientTypes => _ingredientTypes;
  bool get loading => _loading;
  String? get error => _error;
  List<IngredientType> _ingredientTypes = [];

  /// Load all ingredient types for the given franchise
  Future<void> loadIngredientTypes(String newFranchiseId) async {
    franchiseId = newFranchiseId;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types')
          .orderBy('sortOrder')
          .get();

      _ingredientTypes = snapshot.docs
          .map((doc) => IngredientType.fromFirestore(doc))
          .toList();
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to load ingredient types',
        source: 'ingredient_type_provider.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'errorType': e.runtimeType.toString(),
        },
      );
    }
  }

  /// Reload ingredient types from Firestore (used after sidebar repair/add-new)
  Future<void> reload(String franchiseId) async {
    await loadIngredientTypes(franchiseId);
  }

  /// Returns all type IDs missing from the current provider (for repair UI)
  List<String> missingTypeIds(List<String> ids) {
    final currentIds = allTypeIds.toSet();
    return ids.where((id) => !currentIds.contains(id)).toList();
  }

  /// Adds or updates multiple ingredient types (for repair/add-new flows)
  void addOrUpdateTypes(List<IngredientType> newTypes) {
    for (final t in newTypes) {
      final idx = _ingredientTypes.indexWhere((e) => e.id == t.id);
      if (idx != -1) {
        _ingredientTypes[idx] = t;
      } else {
        _ingredientTypes.add(t);
      }
    }
    notifyListeners();
  }

  Future<void> createType(String franchiseId, IngredientType type) async {
    final colRef = _firestoreService.db
        .collection('franchises')
        .doc(franchiseId)
        .collection('ingredient_types');
    await colRef.doc(type.id).set(type.toMap(includeTimestamps: true));
    await loadIngredientTypes(franchiseId);
  }

  /// Reorders ingredient types and persists updated sortOrder to Firestore
  /// Reorders ingredient types and updates their sortOrder in Firestore
  Future<void> reorderIngredientTypes(
    String franchiseId,
    List<IngredientType> newOrder,
  ) async {
    try {
      final updates = newOrder.asMap().entries.map((entry) {
        return {
          'id': entry.value.id,
          'sortOrder': entry.key,
        };
      }).toList();

      await _firestoreService.updateIngredientTypeSortOrders(
        franchiseId: franchiseId,
        sortedUpdates: updates,
      );

      // Reload local state after update
      await loadIngredientTypes(franchiseId);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to reorder ingredient types',
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_management_screen',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'newOrderIds': newOrder.map((e) => e.id).toList(),
        },
      );
    }
  }

  /// Get a specific type by ID
  IngredientType? getById(String id) {
    return _ingredientTypes.firstWhereOrNull((t) => t.id == id);
  }

  /// Add a new ingredient type to Firestore and local list
  Future<void> addIngredientType(
      String franchiseId, IngredientType type) async {
    try {
      await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types')
          .add(type.toMap(includeTimestamps: true));
      await loadIngredientTypes(franchiseId);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to add ingredient type',
        source: 'ingredient_type_provider.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'typeName': type.name,
          'errorType': e.runtimeType.toString(),
        },
      );
    }
  }

  /// Update an existing ingredient type
  /// Update specific fields of an existing ingredient type
  Future<void> updateIngredientType(
    String franchiseId,
    String typeId,
    Map<String, dynamic> updatedFields,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types')
          .doc(typeId)
          .update({
        ...updatedFields,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadIngredientTypes(franchiseId);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to update ingredient type (partial)',
        source: 'ingredient_type_provider.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'typeId': typeId,
          'updatedFields': updatedFields.keys.toList(),
          'errorType': e.runtimeType.toString(),
        },
      );
    }
  }

  Future<void> deleteIngredientType(String franchiseId, String typeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types')
          .doc(typeId)
          .delete();
      _ingredientTypes.removeWhere((t) => t.id == typeId);
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to delete ingredient type',
        source: 'ingredient_type_provider.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'typeId': typeId,
          'errorType': e.runtimeType.toString(),
        },
      );
    }
  }

  /// Check if the ingredient type is currently referenced by any ingredient_metadata
  Future<bool> isIngredientTypeInUse({
    required String franchiseId,
    required String typeId,
  }) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_metadata')
          .where('typeId', isEqualTo: typeId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to check ingredient type usage',
        source: 'ingredient_type_provider.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'typeId': typeId,
          'errorType': e.runtimeType.toString(),
        },
      );
      return true; // Defensive: assume in-use if error
    }
  }

  Future<String> exportTypesAsJson(String franchiseId) async {
    try {
      final exportable = types.map((type) => type.toMap()).toList();
      return const JsonEncoder.withIndent('  ').convert(exportable);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to export ingredient types as JSON',
        source: 'IngredientTypeProvider',
        screen: 'ingredient_type_management_screen',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'typesLength': types.length,
        },
      );
      return '[]';
    }
  }

  Future<void> bulkReplaceIngredientTypes(
    String franchiseId,
    List<IngredientType> newTypes,
  ) async {
    try {
      final batch = _firestoreService.db.batch();
      final collectionRef = _firestoreService.db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types');

      // 1. Delete existing types
      final existingSnapshot = await collectionRef.get();
      for (final doc in existingSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 2. Add new types
      for (int i = 0; i < newTypes.length; i++) {
        final type = newTypes[i];
        final docRef = collectionRef.doc();
        batch.set(docRef, {
          ...type.toMap(includeTimestamps: true),
          'sortOrder': i,
        });
      }

      await batch.commit();
      await loadIngredientTypes(franchiseId);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed bulk replace of ingredient types',
        stack: stack.toString(),
        severity: 'error',
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_json_import_export_dialog.dart',
        contextData: {
          'franchiseId': franchiseId,
          'newTypeCount': newTypes.length,
        },
      );
      rethrow;
    }
  }

  Future<void> loadTemplateIngredients(
      String templateId, String franchiseId) async {
    try {
      final firestoreService = FirestoreService();

      // 🔹 Load ingredient_metadata from template
      final List<IngredientMetadata> ingredients =
          await firestoreService.getIngredientMetadataTemplate(templateId);

      final batch = firestoreService.db.batch();
      final destRef = firestoreService.db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_metadata');

      for (final ingredient in ingredients) {
        final docRef = destRef.doc(ingredient.id);
        batch.set(docRef, ingredient.toMap());
      }

      await batch.commit();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'template_ingredient_metadata_import_failed',
        source: 'IngredientTypeProvider',
        stack: stack.toString(),
        severity: 'error',
      );
      rethrow;
    }
  }

  // Aliased methods for UI usage compatibility
  Future<void> loadTypes(String franchiseId) =>
      loadIngredientTypes(franchiseId);
  List<IngredientType> get types => _ingredientTypes;

  Future<void> addType(String franchiseId, IngredientType type) =>
      addIngredientType(franchiseId, type);

  Future<void> updateType(String franchiseId, IngredientType type) =>
      updateIngredientType(
          franchiseId, type.id!, type.toMap(includeTimestamps: true));

  Future<void> deleteType(String franchiseId, String typeId) =>
      deleteIngredientType(franchiseId, typeId);

  /// Returns a map of all type IDs to names.
  Map<String, String> get typeIdToName => Map.fromEntries(
      types.where((t) => t.id != null).map((t) => MapEntry(t.id!, t.name)));

  /// Returns a list of all available type IDs.
  List<String> get allTypeIds => types
      .where((t) => t.id != null && t.id!.isNotEmpty)
      .map((t) => t.id!)
      .toList();

  /// Returns a list of all available type names.
  List<String> get allTypeNames => types.map((t) => t.name).toList();

  /// Find a type by name (case-insensitive, trimmed).
  IngredientType? getByName(String name) {
    return types.firstWhereOrNull(
        (t) => t.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  /// Find a type by systemTag (case-insensitive).
  IngredientType? getBySystemTag(String tag) {
    return types.firstWhereOrNull((t) =>
        t.systemTag != null && t.systemTag!.toLowerCase() == tag.toLowerCase());
  }
}
