import 'package:franchise_admin_portal/admin/menu/menu_item_editor_panel.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_unauthorized_dialog.dart';
import 'package:franchise_admin_portal/widgets/delayed_loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/admin/menu/dynamic_menu_item_editor_screen.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_menu_editor_popup_menu.dart';
import 'package:franchise_admin_portal/widgets/header/franchise_app_bar.dart';
import 'package:franchise_admin_portal/admin/menu/export_menu_dialog.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_bulk_selection_toolbar.dart';
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
import 'package:franchise_admin_portal/widgets/filter_dropdown.dart';
import 'package:franchise_admin_portal/admin/menu/bulk_menu_upload_dialog.dart';
import 'package:franchise_admin_portal/admin/menu/menu_item_customizations_dialog.dart';
import 'package:franchise_admin_portal/admin/menu/customization_types.dart'
    as ct;
import 'package:franchise_admin_portal/config/branding_config.dart';

// COLUMN SCHEMA DEFINITION
const menuItemColumns = [
  {"key": "image", "width": 56.0, "header": "Image"},
  {"key": "name", "flex": 3, "header": "Name"},
  {"key": "category", "flex": 2, "header": "Category"},
  {"key": "price", "flex": 2, "header": "Price"},
  {"key": "available", "flex": 2, "header": "Available"},
  {"key": "sku", "flex": 2, "header": "SKU"},
  {"key": "dietary", "flex": 3, "header": "Dietary/Allergens"},
];

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

  // Panel state for add/edit
  MenuItem? _editingMenuItem;
  bool _showEditorPanel = false;

  @override
  void initState() {
    super.initState();
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

  void _showChooseColumnsDialog() {
    // For future: column visibility settings.
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

  Widget buildMenuHeaderRow(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        children: menuItemColumns.map((col) {
          if (col.containsKey("width")) {
            return SizedBox(
              width: col["width"] as double,
              child: Center(
                child: Text(
                  loc.tryString(col["header"] as String? ?? ""),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else {
            return Expanded(
              flex: col["flex"] as int,
              child: Text(
                loc.tryString(col["header"] as String? ?? ""),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }
        }).toList(),
      ),
    );
  }

  Widget buildMenuDataRow(
    BuildContext context,
    MenuItem item,
    List<Category> categories,
    User user,
    bool isSelected,
    bool canEdit,
    bool canDeleteOrExport,
  ) {
    final cat = categories.firstWhere((c) => c.id == item.category,
        orElse: () => Category(id: item.category, name: item.category));
    return InkWell(
      onTap: () {
        final cur = List<String>.from(_selectedIds.value);
        isSelected ? cur.remove(item.id) : cur.add(item.id);
        _selectedIds.value = cur;
      },
      child: Container(
        color: isSelected ? Colors.grey[100] : null,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: menuItemColumns.map((col) {
            switch (col["key"]) {
              case "image":
                return SizedBox(
                  width: col["width"] as double,
                  child: Center(
                    child: (item.image != null && item.image!.isNotEmpty)
                        ? ClipOval(
                            child: Image.network(
                              item.image!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                BrandingConfig.defaultPizzaIcon,
                                width: 40,
                                height: 40,
                              ),
                            ),
                          )
                        : Image.asset(
                            BrandingConfig.defaultPizzaIcon,
                            width: 40,
                            height: 40,
                          ),
                  ),
                );
              case "name":
                return Expanded(
                  flex: col["flex"] as int,
                  child: Text(item.name),
                );
              case "category":
                return Expanded(
                  flex: col["flex"] as int,
                  child: Text(cat.name),
                );
              case "price":
                return Expanded(
                  flex: col["flex"] as int,
                  child: Text("\$${item.price.toStringAsFixed(2)}"),
                );
              case "available":
                return Expanded(
                  flex: col["flex"] as int,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: item.availability ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.availability ? "Available" : "Unavailable",
                        style: TextStyle(
                          color: item.availability ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              case "sku":
                return Expanded(
                  flex: col["flex"] as int,
                  child: Text(item.sku ?? ''),
                );
              case "dietary":
                return Expanded(
                  flex: col["flex"] as int,
                  child: DietaryAllergenChipsRow(
                    dietaryTags: item.dietaryTags ?? [],
                    allergens: item.allergens ?? [],
                  ),
                );
              default:
                return const SizedBox.shrink();
            }
          }).toList()
            ..add(
              SizedBox(
                width: 42,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 22),
                  tooltip: "More",
                  onSelected: (v) {
                    switch (v) {
                      case 'edit':
                        _addOrEditMenuItemPanel(item: item);
                        break;
                      case 'customize':
                        _openCustomizations(context, item, user);
                        break;
                      case 'delete':
                        _deleteMenuItems(context, [item], user);
                        break;
                    }
                  },
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                    if (canEdit)
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(AppLocalizations.of(context)!.edit),
                      ),
                    if (canEdit)
                      PopupMenuItem(
                        value: 'customize',
                        child: Text("Customizations"),
                      ),
                    if (canDeleteOrExport)
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(AppLocalizations.of(context)!.delete),
                      ),
                  ],
                ),
              ),
            ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final user = Provider.of<User?>(context);
    final loc = AppLocalizations.of(context)!;

    if (user == null) return _unauthorizedScaffold();
    if (!(user.isOwner || user.isAdmin || user.isManager))
      return _unauthorizedScaffold();

    final canEdit = _canEdit(user);
    final canDeleteOrExport = _canDeleteOrExport(user);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 11,
            child: StreamBuilder<List<Category>>(
              stream: firestore.getCategories(),
              builder: (context, catSnapshot) {
                return DelayedLoadingShimmer(
                  loading:
                      catSnapshot.connectionState == ConnectionState.waiting,
                  child: Builder(
                    builder: (context) {
                      if (catSnapshot.hasError) {
                        return EmptyStateWidget(
                          title: AppLocalizations.of(context)!
                              .errorLoadingCategories,
                          message: catSnapshot.error.toString(),
                        );
                      }
                      final categories = catSnapshot.data ?? [];
                      if (categories.isEmpty) {
                        return EmptyStateWidget(
                          title: AppLocalizations.of(context)!.noCategories,
                          message:
                              AppLocalizations.of(context)!.noCategoriesMsg,
                        );
                      }
                      return StreamBuilder<List<MenuItem>>(
                        stream: firestore.getMenuItems(),
                        builder: (context, itemSnapshot) {
                          return DelayedLoadingShimmer(
                            loading: itemSnapshot.connectionState ==
                                ConnectionState.waiting,
                            child: Builder(builder: (context) {
                              if (itemSnapshot.hasError) {
                                return EmptyStateWidget(
                                  title: AppLocalizations.of(context)!
                                      .errorLoadingMenu,
                                  message: itemSnapshot.error.toString(),
                                );
                              }
                              var items = itemSnapshot.data ?? [];
                              if (_categoryFilter != null &&
                                  _categoryFilter!.isNotEmpty) {
                                items = items
                                    .where((i) => i.category == _categoryFilter)
                                    .toList();
                              }
                              if (_search.isNotEmpty) {
                                items = items
                                    .where((i) =>
                                        i.name
                                            .toLowerCase()
                                            .contains(_search.toLowerCase()) ||
                                        (i.sku?.toLowerCase().contains(
                                                _search.toLowerCase()) ??
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

                              // --- UI Start ---
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 24,
                                        left: 16,
                                        right: 8,
                                        bottom: 12),
                                    child: Row(
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!
                                              .menuEditorTitle,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                          ),
                                        ),
                                        const Spacer(),
                                        AdminMenuEditorPopupMenu(
                                          showDeleted: _showDeleted,
                                          canDeleteOrExport: canDeleteOrExport,
                                          onShowColumns:
                                              _showChooseColumnsDialog,
                                          onBulkUpload: () async {
                                            final cats = await firestore
                                                .getCategories()
                                                .first;
                                            _bulkUpload(context, cats, user);
                                          },
                                          onToggleShowDeleted: () {
                                            setState(() =>
                                                _showDeleted = !_showDeleted);
                                          },
                                          onExportCSV: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  const ExportMenuDialog(),
                                            );
                                          },
                                          columnsLabel: loc.colColumns,
                                          importCSVLabel: loc.importCSV,
                                          showDeletedLabel: loc.showDeleted,
                                          exportCSVLabel: loc.exportCSV,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Search and category filter
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            decoration: InputDecoration(
                                              hintText:
                                                  AppLocalizations.of(context)!
                                                      .adminSearchHint,
                                              prefixIcon:
                                                  const Icon(Icons.search),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                borderSide: BorderSide.none,
                                              ),
                                              filled: true,
                                              fillColor: Colors.grey[100],
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 0),
                                            ),
                                            onChanged: (q) {
                                              setState(() {
                                                _search = q;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        FilterDropdown<String>(
                                          label: AppLocalizations.of(context)!
                                              .colCategory,
                                          options: [''] +
                                              categories
                                                  .map((cat) => cat.id)
                                                  .toList(),
                                          value: _categoryFilter ?? '',
                                          onChanged: (value) {
                                            setState(() {
                                              _categoryFilter =
                                                  (value != null &&
                                                          value.isNotEmpty)
                                                      ? value
                                                      : null;
                                            });
                                          },
                                          getLabel: (catId) {
                                            if (catId == '')
                                              return AppLocalizations.of(
                                                      context)!
                                                  .all;
                                            final match = categories
                                                .where((c) => c.id == catId);
                                            return match.isNotEmpty
                                                ? match.first.name
                                                : catId;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // TABLE HEADER
                                  buildMenuHeaderRow(context),
                                  const Divider(height: 1),
                                  // TABLE BODY
                                  Expanded(
                                    child: ValueListenableBuilder<List<String>>(
                                      valueListenable: _selectedIds,
                                      builder: (context, selectedIds, _) {
                                        if (items.isEmpty) {
                                          return EmptyStateWidget(
                                            title: AppLocalizations.of(context)!
                                                .noMenuItems,
                                            message:
                                                AppLocalizations.of(context)!
                                                    .noMenuItemsMsg,
                                          );
                                        }
                                        return ListView.separated(
                                          itemCount: items.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(height: 1),
                                          itemBuilder: (ctx, idx) {
                                            final item = items[idx];
                                            final isSelected =
                                                selectedIds.contains(item.id);
                                            return buildMenuDataRow(
                                              ctx,
                                              item,
                                              categories,
                                              user,
                                              isSelected,
                                              canEdit,
                                              canDeleteOrExport,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  ValueListenableBuilder<List<String>>(
                                    valueListenable: _selectedIds,
                                    builder: (context, selectedIds, _) {
                                      return (selectedIds.isNotEmpty &&
                                              canDeleteOrExport)
                                          ? SafeArea(
                                              minimum: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: MediaQuery.of(context)
                                                      .viewPadding
                                                      .bottom,
                                                ),
                                                child:
                                                    AdminBulkSelectionToolbar(
                                                  selectedCount:
                                                      selectedIds.length,
                                                  onDelete: () {
                                                    final selectedItems = items
                                                        .where((i) =>
                                                            selectedIds
                                                                .contains(i.id))
                                                        .toList();
                                                    _deleteMenuItems(context,
                                                        selectedItems, user);
                                                  },
                                                  onClearSelection:
                                                      _clearSelection,
                                                  deleteLabel:
                                                      AppLocalizations.of(
                                                              context)!
                                                          .bulkDelete,
                                                  clearSelectionTooltip:
                                                      AppLocalizations.of(
                                                              context)!
                                                          .clearSelection,
                                                  selectedLabel:
                                                      AppLocalizations.of(
                                                              context)!
                                                          .bulkActionsSelected(
                                                              selectedIds
                                                                  .length),
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
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                  .addItem),
                                          onPressed: () =>
                                              _addOrEditMenuItemPanel(
                                                  item: null),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                              // --- UI End ---
                            }),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // Always keep the editor panel in the widget tree, only show when needed.
          Expanded(
            flex: 9,
            child: Offstage(
              offstage: !_showEditorPanel,
              child: MenuItemEditorPanel(
                isOpen: _showEditorPanel,
                initialCategoryId: _editingMenuItem?.category,
                onClose: _saveOrCloseEditor,
              ),
            ),
          ),
        ],
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

// Extension to safely localize static header keys, fallback to the given string
extension _LocTry on AppLocalizations {
  String tryString(String header) {
    switch (header) {
      case "Image":
        return colImage;
      case "Name":
        return colName;
      case "Category":
        return colCategory;
      case "Price":
        return colPrice;
      case "Available":
        return colAvailable;
      case "SKU":
        return colSKU;
      case "Dietary/Allergens":
        return "Dietary/Allergens";
      default:
        return header;
    }
  }
}
