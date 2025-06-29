import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'category_form_dialog.dart';
import 'bulk_upload_dialog.dart';
import 'category_search_bar.dart';

const categoryColumns = [
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

  Widget buildCategoryHeaderRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: categoryColumns.map((col) {
          if (col.containsKey("width")) {
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

  Widget buildCategoryDataRow(BuildContext context, Category category) {
    return Row(
      children: categoryColumns.map((col) {
        switch (col["key"]) {
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
                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                    tooltip: AppLocalizations.of(context)!.edit,
                    onPressed: () => _openCategoryDialog(category: category),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: AppLocalizations.of(context)!.delete,
                    onPressed: () => _deleteCategory(category),
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
    final loc = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
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
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.upload_file,
                              color: Colors.black87),
                          tooltip: loc.bulkUploadCategories,
                          onPressed: _showBulkUploadDialog,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.black87),
                          tooltip: loc.addCategory,
                          onPressed: () => _openCategoryDialog(),
                        ),
                      ],
                    ),
                  ),
                  // Search bar
                  CategorySearchBar(
                    onChanged: _onSearch,
                  ),
                  const SizedBox(height: 12),
                  // Grid/List area
                  Expanded(
                    child: StreamBuilder<List<Category>>(
                      stream: firestoreService.getCategories(),
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
                                      onPressed: () => _openCategoryDialog(
                                          category: category),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      tooltip: loc.delete,
                                      onPressed: () =>
                                          _deleteCategory(category),
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
                            buildCategoryHeaderRow(context),
                            const Divider(height: 1),
                            Expanded(
                              child: ListView.separated(
                                itemCount: _filteredCategories.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (ctx, idx) => buildCategoryDataRow(
                                    ctx, _filteredCategories[idx]),
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
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.addCategory),
        backgroundColor: DesignTokens.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _openCategoryDialog(),
      ),
    );
  }
}
