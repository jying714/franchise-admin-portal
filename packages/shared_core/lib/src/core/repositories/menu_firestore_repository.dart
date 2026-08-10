// packages/shared_core/lib/src/core/repositories/menu_firestore_repository.dart
//
// Concrete MenuRepository. Phase A1: core menu-item CRUD + reads only.
// Bodies moved from FirestoreServiceImpl (same logic, same paths).
// Authority: docs/slices/bounded-context-repos-v1.md

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import '../models/menu_item.dart';
import '../models/category.dart' as model;
import '../models/ingredient_metadata.dart';
import '../models/ingredient_type_model.dart';
import '../models/customization.dart';
import '../utils/error_logger.dart';
import 'menu_repository.dart';

class MenuFirestoreRepository implements MenuRepository {
  MenuFirestoreRepository({firestore.FirebaseFirestore? db})
      : _db = db ?? firestore.FirebaseFirestore.instance;

  final firestore.FirebaseFirestore _db;

  static const String _menuItems = 'menu_items';

  firestore.CollectionReference<Map<String, dynamic>> _col(
          String franchiseId) =>
      _db.collection('franchises').doc(franchiseId).collection(_menuItems);

  static const String _categories = 'categories';

  firestore.CollectionReference<Map<String, dynamic>> _catCol(
          String franchiseId) =>
      _db.collection('franchises').doc(franchiseId).collection(_categories);

  bool _badFranchise(String? franchiseId) =>
      franchiseId == null ||
      franchiseId.isEmpty ||
      franchiseId == 'unknown' ||
      franchiseId == 'default';

  // --- Menu items (extracted) ---

  @override
  Future<void> addMenuItem(String franchiseId, MenuItem item,
      {String? userId}) async {
    if (_badFranchise(franchiseId)) return;

    try {
      await _col(franchiseId).doc(item.id).set(item.toFirestore());
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to addMenuItem',
        source: 'MenuFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'menuItemId': item.id},
      );
    }
  }

  @override
  Future<void> updateMenuItem(String franchiseId, MenuItem item,
      {String? userId}) async {
    if (_badFranchise(franchiseId)) return;

    try {
      await _col(franchiseId).doc(item.id).update(item.toFirestore());
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to updateMenuItem',
        source: 'MenuFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'menuItemId': item.id},
      );
    }
  }

  @override
  Future<void> deleteMenuItem(String franchiseId, String id,
      {String? userId}) async {
    if (_badFranchise(franchiseId)) return;

    try {
      await _col(franchiseId).doc(id).delete();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to deleteMenuItem',
        source: 'MenuFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'menuItemId': id},
      );
    }
  }

  @override
  Stream<List<MenuItem>> getMenuItems(String franchiseId,
      {String? search, String? sortBy, bool descending = false}) {
    if (_badFranchise(franchiseId)) {
      return Stream.value(<MenuItem>[]);
    }

    firestore.Query q = _col(franchiseId);

    if (search != null && search.isNotEmpty) {
      q = q.where('categoryId', isEqualTo: search);
    }
    // Do NOT orderBy sortOrder in the query: docs without that field are
    // excluded by Firestore. Sort client-side so HQ-authored items load.
    if (sortBy != null && sortBy.isNotEmpty && sortBy != 'sortOrder') {
      q = q.orderBy(sortBy, descending: descending);
    }

    return q.snapshots().map((s) {
      final list = s.docs
          .map((d) {
            try {
              return MenuItem.fromFirestore(
                  d.data() as Map<String, dynamic>, d.id);
            } catch (e) {
              return null;
            }
          })
          .where((item) => item != null)
          .cast<MenuItem>()
          .toList();

      list.sort((a, b) {
        final ao = a.sortOrder ?? 0;
        final bo = b.sortOrder ?? 0;
        if (ao != bo) return ao.compareTo(bo);
        return a.name.compareTo(b.name);
      });

      return list;
    });
  }

  @override
  Future<List<MenuItem>> getMenuItemsOnce(String franchiseId) async {
    if (_badFranchise(franchiseId)) return [];

    final snap = await _col(franchiseId).get();
    return snap.docs
        .map((d) => MenuItem.fromFirestore(d.data(), d.id))
        .toList();
  }

  @override
  Stream<List<MenuItem>> getMenuItemsByIds(
      String franchiseId, List<String> ids) {
    if (_badFranchise(franchiseId) || ids.isEmpty) {
      return Stream.value(<MenuItem>[]);
    }

    return _col(franchiseId)
        .where(firestore.FieldPath.documentId, whereIn: ids)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => MenuItem.fromFirestore(d.data(), d.id)).toList());
  }

  @override
  Future<MenuItem?> getMenuItemById(String itemId,
      {String? franchiseId}) async {
    if (_badFranchise(franchiseId)) return null;

    try {
      final doc = await _col(franchiseId!).doc(itemId).get();
      if (doc.exists && doc.data() != null) {
        return MenuItem.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to getMenuItemById',
        source: 'MenuFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'menuItemId': itemId},
      );
      return null;
    }
  }

  // --- Not yet extracted (Phase A1 later) ---

  @override
  Future<List<MenuItem>> fetchMenuItemsOnce(String franchiseId) =>
      getMenuItemsOnce(franchiseId);

  @override
  Future<void> saveMenuItems(String franchiseId, List<MenuItem> items) =>
      throw UnimplementedError(
          'MenuRepository.saveMenuItems not yet extracted');

  @override
  Future<void> reorderMenuItems(String franchiseId, List<MenuItem> ordered) =>
      throw UnimplementedError(
          'MenuRepository.reorderMenuItems not yet extracted');

  @override
  Stream<List<MenuItem>> getMenuItemsByCategory(String categoryId,
      {String? franchiseId, String? sortBy}) {
    if (_badFranchise(franchiseId)) {
      return Stream.value(<MenuItem>[]);
    }

    firestore.Query q =
        _col(franchiseId!).where('categoryId', isEqualTo: categoryId);

    if (sortBy != null && sortBy.isNotEmpty) {
      q = q.orderBy(sortBy);
    } else {
      q = q.orderBy('sortOrder');
    }

    return q.snapshots().map((s) {
      final list = s.docs
          .map((d) {
            try {
              return MenuItem.fromFirestore(
                  d.data() as Map<String, dynamic>, d.id);
            } catch (e) {
              return null;
            }
          })
          .where((item) => item != null)
          .cast<MenuItem>()
          .where((m) => m.isSellable)
          .toList();

      return list;
    });
  }

  @override
  List<Customization> getCustomizationGroups(MenuItem item) =>
      throw UnimplementedError(
          'MenuRepository.getCustomizationGroups not yet extracted');

  @override
  List<Customization> getPreselectedCustomizations(MenuItem item) =>
      throw UnimplementedError(
          'MenuRepository.getPreselectedCustomizations not yet extracted');

  @override
  Future<List<model.Category>> fetchCategories(String franchiseId) async {
    if (_badFranchise(franchiseId)) return [];

    try {
      final snap = await _catCol(franchiseId).get();
      final list = snap.docs
          .map((d) => model.Category.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) {
        final ao = a.sortOrder ?? 0;
        final bo = b.sortOrder ?? 0;
        if (ao != bo) return ao.compareTo(bo);
        return a.name.compareTo(b.name);
      });
      return list;
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to fetchCategories',
        source: 'MenuFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId},
      );
      return [];
    }
  }

  @override
  Stream<List<model.Category>> getCategories(String franchiseId) {
    if (_badFranchise(franchiseId)) {
      return Stream.value(<model.Category>[]);
    }

    return _catCol(franchiseId).snapshots().map((s) {
      final list = s.docs
          .map((d) {
            try {
              return model.Category.fromFirestore(
                  d.data() as Map<String, dynamic>, d.id);
            } catch (_) {
              return null;
            }
          })
          .where((c) => c != null)
          .cast<model.Category>()
          .toList();

      list.sort((a, b) {
        final ao = a.sortOrder ?? 0;
        final bo = b.sortOrder ?? 0;
        if (ao != bo) return ao.compareTo(bo);
        return a.name.compareTo(b.name);
      });
      return list;
    });
  }

  @override
  Future<void> saveCategory(String franchiseId, model.Category category) =>
      throw UnimplementedError('MenuRepository.saveCategory not yet extracted');

  @override
  Future<void> addCategory({
    required String franchiseId,
    required model.Category category,
  }) async {
    if (_badFranchise(franchiseId)) return;

    try {
      await _catCol(franchiseId).doc(category.id).set(category.toFirestore());
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to addCategory',
        source: 'MenuFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'categoryId': category.id},
      );
    }
  }

  @override
  Future<void> updateCategory(
      String franchiseId, model.Category category) async {
    if (_badFranchise(franchiseId)) return;

    try {
      await _catCol(franchiseId)
          .doc(category.id)
          .update(category.toFirestore());
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to updateCategory',
        source: 'MenuFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'categoryId': category.id},
      );
    }
  }

  @override
  Future<void> deleteCategory({
    required String franchiseId,
    required String categoryId,
  }) async {
    if (_badFranchise(franchiseId)) return;

    try {
      await _catCol(franchiseId).doc(categoryId).delete();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to deleteCategory',
        source: 'MenuFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'categoryId': categoryId},
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> getCategorySchema(
          String franchiseId, String categoryId) =>
      throw UnimplementedError(
          'MenuRepository.getCategorySchema not yet extracted');

  @override
  Future<List<String>> getAllCategorySchemaIds(String franchiseId) =>
      throw UnimplementedError(
          'MenuRepository.getAllCategorySchemaIds not yet extracted');

  @override
  Future<List<IngredientMetadata>> getAllIngredientMetadata(String franchiseId,
          {bool forceRefresh = false}) =>
      throw UnimplementedError(
          'MenuRepository.getAllIngredientMetadata not yet extracted');

  @override
  Future<List<IngredientMetadata>> getIngredientMetadataByIds(
          String franchiseId, List<String> ids) =>
      throw UnimplementedError(
          'MenuRepository.getIngredientMetadataByIds not yet extracted');

  @override
  Future<Map<String, IngredientMetadata>> getIngredientMetadataMap(
          String franchiseId,
          {bool forceRefresh = false}) =>
      throw UnimplementedError(
          'MenuRepository.getIngredientMetadataMap not yet extracted');

  @override
  Future<List<Map<String, dynamic>>> fetchIngredientMetadataAsMaps(
          String franchiseId,
          {bool forceRefresh = false}) =>
      throw UnimplementedError(
          'MenuRepository.fetchIngredientMetadataAsMaps not yet extracted');

  @override
  Future<void> saveIngredientMetadata(
          String franchiseId, IngredientMetadata ingredient) =>
      throw UnimplementedError(
          'MenuRepository.saveIngredientMetadata not yet extracted');

  @override
  Future<void> saveIngredientMetadataBatch(
          String franchiseId, List<IngredientMetadata> ingredients) =>
      throw UnimplementedError(
          'MenuRepository.saveIngredientMetadataBatch not yet extracted');

  @override
  Future<void> deleteIngredientMetadataBatch(
          String franchiseId, List<String> ids) =>
      throw UnimplementedError(
          'MenuRepository.deleteIngredientMetadataBatch not yet extracted');

  @override
  Future<void> replaceIngredientMetadataBatch(
          String franchiseId, List<IngredientMetadata> newItems) =>
      throw UnimplementedError(
          'MenuRepository.replaceIngredientMetadataBatch not yet extracted');

  @override
  Future<List<String>> getAllergensForIngredientIds(
          String franchiseId, List<String>? ingredientIds) =>
      throw UnimplementedError(
          'MenuRepository.getAllergensForIngredientIds not yet extracted');

  @override
  Stream<List<IngredientMetadata>> getIngredientMetadata(String franchiseId) =>
      throw UnimplementedError(
          'MenuRepository.getIngredientMetadata not yet extracted');

  @override
  Stream<List<IngredientType>> getIngredientTypes(String franchiseId) =>
      throw UnimplementedError(
          'MenuRepository.getIngredientTypes not yet extracted');

  @override
  Future<void> saveIngredientType(String franchiseId, IngredientType type) =>
      throw UnimplementedError(
          'MenuRepository.saveIngredientType not yet extracted');

  @override
  Future<void> updateIngredientType(String franchiseId, IngredientType type) =>
      throw UnimplementedError(
          'MenuRepository.updateIngredientType not yet extracted');

  @override
  Future<void> deleteIngredientType(String franchiseId, String typeId) =>
      throw UnimplementedError(
          'MenuRepository.deleteIngredientType not yet extracted');
}
