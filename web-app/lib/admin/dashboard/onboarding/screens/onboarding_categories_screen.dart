import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../../../../../../packages/shared_core/lib/src/core/models/category.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/category_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/franchise_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/franchise_info_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/onboarding_progress_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import '../../../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';
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

  // Use _stagedForDelete and _showSelectAllBanner for robust staged delete/select-all.
  final Set<String> _stagedForDelete = {};
  bool _showSelectAllBanner = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) return;

    final franchiseId = context.read<FranchiseProvider>().franchiseId;

    if (franchiseId.isNotEmpty && franchiseId != 'unknown') {
      final provider = context.read<CategoryProvider>();

      // 🔹 Force reload from Firestore to ensure UI shows latest categories
      provider
          .loadCategories(
        franchiseId,
        forceReloadFromFirestore: true,
      )
          .then((_) {
        if (!mounted) return;
        debugPrint(
          '[OnboardingCategoriesScreen] ✅ Category reload complete. '
          'Count=${provider.categories.length}',
        );
        setState(() {}); // Trigger UI refresh after load
      });
    } else {
      debugPrint(
        '[OnboardingCategoriesScreen] ⚠️ Skipping load: blank/unknown franchiseId.',
      );
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
    if (_stagedForDelete.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.confirmDeletion),
        content: Text(loc.bulkDeleteConfirmation(_stagedForDelete.length)),
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
      final deletedCount = _stagedForDelete.length;

      try {
        await provider
            .bulkDeleteCategoriesFromFirestore(_stagedForDelete.toList());
        _stagedForDelete.clear();

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
            if (_showSelectAllBanner)
              Card(
                color: Colors.amber[100],
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          loc.selectAllPrompt, // Add to .arb
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.select_all),
                        label: Text(loc.selectAll), // Add to .arb
                        onPressed: () {
                          setState(() {
                            _stagedForDelete.clear();
                            _stagedForDelete.addAll(
                              provider.categories.map((c) => c.id),
                            );
                            _showSelectAllBanner = false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        child: Text(loc.cancel),
                        onPressed: () {
                          setState(() {
                            _showSelectAllBanner = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            if (_stagedForDelete.isNotEmpty)
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
                        _stagedForDelete.clear();
                      });
                    },
                    child: Text(loc.clearSelection),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '${_stagedForDelete.length} ${loc.toDelete}',
                    style: const TextStyle(color: Colors.red),
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
                            isSelected: _stagedForDelete.contains(cat.id),
                            onSelect: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _stagedForDelete.add(cat.id);
                                  if (_stagedForDelete.length == 1) {
                                    _showSelectAllBanner = true;
                                  }
                                } else {
                                  _stagedForDelete.remove(cat.id);
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
