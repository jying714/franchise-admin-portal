import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_sortable_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'category_form_dialog.dart';
import 'bulk_upload_dialog.dart';
import 'category_search_bar.dart';

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
  String _searchQuery = '';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    firestoreService = Provider.of<FirestoreService>(context, listen: false);
  }

  Future<void> _openCategoryDialog({Category? category}) async {
    await showDialog<Category>(
      context: context,
      builder: (_) => CategoryFormDialog(
        category: category,
        onSaved: (Category saved) async {
          setState(() => _isLoading = true);
          if (category == null) {
            await firestoreService.addCategory(saved);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(AppLocalizations.of(context)!.categoryAdded)),
            );
          } else {
            await firestoreService.updateCategory(saved);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(AppLocalizations.of(context)!.categoryUpdated)),
            );
          }
          setState(() => _isLoading = false);
        },
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteCategory),
        content: Text(
            AppLocalizations.of(context)!.deleteCategoryConfirm(category.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      await firestoreService.deleteCategory(category.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.categoryDeleted)),
      );
      setState(() => _isLoading = false);
    }
  }

  void _showBulkUploadDialog() async {
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
    });
  }

  // AdminGridSortCallback signature: (String key, bool ascending)
  void _onSort(String key, bool ascending) {
    setState(() {
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.adminCategoryManagement),
        backgroundColor: DesignTokens.primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.upload_file, color: DesignTokens.foregroundColor),
            tooltip: loc.bulkUploadCategories,
            onPressed: _showBulkUploadDialog,
          ),
          IconButton(
            icon: Icon(Icons.add, color: DesignTokens.foregroundColor),
            tooltip: loc.addCategory,
            onPressed: () => _openCategoryDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingShimmerWidget()
          : Padding(
              padding: DesignTokens.gridPadding,
              child: Column(
                children: [
                  // ---- SEARCH BAR ----
                  CategorySearchBar(
                    onChanged: _onSearch,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<List<Category>>(
                      stream: firestoreService.getCategories(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LoadingShimmerWidget();
                        }
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

                        if (_filteredCategories.isEmpty) {
                          return EmptyStateWidget(
                            title: loc.noCategoriesFound,
                            message: loc.noCategoriesMessage,
                            imageAsset: BrandingConfig.bannerPlaceholder,
                          );
                        }

                        return AdminSortableGrid<Category>(
                          items: _filteredCategories,
                          columns: [
                            loc.categoryName,
                            loc.categoryDescription,
                          ],
                          columnKeys: [
                            'name',
                            'description'
                          ], // <-- ADD THIS LINE
                          sortKeys: ['name', 'description'],
                          itemBuilder: (ctx, category) => ListTile(
                            leading: (category.image != null &&
                                    category.image!.isNotEmpty)
                                ? CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(category.image!),
                                    radius: 24,
                                  )
                                : CircleAvatar(
                                    backgroundImage: AssetImage(
                                        BrandingConfig.defaultCategoryIcon),
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
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blueGrey),
                                  tooltip: loc.edit,
                                  onPressed: () =>
                                      _openCategoryDialog(category: category),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  tooltip: loc.delete,
                                  onPressed: () => _deleteCategory(category),
                                ),
                              ],
                            ),
                          ),
                          onSort: _onSort,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
