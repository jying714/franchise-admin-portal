// lib/core/providers/category_provider.dart
import 'package:franchise_admin_portal/core/models/onboarding_validation_issue.dart';
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

  // Tracks whether we've completed at least one successful Firestore load.
  bool _hasLoaded = false;
  bool get isLoaded => _hasLoaded;

  CategoryProvider({
    required this.firestore,
    required this.franchiseId,
  });

  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _loading;
  bool get isDirty =>
      !const DeepCollectionEquality().equals(_original, _current);
  bool get groupByVisible => _groupByVisible;

  Set<String> get selectedCategoryIds => _selectedCategoryIds;

  /// Schema issue sidebar
  final List<Category> _stagedCategories = [];
  int get stagedCategoryCount => _stagedCategories.length;

  /// End

  String? _loadedFranchiseId;
  final List<Category> _categories = [];

  set groupByVisible(bool val) {
    _groupByVisible = val;
    notifyListeners();
  }

  Future<void> createCategory(Category newCategory) async {
    final colRef = firestore.db
        .collection('franchises')
        .doc(franchiseId)
        .collection('categories');
    await colRef.doc(newCategory.id).set(newCategory.toFirestore());
    addOrUpdateCategory(newCategory);
  }

  /// Adds or updates multiple new categories (for repair/add-new)
  void addOrUpdateCategories(List<Category> newCategories) {
    for (final cat in newCategories) {
      addOrUpdateCategory(cat);
    }
    notifyListeners();
  }

  /// Returns all category IDs missing from the current provider (for repair UI)
  List<String> missingCategoryIds(List<String> ids) {
    final currentIds = allCategoryIds.toSet();
    return ids.where((id) => !currentIds.contains(id)).toList();
  }

  /// Reload categories from Firestore (useful after mapping or create-new in repair UI)
  Future<void> reload(String franchiseId,
      {bool forceReloadFromFirestore = false}) async {
    print('[CategoryProvider - reLoad] Incoming franchiseId="$franchiseId"');
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[CategoryProvider][RELOAD] ⚠️ Called with blank/unknown franchiseId! Skipping reload.');
      await ErrorLogger.log(
        message:
            'CategoryProvider: reload called with blank/unknown franchiseId',
        stack: '',
        source: 'category_provider.dart',
        screen: 'category_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }

    if (forceReloadFromFirestore) {
      print(
          '[CategoryProvider][RELOAD] 🔄 Forcing reload from Firestore for franchise "$franchiseId"...');
      _hasLoaded = false;
    } else {
      print(
          '[CategoryProvider][RELOAD] ♻️ Reloading categories for franchise "$franchiseId"...');
    }

    await loadCategories(franchiseId,
        forceReloadFromFirestore: forceReloadFromFirestore);
  }

  Future<void> loadCategories(
    String franchiseId, {
    bool forceReloadFromFirestore = false,
  }) async {
    print('[CategoryProvider][LOAD] Incoming franchiseId="$franchiseId"');

    // 🔹 If caller passed blank/unknown, try to use the last loaded franchise ID
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      if (_loadedFranchiseId != null && _loadedFranchiseId!.isNotEmpty) {
        print(
          '[CategoryProvider][LOAD] ℹ️ Using cached franchiseId="$_loadedFranchiseId" since incoming was blank/unknown.',
        );
        franchiseId = _loadedFranchiseId!;
      }
    }

    // 🔹 Still invalid? bail and log
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print('[CategoryProvider][LOAD] ⚠️ No valid franchiseId. Skipping load.');
      await ErrorLogger.log(
        message: 'CategoryProvider: load called with blank/unknown franchiseId',
        stack: '',
        source: 'category_provider.dart',
        screen: 'category_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }

    // 🔹 Skip if already loaded for this franchise and no force reload
    if (_hasLoaded &&
        _loadedFranchiseId == franchiseId &&
        !forceReloadFromFirestore) {
      print(
        '[CategoryProvider][LOAD] ✅ Already loaded for "$franchiseId". Skipping fetch.',
      );
      return;
    }

    try {
      print(
        '[CategoryProvider][LOAD] 📡 Fetching categories for franchise "$franchiseId"...',
      );
      final fetched = await firestore.fetchCategories(franchiseId);

      print('[CategoryProvider][LOAD] ✅ Fetched ${fetched.length} categories.');
      for (final category in fetched) {
        print('    • id="${category.id}", name="${category.name}"');
      }

      _categories
        ..clear()
        ..addAll(fetched);

      _hasLoaded = true;
      _loadedFranchiseId = franchiseId;

      notifyListeners();
    } catch (e, stack) {
      print('[CategoryProvider][LOAD][ERROR] ❌ Failed to load categories: $e');
      await ErrorLogger.log(
        message: 'category_load_error',
        stack: stack.toString(),
        source: 'category_provider.dart',
        screen: 'category_provider.dart',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  /// Uniform loader used by the review screen.
  /// If [forceReloadFromFirestore] is false and data is warm, this is a no-op.
  Future<void> load(
      {bool forceReloadFromFirestore = false,
      String? franchiseIdOverride}) async {
    if (franchiseIdOverride != null &&
        franchiseIdOverride.isNotEmpty &&
        franchiseIdOverride != franchiseId) {
      franchiseId = franchiseIdOverride;
    }
    print('[CategoryProvider - load] Incoming franchiseId="$franchiseId"');
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      debugPrint(
          '[CategoryProvider][load] ⚠️ Skipping load: empty/unknown franchiseId.');
      return;
    }

    if (_hasLoaded && !forceReloadFromFirestore) {
      debugPrint(
          '[CategoryProvider][load] 🔁 Using warm cache (categories=${_current.length}).');
      return;
    }

    await loadCategories(franchiseId,
        forceReloadFromFirestore: forceReloadFromFirestore);
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
      await loadCategories(franchiseId,
          forceReloadFromFirestore:
              true); // ⬅️ Forces Firestore re-fetch, like ingredients
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

      await loadCategories(franchiseId, forceReloadFromFirestore: true);
      // 🔁 reload after deletion
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
      // Defer to next frame to avoid build cycle errors
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadCategories(franchiseId, forceReloadFromFirestore: true);
      });
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

  /// Returns a map of all category IDs to names.
  Map<String, String> get categoryIdToName =>
      Map.fromEntries(categories.map((c) => MapEntry(c.id, c.name)));

  /// Returns a list of all available category IDs.
  List<String> get allCategoryIds => categories.map((c) => c.id).toList();

  /// Returns a list of all available category names.
  List<String> get allCategoryNames => categories.map((c) => c.name).toList();

  /// Find a category by name (case-insensitive, trimmed).
  Category? getByName(String name) {
    return categories.firstWhereOrNull(
        (c) => c.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  /// Find a category by ID (case-insensitive).
  Category? getByIdCaseInsensitive(String id) {
    return categories
        .firstWhereOrNull((c) => c.id.toLowerCase() == id.toLowerCase());
  }

  /// schema issue sidebar methods to add, discard and stage categories
  void stageCategory(Category category) {
    final alreadyStaged = _stagedCategories.any((c) => c.id == category.id);
    final alreadyInCurrent = _current.any((c) => c.id == category.id);

    debugPrint('[CategoryProvider] stageCategory called: '
        'id=${category.id}, name=${category.name}, '
        'alreadyStaged=$alreadyStaged, alreadyInCurrent=$alreadyInCurrent');

    if (alreadyStaged || alreadyInCurrent) {
      debugPrint('[CategoryProvider] Not staging: already exists.');
      return;
    }

    _stagedCategories.add(category);
    _current.add(category);

    debugPrint('[CategoryProvider] Staged new category: '
        'id=${category.id}, name=${category.name}. '
        'StagedCategories=${_stagedCategories.length}, Current=${_current.length}');
    notifyListeners();
  }

  Future<void> saveStagedCategories() async {
    try {
      final colRef = firestore.db
          .collection('franchises')
          .doc(franchiseId)
          .collection('categories');

      final batch = firestore.db.batch();

      for (final category in _stagedCategories) {
        batch.set(colRef.doc(category.id), category.toFirestore());
      }
      print(
          '[CategoryProvider] Persisting ${_stagedCategories.length} categories');

      await batch.commit();
      _original = List.from(_current);
      _stagedCategories.clear();
      notifyListeners();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'category_stage_save_failed',
        stack: stack.toString(),
        source: 'CategoryProvider',
        screen: 'onboarding_categories_screen',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  void discardStagedCategories() {
    for (final cat in _stagedCategories) {
      _current.removeWhere((c) => c.id == cat.id);
    }
    _stagedCategories.clear();
    print('[ProviderName] Discarded staged items: '
        'count=${_stagedCategories.length} before clearing');

    notifyListeners();
  }

  bool get hasStagedCategoryChanges => _stagedCategories.isNotEmpty;
  List<Category> get stagedCategories => List.unmodifiable(_stagedCategories);

  /// Attempts to stage a new category if it doesn't already exist in Firestore or staged memory.
  /// Returns true if the category was staged, false if it already exists.
  bool stageIfNew({required String id, required String name}) {
    final alreadyExists = _current.any((c) => c.id == id) ||
        _stagedCategories.any((c) => c.id == id);

    if (!alreadyExists) {
      final newCat = Category(
        id: id,
        name: name,
        sortOrder: _current.length,
      );
      stageCategory(newCat);
      debugPrint('[CategoryProvider] stageIfNew -> Staged new category: '
          'id=${newCat.id}, name=${newCat.name}');
      return true;
    }

    debugPrint('[CategoryProvider] Category already exists: $id');
    return false;
  }

  Future<List<OnboardingValidationIssue>> validate({
    List<String>? referencedCategoryIds, // For checking unused/in-use
  }) async {
    final issues = <OnboardingValidationIssue>[];
    try {
      final categoryNames = <String>{};
      for (final cat in _current) {
        // Uniqueness
        if (!categoryNames.add(cat.name.trim().toLowerCase())) {
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
            contextData: {
              'category': cat.toFirestore(),
            },
          ));
        }
      }
      // Required: at least one category
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

      // (Optional) Unused category warning
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
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'category_validate_failed',
        stack: stack.toString(),
        source: 'CategoryProvider.validate',
        severity: 'error',
        contextData: {},
      );
    }
    return issues;
  }
}
