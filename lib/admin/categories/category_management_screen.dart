import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'category_form_dialog.dart';
import 'bulk_upload_dialog.dart';
import 'category_search_bar.dart';
import 'bulk_action_bar.dart';
import 'unauthorized_widget.dart';
import 'undo_snackbar.dart';

// Optionally for user id (for error logging)
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';

const categoryColumns = [
  {"key": "select", "width": 40.0, "header": ""},
  {"key": "image", "width": 56.0, "header": ""},
  {"key": "name", "flex": 3, "header": "Category Name"},
  {"key": "description", "flex": 5, "header": "Description (optional)"},
  {"key": "actions", "width": 96.0, "header": ""},
];

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  late FirestoreService firestoreService;
  List<Category> _allCategories = [];
  List<Category> _filteredCategories = [];
  Set<String> _selectedIds = {};
  String _searchQuery = '';
  String _sortKey = 'name';
  bool _sortAsc = true;
  bool _isLoading = false;
  bool _bulkLoading = false;

  @override
  void initState() {
    super.initState();
    firestoreService = Provider.of<FirestoreService>(context, listen: false);
  }

  bool _canManageCategories(BuildContext context) {
    final user = Provider.of<UserProfileNotifier>(context, listen: false).user;
    if (user == null) return false;
    final roles = user.roles ?? <String>[];
    return roles.contains('owner') ||
        roles.contains('admin') ||
        roles.contains('manager') ||
        roles.contains('developer');
  }

  void _onCategorySelect(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _onSelectAll(bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedIds = _filteredCategories.map((c) => c.id).toSet();
      } else {
        _selectedIds.clear();
      }
    });
  }

  Future<void> _openCategoryDialog({Category? category}) async {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    if (!_canManageCategories(context) || _isLoading || _bulkLoading) return;
    await showDialog<Category>(
      context: context,
      builder: (_) => CategoryFormDialog(
        category: category,
        onSaved: (Category saved) async {
          setState(() => _isLoading = true);
          final userId =
              Provider.of<UserProfileNotifier?>(context, listen: false)
                  ?.user
                  ?.id;
          try {
            if (category == null) {
              await firestoreService.addCategory(franchiseId, saved);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppLocalizations.of(context)!.categoryAdded)),
              );
            } else {
              await firestoreService.updateCategory(franchiseId, saved);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.categoryUpdated)),
              );
            }
          } catch (e, stack) {
            // Log error to Firestore
            try {
              await firestoreService.logError(
                franchiseId,
                message: e.toString(),
                source: 'category_management_screen',
                screen: 'CategoryManagementScreen',
                userId: userId,
                stackTrace: stack.toString(),
                errorType: e.runtimeType.toString(),
                severity: 'error',
                contextData: {
                  'categoryId': category?.id ?? 'new',
                  'name': saved.name,
                  'image': saved.image,
                  'description': saved.description,
                  'operation': category == null ? 'add' : 'update',
                },
              );
            } catch (_) {}
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(AppLocalizations.of(context)!.failedToSaveCategory)),
            );
          } finally {
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  Future<void> _deleteCategory(Category category,
      {bool showUndo = true}) async {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    if (!_canManageCategories(context) || _isLoading || _bulkLoading) return;
    final loc = AppLocalizations.of(context)!;
    final userId =
        Provider.of<UserProfileNotifier?>(context, listen: false)?.user?.id;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteCategory),
        content: Text(loc.deleteCategoryConfirm(category.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await firestoreService.deleteCategory(franchiseId, category.id);
      } catch (e, stack) {
        try {
          await firestoreService.logError(
            franchiseId,
            message: e.toString(),
            source: 'category_management_screen',
            screen: 'CategoryManagementScreen',
            userId: userId,
            stackTrace: stack.toString(),
            errorType: e.runtimeType.toString(),
            severity: 'error',
            contextData: {
              'categoryId': category.id,
              'name': category.name,
              'operation': 'delete',
            },
          );
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.failedToDeleteCategory)),
        );
      }
      setState(() => _isLoading = false);
      if (showUndo) {
        UndoSnackbar.show(
          context,
          message: loc.categoryDeleted,
          onUndo: () async {
            setState(() => _isLoading = true);
            try {
              await firestoreService.addCategory(franchiseId, category);
            } catch (e, stack) {
              try {
                await firestoreService.logError(
                  franchiseId,
                  message: e.toString(),
                  source: 'category_management_screen',
                  screen: 'CategoryManagementScreen',
                  userId: userId,
                  stackTrace: stack.toString(),
                  errorType: e.runtimeType.toString(),
                  severity: 'error',
                  contextData: {
                    'categoryId': category.id,
                    'name': category.name,
                    'operation': 'undo_restore',
                  },
                );
              } catch (_) {}
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.failedToRestoreCategory)),
              );
            }
            setState(() => _isLoading = false);
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.categoryDeleted)),
        );
      }
    }
  }

  Future<void> _bulkDeleteCategories() async {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    if (!_canManageCategories(context) || _isLoading || _bulkLoading) return;
    final loc = AppLocalizations.of(context)!;
    final userId =
        Provider.of<UserProfileNotifier?>(context, listen: false)?.user?.id;
    final selectedCats =
        _filteredCategories.where((c) => _selectedIds.contains(c.id)).toList();
    if (selectedCats.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.delete),
        content: Text(loc.deleteCategoryConfirm(
          loc.selectedCount(selectedCats.length),
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _bulkLoading = true);
      try {
        for (final c in selectedCats) {
          await firestoreService.deleteCategory(franchiseId, c.id);
        }
      } catch (e, stack) {
        try {
          await firestoreService.logError(
            franchiseId,
            message: e.toString(),
            source: 'category_management_screen',
            screen: 'CategoryManagementScreen',
            userId: userId,
            stackTrace: stack.toString(),
            errorType: e.runtimeType.toString(),
            severity: 'error',
            contextData: {
              'categoryIds': selectedCats.map((c) => c.id).toList(),
              'operation': 'bulk_delete',
            },
          );
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.failedToDeleteCategory)),
        );
      }
      setState(() {
        _bulkLoading = false;
        _selectedIds.clear();
      });
      UndoSnackbar.show(
        context,
        message: loc.categoryDeleted,
        onUndo: () async {
          setState(() => _bulkLoading = true);
          try {
            for (final c in selectedCats) {
              await firestoreService.addCategory(franchiseId, c);
            }
          } catch (e, stack) {
            try {
              await firestoreService.logError(
                franchiseId,
                message: e.toString(),
                source: 'category_management_screen',
                screen: 'CategoryManagementScreen',
                userId: userId,
                stackTrace: stack.toString(),
                errorType: e.runtimeType.toString(),
                severity: 'error',
                contextData: {
                  'categoryIds': selectedCats.map((c) => c.id).toList(),
                  'operation': 'undo_bulk_restore',
                },
              );
            } catch (_) {}
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.failedToRestoreCategory)),
            );
          }
          setState(() => _bulkLoading = false);
        },
      );
    }
  }

  void _showBulkUploadDialog() async {
    if (!_canManageCategories(context) || _isLoading || _bulkLoading) return;
    final uploaded = await showDialog<bool>(
      context: context,
      builder: (_) => const BulkUploadDialog(),
    );
    if (uploaded == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.bulkUploadSuccess)),
      );
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _filteredCategories = _allCategories
          .where(
              (c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
      // Deselect anything not visible
      _selectedIds
          .removeWhere((id) => !_filteredCategories.any((c) => c.id == id));
    });
  }

  void _onSort(String key, bool ascending) {
    setState(() {
      _sortKey = key;
      _sortAsc = ascending;
      _filteredCategories.sort((a, b) {
        int cmp = 0;
        switch (key) {
          case 'name':
            cmp = a.name.compareTo(b.name);
            break;
          case 'description':
            cmp = (a.description ?? '').compareTo(b.description ?? '');
            break;
          default:
            cmp = 0;
        }
        return ascending ? cmp : -cmp;
      });
    });
  }

  Widget buildCategoryHeaderRow(BuildContext context, bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: categoryColumns.map((col) {
          if (col["key"] == "select" && isDesktop) {
            return SizedBox(
              width: col["width"] as double,
              child: Checkbox(
                value: _filteredCategories.isNotEmpty &&
                    _selectedIds.length == _filteredCategories.length,
                onChanged: (checked) => _onSelectAll(checked),
                tristate: false,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                semanticLabel: AppLocalizations.of(context)!.bulkSelection,
              ),
            );
          } else if (col.containsKey("width")) {
            return SizedBox(
              width: col["width"] as double,
              child: Center(
                child: Text(
                  col["header"] as String? ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else {
            return Expanded(
              flex: col["flex"] as int,
              child: Text(
                col["header"] as String? ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }
        }).toList(),
      ),
    );
  }

  Widget buildCategoryDataRow(
      BuildContext context, Category category, bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: categoryColumns.map((col) {
        switch (col["key"]) {
          case "select":
            if (!isDesktop) return const SizedBox(width: 0);
            return SizedBox(
              width: col["width"] as double,
              child: Checkbox(
                value: _selectedIds.contains(category.id),
                onChanged: (checked) =>
                    _onCategorySelect(category.id, checked ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                semanticLabel: AppLocalizations.of(context)!.bulkSelection,
              ),
            );
          case "image":
            return SizedBox(
              width: col["width"] as double,
              child: Center(
                child: (category.image != null && category.image!.isNotEmpty)
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(category.image!),
                        radius: 20,
                      )
                    : CircleAvatar(
                        backgroundImage:
                            AssetImage(BrandingConfig.defaultCategoryIcon),
                        radius: 20,
                      ),
              ),
            );
          case "name":
            return Expanded(
              flex: col["flex"] as int,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
                child: Text(category.name),
              ),
            );
          case "description":
            return Expanded(
              flex: col["flex"] as int,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
                child: Text(category.description ?? ''),
              ),
            );
          case "actions":
            return SizedBox(
              width: col["width"] as double,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: colorScheme.secondary),
                    tooltip: AppLocalizations.of(context)!.edit,
                    onPressed: _isLoading || _bulkLoading
                        ? null
                        : () => _openCategoryDialog(category: category),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: colorScheme.error),
                    tooltip: AppLocalizations.of(context)!.delete,
                    onPressed: _isLoading || _bulkLoading
                        ? null
                        : () => _deleteCategory(category),
                  ),
                ],
              ),
            );
          default:
            return const SizedBox.shrink();
        }
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    final loc = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final colorScheme = Theme.of(context).colorScheme;

    if (!_canManageCategories(context)) {
      return UnauthorizedWidget(
        message: loc.unauthorizedAccessMessage,
        actionLabel: loc.returnHome,
        onHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: colorScheme.background,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main content column, matches MenuEditorScreen (flex: 11)
              Expanded(
                flex: 11,
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: section title & actions (like Menu Editor)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              loc.adminCategoryManagement,
                              style: TextStyle(
                                color: colorScheme.onBackground,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.upload_file,
                                  color: colorScheme.onBackground),
                              tooltip: loc.bulkUploadCategories,
                              onPressed: _isLoading || _bulkLoading
                                  ? null
                                  : _showBulkUploadDialog,
                            ),
                            IconButton(
                              icon: Icon(Icons.add,
                                  color: colorScheme.onBackground),
                              tooltip: loc.addCategory,
                              onPressed: _isLoading || _bulkLoading
                                  ? null
                                  : () => _openCategoryDialog(),
                            ),
                          ],
                        ),
                      ),
                      // Search bar
                      CategorySearchBar(
                        onChanged: _onSearch,
                        onSortChanged: (sortKey) =>
                            _onSort(sortKey ?? _sortKey, _sortAsc),
                        currentSort: _sortKey,
                        ascending: _sortAsc,
                        onSortDirectionToggle: () =>
                            _onSort(_sortKey, !_sortAsc),
                      ),
                      const SizedBox(height: 12),
                      // Bulk actions bar (desktop only)
                      if (!isMobile && _selectedIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: BulkActionBar(
                            selectedCount: _selectedIds.length,
                            onBulkDelete: _bulkDeleteCategories,
                            onClearSelection: () =>
                                setState(() => _selectedIds.clear()),
                          ),
                        ),
                      // Grid/List area
                      Expanded(
                        child: StreamBuilder<List<Category>>(
                          stream: firestoreService.getCategories(franchiseId),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return EmptyStateWidget(
                                title: loc.errorLoadingCategories,
                                message: loc.pleaseTryAgain,
                                imageAsset: BrandingConfig.bannerPlaceholder,
                                onRetry: () => setState(() {}),
                                buttonText: loc.retry,
                              );
                            }
                            _allCategories = snapshot.data ?? [];
                            _filteredCategories = _searchQuery.isEmpty
                                ? _allCategories
                                : _allCategories
                                    .where((c) => c.name
                                        .toLowerCase()
                                        .contains(_searchQuery.toLowerCase()))
                                    .toList();

                            // Deselect any no longer present
                            _selectedIds.removeWhere((id) =>
                                !_filteredCategories.any((c) => c.id == id));

                            if (_filteredCategories.isEmpty) {
                              return EmptyStateWidget(
                                title: loc.noCategoriesFound,
                                message: loc.noCategoriesMessage,
                                imageAsset: BrandingConfig.bannerPlaceholder,
                              );
                            }

                            // MOBILE VERSION (column based)
                            if (isMobile) {
                              return ListView.separated(
                                itemCount: _filteredCategories.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (ctx, idx) {
                                  final category = _filteredCategories[idx];
                                  return ListTile(
                                    leading: (category.image != null &&
                                            category.image!.isNotEmpty)
                                        ? CircleAvatar(
                                            backgroundImage:
                                                NetworkImage(category.image!),
                                            radius: 24,
                                          )
                                        : CircleAvatar(
                                            backgroundImage: AssetImage(
                                                BrandingConfig
                                                    .defaultCategoryIcon),
                                            radius: 24,
                                          ),
                                    title: Text(category.name),
                                    subtitle: (category.description != null &&
                                            category.description!.isNotEmpty)
                                        ? Text(category.description!)
                                        : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit,
                                              color: colorScheme.secondary),
                                          tooltip: loc.edit,
                                          onPressed: _isLoading || _bulkLoading
                                              ? null
                                              : () => _openCategoryDialog(
                                                  category: category),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete,
                                              color: colorScheme.error),
                                          tooltip: loc.delete,
                                          onPressed: _isLoading || _bulkLoading
                                              ? null
                                              : () => _deleteCategory(category),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }

                            // DESKTOP/TABLET VERSION (row based, aligned columns)
                            return Column(
                              children: [
                                buildCategoryHeaderRow(context, true),
                                const Divider(height: 1),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: _filteredCategories.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (ctx, idx) =>
                                        buildCategoryDataRow(ctx,
                                            _filteredCategories[idx], true),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Right panel placeholder, matches MenuEditorScreen (flex: 9)
              Expanded(
                flex: 9,
                child: Container(), // Future right panel
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : colorScheme.onPrimary,
            ),
            label: Text(
              loc.addCategory,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : colorScheme.onPrimary,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : colorScheme.primary,
            foregroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : colorScheme.onPrimary,
            onPressed:
                _isLoading || _bulkLoading ? null : () => _openCategoryDialog(),
            tooltip: loc.addCategory,
          ),
        ),
        if (_isLoading || _bulkLoading)
          Container(
            color: Colors.black.withOpacity(0.22),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
