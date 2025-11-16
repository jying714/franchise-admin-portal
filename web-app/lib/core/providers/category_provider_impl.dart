// web_app/lib/core/providers/category_provider_impl.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';
import 'package:collection/collection.dart';

class CategoryProviderImpl extends ChangeNotifier implements CategoryProvider {
  final FirestoreService _firestore;
  String _franchiseId;

  List<Category> _original = [];
  List<Category> _current = [];
  final Set<String> _selectedCategoryIds = {};
  bool _loading = true;
  bool _groupByVisible = false;
  bool _hasLoaded = false;
  String? _loadedFranchiseId;
  final List<Category> _stagedCategories = [];
  final List<Category> _categories = [];

  CategoryProviderImpl({
    required FirestoreService firestore,
    required String franchiseId,
  })  : _firestore = firestore,
        _franchiseId = franchiseId;

  @override
  List<Category> get categories => List.unmodifiable(_categories);

  @override
  bool get isLoading => _loading;

  @override
  bool get isDirty =>
      !const DeepCollectionEquality().equals(_original, _current);

  @override
  bool get isLoaded => _hasLoaded;

  @override
  bool get groupByVisible => _groupByVisible;

  @override
  set groupByVisible(bool val) {
    if (val != _groupByVisible) {
      _groupByVisible = val;
      notifyListeners();
    }
  }

  @override
  Set<String> get selectedCategoryIds => _selectedCategoryIds;

  @override
  int get stagedCategoryCount => _stagedCategories.length;

  @override
  List<Category> get stagedCategories => List.unmodifiable(_stagedCategories);

  @override
  bool get hasStagedCategoryChanges => _stagedCategories.isNotEmpty;

  @override
  Future<void> load(
      {bool forceReloadFromFirestore = false,
      String? franchiseIdOverride}) async {
    if (franchiseIdOverride != null && franchiseIdOverride.isNotEmpty) {
      _franchiseId = franchiseIdOverride;
    }

    if (_franchiseId.isEmpty || _franchiseId == 'unknown') return;

    if (_hasLoaded &&
        !forceReloadFromFirestore &&
        _loadedFranchiseId == _franchiseId) return;

    await _loadCategories(_franchiseId,
        forceReloadFromFirestore: forceReloadFromFirestore);
  }

  @override
  Future<void> reload(String franchiseId,
      {bool forceReloadFromFirestore = false}) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    if (forceReloadFromFirestore) _hasLoaded = false;
    await _loadCategories(franchiseId,
        forceReloadFromFirestore: forceReloadFromFirestore);
  }

  Future<void> _loadCategories(String franchiseId,
      {bool forceReloadFromFirestore = false}) async {
    _loading = true;
    notifyListeners();

    try {
      final fetched = await _firestore.fetchCategories(franchiseId);
      _categories
        ..clear()
        ..addAll(fetched);
      _original = List.from(fetched);
      _current = List.from(fetched);
      _hasLoaded = true;
      _loadedFranchiseId = franchiseId;
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to load categories',
        stack: stack.toString(),
        source: 'CategoryProviderImpl',
        severity: 'error',
      );
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> createCategory(Category newCategory) async {
    if (_franchiseId.isEmpty || _franchiseId == 'unknown') return;
    try {
      await _firestore.saveCategory(_franchiseId, newCategory);
      addOrUpdateCategory(newCategory);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to create category',
        stack: stack.toString(),
        source: 'CategoryProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  void addOrUpdateCategories(List<Category> newCategories) {
    for (final cat in newCategories) {
      addOrUpdateCategory(cat);
    }
    notifyListeners();
  }

  @override
  List<String> missingCategoryIds(List<String> ids) {
    final currentIds = allCategoryIds.toSet();
    return ids.where((id) => !currentIds.contains(id)).toList();
  }

  @override
  Future<void> saveCategories() async {
    if (_franchiseId.isEmpty || _franchiseId == 'unknown') return;
    try {
      await _firestore.saveAllCategories(_franchiseId, _current);
      _original = List.from(_current);
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to save categories',
        stack: stack.toString(),
        source: 'CategoryProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  void addOrUpdateCategory(Category category) {
    final index = _current.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _current[index] = category;
    } else {
      _current.add(category);
    }
    notifyListeners();
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    if (_franchiseId.isEmpty || _franchiseId == 'unknown') return;
    try {
      await _firestore.deleteCategory(
          franchiseId: _franchiseId, categoryId: categoryId);
      await reload(_franchiseId, forceReloadFromFirestore: true);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to delete category',
        stack: stack.toString(),
        source: 'CategoryProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  Future<void> bulkDeleteCategoriesFromFirestore(List<String> ids) async {
    if (_franchiseId.isEmpty || _franchiseId == 'unknown') return;
    try {
      await _firestore.deleteCategoriesBatch(_franchiseId, ids);
      await reload(_franchiseId, forceReloadFromFirestore: true);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to bulk delete categories',
        stack: stack.toString(),
        source: 'CategoryProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
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

  @override
  void toggleSelection(String categoryId) {
    if (_selectedCategoryIds.contains(categoryId)) {
      _selectedCategoryIds.remove(categoryId);
    } else {
      _selectedCategoryIds.add(categoryId);
    }
    notifyListeners();
  }

  @override
  void clearSelection() {
    _selectedCategoryIds.clear();
    notifyListeners();
  }

  @override
  void deleteSelected() {
    _current.removeWhere((c) => _selectedCategoryIds.contains(c.id));
    _selectedCategoryIds.clear();
    notifyListeners();
  }

  @override
  void revertChanges() {
    _current = List.from(_original);
    _selectedCategoryIds.clear();
    notifyListeners();
  }

  @override
  void updateFranchiseId(String newId) {
    if (newId != _franchiseId && newId.isNotEmpty) {
      _franchiseId = newId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        reload(_franchiseId, forceReloadFromFirestore: true);
      });
    }
  }

  @override
  Future<void> bulkImportCategories(List<Category> imported) async {
    _current = List.from(imported);
    _applySortOrder();
    notifyListeners();
  }

  @override
  String exportAsJson() {
    final encoded = _current.map((c) => c.toFirestore()).toList();
    return Category.encodeJson(encoded);
  }

  @override
  Category? getCategoryById(String id) {
    return _current.firstWhereOrNull((c) => c.id == id);
  }

  @override
  Future<void> loadTemplate(String templateId) async {
    try {
      final snapshot = await _firestore.db
          .collection('onboarding_templates')
          .doc(templateId)
          .collection('categories')
          .get();

      final imported = snapshot.docs
          .map((doc) => Category.fromFirestore(doc.data(), doc.id))
          .toList();
      _current = imported;
      _applySortOrder();
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to load category template',
        stack: stack.toString(),
        source: 'CategoryProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  Map<String, String> get categoryIdToName =>
      Map.fromEntries(categories.map((c) => MapEntry(c.id, c.name)));

  @override
  List<String> get allCategoryIds => categories.map((c) => c.id).toList();

  @override
  List<String> get allCategoryNames => categories.map((c) => c.name).toList();

  @override
  Category? getByName(String name) {
    return categories.firstWhereOrNull(
        (c) => c.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  @override
  Category? getByIdCaseInsensitive(String id) {
    return categories
        .firstWhereOrNull((c) => c.id.toLowerCase() == id.toLowerCase());
  }

  @override
  void stageCategory(Category category) {
    if (_stagedCategories.any((c) => c.id == category.id) ||
        _current.any((c) => c.id == category.id)) return;
    _stagedCategories.add(category);
    _current.add(category);
    notifyListeners();
  }

  @override
  Future<void> saveStagedCategories() async {
    if (_franchiseId.isEmpty || _franchiseId == 'unknown') return;
    if (_stagedCategories.isEmpty) return;

    try {
      await _firestore.saveCategoriesBatch(_franchiseId, _stagedCategories);
      _original = List.from(_current);
      _stagedCategories.clear();
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to save staged categories',
        stack: stack.toString(),
        source: 'CategoryProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  void discardStagedCategories() {
    _current.removeWhere((c) => _stagedCategories.any((s) => s.id == c.id));
    _stagedCategories.clear();
    notifyListeners();
  }

  @override
  bool stageIfNew({required String id, required String name}) {
    if (_current.any((c) => c.id == id) ||
        _stagedCategories.any((c) => c.id == id)) return false;
    final newCat = Category(id: id, name: name, sortOrder: _current.length);
    stageCategory(newCat);
    return true;
  }

  @override
  Future<List<OnboardingValidationIssue>> validate(
      {List<String>? referencedCategoryIds}) async {
    final issues = <OnboardingValidationIssue>[];
    final names = <String>{};

    for (final cat in _current) {
      if (!names.add(cat.name.trim().toLowerCase())) {
        issues.add(OnboardingValidationIssue(
          section: 'Categories',
          itemId: cat.id,
          itemDisplayName: cat.name,
          severity: OnboardingIssueSeverity.critical,
          code: 'DUPLICATE_CATEGORY_NAME',
          message: "Duplicate category name: '${cat.name}'.",
          affectedFields: ['name'],
          isBlocking: true,
          fixRoute: '/onboarding/categories',
          itemLocator: cat.id,
          resolutionHint: "All category names must be unique.",
          actionLabel: "Fix Now",
          icon: Icons.label_important,
          detectedAt: DateTime.now(),
        ));
      }
    }

    if (_current.isEmpty) {
      issues.add(OnboardingValidationIssue(
        section: 'Categories',
        itemId: '',
        itemDisplayName: '',
        severity: OnboardingIssueSeverity.critical,
        code: 'NO_CATEGORIES_DEFINED',
        message: "At least one menu category must be defined.",
        affectedFields: ['categories'],
        isBlocking: true,
        fixRoute: '/onboarding/categories',
        resolutionHint: "Add at least one category.",
        actionLabel: "Add Category",
        icon: Icons.add_box_outlined,
        detectedAt: DateTime.now(),
      ));
    }

    if (referencedCategoryIds != null) {
      for (final cat in _current) {
        if (!referencedCategoryIds.contains(cat.id)) {
          issues.add(OnboardingValidationIssue(
            section: 'Categories',
            itemId: cat.id,
            itemDisplayName: cat.name,
            severity: OnboardingIssueSeverity.warning,
            code: 'UNUSED_CATEGORY',
            message: "Category '${cat.name}' is not used by any menu item.",
            affectedFields: [],
            isBlocking: false,
            fixRoute: '/onboarding/categories',
            itemLocator: cat.id,
            resolutionHint: "Consider removing unused categories.",
            actionLabel: "Review",
            icon: Icons.info_outline,
            detectedAt: DateTime.now(),
          ));
        }
      }
    }

    return issues;
  }
}
