import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../services/firestore_service_BACKUP.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';
import '../models/menu_template_ref.dart';
import '../models/size_template.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'franchise_info_provider.dart';
import 'package:collection/collection.dart';
import 'category_provider.dart';
import 'ingredient_metadata_provider.dart';
import 'ingredient_type_provider.dart';
import 'package:provider/provider.dart';
import '../models/onboarding_validation_issue.dart';

class MenuItemProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  List<MenuTemplateRef> _templateRefs = [];
  bool _templateRefsLoading = false;
  String? _templateRefsError;
  FranchiseInfoProvider _franchiseInfoProvider;

  late IngredientMetadataProvider _ingredientProvider;
  late CategoryProvider _categoryProvider;
  late IngredientTypeProvider _typeProvider;

  // 🔢 Size Templates
  List<SizeTemplate> _sizeTemplates = [];
  String? _selectedSizeTemplateId;

  List<SizeTemplate> get sizeTemplates => _sizeTemplates;
  String? get selectedSizeTemplateId => _selectedSizeTemplateId;

  set franchiseInfoProvider(FranchiseInfoProvider value) {
    final oldType = _franchiseInfoProvider.franchise?.restaurantType;
    final newType = value.franchise?.restaurantType;
    _franchiseInfoProvider = value;
    if (newType != null && newType.isNotEmpty && newType != oldType) {
      loadTemplateRefs();
    }
  }

  void injectDependencies({
    required IngredientMetadataProvider ingredientProvider,
    required CategoryProvider categoryProvider,
    required IngredientTypeProvider typeProvider,
  }) {
    _ingredientProvider = ingredientProvider;
    _categoryProvider = categoryProvider;
    _typeProvider = typeProvider;
  }

  void setSelectedSizeTemplateId(String? id) {
    _selectedSizeTemplateId = id;
    notifyListeners();
  }

  Future<void> loadSizeTemplates(String restaurantType) async {
    try {
      _sizeTemplates =
          await _firestoreService.getSizeTemplatesForTemplate(restaurantType);
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to load size templates',
        source: 'MenuItemProvider',
        severity: 'error',
        stack: stack.toString(),
      );
    }
  }

  List<MenuItem> _original = [];
  List<MenuItem> _working = [];

  bool _isLoading = false;
  String? _franchiseId;

  // Tracks whether we've completed at least one successful Firestore load.
  bool _hasLoaded = false;
  String? _loadedFranchiseId;

  bool get isLoaded => _hasLoaded;

  List<MenuTemplateRef> get templateRefs => _templateRefs;
  bool get templateRefsLoading => _templateRefsLoading;
  String? get templateRefsError => _templateRefsError;

  MenuItemProvider({
    required FirestoreService firestoreService,
    required FranchiseInfoProvider franchiseInfoProvider,
  })  : _firestoreService = firestoreService,
        _franchiseInfoProvider = franchiseInfoProvider;

  List<MenuItem> get menuItems => _working;
  bool get isLoading => _isLoading;

  bool get isDirty {
    if (_original.length != _working.length) return true;
    for (int i = 0; i < _original.length; i++) {
      if (_original[i].toMap().toString() != _working[i].toMap().toString()) {
        return true;
      }
    }
    return false;
  }

  /// Uniform loader used by the review screen.
  /// - Provide [franchiseIdOverride] if this provider hasn't been told its franchise yet.
  /// - If [forceReloadFromFirestore] is false and data is warm, this is a no-op.
  Future<void> load(
      {bool forceReloadFromFirestore = false,
      String? franchiseIdOverride}) async {
    if (franchiseIdOverride != null && franchiseIdOverride.isNotEmpty) {
      _franchiseId = franchiseIdOverride;
    }

    final id = _franchiseId;
    if (id == null || id.isEmpty || id == 'unknown') {
      debugPrint(
          '[MenuItemProvider][load] ⚠️ Skipping load: missing/unknown franchiseId.');
      return;
    }

    if (_hasLoaded && !forceReloadFromFirestore) {
      debugPrint(
          '[MenuItemProvider][load] 🔁 Using warm cache (items=${_working.length}).');
      return;
    }

    debugPrint(
        '[MenuItemProvider][load] 📡 Fetching menu items for franchise "$id"...');
    await loadMenuItems(id); // ← uses your existing method
    _hasLoaded = true;
    debugPrint('[MenuItemProvider][load] ✅ Loaded (items=${_working.length}).');
  }

  Future<void> reload(String franchiseId,
      {bool forceReloadFromFirestore = false}) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[MenuItemProvider][RELOAD] ⚠️ Called with blank/unknown franchiseId! Skipping reload.');
      ErrorLogger.log(
        message:
            'MenuItemProvider: reload called with blank/unknown franchiseId',
        stack: '',
        source: 'menu_item_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }

    if (forceReloadFromFirestore) {
      print(
          '[MenuItemProvider][RELOAD] 🔄 Forcing reload from Firestore for franchise "$franchiseId"...');
      _hasLoaded = false;
    } else {
      print(
          '[MenuItemProvider][RELOAD] ♻️ Reloading menu items for franchise "$franchiseId"...');
    }

    await loadMenuItems(franchiseId,
        forceReloadFromFirestore: forceReloadFromFirestore);
  }

  Future<void> loadMenuItems(
    String franchiseId, {
    bool forceReloadFromFirestore = false,
  }) async {
    print(
        '\n[MenuItemProvider][LOAD] 🚀 Starting menu item load for franchiseId="$franchiseId"');
    print(
        '   ➤ _loadedFranchiseId = "${_loadedFranchiseId ?? 'null'}", _hasLoaded = $_hasLoaded');
    print('   ➤ forceReloadFromFirestore = $forceReloadFromFirestore');

    // Defensive: Block blank/unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[MenuItemProvider][LOAD] ⚠️ Called with blank/unknown franchiseId! Skipping load.');
      ErrorLogger.log(
        message: 'MenuItemProvider: load called with blank/unknown franchiseId',
        stack: '',
        source: 'menu_item_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }

    // Skip reload if already loaded for same franchise (unless forced)
    if (!forceReloadFromFirestore &&
        _hasLoaded &&
        _loadedFranchiseId == franchiseId) {
      print(
          '[MenuItemProvider][LOAD] ⏩ Already loaded for this franchise. Skipping fetch.');
      return;
    }

    try {
      print(
          '[MenuItemProvider][LOAD] 📡 Fetching menu items from Firestore...');
      final fetched = await _firestoreService.fetchMenuItems(franchiseId);

      print('[MenuItemProvider][LOAD] ✅ Fetched ${fetched.length} menu items.');
      for (final item in fetched) {
        print('    • id="${item.id}", name="${item.name}"');
      }

      // Replace in-memory collections
      _working
        ..clear()
        ..addAll(fetched);

      _original = _working.map((e) => e.copyWith()).toList();

      _hasLoaded = true;
      _loadedFranchiseId = franchiseId;

      notifyListeners();
      print('[MenuItemProvider][LOAD] 🎯 Load complete. UI notified.');
    } catch (e, stack) {
      print('[MenuItemProvider][LOAD][ERROR] ❌ Failed to load menu items: $e');
      ErrorLogger.log(
        message: 'menu_item_load_error',
        stack: stack.toString(),
        source: 'menu_item_provider.dart',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }

    print('[MenuItemProvider][LOAD] 🏁 Finished.\n');
  }

  void addOrUpdateMenuItem(MenuItem item) {
    print('[DEBUG] addOrUpdateMenuItem called with id=${item.id}');
    final index = _working.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      _working.add(item);
    } else {
      _working[index] = item;
    }
    notifyListeners(); // ✅ Needed for UI to react to dirty state
  }

  void deleteMenuItem(String id) {
    _working.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<void> persistChanges() async {
    print('[DEBUG] persistChanges called');
    if (_franchiseId == null || !isDirty) {
      print(
          '[DEBUG] Aborting persistChanges: isDirty=$isDirty, franchiseId=$_franchiseId');
      return;
    }

    if (_ingredientProvider == null ||
        _categoryProvider == null ||
        _typeProvider == null) {
      throw StateError('Dependencies not injected into MenuItemProvider.');
    }

    try {
      // --- 1. Save staged ingredient types FIRST ---
      if (_typeProvider.hasStagedTypeChanges) {
        try {
          print('[DEBUG] Saving staged ingredient types...');
          print('[DEBUG] Staged Ingredient Types to save: '
              '${_typeProvider.stagedTypes.map((t) => t.id).toList()}');
          await _typeProvider.saveStagedIngredientTypes();
          print('[DEBUG] Staged ingredient types saved');
        } catch (e, stack) {
          ErrorLogger.log(
            message: 'Failed to save staged ingredient types',
            source: 'MenuItemProvider',
            severity: 'error',
            stack: stack.toString(),
            contextData: {'franchiseId': _franchiseId},
          );
          rethrow; // 🚨 BLOCK SAVE if fail!
        }
      }

      // --- 2. Save staged ingredients SECOND ---
      if (_ingredientProvider.hasStagedChanges) {
        try {
          print('[DEBUG] Saving staged ingredients...');
          print('[DEBUG] Staged Ingredients to save: '
              '${_ingredientProvider.stagedIngredients.map((e) => e.id).toList()}');
          await _ingredientProvider.saveStagedIngredients();
          print('[DEBUG] Staged ingredients saved');
        } catch (e, stack) {
          ErrorLogger.log(
            message: 'Failed to save staged ingredients',
            source: 'MenuItemProvider',
            severity: 'error',
            stack: stack.toString(),
            contextData: {'franchiseId': _franchiseId},
          );
          rethrow; // 🚨 BLOCK SAVE if fail!
        }
      }

      // --- 3. Save staged categories THIRD ---
      if (_categoryProvider.hasStagedCategoryChanges) {
        try {
          print('[DEBUG] Saving staged categories...');
          print('[DEBUG] Staged Categories to save: '
              '${_categoryProvider.stagedCategories.map((c) => c.id).toList()}');
          await _categoryProvider.saveStagedCategories();
          print('[DEBUG] Staged categories saved');
        } catch (e, stack) {
          ErrorLogger.log(
            message: 'Failed to save staged categories',
            source: 'MenuItemProvider',
            severity: 'error',
            stack: stack.toString(),
            contextData: {'franchiseId': _franchiseId},
          );
          rethrow; // 🚨 BLOCK SAVE if fail!
        }
      }

      // --- 4. Save menu items LAST ---
      print('[DEBUG] Saving ${_working.length} menu items...');
      await _firestoreService.saveMenuItems(_franchiseId!, _working);
      print('[DEBUG] Menu items saved');

      // --- 5. Clear staged memory (regardless of error) ---
      _ingredientProvider.discardStagedIngredients();
      _categoryProvider.discardStagedCategories();
      _typeProvider.discardStagedIngredientTypes();
      print('[DEBUG] All staged data discarded');

      // --- 6. Mark menu items clean ---
      _original = _working.map((e) => e.copyWith()).toList();
      notifyListeners();
      print('[DEBUG] Save complete, isDirty=$isDirty');
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to persist menu item changes',
        source: 'MenuItemProvider',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': _franchiseId},
      );
      rethrow;
    }
  }

  void revertChanges() {
    _working = _original.map((e) => e.copyWith()).toList();
    notifyListeners();
  }

  Future<void> reorderMenuItems(List<MenuItem> reordered) async {
    if (_franchiseId == null) return;

    try {
      await _firestoreService.reorderMenuItems(_franchiseId!, reordered);
      _working = reordered;
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to reorder menu items',
        source: 'MenuItemProvider',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': _franchiseId},
      );
    }
  }

  Future<void> loadTemplateRefs() async {
    _templateRefsLoading = true;
    _templateRefsError = null;
    notifyListeners();

    try {
      final franchise = _franchiseInfoProvider.franchise;
      if (franchise == null ||
          franchise.restaurantType == null ||
          franchise.restaurantType!.isEmpty) {
        throw Exception('Missing restaurant type during template load');
      }

      _templateRefs = await _firestoreService.fetchMenuTemplateRefs(
        restaurantType: franchise.restaurantType!,
      );
    } catch (e, stack) {
      _templateRefsError = e.toString();
      ErrorLogger.log(
        message: 'Failed to load menu template refs',
        source: 'MenuItemProvider',
        severity: 'error',
        stack: stack.toString(),
      );
    } finally {
      _templateRefsLoading = false;
      notifyListeners();
    }
  }

  Future<MenuItem?> fetchMenuItemTemplateById({
    required String restaurantType,
    required String templateId,
  }) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('onboarding_templates')
          .doc(restaurantType)
          .collection('menu_items')
          .doc(templateId)
          .get();

      if (!docSnapshot.exists) {
        ErrorLogger.log(
          message: 'Menu item template not found',
          source: 'MenuItemProvider.fetchMenuItemTemplateById',
          severity: 'warning',
          contextData: {
            'restaurantType': restaurantType,
            'templateId': templateId,
          },
        );
        return null;
      }

      final data = docSnapshot.data();
      if (data == null) {
        ErrorLogger.log(
          message: 'Empty menu item template document',
          source: 'MenuItemProvider.fetchMenuItemTemplateById',
          severity: 'error',
          contextData: {
            'restaurantType': restaurantType,
            'templateId': templateId,
          },
        );
        return null;
      }

      try {
        return MenuItem.fromFirestore(data, docSnapshot.id);
      } catch (e, stack) {
        ErrorLogger.log(
          message: 'MenuItem.fromFirestore threw during template fetch',
          stack: stack.toString(),
          source: 'MenuItemProvider.fetchMenuItemTemplateById',
          severity: 'error',
          contextData: {
            'restaurantType': restaurantType,
            'templateId': templateId,
            'rawData': data.map((k, v) => MapEntry(k, _safeStringify(v))),
            'error': e.toString(),
            'env': kReleaseMode ? 'production' : 'development',
          },
        );
        return null;
      }
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Unhandled exception during menu item template fetch',
        stack: stack.toString(),
        source: 'MenuItemProvider.fetchMenuItemTemplateById',
        severity: 'error',
        contextData: {
          'restaurantType': restaurantType,
          'templateId': templateId,
          'error': e.toString(),
        },
      );
      return null;
    }
  }

  MenuItem applyTemplateToNewItem(MenuItem template) {
    return template.copyWith(
      id: '',
      templateRefs: [template.id],
      archived: false,
      available: true,
      sortOrder: _working.length,
    );
  }

  /// Returns a list of missing required fields for a given MenuItem (used by onboarding/repair UI)
  List<String> getMissingRequiredFields(MenuItem item) {
    final missing = <String>[];
    if (item.name.isEmpty) missing.add('name');
    if (item.description.isEmpty) missing.add('description');
    if (item.categoryId.isEmpty) missing.add('categoryId');
    if (item.category.isEmpty) missing.add('category');
    if (item.price == 0.0 &&
        (item.sizePrices == null || item.sizePrices!.isEmpty))
      missing.add('price');
    if (item.includedIngredients == null || item.includedIngredients!.isEmpty)
      missing.add('includedIngredients');
    if (item.customizationGroups == null || item.customizationGroups!.isEmpty)
      missing.add('customizationGroups');
    if (item.sizes != null &&
        item.sizes!.isNotEmpty &&
        (item.sizePrices == null || item.sizePrices!.isEmpty))
      missing.add('sizePrices');
    // Add more as your onboarding requires
    return missing;
  }

  Future<MenuItem> repairMenuItemReferences(MenuItem item,
      {required Map<String, String> ingredientIdMap,
      required Map<String, String> categoryIdMap}) async {
    // Implement logic to map/repair all invalid IDs based on mappings from UI
    // Return the fixed MenuItem
    // (Useful for bulk import/fixes, not required for single-item UI)
    return item;
  }

  void updateWorkingMenuItem(MenuItem item) {
    final idx = _working.indexWhere((m) => m.id == item.id);
    if (idx != -1) {
      _working[idx] = item;
      notifyListeners();
    }
  }

  String _safeStringify(dynamic v) {
    if (v is Timestamp) return v.toDate().toIso8601String();
    if (v is Map)
      return v.map((k, val) => MapEntry(k, _safeStringify(val))).toString();
    if (v is List) return v.map(_safeStringify).toList().toString();
    return v.toString();
  }

  /// Returns all menu item IDs for mapping/repair UI.
  List<String> get allMenuItemIds => menuItems.map((m) => m.id).toList();

  /// Find a menu item by name (case-insensitive, trimmed).
  MenuItem? getByName(String name) {
    return menuItems.firstWhereOrNull(
        (m) => m.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  /// Find a menu item by ID (case-insensitive).
  MenuItem? getByIdCaseInsensitive(String id) {
    return menuItems
        .firstWhereOrNull((m) => m.id.toLowerCase() == id.toLowerCase());
  }

  Future<void> logRepairAction({
    required String menuItemId,
    required String field,
    required String oldValue,
    required String newValue,
    required String user,
  }) async {
    ErrorLogger.log(
      message: 'MenuItem repair',
      source: 'MenuItemProvider',
      severity: 'info',
      contextData: {
        'menuItemId': menuItemId,
        'field': field,
        'oldValue': oldValue,
        'newValue': newValue,
        'user': user,
      },
    );
  }

  Future<void> refreshAllProviders({
    required CategoryProvider categoryProvider,
    required IngredientMetadataProvider ingredientProvider,
    required IngredientTypeProvider ingredientTypeProvider,
    String? franchiseId,
  }) async {
    final fid =
        franchiseId ?? _franchiseId ?? _franchiseInfoProvider.franchise?.id;
    if (fid == null || fid.isEmpty) return;

    await Future.wait([
      _franchiseInfoProvider.reload(),
      categoryProvider.reload(fid),
      ingredientProvider.reload(),
      ingredientTypeProvider.reload(fid),
    ]);
    notifyListeners();
  }

  /// Returns all unique category IDs referenced by current menu items.
  List<String> get allReferencedCategoryIds {
    final ids = <String>{};
    for (final item in menuItems) {
      ids.add(item.categoryId);
    }
    return ids.toList();
  }

  /// Returns all unique ingredient IDs referenced by all menu items.
  List<String> get allReferencedIngredientIds {
    final ids = <String>{};
    for (final item in menuItems) {
      ids.addAll(item.allReferencedIngredientIds);
    }
    return ids.toList();
  }

  /// Returns all unique ingredient type IDs referenced by all menu items.
  List<String> get allReferencedIngredientTypeIds {
    final ids = <String>{};
    for (final item in menuItems) {
      ids.addAll(item.allReferencedIngredientTypeIds);
    }
    return ids.toList();
  }

  Future<void> deleteFromFirestore(String id) async {
    if (_franchiseId == null) return;

    try {
      await _firestoreService.deleteMenuItem(_franchiseId!, id);
      deleteMenuItem(id);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to delete menu item from Firestore',
        source: 'MenuItemProvider',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': _franchiseId, 'menuItemId': id},
      );
    }
  }

  Future<List<OnboardingValidationIssue>> validate({
    required List<String> validCategoryIds,
    required List<String> validIngredientIds,
    required List<String> validTypeIds,
  }) async {
    final issues = <OnboardingValidationIssue>[];
    try {
      final menuItemNames = <String>{};
      for (final item in _working) {
        // Name uniqueness
        if (!menuItemNames.add(item.name.trim().toLowerCase())) {
          issues.add(OnboardingValidationIssue(
            section: 'Menu Items',
            itemId: item.id,
            itemDisplayName: item.name,
            severity: OnboardingIssueSeverity.critical,
            code: 'DUPLICATE_MENU_ITEM_NAME',
            message: "Duplicate menu item name: '${item.name}'.",
            affectedFields: ['name'],
            isBlocking: true,
            fixRoute: '/onboarding/menu_items',
            itemLocator: item.id,
            resolutionHint: "Menu item names must be unique.",
            actionLabel: "Fix Now",
            icon: Icons.label_important,
            detectedAt: DateTime.now(),
            contextData: {
              'menu_item': item.toMap(),
            },
          ));
        }
        // Category reference valid
        if (!validCategoryIds.contains(item.categoryId)) {
          issues.add(OnboardingValidationIssue(
            section: 'Menu Items',
            itemId: item.id,
            itemDisplayName: item.name,
            severity: OnboardingIssueSeverity.critical,
            code: 'INVALID_CATEGORY_REFERENCE',
            message:
                "Menu item '${item.name}' references a missing or invalid category.",
            affectedFields: ['categoryId'],
            isBlocking: true,
            fixRoute: '/onboarding/menu_items',
            itemLocator: item.id,
            resolutionHint: "Assign a valid category.",
            actionLabel: "Fix Now",
            icon: Icons.link_off,
            detectedAt: DateTime.now(),
          ));
        }
        // Ingredient references valid
        for (final includedIng in item.includedIngredients ?? []) {
          if (!validIngredientIds.contains(includedIng.ingredientId)) {
            issues.add(OnboardingValidationIssue(
              section: 'Menu Items',
              itemId: item.id,
              itemDisplayName: item.name,
              severity: OnboardingIssueSeverity.critical,
              code: 'INVALID_INGREDIENT_REFERENCE',
              message:
                  "Menu item '${item.name}' references a missing ingredient.",
              affectedFields: ['includedIngredients'],
              isBlocking: true,
              fixRoute: '/onboarding/menu_items',
              itemLocator: item.id,
              resolutionHint: "Replace or remove invalid ingredient reference.",
              actionLabel: "Fix Now",
              icon: Icons.link_off,
              detectedAt: DateTime.now(),
              contextData: {
                'missingIngredientId': includedIng.ingredientId,
              },
            ));
          }
          // Optional: Check included ingredient's type is valid
          if (includedIng.typeId != null &&
              !validTypeIds.contains(includedIng.typeId)) {
            issues.add(OnboardingValidationIssue(
              section: 'Menu Items',
              itemId: item.id,
              itemDisplayName: item.name,
              severity: OnboardingIssueSeverity.critical,
              code: 'INVALID_TYPE_REFERENCE',
              message:
                  "Menu item '${item.name}' includes an ingredient with an invalid type.",
              affectedFields: ['includedIngredients.typeId'],
              isBlocking: true,
              fixRoute: '/onboarding/menu_items',
              itemLocator: item.id,
              resolutionHint: "Assign a valid type.",
              actionLabel: "Fix Now",
              icon: Icons.link_off,
              detectedAt: DateTime.now(),
              contextData: {
                'includedIngredient': includedIng.toMap(),
              },
            ));
          }
        }
        // Required fields check (e.g., price, sizePrices, etc)
        // Check for each menu item required field as per your schema
        if (item.price == null) {
          issues.add(OnboardingValidationIssue(
            section: 'Menu Items',
            itemId: item.id,
            itemDisplayName: item.name,
            severity: OnboardingIssueSeverity.critical,
            code: 'MISSING_REQUIRED_FIELD',
            message:
                "Menu item '${item.name}' is missing required field: price.",
            affectedFields: ['price'],
            isBlocking: true,
            fixRoute: '/onboarding/menu_items',
            itemLocator: item.id,
            resolutionHint: "Enter a valid price.",
            actionLabel: "Fix Now",
            icon: Icons.price_change,
            detectedAt: DateTime.now(),
          ));
        }
        // ... Repeat for other schema-required fields (sizePrices, available, image, etc)
      }
      if (_working.isEmpty) {
        issues.add(OnboardingValidationIssue(
          section: 'Menu Items',
          itemId: '',
          itemDisplayName: '',
          severity: OnboardingIssueSeverity.critical,
          code: 'NO_MENU_ITEMS_DEFINED',
          message: "At least one menu item must be defined.",
          affectedFields: ['menu_items'],
          isBlocking: true,
          fixRoute: '/onboarding/menu_items',
          resolutionHint: "Add at least one menu item.",
          actionLabel: "Add Item",
          icon: Icons.add_box_outlined,
          detectedAt: DateTime.now(),
        ));
      }
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'menu_item_validate_failed',
        stack: stack.toString(),
        source: 'MenuItemProvider.validate',
        severity: 'error',
        contextData: {},
      );
    }
    return issues;
  }
}
