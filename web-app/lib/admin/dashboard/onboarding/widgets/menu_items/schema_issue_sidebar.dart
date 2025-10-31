// lib/admin/dashboard/onboarding/widgets/menu_items/schema_issue_sidebar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../../packages/shared_core/lib/src/core/models/menu_item_schema_issue.dart';
import '../../../../../../../packages/shared_core/lib/src/core/providers/category_provider.dart';
import '../../../../../../../packages/shared_core/lib/src/core/providers/ingredient_metadata_provider.dart';
import '../../../../../../../packages/shared_core/lib/src/core/providers/ingredient_type_provider.dart';
import '../../../../../../../packages/shared_core/lib/src/core/models/category.dart';
import '../../../../../../../packages/shared_core/lib/src/core/models/ingredient_metadata.dart';
import '../../../../../../../packages/shared_core/lib/src/core/models/ingredient_type_model.dart';
import '../../../../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/ingredient_creation_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/ingredient_type_creation_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/category_creation_dialog.dart';

/// Sidebar for displaying and resolving schema issues for a MenuItem during onboarding.
/// All repairs are applied via the passed-in callback.
class SchemaIssueSidebar extends StatelessWidget {
  final List<MenuItemSchemaIssue> issues;
  final void Function(MenuItemSchemaIssue issue, String newValue) onRepair;
  final VoidCallback? onClose;

  const SchemaIssueSidebar({
    Key? key,
    required this.issues,
    required this.onRepair,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasIssues = issues.isNotEmpty;
    final categoryProvider = context.watch<CategoryProvider>();
    final ingredientProvider = context.watch<IngredientMetadataProvider>();
    final ingredientTypeProvider = context.watch<IngredientTypeProvider>();
    final resolvedCount = issues.where((issue) => issue.resolved).length;
    final hasUnresolved = issues.any((issue) => !issue.resolved);
    print(
        '[SchemaIssueSidebar] Rendering... hasUnresolved=$hasUnresolved, resolvedCount=$resolvedCount/${issues.length}');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: hasUnresolved ? 420 : 64,
      constraints: BoxConstraints(
        maxWidth: hasUnresolved ? 480 : 96,
        minWidth: 56,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 12, offset: Offset(-3, 0)),
        ],
        border: Border(
          left: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: hasUnresolved
          // ========== FULL SIDEBAR ========== //
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  color: Colors.red.shade700.withOpacity(0.95),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hasUnresolved
                              ? 'Schema Issues Detected'
                              : 'All Issues Resolved',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18),
                        ),
                      ),
                      if (onClose != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: onClose,
                          tooltip: 'Close',
                        ),
                    ],
                  ),
                ),
                // List of issues (scrollable)
                Expanded(
                  child: ListView.separated(
                    itemCount: issues.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final issue = issues[index];
                      if (issue.resolved) {
                        return _ResolvedIssueTile(issue: issue);
                      }
                      switch (issue.type) {
                        case MenuItemSchemaIssueType.category:
                          final loc = AppLocalizations.of(context)!;
                          return _CategoryRepairTile(
                            issue: issue,
                            provider: categoryProvider,
                            onRepair: (newValue) =>
                                _handleRepair(context, issue, newValue),
                            loc: loc,
                          );
                        case MenuItemSchemaIssueType.ingredient:
                          final loc = AppLocalizations.of(context)!;
                          return _IngredientRepairTile(
                            issue: issue,
                            provider: ingredientProvider,
                            onRepair: (newValue) =>
                                _handleRepair(context, issue, newValue),
                            loc: loc,
                          );
                        case MenuItemSchemaIssueType.ingredientType:
                          final loc = AppLocalizations.of(context)!;
                          return _IngredientTypeRepairTile(
                            issue: issue,
                            provider: ingredientTypeProvider,
                            onRepair: (newValue) =>
                                _handleRepair(context, issue, newValue),
                            loc: loc,
                          );
                        case MenuItemSchemaIssueType.missingField:
                          return _MissingFieldRepairTile(
                            issue: issue,
                            onRepair: (newValue) =>
                                _handleRepair(context, issue, newValue),
                          );
                        default:
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            leading: Container(
                              width: 24,
                              alignment: Alignment.center,
                              child: const Icon(Icons.error_outline,
                                  color: Colors.red),
                            ),
                            title: Text(
                              issue.displayMessage.isNotEmpty
                                  ? issue.displayMessage
                                  : 'Unrecognized schema issue',
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                      }
                    },
                  ),
                ),
                // Status and actions
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasUnresolved)
                        Row(
                          children: [
                            Icon(Icons.error,
                                color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$resolvedCount / ${issues.length} issues resolved',
                                style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'All issues resolved!',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      if (hasUnresolved) const SizedBox(height: 12),
                      if (hasUnresolved)
                        Text(
                          'Please resolve all schema issues before saving this menu item.',
                          style: TextStyle(
                              color: Colors.red.shade600, fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            )
          // ========== COLLAPSED SIDEBAR (NO ISSUES) ========== //
          : Center(
              child: Tooltip(
                message: "No schema issues detected",
                preferBelow: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 36),
                    SizedBox(height: 8),
                    RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        "No Issues",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _handleRepair(
      BuildContext context, MenuItemSchemaIssue issue, String newValue) async {
    try {
      print(
          '[SchemaIssueSidebar] _handleRepair triggered for issue: ${issue.displayMessage}, value: $newValue');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        onRepair(issue, newValue);
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'schema_issue_sidebar_repair_failed',
        stack: stack.toString(),
        source: 'schema_issue_sidebar.dart',
        screen: 'schema_issue_sidebar',
        severity: 'error',
        contextData: {
          'issueType': issue.typeKey,
          'missingReference': issue.missingReference,
          'menuItemId': issue.menuItemId,
          'field': issue.field,
          'selectedValue': newValue,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update reference. See error logs.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ---------- Per-Issue-Type Repair Tiles ----------

class _CategoryRepairTile extends StatelessWidget {
  final MenuItemSchemaIssue issue;
  final CategoryProvider provider;
  final ValueChanged<String> onRepair;
  final AppLocalizations loc;

  const _CategoryRepairTile({
    Key? key,
    required this.issue,
    required this.provider,
    required this.onRepair,
    required this.loc,
  }) : super(key: key);

  Future<void> _handleCreateCategory(BuildContext context) async {
    final newCategory = await showDialog<Category>(
      context: context,
      builder: (ctx) => CategoryCreationDialog(
        loc: loc,
        suggestedName: issue.context ?? issue.label ?? issue.missingReference,
      ),
    );

    if (newCategory != null) {
      try {
        provider.stageCategory(newCategory);
        onRepair(newCategory.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.categoryStagedSuccessfully(newCategory.name),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e, stack) {
        await ErrorLogger.log(
          message: 'category_stage_failed',
          stack: stack.toString(),
          source: '_CategoryRepairTile',
          screen: 'schema_issue_sidebar.dart',
          severity: 'error',
          contextData: {
            'categoryName': newCategory.name,
            'issueContext':
                issue.context ?? issue.label ?? issue.missingReference,
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.genericErrorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue.displayMessage,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blueGrey),
                tooltip: loc.createNewCategory,
                onPressed: () => _handleCreateCategory(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: null,
            isExpanded: true,
            hint: Text(loc.selectCategory),
            items: [
              for (final id in provider.allCategoryIds)
                DropdownMenuItem(
                  value: id,
                  child: Text(provider.categoryIdToName[id] ?? id),
                ),
            ],
            onChanged: (value) {
              if (value != null) onRepair(value);
            },
          ),
        ],
      ),
    );
  }
}

class _IngredientRepairTile extends StatelessWidget {
  final MenuItemSchemaIssue issue;
  final IngredientMetadataProvider provider;
  final ValueChanged<String> onRepair;
  final AppLocalizations loc;

  const _IngredientRepairTile({
    Key? key,
    required this.issue,
    required this.provider,
    required this.onRepair,
    required this.loc,
  }) : super(key: key);

  Future<void> _handleCreateIngredient(BuildContext context) async {
    final newIngredient = await showDialog<IngredientMetadata>(
      context: context,
      builder: (ctx) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: context.read<IngredientTypeProvider>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<IngredientMetadataProvider>(),
          ),
        ],
        child: IngredientCreationDialog(
          loc: loc,
          suggestedName: issue.context ?? issue.label ?? issue.missingReference,
        ),
      ),
    );

    if (newIngredient != null) {
      try {
        provider.stageIngredient(newIngredient); // 🔄 stage it, don’t save
        onRepair(newIngredient.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.ingredientStagedSuccessfully(newIngredient.name),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e, stack) {
        await ErrorLogger.log(
          message: 'ingredient_stage_failed',
          stack: stack.toString(),
          source: '_IngredientRepairTile',
          screen: 'schema_issue_sidebar.dart',
          severity: 'error',
          contextData: {
            'ingredientName': newIngredient.name,
            'issueContext':
                issue.context ?? issue.label ?? issue.missingReference,
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.genericErrorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allIds = provider.allIngredientIds;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                alignment: Alignment.center,
                child: const Icon(Icons.egg_alt_rounded, color: Colors.brown),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue.displayMessage,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blueGrey),
                tooltip: loc.createNewIngredient,
                onPressed: () => _handleCreateIngredient(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: null,
            isExpanded: true,
            hint: Text(loc.selectIngredient),
            items: [
              for (final id in allIds)
                DropdownMenuItem(
                  value: id,
                  child: Text('${provider.ingredientIdToName[id] ?? id}'),
                ),
            ],
            onChanged: (value) {
              if (value != null) onRepair(value);
            },
          ),
        ],
      ),
    );
  }
}

class _IngredientTypeRepairTile extends StatelessWidget {
  final MenuItemSchemaIssue issue;
  final IngredientTypeProvider provider;
  final ValueChanged<String> onRepair;
  final AppLocalizations loc;

  const _IngredientTypeRepairTile({
    Key? key,
    required this.issue,
    required this.provider,
    required this.onRepair,
    required this.loc,
  }) : super(key: key);

  Future<void> _handleCreateIngredientType(BuildContext context) async {
    final newType = await showDialog<IngredientType>(
      context: context,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: provider,
        child: IngredientTypeCreationDialog(
          loc: loc,
          suggestedName: issue.context ?? issue.label ?? issue.missingReference,
        ),
      ),
    );

    if (newType != null) {
      try {
        provider.stageIngredientType(newType); // ✅ stage for persistence
        onRepair(newType.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.ingredientTypeStagedSuccessfully(newType.name),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e, stack) {
        await ErrorLogger.log(
          message: 'ingredient_type_stage_failed',
          stack: stack.toString(),
          source: '_IngredientTypeRepairTile',
          screen: 'schema_issue_sidebar.dart',
          severity: 'error',
          contextData: {
            'typeName': newType.name,
            'issueContext':
                issue.context ?? issue.label ?? issue.missingReference,
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.genericErrorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allIds = provider.allTypeIds;
    final typeIdToName = provider.typeIdToName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                alignment: Alignment.center,
                child: const Icon(Icons.label_important, color: Colors.purple),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue.displayMessage,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blueGrey),
                tooltip: loc.createNewIngredientType,
                onPressed: () => _handleCreateIngredientType(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: null,
            hint: Text(loc.selectIngredientType),
            items: [
              for (final id in allIds)
                DropdownMenuItem(
                  value: id,
                  child: Text('${typeIdToName[id] ?? id}'),
                ),
            ],
            onChanged: (value) {
              if (value != null) onRepair(value);
            },
          ),
        ],
      ),
    );
  }
}

class _MissingFieldRepairTile extends StatelessWidget {
  final MenuItemSchemaIssue issue;
  final ValueChanged<String> onRepair;

  const _MissingFieldRepairTile({
    Key? key,
    required this.issue,
    required this.onRepair,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                alignment: Alignment.center,
                child: const Icon(Icons.edit_note_rounded,
                    color: Colors.blueAccent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue.displayMessage,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Enter ${issue.label ?? issue.field}',
            ),
            onFieldSubmitted: (value) {
              if (value.isNotEmpty) onRepair(value);
            },
          ),
        ],
      ),
    );
  }
}

// ------------- Resolved Issue Tile (read-only) -------------

class _ResolvedIssueTile extends StatelessWidget {
  final MenuItemSchemaIssue issue;
  const _ResolvedIssueTile({Key? key, required this.issue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                alignment: Alignment.center,
                child: const Icon(Icons.check_circle, color: Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue.displayMessage,
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.green,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 40),
            child: Text(
              'Resolved',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
