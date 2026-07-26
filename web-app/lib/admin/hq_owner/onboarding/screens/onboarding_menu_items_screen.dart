import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider_impl.dart';
import 'package:franchise_admin_portal/core/utils/features/feature_gate_banner.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/menu_item_editor_sheet.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/menu_items_list_tile.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/menu_item_template_picker_dialog.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/schema_issue_sidebar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/screens/hq_onboarding_shell_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:franchise_admin_portal/core/services/admin_firestore_service.dart';
import 'package:franchise_admin_portal/core/providers/menu_item_provider_impl.dart';

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
        await _reloadFoundationProviders(franchiseId);
        if (mounted) {
          setState(() {
            _hasInitialized = true;
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _editingItem != null) {
              _checkForSchemaIssues(_editingItem);
            }
          });
        }
      });
    }
  }

  void _navigateToSection(String sectionKey) {
    final hqShell =
        context.findAncestorStateOfType<HqOnboardingShellScreenState>();
    if (hqShell != null) {
      hqShell.switchToSection(sectionKey);
      return;
    }
    debugPrint(
      '[OnboardingMenuItemsScreen] ⚠️ No HQ shell for section=$sectionKey',
    );
  }

  Future<void> _reloadFoundationProviders(String franchiseId) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;

    final typeProvider =
        Provider.of<shared.IngredientTypeProvider>(context, listen: false);
    final metadataProvider =
        Provider.of<shared.IngredientMetadataProvider>(context, listen: false);
    final categoryProvider =
        Provider.of<shared.CategoryProvider>(context, listen: false);
    final menuProvider =
        Provider.of<shared.MenuItemProvider>(context, listen: false);

    // Metadata load() has no franchiseIdOverride — bind franchise first.
    if (metadataProvider is IngredientMetadataProviderImpl) {
      metadataProvider.updateFranchiseId(franchiseId);
    }

    await Future.wait([
      typeProvider.load(
        franchiseIdOverride: franchiseId,
        forceReloadFromFirestore: true,
      ),
      metadataProvider.load(forceReloadFromFirestore: true),
      categoryProvider.load(
        franchiseIdOverride: franchiseId,
        forceReloadFromFirestore: true,
      ),
      menuProvider.load(
        franchiseIdOverride: franchiseId,
        forceReloadFromFirestore: true,
      ),
    ]);
  }

  Future<void> _markComplete() async {
    final onboarding =
        Provider.of<shared.OnboardingProgressProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    try {
      final isComplete = onboarding.isStepComplete('onboardingMenuItems');
      if (isComplete) {
        await onboarding.markStepIncomplete('onboardingMenuItems');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Step marked incomplete')),
          );
        }
      } else {
        await onboarding.markStepComplete('onboardingMenuItems');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    loc.menuItemMarkedAsComplete ?? 'Step marked complete')),
          );
        }
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

  Future<void> _onNormalizeAll() async {
    final menuProvider =
        Provider.of<shared.MenuItemProvider>(context, listen: false);
    try {
      await menuProvider.normalizeSchemaReferences();
      _editorKey.currentState?.forceRecomputeIssues();
      _onFullRefresh();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'menu_items_normalize_failed',
        stack: stack.toString(),
        source: 'onboarding_menu_items_screen',
        severity: 'warning',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Normalize failed: $e')),
      );
    }
  }

  void _onFullRefresh() {
    final issues = _editorKey.currentState?.currentIssues;
    if (issues != null) {
      setState(() => _inlineSchemaIssues = List.from(issues));
    } else if (_editingItem != null) {
      _checkForSchemaIssues(
        _editorKey.currentState?.currentDraft ?? _editingItem,
      );
    } else {
      setState(() => _inlineSchemaIssues = []);
    }
  }

  void openEditor(shared.MenuItem item) {
    setState(() {
      _editingItem = item;
      _isEditing = true;
      _inlineSchemaIssues = [];
    });
    // Sheet recomputes issues in its own post-frame; parent listens via callback.
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
    final typeProvider = context.watch<shared.IngredientTypeProvider>();
    final ingredientProvider =
        context.watch<shared.IngredientMetadataProvider>();
    final categoryProvider = context.watch<shared.CategoryProvider>();

    final typeCount = typeProvider.ingredientTypes.length;
    final categoryCount = categoryProvider.categories.length;
    final allIngredients = ingredientProvider.allIngredients;
    final typedCount =
        allIngredients.where((i) => (i.typeId ?? '').trim().isNotEmpty).length;
    final orphanCount =
        allIngredients.where((i) => (i.typeId ?? '').trim().isEmpty).length;

    final readinessFailures = <String>[];
    if (typeCount < 1) {
      readinessFailures
          .add('Need at least 1 ingredient type (have $typeCount)');
    }
    if (categoryCount < 1) {
      readinessFailures.add('Need at least 1 category (have $categoryCount)');
    }
    if (typedCount < 5) {
      readinessFailures.add(
        'Need at least 5 ingredients with a type (have $typedCount)',
      );
    }
    if (orphanCount > 0) {
      readinessFailures.add(
        '$orphanCount ingredient(s) missing a type — assign types in Core Menu Foundation',
      );
    }

    // P2.2 — mark complete only when no item has schema errors
    bool anyItemHasSchemaErrors = false;
    for (final item in provider.menuItems) {
      final itemIssues = shared.MenuItemSchemaIssue.detectAllIssues(
        menuItem: item,
        categories: categoryProvider.categories,
        ingredients: allIngredients,
        ingredientTypes: typeProvider.ingredientTypes,
      );
      if (itemIssues.any((i) => i.severity == 'error')) {
        anyItemHasSchemaErrors = true;
        break;
      }
    }

    if (readinessFailures.isNotEmpty && !_isEditing) {
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
                iconData: Icons.warning_amber_outlined,
                title: 'Foundation not ready for menu items',
                message:
                    '${readinessFailures.join('\n')}\n\nLoaded: $typeCount types · ${allIngredients.length} ingredients ($typedCount typed, $orphanCount orphan) · $categoryCount categories',
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
                      await _reloadFoundationProviders(franchiseId);
                      if (mounted) setState(() {});
                    },
                    label: const Text('Force Full Sync'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.list_alt),
                    onPressed: () =>
                        _navigateToSection('onboarding_menu_foundation'),
                    label: const Text('Open Core Menu Foundation'),
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
                icon: const Icon(Icons.check_circle_outline),
                tooltip: anyItemHasSchemaErrors
                    ? 'Fix schema errors on all items first'
                    : (loc.markAsComplete),
                onPressed: anyItemHasSchemaErrors ? null : _markComplete,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab-onboarding-menu-items',
            onPressed: () {
              try {
                openEditor(shared.MenuItem(
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
                ));
              } catch (e, st) {
                shared.ErrorLogger.log(
                  message: 'Failed to open MenuItem editor',
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
                          onSchemaIssuesChanged: (issues) {
                            if (!mounted) return;
                            setState(
                                () => _inlineSchemaIssues = List.from(issues));
                          },
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
                          issues: _inlineSchemaIssues,
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
                        color: colorScheme.primaryContainer.withOpacity(0.35),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                                '✅ Dependencies loaded • ${context.watch<shared.IngredientMetadataProvider>().allIngredients.length} ingredients • ${context.watch<shared.CategoryProvider>().categories.length} categories • ${context.watch<shared.IngredientTypeProvider>().ingredientTypes.length} types',
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
                                await _reloadFoundationProviders(franchiseId);
                                if (mounted) setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ UI fully refreshed'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
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
                                    final menuProvider =
                                        Provider.of<shared.MenuItemProvider>(
                                            context,
                                            listen: false);
                                    try {
                                      await menuProvider.persistChanges();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text('Changes saved')),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text('Save failed: $e')),
                                        );
                                      }
                                    }
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
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    icon: const Icon(
                                        Icons.dashboard_customize_outlined),
                                    label: const Text('Add from template'),
                                    onPressed: () async {
                                      await MenuItemTemplatePickerDialog.show(
                                          context);
                                      if (!mounted) return;

                                      // Residual UX: recompute badges / mark-complete
                                      // from provider items after bulk template import.
                                      setState(() {});

                                      final menuProvider =
                                          Provider.of<shared.MenuItemProvider>(
                                        context,
                                        listen: false,
                                      );
                                      final categories =
                                          Provider.of<shared.CategoryProvider>(
                                        context,
                                        listen: false,
                                      ).categories;
                                      final ingredients = Provider.of<
                                          shared.IngredientMetadataProvider>(
                                        context,
                                        listen: false,
                                      ).allIngredients;
                                      final types = Provider.of<
                                          shared.IngredientTypeProvider>(
                                        context,
                                        listen: false,
                                      ).ingredientTypes;

                                      var errorCount = 0;
                                      for (final item
                                          in menuProvider.menuItems) {
                                        final issues =
                                            shared.MenuItemSchemaIssue
                                                .detectAllIssues(
                                          menuItem: item,
                                          categories: categories,
                                          ingredients: ingredients,
                                          ingredientTypes: types,
                                        );
                                        if (issues.any(
                                            (i) => i.severity == 'error')) {
                                          errorCount++;
                                        }
                                      }

                                      if (!mounted) return;
                                      if (errorCount > 0) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Template applied · $errorCount item(s) still have schema errors — edit to fix',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      } else if (menuProvider
                                          .menuItems.isNotEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              menuProvider.isDirty
                                                  ? 'Template applied · all items clean — save changes if needed'
                                                  : 'Template applied · all items clean',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              )
                            : Builder(
                                builder: (context) {
                                  final seenIds = <String>{};
                                  final uniqueItems = <shared.MenuItem>[];
                                  for (final item in provider.menuItems) {
                                    if (seenIds.add(item.id)) {
                                      uniqueItems.add(item);
                                    } else {
                                      debugPrint(
                                        '[OnboardingMenuItemsScreen] Duplicate menu item id skipped: ${item.id} (${item.name})',
                                      );
                                    }
                                  }

                                  return ReorderableListView(
                                    onReorder: (oldIndex, newIndex) {
                                      final items = List.of(uniqueItems);
                                      if (newIndex > oldIndex) newIndex -= 1;
                                      final item = items.removeAt(oldIndex);
                                      items.insert(newIndex, item);
                                      provider.reorderMenuItems(items);
                                    },
                                    children: [
                                      for (var index = 0;
                                          index < uniqueItems.length;
                                          index++)
                                        MenuItemListTile(
                                          key: ValueKey(
                                            'menu_item_${uniqueItems[index].id}_$index',
                                          ),
                                          item: uniqueItems[index],
                                          hasSchemaErrors:
                                              shared.MenuItemSchemaIssue
                                                  .detectAllIssues(
                                            menuItem: uniqueItems[index],
                                            categories:
                                                categoryProvider.categories,
                                            ingredients: ingredientProvider
                                                .allIngredients,
                                            ingredientTypes:
                                                typeProvider.ingredientTypes,
                                          ).any((i) => i.severity == 'error'),
                                          isSelected: _selectedIds
                                              .contains(uniqueItems[index].id),
                                          onSelect: (checked) {
                                            final id = uniqueItems[index].id;
                                            setState(() {
                                              if (checked == true) {
                                                _selectedIds.add(id);
                                              } else {
                                                _selectedIds.remove(id);
                                              }
                                            });
                                          },
                                          onEdit: () =>
                                              openEditor(uniqueItems[index]),
                                          onDelete: () async {
                                            final item = uniqueItems[index];
                                            final confirmed =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (dialogContext) =>
                                                  AlertDialog(
                                                title: const Text(
                                                    'Delete menu item?'),
                                                content: Text(
                                                  'Are you sure you want to delete "${item.name}"?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                                dialogContext)
                                                            .pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                                dialogContext)
                                                            .pop(true),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirmed != true) return;
                                            final menuProvider = Provider.of<
                                                shared.MenuItemProvider>(
                                              context,
                                              listen: false,
                                            );
                                            try {
                                              final franchiseId = Provider.of<
                                                  shared.FranchiseProvider>(
                                                context,
                                                listen: false,
                                              ).franchiseId;

                                              // Bind franchise on this provider instance.
                                              if (menuProvider
                                                  is MenuItemProviderImpl) {
                                                menuProvider.setFranchiseId(
                                                    franchiseId);
                                              }

                                              final impl = menuProvider
                                                  as MenuItemProviderImpl;
                                              impl.setFranchiseId(franchiseId);
                                              await impl
                                                  .deleteMenuItemAndPersist(
                                                      item.id);
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content:
                                                      Text('✅ Item deleted'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } catch (e, stack) {
                                              shared.ErrorLogger.log(
                                                message:
                                                    'delete_menu_item_failed',
                                                stack: stack.toString(),
                                                source:
                                                    'onboarding_menu_items_screen',
                                                severity: 'error',
                                              );
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      '❌ Delete failed: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                    ],
                                  );
                                },
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
                              tooltip: 'Add menu item',
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
                              icon: const Icon(
                                  Icons.dashboard_customize_outlined),
                              label: const Text('Add from template'),
                              onPressed: () async {
                                await MenuItemTemplatePickerDialog.show(
                                    context);
                                if (!mounted) return;

                                // Residual UX: recompute badges / mark-complete
                                // from provider items after bulk template import.
                                setState(() {});

                                final menuProvider =
                                    Provider.of<shared.MenuItemProvider>(
                                  context,
                                  listen: false,
                                );
                                final categories =
                                    Provider.of<shared.CategoryProvider>(
                                  context,
                                  listen: false,
                                ).categories;
                                final ingredients = Provider.of<
                                    shared.IngredientMetadataProvider>(
                                  context,
                                  listen: false,
                                ).allIngredients;
                                final types =
                                    Provider.of<shared.IngredientTypeProvider>(
                                  context,
                                  listen: false,
                                ).ingredientTypes;

                                var errorCount = 0;
                                for (final item in menuProvider.menuItems) {
                                  final issues = shared.MenuItemSchemaIssue
                                      .detectAllIssues(
                                    menuItem: item,
                                    categories: categories,
                                    ingredients: ingredients,
                                    ingredientTypes: types,
                                  );
                                  if (issues
                                      .any((i) => i.severity == 'error')) {
                                    errorCount++;
                                  }
                                }

                                if (!mounted) return;
                                if (errorCount > 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Template applied · $errorCount item(s) still have schema errors — edit to fix',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                } else if (menuProvider.menuItems.isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        menuProvider.isDirty
                                            ? 'Template applied · all items clean — save changes if needed'
                                            : 'Template applied · all items clean',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle),
                              label: Text(
                                anyItemHasSchemaErrors
                                    ? 'Fix schema errors first'
                                    : 'Mark Complete',
                              ),
                              onPressed:
                                  anyItemHasSchemaErrors ? null : _markComplete,
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
