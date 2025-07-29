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

class MenuItemProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  List<MenuTemplateRef> _templateRefs = [];
  bool _templateRefsLoading = false;
  String? _templateRefsError;
  FranchiseInfoProvider _franchiseInfoProvider;

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
    _isLoading = true;
    _franchiseId = franchiseId;
    notifyListeners();

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
      notifyListeners();
    }
  }

  void addOrUpdateMenuItem(MenuItem item) {
    final index = _working.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      _working.add(item);
    } else {
      _working[index] = item;
    }
    notifyListeners();
  }

  void deleteMenuItem(String id) {
    _working.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<void> persistChanges() async {
    if (_franchiseId == null || !isDirty) return;

    try {
      await _firestoreService.saveMenuItems(_franchiseId!, _working);
      _original = _working.map((e) => e.copyWith()).toList();
      notifyListeners();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to persist menu item changes',
        source: 'MenuItemProvider',
        screen: 'menu_item_provider',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': _franchiseId},
      );
    }
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
}
