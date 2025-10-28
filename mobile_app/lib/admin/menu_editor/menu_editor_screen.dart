import 'package:doughboys_pizzeria_final/widgets/admin/admin_unauthorized_dialog.dart';
import 'package:flutter/material.dart';
import 'package:doughboys_pizzeria_final/admin/menu_editor/dynamic_menu_item_editor_screen.dart';
import 'package:doughboys_pizzeria_final/widgets/admin/admin_menu_editor_popup_menu.dart';
import 'package:doughboys_pizzeria_final/widgets/header/franchise_app_bar.dart';
import 'package:doughboys_pizzeria_final/widgets/admin/admin_menu_item_actions_row.dart';
import 'package:doughboys_pizzeria_final/admin/menu_editor/export_menu_dialog.dart';
import 'package:doughboys_pizzeria_final/widgets/admin/admin_bulk_selection_toolbar.dart';
import 'package:doughboys_pizzeria_final/widgets/admin/admin_menu_item_row.dart';
import 'package:doughboys_pizzeria_final/widgets/status_chip.dart';
import 'package:doughboys_pizzeria_final/widgets/admin/admin_delete_confirm_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:doughboys_pizzeria_final/widgets/data_export_button.dart';
import 'package:doughboys_pizzeria_final/core/models/menu_item.dart';
import 'package:doughboys_pizzeria_final/widgets/admin/admin_unauthorized_widget.dart';
import 'package:doughboys_pizzeria_final/core/models/category.dart';
import 'package:doughboys_pizzeria_final/widgets/dietary_allergen_chips_row.dart';
import 'package:doughboys_pizzeria_final/core/models/customization.dart';
import 'package:doughboys_pizzeria_final/core/models/user.dart';
import 'package:doughboys_pizzeria_final/core/services/firestore_service.dart';
import 'package:doughboys_pizzeria_final/core/services/audit_log_service.dart';
import 'package:doughboys_pizzeria_final/widgets/loading_shimmer_widget.dart';
import 'package:doughboys_pizzeria_final/widgets/empty_state_widget.dart';
import 'package:doughboys_pizzeria_final/widgets/admin/admin_sortable_grid.dart';
import 'package:doughboys_pizzeria_final/widgets/admin/admin_search_bar.dart';
import 'package:doughboys_pizzeria_final/widgets/network_image_widget.dart';
import 'package:doughboys_pizzeria_final/admin/menu_editor/menu_item_form_dialog.dart';
import 'package:doughboys_pizzeria_final/admin/menu_editor/bulk_menu_upload_dialog.dart';
import 'package:doughboys_pizzeria_final/admin/menu_editor/menu_item_customizations_dialog.dart';
import 'package:doughboys_pizzeria_final/admin/menu_editor/customization_types.dart'
    as ct;
import 'package:doughboys_pizzeria_final/config/branding_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:doughboys_pizzeria_final/widgets/filter_dropdown.dart';

class MenuEditorScreen extends StatefulWidget {
  const MenuEditorScreen({super.key});

  @override
  State<MenuEditorScreen> createState() => _MenuEditorScreenState();
}

class _MenuEditorScreenState extends State<MenuEditorScreen> {
  final ValueNotifier<List<String>> _selectedIds =
      ValueNotifier<List<String>>([]);

  String _search = '';
  String? _sortKey;
  bool _sortAsc = true;
  String? _categoryFilter;
  bool _showDeleted = false;
  MenuItem? _lastDeletedItem;

  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');
  final TextEditingController _searchController = TextEditingController();

  final List<String> _allColumnKeys = [
    'image',
    'name',
    'category',
    'price',
    'available',
    'sku',
    'dietary',
  ];
  final int _maxVisibleColumns = 5;
  List<String> _visibleColumnKeys = ['image', 'name', 'price'];

  @override
  void dispose() {
    _searchQuery.dispose();
    _selectedIds.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTablet = MediaQuery.of(context).size.width > 600;
    if (isTablet && _visibleColumnKeys.length < 5) {
      _visibleColumnKeys = ['image', 'name', 'category', 'price', 'available'];
    }
  }

  void _onSearchChanged(String value) => setState(() => _search = value);
  void _onSortChanged(String sortKey, bool asc) => setState(() {
        _sortKey = sortKey;
        _sortAsc = asc;
      });
  void _clearSelection() {
    _selectedIds.value = [];
  }

  bool _canEdit(User? user) =>
      user != null && (user.isOwner || user.isAdmin || user.isManager);
  bool _canDeleteOrExport(User? user) =>
      user != null && (user.isOwner || user.isAdmin);

  Future<void> _addOrEditMenuItem(BuildContext context,
      {MenuItem? item,
      required List<Category> categories,
      required User user}) async {
    print(
        'Launching MenuItemFormDialog with item: $item, categories: $categories, user: $user');
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    if (!_canEdit(user)) {
      await _logUnauthorizedAttempt(user, 'edit_menu_item', item?.id);
      _showUnauthorizedDialog();
      return;
    }
    final result = await showDialog<MenuItem>(
      context: context,
      builder: (_) => MenuItemFormDialog(
        initialItem: item,
        categories: categories,
        onSave: (savedItem) async {
          if (item == null) {
            await firestore.addMenuItem(savedItem, userId: user.id);
            await AuditLogService().addLog(
              userId: user.id,
              action: 'add_menu_item',
              targetType: 'menu_item',
              targetId: savedItem.id,
              details: {'name': savedItem.name},
            );
          } else {
            await firestore.updateMenuItem(savedItem, userId: user.id);
            await AuditLogService().addLog(
              userId: user.id,
              action: 'update_menu_item',
              targetType: 'menu_item',
              targetId: savedItem.id,
              details: {'name': savedItem.name},
            );
          }
        },
      ),
    );
    print('Dialog result: $result');
    if (result != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(item == null
                ? AppLocalizations.of(context)!.itemAdded
                : AppLocalizations.of(context)!.itemUpdated),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  String _columnDisplayName(String key) {
    final loc = AppLocalizations.of(context)!;
    switch (key) {
      case 'image':
        return loc.colImage;
      case 'name':
        return loc.colName;
      case 'category':
        return loc.colCategory;
      case 'price':
        return loc.colPrice;
      case 'available':
        return loc.colAvailable;
      case 'sku':
        return loc.colSKU;
      case 'dietary':
        return "Dietary/Allergens";
      default:
        return key;
    }
  }

  void _showChooseColumnsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final availableColumns = _allColumnKeys;
            return AlertDialog(
              title: Text("Select Columns"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableColumns.map((col) {
                    final isChecked = _visibleColumnKeys.contains(col);
                    final disabled = !isChecked &&
                        _visibleColumnKeys.length >= _maxVisibleColumns;
                    return CheckboxListTile(
                      title: Text(_columnDisplayName(col)),
                      value: isChecked,
                      onChanged: disabled
                          ? null
                          : (checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  if (_visibleColumnKeys.length <
                                      _maxVisibleColumns) {
                                    _visibleColumnKeys.add(col);
                                  }
                                } else {
                                  _visibleColumnKeys.remove(col);
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: Text('Apply'),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _bulkUpload(
      BuildContext context, List<Category> categories, User user) async {
    if (!_canDeleteOrExport(user)) {
      await _logUnauthorizedAttempt(user, 'bulk_upload_menu_items');
      _showUnauthorizedDialog();
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => BulkMenuUploadDialog(
        categories: categories,
        onComplete: () => Navigator.of(context).pop(true),
      ),
    );
    if (result == true) {
      await AuditLogService().addLog(
        userId: user.id,
        action: 'bulk_upload_menu_items',
        targetType: 'menu_item',
        targetId: '',
        details: {},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.bulkImportSuccess)),
      );
    }
  }

  Future<void> _deleteMenuItems(
      BuildContext context, List<MenuItem> items, User user) async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    if (!_canDeleteOrExport(user)) {
      await _logUnauthorizedAttempt(user, 'delete_menu_items');
      _showUnauthorizedDialog();
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AdminDeleteConfirmDialog(itemCount: items.length),
    );

    if (confirm == true) {
      for (final item in items) {
        await firestore.deleteMenuItem(item.id, userId: user.id);
        await AuditLogService().addLog(
          userId: user.id,
          action: 'delete_menu_item',
          targetType: 'menu_item',
          targetId: item.id,
          details: {'name': item.name},
        );
      }
      setState(() {
        _lastDeletedItem = items.last;
        _selectedIds.value = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.itemDeleted),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.undo,
            onPressed: () async {
              if (_lastDeletedItem != null) {
                await firestore.addMenuItem(_lastDeletedItem!, userId: user.id);
                await AuditLogService().addLog(
                  userId: user.id,
                  action: 'undo_delete_menu_item',
                  targetType: 'menu_item',
                  targetId: _lastDeletedItem!.id,
                  details: {'name': _lastDeletedItem!.name},
                );
                setState(() => _lastDeletedItem = null);
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _openCustomizations(
      BuildContext context, MenuItem item, User user) async {
    if (!_canEdit(user)) {
      await _logUnauthorizedAttempt(user, 'edit_customizations', item.id);
      _showUnauthorizedDialog();
      return;
    }
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    // Use shared mapping utilities
    final List<ct.CustomizationGroup> groups =
        item.customizations.map((c) => ct.customizationToGroup(c)).toList();

    final result = await showDialog<List<ct.CustomizationGroup>>(
      context: context,
      builder: (_) => MenuItemCustomizationsDialog(
        initialGroups: groups,
      ),
    );

    if (result != null) {
      final updatedCustomizations =
          result.map((g) => ct.groupToCustomization(g)).toList();
      await firestore.updateMenuItem(
        item.copyWith(customizations: updatedCustomizations),
        userId: user.id,
      );
      await AuditLogService().addLog(
        userId: user.id,
        action: 'update_customizations',
        targetType: 'menu_item',
        targetId: item.id,
        details: {},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.customizationsUpdated)),
      );
    }
  }

  Future<void> _exportToCSV(
      BuildContext context, List<MenuItem> items, User user) async {
    if (!_canDeleteOrExport(user)) {
      await _logUnauthorizedAttempt(user, 'export_menu_csv');
      _showUnauthorizedDialog();
      return;
    }
    // Export logic handled elsewhere
    await AuditLogService().addLog(
      userId: user.id,
      action: 'export_menu_csv',
      targetType: 'menu_item',
      targetId: '',
      details: {'itemCount': items.length},
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.exportStarted)),
    );
  }

  Future<void> _logUnauthorizedAttempt(User user, String action,
      [String? targetId]) async {
    await AuditLogService().addLog(
      userId: user.id,
      action: 'unauthorized_attempt',
      targetType: 'menu_item',
      targetId: targetId ?? '',
      details: {'attemptedAction': action},
    );
  }

  void _showUnauthorizedDialog() {
    showDialog(
      context: context,
      builder: (_) => const AdminUnauthorizedDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final user = Provider.of<User?>(context);
    final loc = AppLocalizations.of(context)!;
    if (user == null) {
      return _unauthorizedScaffold();
    }
    if (!(user.isOwner || user.isAdmin || user.isManager)) {
      return _unauthorizedScaffold();
    }

    final canEdit = _canEdit(user);
    final canDeleteOrExport = _canDeleteOrExport(user);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: FranchiseAppBar(
        title: AppLocalizations.of(context)!.menuEditorTitle,
        actions: [
          AdminMenuEditorPopupMenu(
            showDeleted: _showDeleted,
            canDeleteOrExport: canDeleteOrExport,
            onShowColumns: _showChooseColumnsDialog,
            onBulkUpload: () async {
              final cats = await firestore.getCategories().first;
              _bulkUpload(context, cats, user);
            },
            onToggleShowDeleted: () {
              setState(() => _showDeleted = !_showDeleted);
            },
            onExportCSV: () {
              showDialog(
                context: context,
                builder: (_) => const ExportMenuDialog(),
              );
            },
            columnsLabel:
                loc.colColumns, // Use your .arb keys here as appropriate
            importCSVLabel: loc.importCSV, // Add to .arb if missing
            showDeletedLabel: loc.showDeleted, // Add to .arb if missing
            exportCSVLabel: loc.exportCSV, // Add to .arb if missing
          ),
        ],
      ),
      body: StreamBuilder<List<Category>>(
        stream: firestore.getCategories(),
        builder: (context, catSnapshot) {
          if (catSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerWidget();
          }
          if (catSnapshot.hasError) {
            return EmptyStateWidget(
              title: AppLocalizations.of(context)!.errorLoadingCategories,
              message: catSnapshot.error.toString(),
            );
          }
          final categories = catSnapshot.data ?? [];
          if (categories.isEmpty) {
            return EmptyStateWidget(
              title: AppLocalizations.of(context)!.noCategories,
              message: AppLocalizations.of(context)!.noCategoriesMsg,
            );
          }
          return StreamBuilder<List<MenuItem>>(
            stream: firestore.getMenuItems(),
            builder: (context, itemSnapshot) {
              if (itemSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingShimmerWidget();
              }
              if (itemSnapshot.hasError) {
                return EmptyStateWidget(
                  title: AppLocalizations.of(context)!.errorLoadingMenu,
                  message: itemSnapshot.error.toString(),
                );
              }
              var items = itemSnapshot.data ?? [];
              if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
                items =
                    items.where((i) => i.category == _categoryFilter).toList();
              }
              if (_search.isNotEmpty) {
                items = items
                    .where((i) =>
                        i.name.toLowerCase().contains(_search.toLowerCase()) ||
                        (i.sku?.toLowerCase().contains(_search.toLowerCase()) ??
                            false))
                    .toList();
              }
              // Sorting logic
              if (_sortKey != null) {
                items.sort((a, b) {
                  int cmp = 0;
                  switch (_sortKey) {
                    case 'name':
                      cmp = a.name.compareTo(b.name);
                      break;
                    case 'category':
                      cmp = a.category.compareTo(b.category);
                      break;
                    case 'price':
                      cmp = a.price.compareTo(b.price);
                      break;
                    default:
                      cmp = 0;
                  }
                  return _sortAsc ? cmp : -cmp;
                });
              }
              final columns =
                  _visibleColumnKeys.map(_columnDisplayName).toList();
              final sortKeys = _visibleColumnKeys.map((key) {
                switch (key) {
                  case 'name':
                  case 'category':
                  case 'price':
                    return key;
                  default:
                    return '';
                }
              }).toList();
              //print('[DEBUG] MenuEditorScreen: items.length = ${items.length}');
              // for (var i = 0; i < items.length; i++) {
              //   print('[DEBUG] MenuEditorScreen: item[$i] = ${items[i].name}');
              // }
              return Column(
                children: [
                  AdminSearchBar(
                    controller: _searchController,
                    hintText: AppLocalizations.of(context)!.adminSearchHint,
                    onChanged: (q) => _searchQuery.value = q,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: FilterDropdown<String>(
                      label: AppLocalizations.of(context)!.colCategory,
                      options: [''] + categories.map((cat) => cat.id).toList(),
                      value: _categoryFilter ?? '',
                      onChanged: (value) {
                        setState(() {
                          _categoryFilter = (value != null && value.isNotEmpty)
                              ? value
                              : null;
                        });
                      },
                      getLabel: (catId) {
                        if (catId == '')
                          return AppLocalizations.of(context)!.all;
                        final match = categories.where((c) => c.id == catId);
                        return match.isNotEmpty ? match.first.name : catId;
                      },
                    ),
                  ),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: _searchQuery,
                      builder: (context, search, _) {
                        var filteredItems = items;
                        if (search.isNotEmpty) {
                          filteredItems = items
                              .where((i) =>
                                  i.name
                                      .toLowerCase()
                                      .contains(search.toLowerCase()) ||
                                  (i.sku
                                          ?.toLowerCase()
                                          .contains(search.toLowerCase()) ??
                                      false))
                              .toList();
                        }
                        return AdminSortableGrid<MenuItem>(
                          items: filteredItems,
                          columns: columns,
                          sortKeys: sortKeys,
                          columnKeys: _visibleColumnKeys,
                          sortKey: _sortKey,
                          ascending: _sortAsc,
                          onSort: _onSortChanged,
                          itemBuilder: (ctx, item) {
                            return ValueListenableBuilder<List<String>>(
                              valueListenable: _selectedIds,
                              builder: (context, selectedIds, _) {
                                final isSelected =
                                    selectedIds.contains(item.id);
                                return AdminMenuItemRow(
                                  visibleColumns: _visibleColumnKeys,
                                  item: item,
                                  isSelected: isSelected,
                                  categories: categories,
                                  user: user,
                                  canEdit: canEdit,
                                  canDeleteOrExport: canDeleteOrExport,
                                  onSelect: () {
                                    final current =
                                        List<String>.from(selectedIds);
                                    if (isSelected) {
                                      current.remove(item.id);
                                    } else {
                                      current.add(item.id);
                                    }
                                    _selectedIds.value = current;
                                  },
                                  onEdit: () => _addOrEditMenuItem(
                                    context,
                                    item: item,
                                    categories: categories,
                                    user: user,
                                  ),
                                  onCustomize: () => _openCustomizations(
                                    context,
                                    item,
                                    user,
                                  ),
                                  onDelete: () => _deleteMenuItems(
                                    context,
                                    [item],
                                    user,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  ValueListenableBuilder<List<String>>(
                    valueListenable: _selectedIds,
                    builder: (context, selectedIds, _) {
                      return (selectedIds.isNotEmpty && canDeleteOrExport)
                          ? SafeArea(
                              minimum: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewPadding.bottom,
                                ),
                                child: AdminBulkSelectionToolbar(
                                  selectedCount: selectedIds.length,
                                  onDelete: () {
                                    final selectedItems = items
                                        .where(
                                            (i) => selectedIds.contains(i.id))
                                        .toList();
                                    _deleteMenuItems(
                                        context, selectedItems, user);
                                  },
                                  onClearSelection: _clearSelection,
                                  deleteLabel:
                                      AppLocalizations.of(context)!.bulkDelete,
                                  clearSelectionTooltip:
                                      AppLocalizations.of(context)!
                                          .clearSelection,
                                  selectedLabel: AppLocalizations.of(context)!
                                      .bulkActionsSelected(selectedIds.length),
                                ),
                              ),
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addItem),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DynamicMenuItemEditorScreen(),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _cellSpacer() => const SizedBox(width: 8);

  Widget _unauthorizedScaffold() {
    return AdminUnauthorizedWidget(
      title: AppLocalizations.of(context)!.menuEditorTitle,
      message: AppLocalizations.of(context)!
          .unauthorizedMessage, // Add this to your .arb for best practice!
      buttonText: AppLocalizations.of(context)!
          .returnHome, // Add to .arb if not present
    );
  }
}
