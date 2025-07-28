import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/menu_item.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/core/models/menu_template_ref.dart';
import 'package:franchise_admin_portal/core/models/size_template.dart';

class MenuItemProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  List<MenuTemplateRef> _templateRefs = [];
  bool _templateRefsLoading = false;
  String? _templateRefsError;

  // 🔢 Size Templates (Dropdown + Preview)
  List<SizeTemplate> _sizeTemplates = [];
  String? _selectedSizeTemplateId;

  List<SizeTemplate> get sizeTemplates => _sizeTemplates;
  String? get selectedSizeTemplateId => _selectedSizeTemplateId;

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

  MenuItemProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

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
      _templateRefs = await _firestoreService.fetchMenuTemplateRefs();
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
}
