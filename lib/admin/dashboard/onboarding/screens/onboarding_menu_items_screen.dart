import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/menu_item_provider.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_progress_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/core/utils/features/feature_guard.dart';
import 'package:franchise_admin_portal/core/utils/features/feature_gate_banner.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_editor_sheet.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_items_list_tile.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_json_import_export_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_template_picker_dialog.dart';
import 'package:franchise_admin_portal/core/models/menu_item.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider.dart';
import 'package:franchise_admin_portal/core/providers/category_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/schema_issue_sidebar.dart';
import 'package:franchise_admin_portal/core/models/menu_item_schema_issue.dart';

class OnboardingMenuItemsScreen extends StatefulWidget {
  const OnboardingMenuItemsScreen({super.key});

  @override
  State<OnboardingMenuItemsScreen> createState() =>
      _OnboardingMenuItemsScreenState();
}

class _OnboardingMenuItemsScreenState extends State<OnboardingMenuItemsScreen> {
  bool _hasInitialized = false;
  final Set<String> _selectedIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) return;

    final franchiseId = context.read<FranchiseProvider>().franchiseId;
    if (franchiseId.isNotEmpty && franchiseId != 'unknown') {
      context.read<MenuItemProvider>().loadMenuItems(franchiseId);
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

  void _openEditor({MenuItem? item}) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (_) => MenuItemEditorSheet(
        existing: item,
        onSave: (updatedItem) async {
          final provider = context.read<MenuItemProvider>();
          provider.addOrUpdateMenuItem(updatedItem);
          Navigator.of(context).pop();
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<MenuItemProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // State for the sidebar and issues
    bool showSchemaSidebar = false;
    List<MenuItemSchemaIssue> schemaIssues = [];
    MenuItem? itemPendingRepair;

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

    // Reusable openEditor with schema checking logic
    void openEditor({MenuItem? item}) {
      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) => MenuItemEditorSheet(
          existing: item,
          onSave: (updatedItem) async {
            // After save, check for schema issues
            checkForSchemaIssues(updatedItem);
            if (!showSchemaSidebar) {
              provider.addOrUpdateMenuItem(updatedItem);
              Navigator.of(context).pop();
            }
            // If issues, sidebar will appear and user must repair/resolve
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      );
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
          // You will likely need to update includedIngredients/optionalAddOns, etc.
          // Example: Replace ingredientId in includedIngredients with newValue
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
          // Update the appropriate field in ingredient references or metadata
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
                icon: const Icon(Icons.library_add),
                tooltip: loc.loadDefaultTemplates,
                onPressed: () => MenuItemTemplatePickerDialog.show(context),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: loc.markAsComplete,
                onPressed: _markComplete,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => openEditor(),
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
                          onPressed: provider.persistChanges,
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
        // === SCHEMA ISSUE SIDEBAR, overlays when there are schema issues after add/edit ===
        if (showSchemaSidebar && itemPendingRepair != null)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 440,
            child: Material(
              elevation: 12,
              color: Colors.white,
              child: SchemaIssueSidebar(
                issues: schemaIssues,
                onRepair:
                    handleSidebarRepair, // must match (MenuItemSchemaIssue, String)
                onClose: () {
                  setState(() {
                    showSchemaSidebar = false;
                    itemPendingRepair = null;
                    schemaIssues = [];
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}
