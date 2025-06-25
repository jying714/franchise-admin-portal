import 'package:franchise_admin_portal/widgets/admin/admin_unauthorized_dialog.dart';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/admin/menu/dynamic_menu_item_editor_screen.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_menu_editor_popup_menu.dart';
import 'package:franchise_admin_portal/widgets/header/franchise_app_bar.dart';
import 'package:franchise_admin_portal/admin/menu/export_menu_dialog.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_bulk_selection_toolbar.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_menu_item_row.dart';
import 'package:franchise_admin_portal/widgets/status_chip.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_delete_confirm_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/menu_item.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_unauthorized_widget.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:franchise_admin_portal/widgets/dietary_allergen_chips_row.dart';
import 'package:franchise_admin_portal/core/models/user.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/services/audit_log_service.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_sortable_grid.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_search_bar.dart';
import 'package:franchise_admin_portal/widgets/filter_dropdown.dart';
import 'package:franchise_admin_portal/admin/menu/bulk_menu_upload_dialog.dart';
import 'package:franchise_admin_portal/admin/menu/menu_item_customizations_dialog.dart';
import 'package:franchise_admin_portal/admin/menu/customization_types.dart'
    as ct;
import 'package:franchise_admin_portal/config/branding_config.dart';

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
  late List<String> _visibleColumnKeys;

  // Panel state for add/edit
  MenuItem? _editingMenuItem;
  bool _showEditorPanel = false;

  @override
  void initState() {
    super.initState();
    _visibleColumnKeys = List<String>.from(_allColumnKeys);
  }

  @override
  void dispose() {
    _searchQuery.dispose();
    _selectedIds.dispose();
    _searchController.dispose();
    super.dispose();
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

  Future<void> _addOrEditMenuItemPanel({MenuItem? item}) async {
    setState(() {
      _editingMenuItem = item;
      _showEditorPanel = true;
    });
  }

  Future<void> _saveOrCloseEditor() async {
    setState(() {
      _showEditorPanel = false;
      _editingMenuItem = null;
    });
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
    // You may want to remove this dialog for the web/tablet experience,
    // or simply let all columns be visible.
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
            columnsLabel: loc.colColumns,
            importCSVLabel: loc.importCSV,
            showDeletedLabel: loc.showDeleted,
            exportCSVLabel: loc.exportCSV,
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

              // ────────────── SPLIT PANEL LAYOUT ──────────────
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Menu List + Filters
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        AdminSearchBar(
                          controller: _searchController,
                          hintText:
                              AppLocalizations.of(context)!.adminSearchHint,
                          onChanged: (q) => _searchQuery.value = q,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: FilterDropdown<String>(
                            label: AppLocalizations.of(context)!.colCategory,
                            options:
                                [''] + categories.map((cat) => cat.id).toList(),
                            value: _categoryFilter ?? '',
                            onChanged: (value) {
                              setState(() {
                                _categoryFilter =
                                    (value != null && value.isNotEmpty)
                                        ? value
                                        : null;
                              });
                            },
                            getLabel: (catId) {
                              if (catId == '')
                                return AppLocalizations.of(context)!.all;
                              final match =
                                  categories.where((c) => c.id == catId);
                              return match.isNotEmpty
                                  ? match.first.name
                                  : catId;
                            },
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width,
                              ),
                              child: ValueListenableBuilder<String>(
                                valueListenable: _searchQuery,
                                builder: (context, search, _) {
                                  var filteredItems = items;
                                  if (_categoryFilter != null &&
                                      _categoryFilter!.isNotEmpty) {
                                    filteredItems = filteredItems
                                        .where((i) =>
                                            i.category == _categoryFilter)
                                        .toList();
                                  }
                                  if (search.isNotEmpty) {
                                    filteredItems = filteredItems.where((i) {
                                      final q = search.toLowerCase();
                                      return i.name.toLowerCase().contains(q) ||
                                          (i.sku?.toLowerCase().contains(q) ??
                                              false);
                                    }).toList();
                                  }
                                  if (_sortKey != null) {
                                    filteredItems.sort((a, b) {
                                      int cmp;
                                      switch (_sortKey) {
                                        case 'name':
                                          cmp = a.name.compareTo(b.name);
                                          break;
                                        case 'category':
                                          cmp =
                                              a.category.compareTo(b.category);
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
                                  return AdminSortableGrid<MenuItem>(
                                    items: filteredItems,
                                    columns: columns,
                                    sortKeys: sortKeys,
                                    columnKeys: _visibleColumnKeys,
                                    sortKey: _sortKey,
                                    ascending: _sortAsc,
                                    onSort: _onSortChanged,
                                    itemBuilder: (ctx, item) {
                                      return ValueListenableBuilder<
                                          List<String>>(
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
                                            canDeleteOrExport:
                                                canDeleteOrExport,
                                            onSelect: () {
                                              final cur = List<String>.from(
                                                  selectedIds);
                                              isSelected
                                                  ? cur.remove(item.id)
                                                  : cur.add(item.id);
                                              _selectedIds.value = cur;
                                            },
                                            onEdit: () =>
                                                _addOrEditMenuItemPanel(
                                                    item: item),
                                            onCustomize: () =>
                                                _openCustomizations(
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
                                        bottom: MediaQuery.of(context)
                                            .viewPadding
                                            .bottom,
                                      ),
                                      child: AdminBulkSelectionToolbar(
                                        selectedCount: selectedIds.length,
                                        onDelete: () {
                                          final selectedItems = items
                                              .where((i) =>
                                                  selectedIds.contains(i.id))
                                              .toList();
                                          _deleteMenuItems(
                                              context, selectedItems, user);
                                        },
                                        onClearSelection: _clearSelection,
                                        deleteLabel:
                                            AppLocalizations.of(context)!
                                                .bulkDelete,
                                        clearSelectionTooltip:
                                            AppLocalizations.of(context)!
                                                .clearSelection,
                                        selectedLabel:
                                            AppLocalizations.of(context)!
                                                .bulkActionsSelected(
                                                    selectedIds.length),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                        if (canEdit)
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 16, bottom: 16, top: 8),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: FloatingActionButton.extended(
                                icon: const Icon(Icons.add),
                                label:
                                    Text(AppLocalizations.of(context)!.addItem),
                                onPressed: () =>
                                    _addOrEditMenuItemPanel(item: null),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Right: Persistent Panel for Add/Edit
                  if (_showEditorPanel)
                    Container(
                      width: 520,
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Panel header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 18),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _editingMenuItem == null
                                      ? AppLocalizations.of(context)!.addItem
                                      : AppLocalizations.of(context)!.editItem,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Close',
                                  onPressed: () => _saveOrCloseEditor(),
                                )
                              ],
                            ),
                          ),
                          Expanded(
                              child: DynamicMenuItemEditorScreen(
                            initialCategoryId: _editingMenuItem?.category,
                          )),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _unauthorizedScaffold() {
    return AdminUnauthorizedWidget(
      title: AppLocalizations.of(context)!.menuEditorTitle,
      message: AppLocalizations.of(context)!.unauthorizedMessage,
      buttonText: AppLocalizations.of(context)!.returnHome,
    );
  }
}
