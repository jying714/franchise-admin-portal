import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/franchise_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/menu_item_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/onboarding_progress_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import '../../../../../../packages/shared_core/lib/src/core/utils/features/feature_guard.dart';
import 'package:franchise_admin_portal/core/utils/features/feature_gate_banner.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_editor_sheet.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_items_list_tile.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_json_import_export_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_template_picker_dialog.dart';
import '../../../../../../packages/shared_core/lib/src/core/models/menu_item.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/ingredient_type_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/category_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/ingredient_metadata_provider.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/schema_issue_sidebar.dart';
import '../../../../../../packages/shared_core/lib/src/core/models/menu_item_schema_issue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingMenuItemsScreen extends StatefulWidget {
  const OnboardingMenuItemsScreen({super.key});

  @override
  State<OnboardingMenuItemsScreen> createState() =>
      _OnboardingMenuItemsScreenState();
}

class _OnboardingMenuItemsScreenState extends State<OnboardingMenuItemsScreen> {
  bool _hasInitialized = false;
  final Set<String> _selectedIds = {};
  bool showSchemaSidebar = false;
  List<MenuItemSchemaIssue> schemaIssues = [];
  MenuItem? itemPendingRepair;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) return;

    final franchiseId = context.read<FranchiseProvider>().franchiseId;
    if (franchiseId.isNotEmpty && franchiseId != 'unknown') {
      // Force reload all prerequisites so screen is always in sync
      context
          .read<IngredientTypeProvider>()
          .loadIngredientTypes(franchiseId, forceReloadFromFirestore: true);
      context
          .read<IngredientMetadataProvider>()
          .load(forceReloadFromFirestore: true);
      context
          .read<CategoryProvider>()
          .loadCategories(franchiseId, forceReloadFromFirestore: true);
      context
          .read<MenuItemProvider>()
          .loadMenuItems(franchiseId, forceReloadFromFirestore: true);
    }

    _hasInitialized = true;
  }

  Future<void> _markComplete() async {
    final onboarding = context.read<OnboardingProgressProvider>();
    final loc = AppLocalizations.of(context)!;

    try {
      await onboarding.markStepComplete('menu_items');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.menuItemMarkedAsComplete)),
        );
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'onboarding_mark_menu_item_complete_failed',
        source: 'onboarding_menu_items_screen.dart',
        screen: 'onboarding_menu_items_screen',
        severity: 'warning',
        stack: stack.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorGeneric)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[DEBUG][OnboardingMenuScreen] build called');
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<MenuItemProvider>();
    provider.injectDependencies(
      ingredientProvider: context.read<IngredientMetadataProvider>(),
      categoryProvider: context.read<CategoryProvider>(),
      typeProvider: context.read<IngredientTypeProvider>(),
    );
    // print(
    //     '[DEBUG] MenuItems in screen: ${provider.menuItems.map((m) => m.toJson())}');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // === Robust dependency checks for required onboarding steps ===
    final ingredientTypes =
        context.watch<IngredientTypeProvider>().ingredientTypes;
    final ingredients = context.watch<IngredientMetadataProvider>().ingredients;
    final categories = context.watch<CategoryProvider>().categories;

    final missingSteps = <String>[];
    if (ingredientTypes.isEmpty) missingSteps.add(loc.stepIngredientTypes);
    if (ingredients.isEmpty) missingSteps.add(loc.stepIngredients);
    if (categories.isEmpty) missingSteps.add(loc.stepCategories);

// If any dependencies are missing, return a clear EmptyState UI with actionable buttons
    if (missingSteps.isNotEmpty) {
      print(
          '[OnboardingMenuItemsScreen] Blocked: Missing dependencies: $missingSteps');
      // Show a SnackBar on first build, not every frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  loc.menuItemsMissingPrerequisites(missingSteps.join(', '))),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      });
      // Return an EmptyStateWidget that lists what to do next
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.onboardingMenuItems),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EmptyStateWidget(
                iconData: Icons.warning_amber_rounded,
                title: loc.missingMenuItemPrereqs,
                message:
                    loc.menuItemsMissingPrerequisites(missingSteps.join(', ')),
              ),
              const SizedBox(height: 24),
              if (ingredientTypes.isEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/dashboard?section=onboardingIngredientTypes',
                  ),
                  label: Text(loc.goToStep(loc.stepIngredientTypes)),
                ),
              if (ingredients.isEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.egg),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/dashboard?section=onboardingIngredients',
                  ),
                  label: Text(loc.goToStep(loc.stepIngredients)),
                ),
              if (categories.isEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.category),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/dashboard?section=onboardingCategories',
                  ),
                  label: Text(loc.goToStep(loc.stepCategories)),
                ),
            ],
          ),
        ),
      );
    }

    // Helper to check and maybe show schema sidebar
    void checkForSchemaIssues(MenuItem menuItem) {
      final categories = context.read<CategoryProvider>().categories;
      final ingredients =
          context.read<IngredientMetadataProvider>().ingredients;
      final ingredientTypes =
          context.read<IngredientTypeProvider>().ingredientTypes;

      // Call your schema issue detection util
      schemaIssues = MenuItemSchemaIssue.detectAllIssues(
        menuItem: menuItem,
        categories: categories,
        ingredients: ingredients,
        ingredientTypes: ingredientTypes,
      );
      showSchemaSidebar = schemaIssues.isNotEmpty;
      itemPendingRepair = showSchemaSidebar ? menuItem : null;
      if (showSchemaSidebar) setState(() {}); // Redraw for the sidebar
    }

    // Callback for repair sidebar
    void handleSidebarRepair(MenuItemSchemaIssue issue, String newValue) {
      if (itemPendingRepair == null) return;

      MenuItem repaired = itemPendingRepair!;

      // Repair logic for each issue type
      switch (issue.type) {
        case MenuItemSchemaIssueType.category:
          repaired = repaired.copyWith(categoryId: newValue);
          break;
        case MenuItemSchemaIssueType.ingredient:
          final updatedIncluded =
              (repaired.includedIngredients ?? []).map((ing) {
            if ((ing['ingredientId'] ?? ing['id']) == issue.missingReference) {
              return {...ing, 'ingredientId': newValue};
            }
            return ing;
          }).toList();
          repaired = repaired.copyWith(includedIngredients: updatedIncluded);
          break;
        case MenuItemSchemaIssueType.ingredientType:
          // (add your logic here as needed)
          break;
        case MenuItemSchemaIssueType.missingField:
          // Repair missing fields by field name
          switch (issue.field) {
            case 'name':
              repaired = repaired.copyWith(name: newValue);
              break;
            case 'description':
              repaired = repaired.copyWith(description: newValue);
              break;
            case 'price':
              repaired =
                  repaired.copyWith(price: double.tryParse(newValue) ?? 0.0);
              break;
            case 'categoryId':
              repaired = repaired.copyWith(categoryId: newValue);
              break;
            // Add additional fields as needed
          }
          break;
      }

      // Re-run issue detection after repairing this field
      final List<MenuItemSchemaIssue> remainingIssues =
          MenuItemSchemaIssue.detectAllIssues(
        menuItem: repaired,
        categories: context.read<CategoryProvider>().categories,
        ingredients: context.read<IngredientMetadataProvider>().allIngredients,
        ingredientTypes: context.read<IngredientTypeProvider>().ingredientTypes,
      );

      if (remainingIssues.isEmpty) {
        provider.addOrUpdateMenuItem(repaired);
        setState(() {
          showSchemaSidebar = false;
          schemaIssues = [];
          itemPendingRepair = null;
        });
        Navigator.of(context).pop(); // Close sidebar/modal if desired
      } else {
        setState(() {
          schemaIssues = remainingIssues;
          itemPendingRepair = repaired;
        });
      }
    }

    // Reusable openEditor with schema checking logic
    void openEditor({MenuItem? item}) {
      final provider = context.read<MenuItemProvider>();

      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          // locally track your issues in the sheet
          List<MenuItemSchemaIssue> issues = [];

          return StatefulBuilder(
            builder: (context, setModalState) {
              final screenWidth = MediaQuery.of(context).size.width;
              final modalWidth =
                  screenWidth > 1280 ? 1080.0 : screenWidth * 0.92;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: modalWidth,
                    maxHeight: MediaQuery.of(context).size.height * 0.98,
                  ),
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: MenuItemEditorSheet(
                            existing: item,
                            firestore: FirebaseFirestore.instance,
                            franchiseId:
                                context.read<FranchiseProvider>().franchiseId,
                            onSave: (updatedItem) async {
                              final provider = context.read<MenuItemProvider>();
                              provider.addOrUpdateMenuItem(
                                  updatedItem); // modifies local cache

                              if (mounted) {
                                Navigator.of(context).pop(); // dismiss sheet
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Item saved.')),
                                );
                              }
                            },
                            onCancel: () => Navigator.of(context).pop(),
                            onSchemaIssuesChanged: (newIssues) {
                              setModalState(() => issues = newIssues);
                            },
                          ),
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: Colors.grey.shade300,
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: issues.isEmpty ? 64 : 440,
                          child: SchemaIssueSidebar(
                            issues: issues,
                            onRepair: handleSidebarRepair,
                            onClose: () => setModalState(() => issues = []),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            title: Text(
              loc.onboardingMenuItems,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.data_object),
                tooltip: loc.importExport,
                onPressed: () => MenuItemJsonImportExportDialog.show(context),
              ),
              // IconButton(
              //   icon: const Icon(Icons.library_add),
              //   tooltip: loc.loadDefaultTemplates,
              //   onPressed: () => MenuItemTemplatePickerDialog.show(context),
              // ),
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: loc.markAsComplete,
                onPressed: _markComplete,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab-onboarding-menu-items',
            onPressed: () async {
              print('[DEBUG][FAB] FloatingActionButton pressed.');
              try {
                print(
                    '[DEBUG][FAB] About to navigate to /dashboard?section=menuItemEditor');

                Navigator.pushNamed(
                  context,
                  '/dashboard?section=menuItemEditor',
                ).then((result) {
                  print('[DEBUG][FAB] Navigation pushNamed returned: $result');
                  if (result is MenuItem) {
                    context
                        .read<MenuItemProvider>()
                        .addOrUpdateMenuItem(result);
                  }
                }).catchError((err, st) async {
                  print('[DEBUG][FAB] pushNamed threw error (async): $err');
                  await ErrorLogger.log(
                    message: 'Async error in pushNamed',
                    stack: st.toString(),
                    source: 'onboarding_menu_items_screen.dart',
                    severity: 'error',
                    screen: 'OnboardingMenuItemsScreen',
                    contextData: {'exception': err.toString()},
                  );
                });
              } catch (e, st) {
                print('[DEBUG][FAB] Exception thrown in navigation: $e\n$st');
                await ErrorLogger.log(
                  message: 'Failed to navigate to MenuItemEditorScreen (sync)',
                  stack: st.toString(),
                  source: 'onboarding_menu_items_screen.dart',
                  severity: 'error',
                  screen: 'OnboardingMenuItemsScreen',
                  contextData: {
                    'exception': e.toString(),
                  },
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'An error occurred while opening the menu item editor.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: Text(loc.addMenuItem),
            backgroundColor: DesignTokens.primaryColor,
          ),
          body: Padding(
            padding: DesignTokens.gridPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FeatureGateBanner(
                  module: 'menu_item_customization',
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    color: Colors.yellow.shade50,
                    alignment: Alignment.center,
                    child:
                        Text('Menu Item Customization is a premium feature.'),
                  ),
                ),
                if (provider.isDirty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final ingredientProvider =
                                context.read<IngredientMetadataProvider>();
                            final categoryProvider =
                                context.read<CategoryProvider>();
                            final typeProvider =
                                context.read<IngredientTypeProvider>();
                            final menuItemProvider =
                                context.read<MenuItemProvider>();

                            // Inject dependencies
                            menuItemProvider.injectDependencies(
                              ingredientProvider: ingredientProvider,
                              categoryProvider: categoryProvider,
                              typeProvider: typeProvider,
                            );
                            print('[DEBUG] --- Staged Data Snapshot ---');
                            print(
                                '[DEBUG] Staged Ingredients: ${ingredientProvider.stagedIngredientCount}');
                            print(
                                '[DEBUG] Staged Categories: ${categoryProvider.stagedCategoryCount}');
                            print(
                                '[DEBUG] Staged Ingredient Types: ${typeProvider.stagedTypes.length}');

                            // Call persist once deps injected
                            await menuItemProvider.persistChanges();
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
                  ),
                Expanded(
                  child: provider.menuItems.isEmpty
                      ? EmptyStateWidget(
                          title: loc.noMenuItemsFound,
                          message: loc.noMenuItemsMessage,
                        )
                      : ReorderableListView(
                          onReorder: (oldIndex, newIndex) {
                            final items = List.of(provider.menuItems);
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = items.removeAt(oldIndex);
                            items.insert(newIndex, item);
                            provider.reorderMenuItems(items);
                          },
                          children: [
                            for (final item in provider.menuItems)
                              MenuItemListTile(
                                key: ValueKey(item.id),
                                item: item,
                                isSelected: _selectedIds.contains(item.id),
                                onSelect: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedIds.add(item.id);
                                    } else {
                                      _selectedIds.remove(item.id);
                                    }
                                  });
                                },
                                onEdit: () => openEditor(item: item),
                                onDelete: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(loc.confirmDeletion),
                                      content: Text(
                                          loc.deleteMenuItemConfirm(item.name)),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text(loc.cancel),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: Text(loc.delete),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await provider.deleteFromFirestore(item.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(loc.menuItemDeleted),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
