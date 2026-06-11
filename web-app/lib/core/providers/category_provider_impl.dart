// web-app/lib/core/providers/category_provider_impl.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:collection/collection.dart';
import 'package:franchise_admin_portal/core/services/admin_firestore_service.dart';

class CategoryProviderImpl extends ChangeNotifier
    implements shared.CategoryProvider {
  final shared.FirestoreService _firestore;
  final AdminFirestoreService _adminService;
  String _franchiseId;

  List<shared.Category> _original = [];
  List<shared.Category> _current = [];
  final Set<String> _selectedCategoryIds = {};
  bool _loading = true;
  bool _groupByVisible = false;
  bool _hasLoaded = false;
  String? _loadedFranchiseId;
  final List<shared.Category> _stagedCategories = [];

  CategoryProviderImpl({
    required shared.FirestoreService firestore,
    required String franchiseId,
    AdminFirestoreService? adminService,
  })  : _firestore = firestore,
        _adminService = adminService ?? AdminFirestoreService(),
        _franchiseId = franchiseId;

  @override
  List<shared.Category> get categories => List.unmodifiable(_current);

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
  List<shared.Category> get stagedCategories =>
      List.unmodifiable(_stagedCategories);

  @override
  bool get hasStagedCategoryChanges => _stagedCategories.isNotEmpty;

  @override
  Future<void> load({
    bool forceReloadFromFirestore = false,
    String? franchiseIdOverride,
  }) async {
    if (franchiseIdOverride != null && franchiseIdOverride.isNotEmpty) {
      _franchiseId = franchiseIdOverride;
    }

    if (_franchiseId.isEmpty || _franchiseId == 'unknown') return;

    if (_hasLoaded &&
        !forceReloadFromFirestore &&
        _loadedFranchiseId == _franchiseId) {
      return;
    }

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
      // Use admin service stream (first emission gives current data)
      final fetched = await _firestore.getCategories(franchiseId).first;
      _current
        ..clear()
        ..addAll(fetched);
      _original = List.from(fetched);
      _hasLoaded = true;
      _loadedFranchiseId = franchiseId;

      shared.ErrorLogger.log(
        message: '✅ Category reload complete. Count=${fetched.length}',
        source: 'CategoryProviderImpl',
        severity: 'info',
      );
    } catch (e, stack) {
      if (e.toString().contains('UnimplementedError')) {
        _current = [];
        _original = [];
        shared.ErrorLogger.log(
          message: 'Lightweight service fallback in admin context',
          stack: stack.toString(),
          source: 'CategoryProviderImpl',
          severity: 'warning',
        );
      } else {
        shared.ErrorLogger.log(
          message: 'Failed to load categories',
          stack: stack.toString(),
          source: 'CategoryProviderImpl',
          severity: 'error',
        );
        rethrow;
      }
    } finally {
      _loading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  @override
  Future<void> createCategory(shared.Category newCategory) async {
    if (_franchiseId.isEmpty || _franchiseId == 'unknown') return;
    try {
      await _adminService.addCategory(
        franchiseId: _franchiseId,
        category: newCategory,
      );
      addOrUpdateCategory(newCategory);
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to create category',
        stack: stack.toString(),
        source: 'CategoryProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
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
      shared.ErrorLogger.log(
        message: 'Failed to save categories',
        stack: stack.toString(),
        source: 'CategoryProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  void addOrUpdateCategory(shared.Category category) {
    final index = _current.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _current[index] = category;
    } else {
      _current.add(category);
    }
    notifyListeners();
  }

  @override
  void addOrUpdateCategories(List<shared.Category> newCategories) {
    for (final cat in newCategories) {
      addOrUpdateCategory(cat);
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
      shared.ErrorLogger.log(
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
      for (final id in ids) {
        await _firestore.deleteCategory(
            franchiseId: _franchiseId, categoryId: id);
      }
      await reload(_franchiseId, forceReloadFromFirestore: true);
    } catch (e, stack) {
      shared.ErrorLogger.log(
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
  Future<void> bulkImportCategories(List<shared.Category> imported) async {
    _current = List.from(imported);
    _applySortOrder();
    notifyListeners();
  }

  @override
  String exportAsJson() {
    final encoded = _current.map((c) => c.toFirestore()).toList();
    return jsonEncode(encoded);
  }

  @override
  shared.Category? getCategoryById(String id) {
    return _current.firstWhereOrNull((c) => c.id == id);
  }

  @override
  Future<void> loadTemplate(String templateId) async {
    if (_franchiseId.isEmpty || _franchiseId == 'unknown') return;

    print(
        '[CategoryProviderImpl] loadTemplate STARTED - templateId: $templateId, franchiseId: $_franchiseId');

    try {
      await (_firestore as AdminFirestoreService).loadTemplateWithFranchiseId(
        franchiseId: _franchiseId,
        templateId: templateId,
      );

      await reload(_franchiseId, forceReloadFromFirestore: true);
      print('[CategoryProviderImpl] loadTemplate SUCCESS');
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to load category template',
        stack: stack.toString(),
        source: 'CategoryProviderImpl.loadTemplate',
        severity: 'error',
        contextData: {'templateId': templateId, 'franchiseId': _franchiseId},
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
  shared.Category? getByName(String name) {
    return categories.firstWhereOrNull(
        (c) => c.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  @override
  shared.Category? getByIdCaseInsensitive(String id) {
    return categories
        .firstWhereOrNull((c) => c.id.toLowerCase() == id.toLowerCase());
  }

  @override
  void stageCategory(shared.Category category) {
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
      await _firestore.saveAllCategories(_franchiseId, _stagedCategories);
      _original = List.from(_current);
      _stagedCategories.clear();
      notifyListeners();
    } catch (e, stack) {
      shared.ErrorLogger.log(
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
    final newCat =
        shared.Category(id: id, name: name, sortOrder: _current.length);
    stageCategory(newCat);
    return true;
  }

  @override
  Future<List<shared.OnboardingValidationIssue>> validate(
      {List<String>? referencedCategoryIds}) async {
    final issues = <shared.OnboardingValidationIssue>[];
    final names = <String>{};

    for (final cat in _current) {
      if (!names.add(cat.name.trim().toLowerCase())) {
        issues.add(shared.OnboardingValidationIssue(
          section: 'Categories',
          itemId: cat.id,
          itemDisplayName: cat.name,
          severity: shared.OnboardingIssueSeverity.critical,
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
      issues.add(shared.OnboardingValidationIssue(
        section: 'Categories',
        itemId: '',
        itemDisplayName: '',
        severity: shared.OnboardingIssueSeverity.critical,
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
          issues.add(shared.OnboardingValidationIssue(
            section: 'Categories',
            itemId: cat.id,
            itemDisplayName: cat.name,
            severity: shared.OnboardingIssueSeverity.warning,
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
