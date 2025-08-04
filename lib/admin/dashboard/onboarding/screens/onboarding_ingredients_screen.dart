import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/ingredient_metadata_template_picker_dialog.dart';
import 'package:franchise_admin_portal/core/models/ingredient_metadata.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_progress_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_info_provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/ingredient_form_card.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/ingredient_list_tile.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/ingredient_metadata_json_import_export_dialog.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider.dart';

class OnboardingIngredientsScreen extends StatefulWidget {
  const OnboardingIngredientsScreen({super.key});

  @override
  State<OnboardingIngredientsScreen> createState() =>
      _OnboardingIngredientsScreenState();
}

class _OnboardingIngredientsScreenState
    extends State<OnboardingIngredientsScreen> {
  late AppLocalizations loc;
  bool _hasInitialized = false;

  // Set to track selected ingredients for bulk actions
  final Set<String> _selectedIngredientIds = {};

  void _openIngredientForm([IngredientMetadata? ingredient]) {
    final loc = AppLocalizations.of(context);
    final provider =
        Provider.of<IngredientMetadataProvider>(context, listen: false);

    if (loc == null) {
      print('[OnboardingIngredientsScreen] ERROR: loc is null in FAB');
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Get the providers from the parent context
        final ingredientProvider =
            Provider.of<IngredientMetadataProvider>(context, listen: false);
        final typeProvider =
            Provider.of<IngredientTypeProvider>(context, listen: false);

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<IngredientMetadataProvider>.value(
                value: ingredientProvider),
            ChangeNotifierProvider<IngredientTypeProvider>.value(
                value: typeProvider),
          ],
          child: IngredientFormCard(
            initialData: ingredient,
            onSaved: () {
              Navigator.of(dialogContext).pop();
            },
            loc: loc,
            parentContext: context,
          ),
        );
      },
    );
  }

  Future<void> _markComplete() async {
    final provider = context.read<IngredientMetadataProvider>();
    final onboardingProvider = context.read<OnboardingProgressProvider>();

    if (provider.ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseAddIngredientTypesFirst)),
      );
      return;
    }

    final isCompleted = onboardingProvider.isStepComplete('ingredients');

    try {
      if (isCompleted) {
        await onboardingProvider.markStepIncomplete('ingredients');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.stepMarkedIncomplete)),
          );
        }
      } else {
        await onboardingProvider.markStepComplete('ingredients');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.stepMarkedComplete)),
          );
        }
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to toggle onboarding step completion',
        stack: stack.toString(),
        source: '_markComplete',
        screen: 'onboarding_ingredients_screen',
        severity: 'error',
        contextData: {'ingredientsCount': provider.ingredients.length},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorGeneric)),
        );
      }
    }
  }

  Future<void> _confirmBulkDelete() async {
    if (_selectedIngredientIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.confirmDeletion),
        content: Text(
          loc.bulkDeleteConfirmation(_selectedIngredientIds.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<IngredientMetadataProvider>();
      final deletedCount =
          _selectedIngredientIds.length; // Capture before clearing

      try {
        // Delete from Firestore and reload provider data
        await provider.bulkDeleteIngredientsFromFirestore(
            _selectedIngredientIds.toList());

        // Explicitly reload provider so UI updates
        await provider.load();

        // Clear selection BEFORE showing snackbar so count is accurate
        _selectedIngredientIds.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.bulkDeleteSuccess(deletedCount)),
            ),
          );
        }
      } catch (e, stack) {
        await ErrorLogger.log(
          message: 'Bulk delete ingredients failed',
          source: 'OnboardingIngredientsScreen',
          screen: 'onboarding_ingredients_screen',
          severity: 'error',
          stack: stack.toString(),
          contextData: {'selectedCount': deletedCount},
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.errorGeneric)),
          );
        }
      }
      setState(() {}); // Refresh UI after clearing selections and loading data
    }
  }

  void _toggleSelectAll(
      List<IngredientMetadata> allIngredients, bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedIngredientIds.addAll(allIngredients.map((e) => e.id));
      } else {
        _selectedIngredientIds.clear();
      }
    });
  }

  void _toggleSelection(String ingredientId, bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedIngredientIds.add(ingredientId);
      } else {
        _selectedIngredientIds.remove(ingredientId);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) return;

    // Just trigger load on the existing provider in the tree
    final provider = context.read<IngredientMetadataProvider>();
    provider.load();

    _hasInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    try {
      final p = Provider.of<IngredientMetadataProvider>(context, listen: false);
      print(
          '[OnboardingIngredientsScreen] build() provider hashCode=${p.hashCode}');
    } catch (e) {
      print('[OnboardingIngredientsScreen] build() NO PROVIDER: $e');
    }
    loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<IngredientMetadataProvider>();
    print(
        '[OnboardingIngredientsScreen] build() provider hashCode=${provider.hashCode}');
    print(
        '[Screen] build: provider.ingredients.length = ${provider.ingredients.length}');

    final groupedIngredients = provider.groupedIngredients;
    final allIngredientsFlat = provider.ingredients;

    final allSelected =
        _selectedIngredientIds.length == allIngredientsFlat.length &&
            allIngredientsFlat.isNotEmpty;
    final someSelected = _selectedIngredientIds.isNotEmpty && !allSelected;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: loc.back,
        ),
        title: Text(
          loc.onboardingIngredients,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.data_object),
              tooltip: loc.importExport,
              onPressed: () {
                final provider = Provider.of<IngredientMetadataProvider>(
                    context,
                    listen: false);
                IngredientMetadataJsonImportExportDialog.show(
                    context, provider);
              },
            ),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.library_add),
              tooltip: loc.selectIngredientTemplate,
              onPressed: () =>
                  IngredientMetadataTemplatePickerDialog.show(context),
            ),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: loc.markAsComplete,
              onPressed: _markComplete,
            ),
          ),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final loc = AppLocalizations.of(context);
          if (loc == null) {
            debugPrint(
                '[OnboardingIngredientsScreen] ERROR: loc is null in FAB');
            return const SizedBox.shrink(); // Prevents crash
          }

          return FloatingActionButton.extended(
            onPressed: () => _openIngredientForm(),
            icon: const Icon(Icons.add),
            label: Text(loc.addIngredient),
            backgroundColor: DesignTokens.primaryColor,
            heroTag: 'onboarding_ingredients_fab',
          );
        },
      ),
      body: Padding(
        padding: DesignTokens.gridPadding,
        child: Column(
          children: [
            if (provider.isDirty)
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final franchiseId =
                          context.read<FranchiseProvider>().franchiseId;
                      final metadataProvider =
                          context.read<IngredientMetadataProvider>();
                      final onboardingProvider =
                          context.read<OnboardingProgressProvider>();

                      try {
                        await metadataProvider.saveAllChanges(franchiseId);
                        await onboardingProvider
                            .markStepComplete('ingredients');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.saveSuccessful)),
                        );
                      } catch (e, stack) {
                        await ErrorLogger.log(
                          message: 'ingredient_save_error',
                          stack: stack.toString(),
                          source: 'onboarding_ingredients_screen',
                          screen: 'onboarding_ingredients_screen',
                          severity: 'error',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.saveFailed)),
                        );
                      }
                    },
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

            // --- Grouping & Sorting Controls ---
            Row(
              children: [
                Text(loc.groupBy + ': '),
                DropdownButton<String?>(
                  value: provider.groupByKey,
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem(value: null, child: Text('None')),
                    DropdownMenuItem(value: 'type', child: Text(loc.type)),
                    DropdownMenuItem(value: 'typeId', child: Text(loc.typeId)),
                  ],
                  onChanged: (val) {
                    provider.groupByKey = val;
                  },
                ),
                const SizedBox(width: 24),
                Text(loc.sortBy + ': '),
                DropdownButton<String>(
                  value: provider.sortKey,
                  items: [
                    DropdownMenuItem(value: 'name', child: Text(loc.name)),
                    DropdownMenuItem(
                        value: 'description', child: Text(loc.description)),
                    DropdownMenuItem(value: 'type', child: Text(loc.type)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      provider.sortKey = val;
                    }
                  },
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: provider.ascending ? loc.ascending : loc.descending,
                  icon: Icon(
                    provider.ascending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                  ),
                  onPressed: () {
                    provider.ascending = !provider.ascending;
                  },
                )
              ],
            ),

            const SizedBox(height: 12),

            if (_selectedIngredientIds.isNotEmpty)
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
                        _selectedIngredientIds.clear();
                      });
                    },
                    child: Text(loc.clearSelection),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            Expanded(
              child: provider.ingredients.isEmpty
                  ? EmptyStateWidget(
                      title: loc.noIngredientsFound,
                      message: loc.noIngredientsMessage,
                    )
                  : ListView(
                      children: groupedIngredients.entries.map((entry) {
                        final groupName = entry.key ?? loc.ungrouped;
                        final groupItems = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: groupItems.every((item) =>
                                        _selectedIngredientIds
                                            .contains(item.id)),
                                    onChanged: (checked) {
                                      setState(() {
                                        for (final item in groupItems) {
                                          if (checked == true) {
                                            _selectedIngredientIds.add(item.id);
                                          } else {
                                            _selectedIngredientIds
                                                .remove(item.id);
                                          }
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    groupName,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...groupItems.map((item) => IngredientListTile(
                                  ingredient: item,
                                  franchiseId: provider.franchiseId,
                                  onEdited: () => _openIngredientForm(item),
                                  onRefresh: () => provider.load(),
                                )),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
