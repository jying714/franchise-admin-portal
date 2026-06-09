import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/core/utils/features/feature_gate_banner.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_editor_sheet.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_items_list_tile.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_json_import_export_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_template_picker_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/schema_issue_sidebar.dart';
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
  List<shared.MenuItemSchemaIssue> schemaIssues = [];
  shared.MenuItem? itemPendingRepair;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final franchiseProvider = context.watch<shared.FranchiseProvider>();
    final franchiseId = franchiseProvider.franchiseId;

    if (franchiseId.isNotEmpty &&
        franchiseId != 'unknown' &&
        !_hasInitialized) {
      _hasInitialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        // Capture consistent instances once
        final typeProvider =
            Provider.of<shared.IngredientTypeProvider>(context, listen: false);
        final metadataProvider = Provider.of<shared.IngredientMetadataProvider>(
            context,
            listen: false);
        final categoryProvider =
            Provider.of<shared.CategoryProvider>(context, listen: false);
        final menuProvider =
            Provider.of<shared.MenuItemProvider>(context, listen: false);

        await Future.wait([
          typeProvider.load(
              franchiseIdOverride: franchiseId, forceReloadFromFirestore: true),
          metadataProvider.load(forceReloadFromFirestore: true),
          categoryProvider.load(
              franchiseIdOverride: franchiseId, forceReloadFromFirestore: true),
          menuProvider.load(
              franchiseIdOverride: franchiseId, forceReloadFromFirestore: true),
        ]);

        if (mounted)
          setState(() {}); // Force watches + missingSteps re-evaluation
      });
    }
  }

  Future<void> _markComplete() async {
    final onboarding =
        Provider.of<shared.OnboardingProgressProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    try {
      await onboarding.markStepComplete('menu_items');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.menuItemMarkedAsComplete)),
        );
      }
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'onboarding_mark_menu_item_complete_failed',
        source: 'onboarding_menu_items_screen.dart',
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
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // === Consistent listening providers (aligned with load instances) ===
    final ingredientTypes =
        context.watch<shared.IngredientTypeProvider>().ingredientTypes;
    final ingredients =
        context.watch<shared.IngredientMetadataProvider>().ingredients;
    final categories = context.watch<shared.CategoryProvider>().categories;
    final provider = context.watch<shared.MenuItemProvider>();

    // === Robust dependency checks ===
    final missingSteps = <String>[];
    if (ingredientTypes.isEmpty) missingSteps.add(loc.stepIngredientTypes);
    if (ingredients.isEmpty) missingSteps.add(loc.stepIngredients);
    if (categories.isEmpty) missingSteps.add(loc.stepCategories);

    if (missingSteps.isNotEmpty) {
      print(
          '[OnboardingMenuItemsScreen] Blocked: Missing dependencies: $missingSteps');
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

    // === Main Content (reached when all deps are populated) ===
    void checkForSchemaIssues(shared.MenuItem menuItem) {
      final categoriesLocal =
          Provider.of<shared.CategoryProvider>(context, listen: false)
              .categories;
      final ingredientsLocal =
          Provider.of<shared.IngredientMetadataProvider>(context, listen: false)
              .ingredients;
      final ingredientTypesLocal =
          Provider.of<shared.IngredientTypeProvider>(context, listen: false)
              .ingredientTypes;

      schemaIssues = shared.MenuItemSchemaIssue.detectAllIssues(
        menuItem: menuItem,
        categories: categoriesLocal,
        ingredients: ingredientsLocal,
        ingredientTypes: ingredientTypesLocal,
      );
      showSchemaSidebar = schemaIssues.isNotEmpty;
      itemPendingRepair = showSchemaSidebar ? menuItem : null;
      if (showSchemaSidebar) setState(() {});
    }

    void handleSidebarRepair(
        shared.MenuItemSchemaIssue issue, String newValue) {
      if (itemPendingRepair == null) return;

      shared.MenuItem repaired = itemPendingRepair!;

      switch (issue.type) {
        case shared.MenuItemSchemaIssueType.category:
          repaired = repaired.copyWith(categoryId: newValue);
          break;
        case shared.MenuItemSchemaIssueType.ingredient:
          final updatedIncluded =
              (repaired.includedIngredients ?? []).map((ing) {
            if ((ing['ingredientId'] ?? ing['id']) == issue.missingReference) {
              return {...ing, 'ingredientId': newValue};
            }
            return ing;
          }).toList();
          repaired = repaired.copyWith(includedIngredients: updatedIncluded);
          break;
        case shared.MenuItemSchemaIssueType.ingredientType:
          break;
        case shared.MenuItemSchemaIssueType.missingField:
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
          }
          break;
      }

      final List<shared.MenuItemSchemaIssue> remainingIssues =
          shared.MenuItemSchemaIssue.detectAllIssues(
        menuItem: repaired,
        categories: Provider.of<shared.CategoryProvider>(context, listen: false)
            .categories,
        ingredients: Provider.of<shared.IngredientMetadataProvider>(context,
                listen: false)
            .ingredients,
        ingredientTypes:
            Provider.of<shared.IngredientTypeProvider>(context, listen: false)
                .ingredientTypes,
      );

      if (remainingIssues.isEmpty) {
        provider.addOrUpdateMenuItem(repaired);
        setState(() {
          showSchemaSidebar = false;
          schemaIssues = [];
          itemPendingRepair = null;
        });
      } else {
        setState(() {
          schemaIssues = remainingIssues;
          itemPendingRepair = repaired;
        });
      }
    }

    void openEditor({shared.MenuItem? item}) {
      final menuProvider =
          Provider.of<shared.MenuItemProvider>(context, listen: false);

      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          List<shared.MenuItemSchemaIssue> issues = [];

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
                            franchiseId: Provider.of<shared.FranchiseProvider>(
                                    context,
                                    listen: false)
                                .franchiseId,
                            onSave: (updatedItem) async {
                              menuProvider.addOrUpdateMenuItem(updatedItem);
                              if (mounted) {
                                Navigator.of(context).pop();
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
                Navigator.pushNamed(
                  context,
                  '/dashboard?section=menuItemEditor',
                ).then((result) {
                  print('[DEBUG][FAB] Navigation pushNamed returned: $result');
                  if (result is shared.MenuItem) {
                    Provider.of<shared.MenuItemProvider>(context, listen: false)
                        .addOrUpdateMenuItem(result);
                  }
                }).catchError((err, st) async {
                  print('[DEBUG][FAB] pushNamed threw error (async): $err');
                  shared.ErrorLogger.log(
                    message: 'Async error in pushNamed',
                    stack: st.toString(),
                    source: 'onboarding_menu_items_screen.dart',
                    severity: 'error',
                    contextData: {'exception': err.toString()},
                  );
                });
              } catch (e, st) {
                print('[DEBUG][FAB] Exception thrown in navigation: $e\n$st');
                shared.ErrorLogger.log(
                  message: 'Failed to navigate to MenuItemEditorScreen (sync)',
                  stack: st.toString(),
                  source: 'onboarding_menu_items_screen.dart',
                  severity: 'error',
                  contextData: {'exception': e.toString()},
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
                                Provider.of<shared.IngredientMetadataProvider>(
                                    context,
                                    listen: false);
                            final categoryProvider =
                                Provider.of<shared.CategoryProvider>(context,
                                    listen: false);
                            final typeProvider =
                                Provider.of<shared.IngredientTypeProvider>(
                                    context,
                                    listen: false);
                            final menuItemProvider =
                                Provider.of<shared.MenuItemProvider>(context,
                                    listen: false);

                            print('[DEBUG] --- Staged Data Snapshot ---');
                            print(
                                '[DEBUG] Staged Ingredients: ${ingredientProvider.stagedIngredientCount}');
                            print(
                                '[DEBUG] Staged Categories: ${categoryProvider.stagedCategoryCount}');
                            print(
                                '[DEBUG] Staged Ingredient Types: ${typeProvider.stagedTypes.length}');

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
                                    provider.deleteMenuItem(item.id);
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
