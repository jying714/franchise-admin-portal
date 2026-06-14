import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/core/utils/features/feature_gate_banner.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_editor_sheet.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_items_list_tile.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_json_import_export_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_template_picker_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/schema_issue_sidebar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/admin/dashboard/admin_dashboard_screen.dart';
import 'package:franchise_admin_portal/config/ui_config.dart';

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
  bool _isEditing = false;
  shared.MenuItem? _editingItem;
  List<shared.MenuItemSchemaIssue> _inlineSchemaIssues = [];

  // GlobalKey for direct access to sheet repair method
  final GlobalKey<MenuItemEditorSheetState> _editorKey =
      GlobalKey<MenuItemEditorSheetState>();

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

        final typeProvider =
            Provider.of<shared.IngredientTypeProvider>(context, listen: false);
        final metadataProvider = Provider.of<shared.IngredientMetadataProvider>(
            context,
            listen: false);
        final categoryProvider =
            Provider.of<shared.CategoryProvider>(context, listen: false);
        final menuProvider =
            Provider.of<shared.MenuItemProvider>(context, listen: false);

        print(
            '[OnboardingMenuItemsScreen] Forcing dependency reload for franchise: $franchiseId');

        await Future.wait([
          typeProvider.load(
              franchiseIdOverride: franchiseId, forceReloadFromFirestore: true),
          metadataProvider.load(forceReloadFromFirestore: true),
          categoryProvider.load(
              franchiseIdOverride: franchiseId, forceReloadFromFirestore: true),
          menuProvider.load(
              franchiseIdOverride: franchiseId, forceReloadFromFirestore: true),
        ]);

        if (mounted) setState(() {});
      });
    }
  }

  void _navigateToSection(String sectionKey) {
    final dashboardState =
        context.findAncestorStateOfType<State<AdminDashboardScreen>>();
    if (dashboardState != null) {
      (dashboardState as dynamic).switchToSection(sectionKey);
    } else {
      Navigator.pushNamed(context, '/admin/dashboard?section=$sectionKey');
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
          SnackBar(
              content:
                  Text(loc.menuItemMarkedAsComplete ?? 'Step marked complete')),
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
          SnackBar(content: Text(loc.errorGeneric ?? 'An error occurred')),
        );
      }
    }
  }

  void _checkForSchemaIssues(shared.MenuItem? currentItem) {
    if (currentItem == null) {
      setState(() => _inlineSchemaIssues = []);
      return;
    }

    final categories =
        Provider.of<shared.CategoryProvider>(context, listen: false).categories;
    final ingredients =
        Provider.of<shared.IngredientMetadataProvider>(context, listen: false)
            .allIngredients;
    final ingredientTypes =
        Provider.of<shared.IngredientTypeProvider>(context, listen: false)
            .ingredientTypes;

    final issues = shared.MenuItemSchemaIssue.detectAllIssues(
      menuItem: currentItem,
      categories: categories,
      ingredients: ingredients,
      ingredientTypes: ingredientTypes,
    );

    setState(() => _inlineSchemaIssues = issues);
  }

  void _onSchemaIssuesChanged(List<shared.MenuItemSchemaIssue> newIssues) {
    print(
        '[OnboardingMenuItemsScreen][INLINE] onSchemaIssuesChanged FIRED: count=${newIssues.length}');
    setState(() {
      _inlineSchemaIssues = List<shared.MenuItemSchemaIssue>.from(newIssues);
    });
  }

  void _handleRepair(shared.MenuItemSchemaIssue issue, String newValue) {
    print(
        '[OnboardingMenuItemsScreen][INLINE] onRepair via key for: ${issue.displayMessage}');
    _editorKey.currentState?.repairSchemaIssue(issue, newValue);
  }

  void _onFullRefresh() {
    // Safe fallback using screen state (MenuItemEditorSheetState may not expose editingItem publicly yet)
    final currentItem = _editingItem;
    _checkForSchemaIssues(currentItem);
  }

  void openEditor({shared.MenuItem? item}) {
    print(
        '[OnboardingMenuItemsScreen] openEditor called for item: ${item?.name ?? "new"}');
    setState(() {
      _isEditing = true;
      _editingItem = item;
    });
  }

  void _exitEditor() {
    setState(() {
      _isEditing = false;
      _editingItem = null;
      _inlineSchemaIssues = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final ingredientTypes =
        context.watch<shared.IngredientTypeProvider>().ingredientTypes;
    final ingredients =
        context.watch<shared.IngredientMetadataProvider>().ingredients;
    final categories = context.watch<shared.CategoryProvider>().categories;
    final provider = context.watch<shared.MenuItemProvider>();

    final missingSteps = <String>[];
    if (ingredientTypes.isEmpty)
      missingSteps.add(loc.stepIngredientTypes ?? 'Ingredient Types');
    if (ingredients.isEmpty)
      missingSteps.add(loc.stepIngredients ?? 'Ingredients');
    if (categories.isEmpty)
      missingSteps.add(loc.stepCategories ?? 'Categories');

    if (missingSteps.isNotEmpty && !_isEditing) {
      print(
          '[OnboardingMenuItemsScreen] Blocked: Missing dependencies: $missingSteps');
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.onboardingMenuItems),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
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
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      final franchiseId = Provider.of<shared.FranchiseProvider>(
                              context,
                              listen: false)
                          .franchiseId;
                      if (franchiseId.isNotEmpty) {
                        Provider.of<shared.CategoryProvider>(context,
                                listen: false)
                            .load(
                                franchiseIdOverride: franchiseId,
                                forceReloadFromFirestore: true);
                      }
                      setState(() {});
                    },
                    label: const Text('Refresh Dependencies'),
                  ),
                  if (ingredientTypes.isEmpty)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.list_alt),
                      onPressed: () =>
                          _navigateToSection('onboardingIngredientTypes'),
                      label: Text(loc.goToStep(
                          loc.stepIngredientTypes ?? 'Ingredient Types')),
                    ),
                  if (ingredients.isEmpty)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.egg),
                      onPressed: () =>
                          _navigateToSection('onboardingIngredients'),
                      label: Text(
                          loc.goToStep(loc.stepIngredients ?? 'Ingredients')),
                    ),
                  if (categories.isEmpty)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.category),
                      onPressed: () =>
                          _navigateToSection('onboardingCategories'),
                      label: Text(
                          loc.goToStep(loc.stepCategories ?? 'Categories')),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Legacy checkForSchemaIssues and handleSidebarRepair kept for full compatibility
    void checkForSchemaIssues(shared.MenuItem menuItem) {
      print(
          '[OnboardingMenuItemsScreen] checkForSchemaIssues called for item: ${menuItem.name}');
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
      print(
          '[OnboardingMenuItemsScreen] handleSidebarRepair called (legacy) - issue: ${issue.displayMessage} value: $newValue');
      if (itemPendingRepair == null) return;

      // Legacy repair logic preserved exactly
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

      setState(() {
        schemaIssues = remainingIssues;
        itemPendingRepair = remainingIssues.isEmpty ? null : repaired;
        showSchemaSidebar = remainingIssues.any((e) => !e.resolved);
      });
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
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to menu list',
                  onPressed: _exitEditor,
                ),
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
                  if (result is shared.MenuItem) {
                    Provider.of<shared.MenuItemProvider>(context, listen: false)
                        .addOrUpdateMenuItem(result);
                  }
                });
              } catch (e, st) {
                shared.ErrorLogger.log(
                  message: 'Failed to navigate to MenuItemEditorScreen',
                  stack: st.toString(),
                  source: 'onboarding_menu_items_screen.dart',
                  severity: 'error',
                );
              }
            },
            icon: const Icon(Icons.add),
            label: Text(loc.addMenuItem),
            backgroundColor: DesignTokens.primaryColor,
          ),
          body: Padding(
            padding: DesignTokens.gridPadding,
            child: _isEditing
                ? Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: MenuItemEditorSheet(
                          key: _editorKey,
                          existing: _editingItem,
                          firestore: FirebaseFirestore.instance,
                          franchiseId: Provider.of<shared.FranchiseProvider>(
                                  context,
                                  listen: false)
                              .franchiseId,
                          onSave: (updatedItem) async {
                            Provider.of<shared.MenuItemProvider>(context,
                                    listen: false)
                                .addOrUpdateMenuItem(updatedItem);
                            setState(() => _isEditing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Item saved.')));
                          },
                          onCancel: () => setState(() => _isEditing = false),
                          onSchemaIssuesChanged: _onSchemaIssuesChanged,
                        ),
                      ),
                      const VerticalDivider(
                          width: 1, thickness: 1, color: Colors.grey),
                      Expanded(
                        flex: 2,
                        child: SchemaIssueSidebar(
                          issues: _inlineSchemaIssues,
                          onRepair: _handleRepair,
                          onFullRefresh: _onFullRefresh,
                          onClose: () {
                            setState(() => _inlineSchemaIssues = []);
                          },
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FeatureGateBanner(
                        module: 'menu_item_customization',
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          color: Colors.yellow.shade50,
                          alignment: Alignment.center,
                          child: const Text(
                              'Menu Item Customization is a premium feature.'),
                        ),
                      ),
                      if (provider.isDirty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  final ingredientProvider = Provider.of<
                                          shared.IngredientMetadataProvider>(
                                      context,
                                      listen: false);
                                  final categoryProvider =
                                      Provider.of<shared.CategoryProvider>(
                                          context,
                                          listen: false);
                                  final typeProvider = Provider.of<
                                          shared.IngredientTypeProvider>(
                                      context,
                                      listen: false);
                                  final menuItemProvider =
                                      Provider.of<shared.MenuItemProvider>(
                                          context,
                                          listen: false);

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
                                      isSelected:
                                          _selectedIds.contains(item.id),
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
                                                loc.deleteMenuItemConfirm(
                                                    item.name)),
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
                                                content:
                                                    Text(loc.menuItemDeleted),
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
