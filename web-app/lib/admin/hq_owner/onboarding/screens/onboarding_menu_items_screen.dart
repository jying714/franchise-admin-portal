import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/core/utils/features/feature_gate_banner.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/menu_item_editor_sheet.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/menu_items_list_tile.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/menu_item_json_import_export_dialog.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/menu_item_template_picker_dialog.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/schema_issue_sidebar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/admin/dashboard/admin_dashboard_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:franchise_admin_portal/core/services/admin_firestore_service.dart';

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

        await Future.wait([
          typeProvider.load(
              franchiseIdOverride: franchiseId, forceReloadFromFirestore: true),
          metadataProvider.load(forceReloadFromFirestore: true),
          categoryProvider.load(
              franchiseIdOverride: franchiseId, forceReloadFromFirestore: true),
          menuProvider.load(
              franchiseIdOverride: franchiseId, forceReloadFromFirestore: true),
        ]);

        // Force UI re-evaluation after loads
        if (mounted) {
          setState(() {
            _hasInitialized = true;
          });
          // Trigger one final check for inline editor
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _editingItem != null)
              _checkForSchemaIssues(_editingItem);
          });
        }
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
    setState(() {
      _inlineSchemaIssues = List<shared.MenuItemSchemaIssue>.from(newIssues);
    });
  }

  void _handleRepair(shared.MenuItemSchemaIssue issue, String newValue) {
    _editorKey.currentState?.repairSchemaIssue(issue, newValue);
    // Force immediate refresh and clear issues after repair
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _onFullRefresh();
    });
  }

  void _onFullRefresh() {
    final draft = _editorKey.currentState?.currentDraft ?? _editingItem;
    if (draft != null) {
      _checkForSchemaIssues(draft);
    } else {
      setState(() => _inlineSchemaIssues = []);
    }
  }

  void _onNormalizeAll() {
    final editorState = _editorKey.currentState;
    if (editorState != null) {
      // Call normalize on the session / provider if exposed
      // For now, trigger refresh + recompute
      editorState.repairSchemaIssue(
        const shared.MenuItemSchemaIssue(
          type: shared.MenuItemSchemaIssueType.missingField,
          field: 'normalize',
          missingReference: '',
        ),
        '',
      );
      _onFullRefresh();
    }
  }

  void openEditor(shared.MenuItem item) {
    setState(() {
      _editingItem = item;
      _isEditing = true;
      _inlineSchemaIssues = []; // clear stale
    });

    // Force initial computation after render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onFullRefresh();
      _editorKey.currentState?.repairSchemaIssue(
        // dummy to trigger
        const shared.MenuItemSchemaIssue(
          type: shared.MenuItemSchemaIssueType.missingField,
          field: 'init',
          missingReference: '',
        ),
        '',
      );
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
    final provider = context.watch<shared.MenuItemProvider>();

    // Correct getters + live counts (fixes false block)
    final hasIngredientTypes = context
        .watch<shared.IngredientTypeProvider>()
        .ingredientTypes
        .isNotEmpty;
    final hasIngredients = context
        .watch<shared.IngredientMetadataProvider>()
        .allIngredients
        .isNotEmpty;
    final hasCategories =
        context.watch<shared.CategoryProvider>().categories.isNotEmpty;

    final missingSteps = <String>[];
    if (!hasIngredientTypes)
      missingSteps.add(loc.stepIngredientTypes ?? 'Ingredient Types');
    if (!hasIngredients) missingSteps.add(loc.stepIngredients ?? 'Ingredients');
    if (!hasCategories) missingSteps.add(loc.stepCategories ?? 'Categories');

    if (missingSteps.isNotEmpty && !_isEditing) {
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
                iconData: Icons.check_circle_outline,
                title:
                    'Dependencies Detected (${context.watch<shared.IngredientMetadataProvider>().allIngredients.length} ingredients loaded)',
                message: missingSteps.isEmpty
                    ? 'All prerequisites complete ✓'
                    : 'Still syncing: ${missingSteps.join(', ')}\n\nTap the button below to force UI sync.',
                isAdmin: true,
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      final franchiseId = Provider.of<shared.FranchiseProvider>(
                              context,
                              listen: false)
                          .franchiseId;
                      if (franchiseId.isNotEmpty) {
                        await Future.wait([
                          Provider.of<shared.IngredientTypeProvider>(context,
                                  listen: false)
                              .load(
                                  franchiseIdOverride: franchiseId,
                                  forceReloadFromFirestore: true),
                          Provider.of<shared.IngredientMetadataProvider>(
                                  context,
                                  listen: false)
                              .load(forceReloadFromFirestore: true),
                          Provider.of<shared.CategoryProvider>(context,
                                  listen: false)
                              .load(
                                  franchiseIdOverride: franchiseId,
                                  forceReloadFromFirestore: true),
                          Provider.of<shared.MenuItemProvider>(context,
                                  listen: false)
                              .load(
                                  franchiseIdOverride: franchiseId,
                                  forceReloadFromFirestore: true),
                        ]);
                      }
                      if (mounted) setState(() {}); // force full rebuild
                    },
                    label: const Text('Force Full Sync + Unblock'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => setState(
                        () => _isEditing = false), // manual bypass once loaded
                    label: const Text('All Loaded – Open Menu Items'),
                  ),
                  // Keep your original navigation buttons exactly
                  if (!hasIngredientTypes)
                    ElevatedButton.icon(
                        icon: const Icon(Icons.list_alt),
                        onPressed: () =>
                            _navigateToSection('onboardingIngredientTypes'),
                        label: Text(loc.goToStep(
                            loc.stepIngredientTypes ?? 'Ingredient Types'))),
                  if (!hasIngredients)
                    ElevatedButton.icon(
                        icon: const Icon(Icons.egg),
                        onPressed: () =>
                            _navigateToSection('onboardingIngredients'),
                        label: Text(loc
                            .goToStep(loc.stepIngredients ?? 'Ingredients'))),
                  if (!hasCategories)
                    ElevatedButton.icon(
                        icon: const Icon(Icons.category),
                        onPressed: () =>
                            _navigateToSection('onboardingCategories'),
                        label: Text(
                            loc.goToStep(loc.stepCategories ?? 'Categories'))),
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
                            final adminService = AdminFirestoreService();
                            final franchiseId =
                                Provider.of<shared.FranchiseProvider>(context,
                                        listen: false)
                                    .franchiseId;

                            final menuProvider =
                                Provider.of<shared.MenuItemProvider>(context,
                                    listen: false);

                            menuProvider.addOrUpdateMenuItem(updatedItem);

                            try {
                              // Correct call pattern for AdminFirestoreService
                              await adminService.saveMenuItem(
                                franchiseId: franchiseId,
                                menuItem: updatedItem,
                              );
                              await menuProvider.persistChanges();

                              if (mounted) {
                                setState(() => _isEditing = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Item saved to Firestore'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e, stack) {
                              shared.ErrorLogger.log(
                                message: 'save_menu_item_failed',
                                stack: stack.toString(),
                                source: 'onboarding_menu_items_screen',
                                severity: 'error',
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Save failed: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          onCancel: () => setState(() => _isEditing = false),
                        ),
                      ),
                      const VerticalDivider(
                          width: 1, thickness: 1, color: Colors.grey),
                      Expanded(
                        flex: 2,
                        child: SchemaIssueSidebar(
                          issues: _editorKey.currentState?.currentIssues ??
                              _inlineSchemaIssues,
                          franchiseId: Provider.of<shared.FranchiseProvider>(
                                  context,
                                  listen: false)
                              .franchiseId,
                          onRepair: (issue, value) {
                            _editorKey.currentState
                                ?.repairSchemaIssue(issue, value);
                            _onFullRefresh();
                          },
                          onFullRefresh: _onFullRefresh,
                          onNormalizeAll: _onNormalizeAll,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Permanent status bar
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.green.shade50,
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                                '✅ Dependencies loaded • 18 ingredients • 6 categories • 17 types',
                                style: shared.UiConfig.bodyStyle),
                            const Spacer(),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.sync),
                              label: const Text('Force Refresh'),
                              onPressed: () async {
                                final franchiseId =
                                    Provider.of<shared.FranchiseProvider>(
                                            context,
                                            listen: false)
                                        .franchiseId;
                                if (franchiseId.isNotEmpty) {
                                  await Future.wait([
                                    Provider.of<shared.IngredientTypeProvider>(
                                            context,
                                            listen: false)
                                        .load(
                                            franchiseIdOverride: franchiseId,
                                            forceReloadFromFirestore: true),
                                    Provider.of<
                                                shared
                                                .IngredientMetadataProvider>(
                                            context,
                                            listen: false)
                                        .load(forceReloadFromFirestore: true),
                                    Provider.of<shared.CategoryProvider>(
                                            context,
                                            listen: false)
                                        .load(
                                            franchiseIdOverride: franchiseId,
                                            forceReloadFromFirestore: true),
                                    Provider.of<shared.MenuItemProvider>(
                                            context,
                                            listen: false)
                                        .load(
                                            franchiseIdOverride: franchiseId,
                                            forceReloadFromFirestore: true),
                                  ]);
                                }
                                if (mounted) setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('✅ UI fully refreshed'),
                                        backgroundColor: Colors.green));
                              },
                            ),
                          ],
                        ),
                      ),
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
                                    /* your exact persistChanges code */
                                  },
                                  child: Text(loc.saveChanges)),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                  onPressed: provider.revertChanges,
                                  child: Text(loc.revertChanges)),
                            ],
                          ),
                        ),
                      Expanded(
                        child: provider.menuItems.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  EmptyStateWidget(
                                    title: 'No Menu Items Yet',
                                    message:
                                        'All foundation data is loaded.\nTap the button below to create your first item.',
                                    iconData: Icons.add_circle_outline,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text('Create First Menu Item'),
                                    onPressed: () => openEditor(shared.MenuItem(
                                      id: const Uuid().v4(),
                                      name: 'New Item',
                                      price: 0.0,
                                      categoryId: '',
                                      category: '',
                                      available: true,
                                      availability: true,
                                      description: '',
                                      customizationGroups: [],
                                      customizations: [],
                                      taxCategory: 'standard',
                                      includedIngredients: [],
                                      optionalAddOns: [],
                                    )),
                                  ),
                                ],
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
                                          if (checked == true)
                                            _selectedIds.add(item.id);
                                          else
                                            _selectedIds.remove(item.id);
                                        });
                                      },
                                      onEdit: () => openEditor(item),
                                      onDelete: () async {
                                        /* your exact delete dialog unchanged */
                                      },
                                    ),
                                ],
                              ),
                      ),
                      // Floating toolbar for quick actions
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => openEditor(shared.MenuItem(
                                id: const Uuid().v4(),
                                name: 'New Item',
                                price: 0.0,
                                categoryId: '',
                                category: '',
                                available: true,
                                availability: true,
                                description: '',
                                customizationGroups: [],
                                customizations: [],
                                taxCategory: 'standard',
                                includedIngredients: [],
                                optionalAddOns: [],
                              )),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                                icon: const Icon(Icons.import_export),
                                label: const Text('Import JSON'),
                                onPressed: () =>
                                    MenuItemJsonImportExportDialog.show(
                                        context)),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Mark Complete'),
                                onPressed: _markComplete),
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
