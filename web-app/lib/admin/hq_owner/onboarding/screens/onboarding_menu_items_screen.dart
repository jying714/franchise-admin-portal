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
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/preview_menu_item_card.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/foundation/mobile_menu_preview_card.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/screens/onboarding_menu_foundation_screen.dart'
    show FoundationFocusRequest;

class OnboardingMenuItemsScreen extends StatefulWidget {
  const OnboardingMenuItemsScreen({super.key});

  @override
  State<OnboardingMenuItemsScreen> createState() =>
      _OnboardingMenuItemsScreenState();
}

class _OnboardingMenuItemsScreenState extends State<OnboardingMenuItemsScreen> {
  String? _boundFranchiseId;
  final Set<String> _selectedIds = {};
  bool showSchemaSidebar = false;
  List<shared.MenuItemSchemaIssue> schemaIssues = [];
  shared.MenuItem? itemPendingRepair;
  bool _isEditing = false;
  shared.MenuItem? _editingItem;
  List<shared.MenuItemSchemaIssue> _inlineSchemaIssues = [];

  /// Preview navigation: null = category list; non-null = items under that category.
  String? _previewCategoryId;

  // W1: local search + sort (in-memory only)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// 'sortOrder' | 'nameAsc' | 'nameDesc'
  String _sortMode = 'sortOrder';

  // GlobalKey for direct access to sheet repair method
  final GlobalKey<MenuItemEditorSheetState> _editorKey =
      GlobalKey<MenuItemEditorSheetState>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filter by name / category, then apply sort. Does not touch provider order.
  List<shared.MenuItem> _visibleMenuItems(List<shared.MenuItem> source) {
    var list = List<shared.MenuItem>.from(source);
    final q = (_searchQuery).trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((item) {
        final name = (item.name).toLowerCase();
        final cat = (item.category).toLowerCase();
        final catId = (item.categoryId).toLowerCase();
        return name.contains(q) || cat.contains(q) || catId.contains(q);
      }).toList();
    }
    switch (_sortMode) {
      case 'nameAsc':
        list.sort(
          (a, b) => (a.name).toLowerCase().compareTo((b.name).toLowerCase()),
        );
        break;
      case 'nameDesc':
        list.sort(
          (a, b) => (b.name).toLowerCase().compareTo((a.name).toLowerCase()),
        );
        break;
      case 'sortOrder':
      default:
        list.sort((a, b) {
          final ao = a.sortOrder ?? 999999;
          final bo = b.sortOrder ?? 999999;
          if (ao != bo) return ao.compareTo(bo);
          return (a.name).toLowerCase().compareTo((b.name).toLowerCase());
        });
        break;
    }
    return list;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final fp = context.watch<shared.FranchiseProvider>();
    // Force dependency on version so rebuilds happen when branding/id bump.
    final _ = fp.currentConfigVersion;
    final franchiseId = fp.franchiseId;

    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    if (_boundFranchiseId == franchiseId) return;

    _boundFranchiseId = franchiseId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _reloadFoundationProviders(franchiseId);
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _editingItem = null;
        _inlineSchemaIssues = [];
        _previewCategoryId = null;
        _selectedIds.clear();
        _searchController.clear();
        _searchQuery = '';
        _sortMode = 'sortOrder';
      });
    });
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
    final ingredientProvider = context.watch<IngredientMetadataProviderImpl>();
    final categoryProvider = context.watch<shared.CategoryProvider>();

    final typeCount = typeProvider.ingredientTypes.length;
    final categoryCount = categoryProvider.categories.length;
    final allIngredients = ingredientProvider.allIngredients;
    final typeIds =
        typeProvider.ingredientTypes.map((t) => (t.id ?? '').trim()).toSet();

    bool isOrphan(shared.IngredientMetadata i) {
      final tid = (i.typeId ?? '').trim();
      return tid.isEmpty || !typeIds.contains(tid);
    }

    final orphanIngredients =
        allIngredients.where(isOrphan).toList(growable: false);
    final orphanCount = orphanIngredients.length;
    final typedCount = allIngredients.length - orphanCount;

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
        'Need at least 5 ingredients with a known type (have $typedCount)',
      );
    }
    if (orphanCount > 0) {
      readinessFailures.add(
        '$orphanCount ingredient(s) missing or unknown type — assign types in Core Menu Foundation',
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
                    onPressed: () {
                      // Handoff: Ingredients tab + orphan filter + first focus.
                      FoundationFocusRequest.showOrphansOnly = true;
                      FoundationFocusRequest.firstOrphanId =
                          orphanIngredients.isNotEmpty
                              ? orphanIngredients.first.id
                              : null;
                      _navigateToSection('onboarding_menu_foundation');
                    },
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
          // FAB is scoped to the list pane (Stack) so it matches foundation.
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
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Left: list surface + pane-scoped FAB ──
                      Expanded(
                        flex: 7,
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Permanent status bar
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  color: theme.scaffoldBackgroundColor,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Dependencies loaded • ${context.watch<shared.IngredientMetadataProvider>().allIngredients.length} ingredients • ${context.watch<shared.CategoryProvider>().categories.length} categories • ${context.watch<shared.IngredientTypeProvider>().ingredientTypes.length} types',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: DesignTokens.textColor,
                                          ),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.sync),
                                        label: const Text('Force Refresh'),
                                        onPressed: () async {
                                          final franchiseId = Provider.of<
                                                      shared.FranchiseProvider>(
                                                  context,
                                                  listen: false)
                                              .franchiseId;
                                          await _reloadFoundationProviders(
                                              franchiseId);
                                          if (mounted) setState(() {});
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('✅ UI fully refreshed'),
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
                                              final menuProvider = Provider.of<
                                                      shared.MenuItemProvider>(
                                                  context,
                                                  listen: false);
                                              try {
                                                await menuProvider
                                                    .persistChanges();
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Changes saved')),
                                                  );
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Save failed: $e')),
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
                                // W1: search + sort (local only)
                                if (provider.menuItems.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Search by name or category',
                                              prefixIcon:
                                                  const Icon(Icons.search),
                                              suffixIcon: _searchQuery.isEmpty
                                                  ? null
                                                  : IconButton(
                                                      icon: const Icon(
                                                          Icons.clear),
                                                      onPressed: () {
                                                        _searchController
                                                            .clear();
                                                        setState(() =>
                                                            _searchQuery = '');
                                                      },
                                                    ),
                                              isDense: true,
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                            onChanged: (v) => setState(
                                                () => _searchQuery = v),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          width: 180,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: theme.dividerColor,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _sortMode,
                                              isExpanded: true,
                                              isDense: true,
                                              hint: const Text('Sort'),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 'sortOrder',
                                                  child: Text('Menu order'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'nameAsc',
                                                  child: Text('Name A–Z'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'nameDesc',
                                                  child: Text('Name Z–A'),
                                                ),
                                              ],
                                              onChanged: (v) {
                                                if (v == null) return;
                                                setState(() => _sortMode = v);
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Expanded(
                                  child: provider.menuItems.isEmpty
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            EmptyStateWidget(
                                              title: 'No Menu Items Yet',
                                              message:
                                                  'All foundation data is loaded.\nTap the button below to create your first item.',
                                              iconData:
                                                  Icons.add_circle_outline,
                                            ),
                                            const SizedBox(height: 24),
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.add),
                                              label: const Text(
                                                  'Create First Menu Item'),
                                              onPressed: () =>
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
                                                menuProfile:
                                                    shared.MenuProfile.standard,
                                                modifierGroups:
                                                    shared.MenuProfileTemplates
                                                        .seedGroups(shared
                                                            .MenuProfile
                                                            .standard),
                                              )),
                                            ),
                                            const SizedBox(height: 12),
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons
                                                  .dashboard_customize_outlined),
                                              label: const Text(
                                                  'Add from template'),
                                              onPressed: () async {
                                                await MenuItemTemplatePickerDialog
                                                    .show(context);
                                                if (!mounted) return;

                                                setState(() {});

                                                final menuProvider =
                                                    Provider.of<
                                                        shared
                                                        .MenuItemProvider>(
                                                  context,
                                                  listen: false,
                                                );
                                                final categories = Provider.of<
                                                    shared.CategoryProvider>(
                                                  context,
                                                  listen: false,
                                                ).categories;
                                                final ingredients = Provider.of<
                                                    shared
                                                    .IngredientMetadataProvider>(
                                                  context,
                                                  listen: false,
                                                ).allIngredients;
                                                final types = Provider.of<
                                                    shared
                                                    .IngredientTypeProvider>(
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
                                                  if (issues.any((i) =>
                                                      i.severity == 'error')) {
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
                                                      backgroundColor:
                                                          Colors.orange,
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
                                                      backgroundColor:
                                                          Colors.green,
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
                                            final uniqueItems =
                                                <shared.MenuItem>[];
                                            for (final item
                                                in provider.menuItems) {
                                              if (seenIds.add(item.id)) {
                                                uniqueItems.add(item);
                                              } else {
                                                debugPrint(
                                                  '[OnboardingMenuItemsScreen] Duplicate menu item id skipped: ${item.id} (${item.name})',
                                                );
                                              }
                                            }

                                            final visibleItems =
                                                _visibleMenuItems(uniqueItems);
                                            final canReorder =
                                                _searchQuery.trim().isEmpty &&
                                                    _sortMode == 'sortOrder';

                                            if (visibleItems.isEmpty) {
                                              return Center(
                                                child: Text(
                                                  'No items match “$_searchQuery”',
                                                  style: theme
                                                      .textTheme.bodyMedium,
                                                ),
                                              );
                                            }

                                            return ReorderableListView(
                                              onReorder: (oldIndex, newIndex) {
                                                if (!canReorder) return;
                                                // Reorder against full unique list
                                                // (visible == unique when canReorder).
                                                final items =
                                                    List.of(uniqueItems);
                                                if (newIndex > oldIndex) {
                                                  newIndex -= 1;
                                                }
                                                final item =
                                                    items.removeAt(oldIndex);
                                                items.insert(newIndex, item);
                                                provider
                                                    .reorderMenuItems(items);
                                              },
                                              children: [
                                                for (var index = 0;
                                                    index < visibleItems.length;
                                                    index++)
                                                  MenuItemListTile(
                                                    key: ValueKey(
                                                      'menu_item_${visibleItems[index].id}_$index',
                                                    ),
                                                    item: visibleItems[index],
                                                    hasSchemaErrors: shared
                                                            .MenuItemSchemaIssue
                                                        .detectAllIssues(
                                                      menuItem:
                                                          visibleItems[index],
                                                      categories:
                                                          categoryProvider
                                                              .categories,
                                                      ingredients:
                                                          ingredientProvider
                                                              .allIngredients,
                                                      ingredientTypes:
                                                          typeProvider
                                                              .ingredientTypes,
                                                    ).any((i) =>
                                                        i.severity == 'error'),
                                                    isSelected:
                                                        _selectedIds.contains(
                                                            visibleItems[index]
                                                                .id),
                                                    onSelect: (checked) {
                                                      final id =
                                                          visibleItems[index]
                                                              .id;
                                                      setState(() {
                                                        if (checked == true) {
                                                          _selectedIds.add(id);
                                                        } else {
                                                          _selectedIds
                                                              .remove(id);
                                                        }
                                                      });
                                                    },
                                                    onEdit: () => openEditor(
                                                        visibleItems[index]),
                                                    onDelete: () async {
                                                      final item =
                                                          visibleItems[index];
                                                      final confirmed =
                                                          await showDialog<
                                                              bool>(
                                                        context: context,
                                                        builder:
                                                            (dialogContext) =>
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
                                                                      .pop(
                                                                          false),
                                                              child: const Text(
                                                                  'Cancel'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                          dialogContext)
                                                                      .pop(
                                                                          true),
                                                              child: const Text(
                                                                  'Delete'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (confirmed != true) {
                                                        return;
                                                      }
                                                      final menuProvider =
                                                          Provider.of<
                                                              shared
                                                              .MenuItemProvider>(
                                                        context,
                                                        listen: false,
                                                      );
                                                      try {
                                                        final franchiseId =
                                                            Provider.of<
                                                                shared
                                                                .FranchiseProvider>(
                                                          context,
                                                          listen: false,
                                                        ).franchiseId;

                                                        if (menuProvider
                                                            is MenuItemProviderImpl) {
                                                          menuProvider
                                                              .setFranchiseId(
                                                                  franchiseId);
                                                        }

                                                        final impl = menuProvider
                                                            as MenuItemProviderImpl;
                                                        impl.setFranchiseId(
                                                            franchiseId);
                                                        await impl
                                                            .deleteMenuItemAndPersist(
                                                                item.id);
                                                        if (!mounted) return;
                                                        setState(() {
                                                          _selectedIds
                                                              .remove(item.id);
                                                        });
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                                '✅ Item deleted'),
                                                            backgroundColor:
                                                                Colors.green,
                                                          ),
                                                        );
                                                      } catch (e, stack) {
                                                        shared.ErrorLogger.log(
                                                          message:
                                                              'delete_menu_item_failed',
                                                          stack:
                                                              stack.toString(),
                                                          source:
                                                              'onboarding_menu_items_screen',
                                                          severity: 'error',
                                                        );
                                                        if (!mounted) return;
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                '❌ Delete failed: $e'),
                                                            backgroundColor:
                                                                Colors.red,
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
                                // Bottom toolbar (template + mark complete only)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(
                                            Icons.dashboard_customize_outlined),
                                        label: const Text('Add from template'),
                                        onPressed: () async {
                                          await MenuItemTemplatePickerDialog
                                              .show(context);
                                          if (!mounted) return;

                                          setState(() {});

                                          final menuProvider = Provider.of<
                                              shared.MenuItemProvider>(
                                            context,
                                            listen: false,
                                          );
                                          final categories = Provider.of<
                                              shared.CategoryProvider>(
                                            context,
                                            listen: false,
                                          ).categories;
                                          final ingredients = Provider.of<
                                              shared
                                              .IngredientMetadataProvider>(
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
                                      const SizedBox(width: 16),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.check_circle),
                                        label: Text(
                                          anyItemHasSchemaErrors
                                              ? 'Fix schema errors first'
                                              : 'Mark Complete',
                                        ),
                                        onPressed: anyItemHasSchemaErrors
                                            ? null
                                            : _markComplete,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              right: 16,
                              bottom: 16,
                              child: FloatingActionButton.extended(
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
                                      source:
                                          'onboarding_menu_items_screen.dart',
                                      severity: 'error',
                                    );
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: Text(loc.addMenuItem),
                                backgroundColor: DesignTokens.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const VerticalDivider(width: 1, thickness: 1),

                      // ── Right: phone preview (foundation parity — no Center) ──
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                  color: Theme.of(context).dividerColor),
                            ),
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: MobileMenuPreviewCard(
                            franchiseId: context
                                .watch<shared.FranchiseProvider>()
                                .franchiseId,
                            interactive: true,
                          ),
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
