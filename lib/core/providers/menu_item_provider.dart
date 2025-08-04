import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:franchise_admin_portal/core/models/menu_item.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/core/models/menu_template_ref.dart';
import 'package:franchise_admin_portal/core/models/size_template.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:franchise_admin_portal/core/providers/franchise_info_provider.dart';
import 'package:collection/collection.dart';
import 'package:franchise_admin_portal/core/providers/category_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider.dart';
import 'package:provider/provider.dart';

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
      await ErrorLogger.log(
        message: 'Failed to load size templates',
        source: 'MenuItemProvider',
        screen: 'menu_item_provider',
        severity: 'error',
        stack: stack.toString(),
      );
    }
  }

  List<MenuItem> _original = [];
  List<MenuItem> _working = [];

  bool _isLoading = false;
  String? _franchiseId;

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

  Future<void> loadMenuItems(String franchiseId) async {
    _franchiseId = franchiseId; // ✅ Assign here so persistChanges works
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    try {
      final items = await _firestoreService.fetchMenuItemsOnce(franchiseId);
      _original = items;
      _working = items.map((e) => e.copyWith()).toList();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to load menu items',
        source: 'MenuItemProvider',
        screen: 'menu_item_provider',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId},
      );
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
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
          await ErrorLogger.log(
            message: 'Failed to save staged ingredient types',
            source: 'MenuItemProvider',
            screen: 'menu_item_provider.dart',
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
          await ErrorLogger.log(
            message: 'Failed to save staged ingredients',
            source: 'MenuItemProvider',
            screen: 'menu_item_provider.dart',
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
          await ErrorLogger.log(
            message: 'Failed to save staged categories',
            source: 'MenuItemProvider',
            screen: 'menu_item_provider.dart',
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
      await ErrorLogger.log(
        message: 'Failed to persist menu item changes',
        source: 'MenuItemProvider',
        screen: 'menu_item_provider.dart',
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
      await ErrorLogger.log(
        message: 'Failed to reorder menu items',
        source: 'MenuItemProvider',
        screen: 'menu_item_provider',
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
      await ErrorLogger.log(
        message: 'Failed to load menu template refs',
        source: 'MenuItemProvider',
        screen: 'menu_item_provider',
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
        await ErrorLogger.log(
          message: 'Menu item template not found',
          source: 'MenuItemProvider.fetchMenuItemTemplateById',
          screen: 'menu_item_editor_sheet.dart',
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
        await ErrorLogger.log(
          message: 'Empty menu item template document',
          source: 'MenuItemProvider.fetchMenuItemTemplateById',
          screen: 'menu_item_editor_sheet.dart',
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
        await ErrorLogger.log(
          message: 'MenuItem.fromFirestore threw during template fetch',
          stack: stack.toString(),
          source: 'MenuItemProvider.fetchMenuItemTemplateById',
          screen: 'menu_item_editor_sheet.dart',
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
      await ErrorLogger.log(
        message: 'Unhandled exception during menu item template fetch',
        stack: stack.toString(),
        source: 'MenuItemProvider.fetchMenuItemTemplateById',
        screen: 'menu_item_editor_sheet.dart',
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
    await ErrorLogger.log(
      message: 'MenuItem repair',
      source: 'MenuItemProvider',
      screen: 'onboarding/repair',
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
      categoryProvider.reload(),
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
      await ErrorLogger.log(
        message: 'Failed to delete menu item from Firestore',
        source: 'MenuItemProvider',
        screen: 'menu_item_provider',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': _franchiseId, 'menuItemId': id},
      );
    }
  }
}
