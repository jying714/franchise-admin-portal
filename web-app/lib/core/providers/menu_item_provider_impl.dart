// web-app/lib/core/providers/menu_item_provider_impl.dart

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:collection/collection.dart';

class MenuItemProviderImpl extends ChangeNotifier
    implements shared.MenuItemProvider {
  final shared.FirestoreService _firestoreService;
  final shared.FranchiseInfoProvider _franchiseInfoProvider;

  late shared.IngredientMetadataProvider _ingredientProvider;
  late shared.CategoryProvider _categoryProvider;
  late shared.IngredientTypeProvider _typeProvider;

  List<shared.MenuTemplateRef> _templateRefs = [];
  bool _templateRefsLoading = false;
  String? _templateRefsError;

  List<shared.SizeTemplate> _sizeTemplates = [];
  String? _selectedSizeTemplateId;

  List<shared.MenuItem> _original = [];
  List<shared.MenuItem> _working = [];

  bool _isLoading = false;
  String? _franchiseId;
  bool _hasLoaded = false;
  String? _loadedFranchiseId;

  MenuItemProviderImpl({
    required shared.FirestoreService firestoreService,
    required shared.FranchiseInfoProvider franchiseInfoProvider,
  })  : _firestoreService = firestoreService,
        _franchiseInfoProvider = franchiseInfoProvider;

  @override
  List<shared.MenuItem> get menuItems => _working;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isDirty {
    if (_original.length != _working.length) return true;
    return !_original.every((o) => _working.any(
        (w) => w.id == o.id && w.toMap().toString() == o.toMap().toString()));
  }

  @override
  bool get isLoaded => _hasLoaded;

  @override
  List<shared.MenuTemplateRef> get templateRefs => _templateRefs;

  @override
  bool get templateRefsLoading => _templateRefsLoading;

  @override
  String? get templateRefsError => _templateRefsError;

  @override
  List<shared.SizeTemplate> get sizeTemplates => _sizeTemplates;

  @override
  String? get selectedSizeTemplateId => _selectedSizeTemplateId;

  @override
  void setSelectedSizeTemplateId(String? id) {
    _selectedSizeTemplateId = id;
    notifyListeners();
  }

  @override
  Future<void> load({
    bool forceReloadFromFirestore = false,
    String? franchiseIdOverride,
  }) async {
    if (franchiseIdOverride != null && franchiseIdOverride.isNotEmpty) {
      _franchiseId = franchiseIdOverride;
    }

    final id = _franchiseId;
    if (id == null || id.isEmpty || id == 'unknown') return;

    if (_hasLoaded && !forceReloadFromFirestore && _loadedFranchiseId == id) {
      return;
    }

    await _loadMenuItems(id,
        forceReloadFromFirestore: forceReloadFromFirestore);
    _hasLoaded = true;
    _loadedFranchiseId = id;
  }

  @override
  Future<void> reload(String franchiseId,
      {bool forceReloadFromFirestore = false}) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    if (forceReloadFromFirestore) _hasLoaded = false;
    await _loadMenuItems(franchiseId,
        forceReloadFromFirestore: forceReloadFromFirestore);
  }

  Future<void> _loadMenuItems(String franchiseId,
      {bool forceReloadFromFirestore = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetched = await _firestoreService.getMenuItemsOnce(franchiseId);
      _working = List.from(fetched);
      _original = fetched.map((e) => e.copyWith()).toList();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to load menu items',
        stack: stack.toString(),
        source: 'MenuItemProviderImpl',
        severity: 'error',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void addOrUpdateMenuItem(shared.MenuItem item) {
    final index = _working.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      _working.add(item);
    } else {
      _working[index] = item;
    }
    notifyListeners();
  }

  @override
  void deleteMenuItem(String id) {
    _working.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  @override
  Future<void> persistChanges() async {
    if (_franchiseId == null || !isDirty) return;

    try {
      if (_typeProvider.hasStagedTypeChanges) {
        await _typeProvider.saveStagedIngredientTypes();
      }
      if (_ingredientProvider.hasStagedChanges) {
        await _ingredientProvider.saveStagedIngredients();
      }
      if (_categoryProvider.hasStagedCategoryChanges) {
        await _categoryProvider.saveStagedCategories();
      }

      await _firestoreService.saveMenuItems(_franchiseId!, _working);
      _original = _working.map((e) => e.copyWith()).toList();
      notifyListeners();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to persist menu item changes',
        stack: stack.toString(),
        source: 'MenuItemProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  void revertChanges() {
    _working = _original.map((e) => e.copyWith()).toList();
    notifyListeners();
  }

  @override
  Future<void> reorderMenuItems(List<shared.MenuItem> reordered) async {
    if (_franchiseId == null) return;
    try {
      await _firestoreService.reorderMenuItems(_franchiseId!, reordered);
      _working = List.from(reordered);
      notifyListeners();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to reorder menu items',
        stack: stack.toString(),
        source: 'MenuItemProviderImpl',
        severity: 'error',
      );
    }
  }

  @override
  Future<void> loadTemplateRefs() async {
    _templateRefsLoading = true;
    notifyListeners();

    try {
      final franchise = _franchiseInfoProvider.franchise;
      if (franchise?.restaurantType == null) {
        throw Exception('Missing restaurant type');
      }
      _templateRefs = await _firestoreService.fetchMenuTemplateRefs(
          restaurantType: franchise!.restaurantType!);
    } catch (e, stack) {
      _templateRefsError = e.toString();
      shared.ErrorLogger.log(
        message: 'Failed to load menu template refs',
        stack: stack.toString(),
        source: 'MenuItemProviderImpl',
        severity: 'error',
      );
    } finally {
      _templateRefsLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<shared.MenuItem?> fetchMenuItemTemplateById({
    required String restaurantType,
    required String templateId,
  }) async {
    try {
      // Safe placeholder - avoids direct db access which causes analyzer issues in this file
      // TODO: Move to a dedicated FirestoreService method later if full template support is needed
      return null;
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to fetch menu item template',
        stack: stack.toString(),
        source: 'MenuItemProviderImpl',
        severity: 'error',
      );
      return null;
    }
  }

  @override
  shared.MenuItem applyTemplateToNewItem(shared.MenuItem template) {
    return template.copyWith(
      id: '',
      templateRefs: [template.id],
      archived: false,
      available: true,
      sortOrder: _working.length,
    );
  }

  @override
  List<String> getMissingRequiredFields(shared.MenuItem item) {
    final missing = <String>[];
    if (item.name.isEmpty) missing.add('name');
    if (item.description.isEmpty) missing.add('description');
    if (item.categoryId.isEmpty) missing.add('categoryId');
    if (item.price == 0.0 &&
        (item.sizePrices == null || item.sizePrices!.isEmpty)) {
      missing.add('price');
    }
    if (item.includedIngredients == null || item.includedIngredients!.isEmpty) {
      missing.add('includedIngredients');
    }
    return missing;
  }

  @override
  Future<List<shared.OnboardingValidationIssue>> validate({
    required List<String> validCategoryIds,
    required List<String> validIngredientIds,
    required List<String> validTypeIds,
  }) async {
    final issues = <shared.OnboardingValidationIssue>[];
    final names = <String>{};

    for (final item in _working) {
      if (!names.add(item.name.trim().toLowerCase())) {
        issues.add(shared.OnboardingValidationIssue(
          section: 'Menu Items',
          itemId: item.id,
          itemDisplayName: item.name,
          severity: shared.OnboardingIssueSeverity.critical,
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
        ));
      }

      if (!validCategoryIds.contains(item.categoryId)) {
        issues.add(shared.OnboardingValidationIssue(
          section: 'Menu Items',
          itemId: item.id,
          itemDisplayName: item.name,
          severity: shared.OnboardingIssueSeverity.critical,
          code: 'INVALID_CATEGORY_REFERENCE',
          message: "Menu item '${item.name}' references invalid category.",
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
    }

    if (_working.isEmpty) {
      issues.add(shared.OnboardingValidationIssue(
        section: 'Menu Items',
        itemId: '',
        itemDisplayName: '',
        severity: shared.OnboardingIssueSeverity.critical,
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

    return issues;
  }

  @override
  List<String> get allMenuItemIds => menuItems.map((m) => m.id).toList();

  @override
  shared.MenuItem? getByName(String name) {
    return menuItems.firstWhereOrNull(
        (m) => m.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  @override
  shared.MenuItem? getByIdCaseInsensitive(String id) {
    return menuItems
        .firstWhereOrNull((m) => m.id.toLowerCase() == id.toLowerCase());
  }

  @override
  List<String> get allReferencedCategoryIds {
    return menuItems.map((m) => m.categoryId).toSet().toList();
  }

  @override
  List<String> get allReferencedIngredientIds {
    final ids = <String>{};
    for (final item in menuItems) {
      ids.addAll(item.allReferencedIngredientIds);
    }
    return ids.toList();
  }

  @override
  List<String> get allReferencedIngredientTypeIds {
    final ids = <String>{};
    for (final item in menuItems) {
      ids.addAll(item.allReferencedIngredientTypeIds);
    }
    return ids.toList();
  }

  @override
  Future<Map<String, int>> normalizeSchemaReferences() async {
    if (_franchiseId == null || _franchiseId!.isEmpty) {
      return {};
    }

    try {
      final result = await (_firestoreService as dynamic)
          .normalizeSchemaReferences(franchiseId: _franchiseId!);

      // Refresh everything after normalization
      await reload(_franchiseId!, forceReloadFromFirestore: true);

      notifyListeners();
      return result as Map<String, int>;
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'normalizeSchemaReferences failed in provider',
        stack: stack.toString(),
        source: 'MenuItemProviderImpl',
        severity: 'error',
      );
      return {};
    }
  }
}
