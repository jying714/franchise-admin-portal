import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/menu_item_provider.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_progress_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_form_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_items_list_tile.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_json_import_export_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_template_picker_dialog.dart';

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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<MenuItemProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
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
        onPressed: () => MenuItemFormDialog.show(context),
        icon: const Icon(Icons.add),
        label: Text(loc.addMenuItem),
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
            const SizedBox(height: 12),
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
                            onEdit: () => MenuItemFormDialog.show(
                              context,
                              initialItem: item,
                            ),
                            onDelete: () async {
                              final loc = AppLocalizations.of(context)!;
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
                                          backgroundColor: Colors.red),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(loc.delete),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await provider.deleteFromFirestore(item.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(loc.menuItemDeleted)),
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
    );
  }
}
