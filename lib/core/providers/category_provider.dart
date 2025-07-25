// lib/core/providers/category_provider.dart

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class CategoryProvider extends ChangeNotifier {
  final FirestoreService firestore;
  String franchiseId;

  List<Category> _original = [];
  List<Category> _current = [];
  final Set<String> _selectedCategoryIds = {};

  bool _loading = true;
  bool _groupByVisible = false;

  CategoryProvider({
    required this.firestore,
    required this.franchiseId,
  });

  List<Category> get categories => _current;
  bool get isLoading => _loading;
  bool get isDirty =>
      !const DeepCollectionEquality().equals(_original, _current);
  bool get groupByVisible => _groupByVisible;

  Set<String> get selectedCategoryIds => _selectedCategoryIds;

  set groupByVisible(bool val) {
    _groupByVisible = val;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _loading = true;
    notifyListeners();
    try {
      _original = await firestore.fetchCategories(franchiseId);
      _current = List.from(_original);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to load categories',
        stack: stack.toString(),
        source: 'CategoryProvider',
        screen: 'onboarding_categories_screen',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> saveCategories() async {
    try {
      await firestore.saveAllCategories(franchiseId, _current);
      _original = List.from(_current);
      notifyListeners();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to save categories',
        stack: stack.toString(),
        source: 'CategoryProvider',
        screen: 'onboarding_categories_screen',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  void addOrUpdateCategory(Category category) {
    final index = _current.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _current[index] = category;
    } else {
      _current.add(category);
    }
    notifyListeners();
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await firestore.deleteCategory(
          franchiseId: franchiseId, categoryId: categoryId);
      await loadCategories(); // ⬅️ Forces Firestore re-fetch, like ingredients
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'category_deletion_failed',
        stack: stack.toString(),
        source: 'CategoryProvider',
        screen: 'onboarding_categories_screen',
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
          'categoryId': categoryId,
        },
      );
      rethrow;
    }
  }

  Future<void> bulkDeleteCategoriesFromFirestore(List<String> ids) async {
    try {
      final batch = firestore.db.batch();
      final colRef = firestore.db
          .collection('franchises')
          .doc(franchiseId)
          .collection('categories');

      for (final id in ids) {
        batch.delete(colRef.doc(id));
      }

      await batch.commit();

      await loadCategories(); // 🔁 reload after deletion
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'bulk_delete_categories_failed',
        stack: stack.toString(),
        source: 'CategoryProvider',
        screen: 'onboarding_categories_screen',
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
          'deletedCount': ids.length,
        },
      );
      rethrow;
    }
  }

  void reorderCategories(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _current.removeAt(oldIndex);
    _current.insert(newIndex, item);
    _applySortOrder();
    notifyListeners();
  }

  void _applySortOrder() {
    for (int i = 0; i < _current.length; i++) {
      _current[i] = _current[i].copyWith(sortOrder: i);
    }
  }

  void toggleSelection(String categoryId) {
    if (_selectedCategoryIds.contains(categoryId)) {
      _selectedCategoryIds.remove(categoryId);
    } else {
      _selectedCategoryIds.add(categoryId);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedCategoryIds.clear();
    notifyListeners();
  }

  void deleteSelected() {
    _current.removeWhere((c) => _selectedCategoryIds.contains(c.id));
    _selectedCategoryIds.clear();
    notifyListeners();
  }

  void revertChanges() {
    _current = List.from(_original);
    _selectedCategoryIds.clear();
    notifyListeners();
  }

  void updateFranchiseId(String newId) {
    if (newId != franchiseId && newId.isNotEmpty) {
      franchiseId = newId;
      loadCategories(); // 🔁 Automatically load categories for the new franchise
    }
  }

  Future<void> bulkImportCategories(List<Category> imported) async {
    _current = List.from(imported);
    _applySortOrder();
    notifyListeners();
  }

  String exportAsJson() {
    final encoded = _current.map((c) => c.toFirestore()).toList();
    return Category.encodeJson(encoded);
  }

  Category? getCategoryById(String id) {
    return _current.firstWhereOrNull((c) => c.id == id);
  }

  Future<void> loadTemplate(String templateId) async {
    try {
      final snapshot = await firestore.db
          .collection('onboarding_templates')
          .doc(templateId)
          .collection('categories')
          .get();

      final imported = snapshot.docs.map((doc) {
        final data = doc.data();
        final id = doc.id;
        return Category.fromFirestore(data, id);
      }).toList();

      _current = imported;
      _applySortOrder();
      notifyListeners();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'category_template_load_failed',
        stack: stack.toString(),
        source: 'CategoryProvider',
        screen: 'onboarding_categories_screen',
        severity: 'error',
        contextData: {
          'templateId': templateId,
          'franchiseId': franchiseId,
        },
      );
      rethrow;
    }
  }
}
