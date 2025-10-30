import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_portal/core/models/category.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:admin_portal/config/branding_config.dart';
import 'package:admin_portal/widgets/empty_state_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/core/providers/franchise_provider.dart';
import 'package:admin_portal/core/providers/user_profile_notifier.dart';
import 'package:admin_portal/core/utils/user_permissions.dart';
import 'package:admin_portal/core/providers/role_guard.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:admin_portal/widgets/subscription_access_guard.dart';
import 'package:admin_portal/admin/hq_owner/widgets/active_plan_banner.dart';
import 'package:admin_portal/widgets/subscription/grace_period_banner.dart';
import 'category_form_dialog.dart';
import 'bulk_upload_dialog.dart';
import 'category_search_bar.dart';
import 'bulk_action_bar.dart';
import 'unauthorized_widget.dart';
import 'undo_snackbar.dart';

const categoryColumns = [
  {"key": "select", "width": 40.0, "header": ""},
  {"key": "image", "width": 56.0, "header": ""},
  {"key": "name", "flex": 3, "header": "Category Name"},
  {"key": "description", "flex": 5, "header": "Description (optional)"},
  {"key": "actions", "width": 96.0, "header": ""},
];

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requireAnyRole: [
        'platform_owner',
        'hq_owner',
        'manager',
        'developer',
        'admin',
      ],
      featureName: 'category_management_screen',
      screen: 'CategoryManagementScreen',
      child: const CategoryManagementScreenContent(),
    );
  }
}

class CategoryManagementScreenContent extends StatefulWidget {
  const CategoryManagementScreenContent({super.key});

  @override
  State<CategoryManagementScreenContent> createState() =>
      _CategoryManagementScreenContentState();
}

class _CategoryManagementScreenContentState
    extends State<CategoryManagementScreenContent> {
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

  bool get _canManage {
    final user = Provider.of<UserProfileNotifier>(context, listen: false).user;
    return UserPermissions.canManageCategories(user);
  }

  void _onCategorySelect(String id, bool selected) {
    setState(() {
      selected ? _selectedIds.add(id) : _selectedIds.remove(id);
    });
  }

  void _onSelectAll(bool? checked) {
    setState(() {
      _selectedIds =
          checked == true ? _filteredCategories.map((c) => c.id).toSet() : {};
    });
  }

  Future<void> _openCategoryDialog({Category? category}) async {
    final franchiseId = context.read<FranchiseProvider>().franchiseId;
    if (!_canManage || _isLoading || _bulkLoading) return;

    await showDialog<Category>(
      context: context,
      builder: (_) => CategoryFormDialog(
        franchiseId: franchiseId, // ✅ REQUIRED FIX
        category: category,
        onSaved: (Category saved) async {
          setState(() => _isLoading = true);
          final userId =
              Provider.of<UserProfileNotifier?>(context, listen: false)
                  ?.user
                  ?.id;
          try {
            if (category == null) {
              await firestoreService.addCategory(
                franchiseId: franchiseId,
                category: saved,
              );
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
            await ErrorLogger.log(
              message: e.toString(),
              stack: stack.toString(),
              source: 'category_management_screen',
              screen: 'CategoryManagementScreen',
              contextData: {
                'franchiseId': franchiseId,
                'userId': userId,
                'categoryId': category?.id ?? 'new',
                'name': saved.name,
                'image': saved.image,
                'description': saved.description,
                'operation': category == null ? 'add' : 'update',
              },
            );
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
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    if (!_canManage || _isLoading || _bulkLoading) return;
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
              child: Text(loc.cancel)),
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
        await firestoreService.deleteCategory(
          franchiseId: franchiseId,
          categoryId: category.id,
        );
      } catch (e, stack) {
        await ErrorLogger.log(
          message: e.toString(),
          stack: stack.toString(),
          source: 'category_management_screen',
          screen: 'CategoryManagementScreen',
          contextData: {
            'franchiseId': franchiseId,
            'userId': userId,
            'categoryId': category.id,
            'name': category.name,
            'operation': 'delete',
          },
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.failedToDeleteCategory)));
      }
      setState(() => _isLoading = false);
      if (showUndo) {
        UndoSnackbar.show(
          context,
          message: loc.categoryDeleted,
          onUndo: () async {
            setState(() => _isLoading = true);
            try {
              await firestoreService.addCategory(
                franchiseId: franchiseId,
                category: category,
              );
            } catch (e, stack) {
              await ErrorLogger.log(
                message: e.toString(),
                stack: stack.toString(),
                source: 'category_management_screen',
                screen: 'CategoryManagementScreen',
                contextData: {
                  'franchiseId': franchiseId,
                  'userId': userId,
                  'categoryId': category.id,
                  'name': category.name,
                  'operation': 'undo_restore',
                },
              );
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.failedToRestoreCategory)));
            }
            setState(() => _isLoading = false);
          },
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.categoryDeleted)));
      }
    }
  }

  void _showBulkUploadDialog() async {
    if (!_canManage || _isLoading || _bulkLoading) return;
    final franchiseId = context.read<FranchiseProvider>().franchiseId;

    final uploaded = await showDialog<bool>(
      context: context,
      builder: (_) => BulkUploadDialog(franchiseId: franchiseId),
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
          .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _selectedIds
          .removeWhere((id) => !_filteredCategories.any((c) => c.id == id));
    });
  }

  void _onSort(String key, bool ascending) {
    setState(() {
      _sortKey = key;
      _sortAsc = ascending;
      _filteredCategories.sort((a, b) {
        final cmp = switch (key) {
          'name' => a.name.compareTo(b.name),
          'description' => (a.description ?? '').compareTo(b.description ?? ''),
          _ => 0,
        };
        return ascending ? cmp : -cmp;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    final loc = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        SubscriptionAccessGuard(
          child: Scaffold(
            backgroundColor: colorScheme.background,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 11,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GracePeriodBanner(),
                        Row(
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
                        const SizedBox(height: 12),
                        CategorySearchBar(
                          onChanged: _onSearch,
                          onSortChanged: (sortKey) =>
                              _onSort(sortKey ?? _sortKey, _sortAsc),
                          currentSort: _sortKey,
                          ascending: _sortAsc,
                          onSortDirectionToggle: () =>
                              _onSort(_sortKey, !_sortAsc),
                        ),
                        if (!isMobile && _selectedIds.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: BulkActionBar(
                              selectedCount: _selectedIds.length,
                              onBulkDelete: () {},
                              onClearSelection: () =>
                                  setState(() => _selectedIds.clear()),
                            ),
                          ),
                        const SizedBox(height: 12),
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
                              _selectedIds.removeWhere((id) =>
                                  !_filteredCategories.any((c) => c.id == id));

                              if (_filteredCategories.isEmpty) {
                                return EmptyStateWidget(
                                  title: loc.noCategoriesFound,
                                  message: loc.noCategoriesMessage,
                                  imageAsset: BrandingConfig.bannerPlaceholder,
                                );
                              }

                              return isMobile
                                  ? ListView.separated(
                                      itemCount: _filteredCategories.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(height: 1),
                                      itemBuilder: (ctx, idx) {
                                        final category =
                                            _filteredCategories[idx];
                                        return ListTile(
                                          leading: (category
                                                      .image?.isNotEmpty ??
                                                  false)
                                              ? CircleAvatar(
                                                  backgroundImage: NetworkImage(
                                                      category.image!),
                                                  radius: 24,
                                                )
                                              : CircleAvatar(
                                                  backgroundImage: AssetImage(
                                                      BrandingConfig
                                                          .defaultCategoryIcon),
                                                  radius: 24,
                                                ),
                                          title: Text(category.name),
                                          subtitle: (category.description
                                                      ?.isNotEmpty ??
                                                  false)
                                              ? Text(category.description!)
                                              : null,
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit,
                                                    color:
                                                        colorScheme.secondary),
                                                tooltip: loc.edit,
                                                onPressed: _isLoading ||
                                                        _bulkLoading
                                                    ? null
                                                    : () => _openCategoryDialog(
                                                        category: category),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete,
                                                    color: colorScheme.error),
                                                tooltip: loc.delete,
                                                onPressed:
                                                    _isLoading || _bulkLoading
                                                        ? null
                                                        : () => _deleteCategory(
                                                            category),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    )
                                  : Column(
                                      children: [
                                        buildCategoryHeaderRow(context, true),
                                        const Divider(height: 1),
                                        Expanded(
                                          child: ListView.separated(
                                            itemCount:
                                                _filteredCategories.length,
                                            separatorBuilder: (_, __) =>
                                                const Divider(height: 1),
                                            itemBuilder: (ctx, idx) =>
                                                buildCategoryDataRow(
                                                    ctx,
                                                    _filteredCategories[idx],
                                                    true),
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
                Expanded(flex: 9, child: Container()),
              ],
            ),
          ),
        ),
        if (_isLoading || _bulkLoading)
          Container(
            color: Colors.black.withOpacity(0.22),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
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
                semanticLabel: AppLocalizations.of(context)!.bulkSelection,
              ),
            );
          } else if (col.containsKey("width")) {
            return SizedBox(
              width: col["width"] as double,
              child: Center(
                child: Text(col["header"] as String? ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          } else {
            return Expanded(
              flex: col["flex"] as int,
              child: Text(col["header"] as String? ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
              ),
            );
          case "image":
            return SizedBox(
              width: col["width"] as double,
              child: Center(
                child: category.image != null && category.image!.isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(category.image!),
                        radius: 20)
                    : CircleAvatar(
                        backgroundImage:
                            AssetImage(BrandingConfig.defaultCategoryIcon),
                        radius: 20),
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
}
