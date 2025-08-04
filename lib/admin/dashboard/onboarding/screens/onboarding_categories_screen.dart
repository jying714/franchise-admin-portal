import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:franchise_admin_portal/core/providers/category_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_info_provider.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_progress_provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/categories/category_list_tile.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/categories/category_form_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/categories/category_json_import_export_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/categories/categories_template_picker_dialog.dart';

class OnboardingCategoriesScreen extends StatefulWidget {
  const OnboardingCategoriesScreen({super.key});

  @override
  State<OnboardingCategoriesScreen> createState() =>
      _OnboardingCategoriesScreenState();
}

class _OnboardingCategoriesScreenState
    extends State<OnboardingCategoriesScreen> {
  bool _hasInitialized = false;
  final Set<String> _selectedIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) return;

    final franchiseId = context.read<FranchiseProvider>().franchiseId;
    final firestore = context.read<FirestoreService>();

    if (franchiseId.isNotEmpty && franchiseId != 'unknown') {
      final provider = context.read<CategoryProvider>();
      provider.loadCategories();
    }

    _hasInitialized = true;
  }

  Future<void> _openCategoryForm([Category? category]) async {
    final loc = AppLocalizations.of(context)!;
    final franchiseId = context.read<FranchiseProvider>().franchiseId;

    final result = await CategoryFormDialog.show(
      parentContext: context,
      initialCategory: category,
      franchiseId: franchiseId,
    );

    if (result != null) {
      context.read<CategoryProvider>().addOrUpdateCategory(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.categorySaved)),
      );
    }
  }

  Future<void> _openImportExportDialog() async {
    final loc = AppLocalizations.of(context)!;
    await CategoryJsonImportExportDialog.show(context);
  }

  Future<void> _markComplete() async {
    final onboarding = context.read<OnboardingProgressProvider>();
    final loc = AppLocalizations.of(context)!;

    final isCompleted = onboarding.isStepComplete('categories');

    try {
      if (isCompleted) {
        await onboarding.markStepIncomplete('categories');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.stepMarkedIncomplete)),
          );
        }
      } else {
        await onboarding.markStepComplete('categories');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.stepMarkedComplete)),
          );
        }
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'onboarding_mark_complete_toggle_failed',
        source: 'onboarding_categories_screen.dart',
        screen: 'onboarding_categories_screen',
        severity: 'warning',
        stack: stack.toString(),
        contextData: {'step': 'categories'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorGeneric)),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    final loc = AppLocalizations.of(context)!;
    final provider = context.read<CategoryProvider>();
    final onboarding = context.read<OnboardingProgressProvider>();
    final franchiseId = context.read<FranchiseProvider>().franchiseId;

    try {
      await provider.saveCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.saveSuccessful)),
        );
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to save categories',
        source: 'onboarding_categories_screen.dart',
        screen: 'onboarding_categories_screen',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.saveFailed)),
        );
      }
    }
  }

  Future<void> _confirmBulkDelete() async {
    final loc = AppLocalizations.of(context)!;
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.confirmDeletion),
        content: Text(loc.bulkDeleteConfirmation(_selectedIds.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<CategoryProvider>();
      final deletedCount = _selectedIds.length;

      try {
        await provider.bulkDeleteCategoriesFromFirestore(_selectedIds.toList());
        _selectedIds.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.bulkDeleteSuccess(deletedCount))),
          );
        }
      } catch (e, stack) {
        await ErrorLogger.log(
          message: 'bulk_delete_categories_failed',
          stack: stack.toString(),
          source: 'OnboardingCategoriesScreen',
          screen: 'onboarding_categories_screen',
          severity: 'error',
          contextData: {'selectedCount': deletedCount},
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.errorGeneric)),
          );
        }
      }
      setState(() {}); // Refresh UI selection state
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<CategoryProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          loc.onboardingCategories,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.data_object),
            tooltip: loc.importExportCategories,
            onPressed: _openImportExportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.library_add),
            tooltip: loc.selectCategoryTemplate,
            onPressed: () async {
              await CategoriesTemplatePickerDialog.show(
                  context); // this is the screen context, not the dialog's context
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: loc.markAsComplete,
            onPressed: _markComplete,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'onboarding_categories_fab',
        onPressed: () => _openCategoryForm(),
        icon: const Icon(Icons.add),
        label: Text(loc.addCategory),
        backgroundColor: DesignTokens.primaryColor,
      ),
      body: Padding(
        padding: DesignTokens.gridPadding,
        child: Column(
          children: [
            if (provider.isDirty)
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _saveChanges,
                    child: Text(loc.saveChanges),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: provider.revertChanges,
                    child: Text(loc.revertChanges),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            if (_selectedIds.isNotEmpty)
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever),
                    label: Text(loc.deleteSelected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: _confirmBulkDelete,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedIds.clear();
                      });
                    },
                    child: Text(loc.clearSelection),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Expanded(
              child: provider.categories.isEmpty
                  ? EmptyStateWidget(
                      title: loc.noCategoriesFound,
                      message: loc.noCategoriesMessage,
                    )
                  : ReorderableListView(
                      onReorder: (oldIndex, newIndex) {
                        provider.reorderCategories(oldIndex, newIndex);
                      },
                      children: [
                        for (final cat in provider.categories)
                          CategoryListTile(
                            key: ValueKey(cat.id),
                            category: cat,
                            isSelected: _selectedIds.contains(cat.id),
                            onSelect: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedIds.add(cat.id);
                                } else {
                                  _selectedIds.remove(cat.id);
                                }
                              });
                            },
                            onEdit: () => _openCategoryForm(cat),
                            onDelete: () async {
                              final provider = context.read<CategoryProvider>();
                              final loc = AppLocalizations.of(context)!;
                              final scaffold = ScaffoldMessenger.of(context);

                              try {
                                await provider.deleteCategory(cat.id);
                                scaffold.showSnackBar(
                                  SnackBar(content: Text(loc.categoryDeleted)),
                                );
                              } catch (_) {
                                scaffold.showSnackBar(
                                  SnackBar(content: Text(loc.errorGeneric)),
                                );
                              }
                            },
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
