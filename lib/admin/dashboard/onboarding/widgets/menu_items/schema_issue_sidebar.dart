// lib/admin/dashboard/onboarding/widgets/menu_items/schema_issue_sidebar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/menu_item_schema_issue.dart';
import 'package:franchise_admin_portal/core/providers/category_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:franchise_admin_portal/core/models/ingredient_metadata.dart';
import 'package:franchise_admin_portal/core/models/ingredient_type_model.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

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
    final categoryProvider = context.watch<CategoryProvider>();
    final ingredientProvider = context.watch<IngredientMetadataProvider>();
    final ingredientTypeProvider = context.watch<IngredientTypeProvider>();

    final resolvedCount = issues.where((issue) => issue.resolved).length;
    final hasUnresolved = issues.any((issue) => !issue.resolved);

    return Material(
      elevation: 8,
      color: Colors.white,
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxWidth: 480, minWidth: 320),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              color: Colors.red.shade700.withOpacity(0.95),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
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
            if (issues.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No schema issues detected.',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              )
            else
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
                        return _CategoryRepairTile(
                          issue: issue,
                          provider: categoryProvider,
                          onRepair: (newValue) =>
                              _handleRepair(context, issue, newValue),
                        );
                      case MenuItemSchemaIssueType.ingredient:
                        return _IngredientRepairTile(
                          issue: issue,
                          provider: ingredientProvider,
                          onRepair: (newValue) =>
                              _handleRepair(context, issue, newValue),
                        );
                      case MenuItemSchemaIssueType.ingredientType:
                        return _IngredientTypeRepairTile(
                          issue: issue,
                          provider: ingredientTypeProvider,
                          onRepair: (newValue) =>
                              _handleRepair(context, issue, newValue),
                        );
                      default:
                        return ListTile(
                          leading: const Icon(Icons.error_outline,
                              color: Colors.red),
                          title: Text(issue.displayMessage),
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
                        Icon(Icons.error, color: Colors.red.shade700, size: 20),
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
                      style:
                          TextStyle(color: Colors.red.shade600, fontSize: 13),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleRepair(
      BuildContext context, MenuItemSchemaIssue issue, String newValue) async {
    try {
      onRepair(issue, newValue);
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

  const _CategoryRepairTile({
    Key? key,
    required this.issue,
    required this.provider,
    required this.onRepair,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final allIds = provider.allCategoryIds;
    final allNames = provider.allCategoryNames;
    return ListTile(
      leading: const Icon(Icons.category, color: Colors.orange),
      title: Text(issue.displayMessage),
      subtitle: DropdownButtonFormField<String>(
        value: null,
        hint: const Text('Select Category'),
        items: [
          for (final id in allIds)
            DropdownMenuItem(
              value: id,
              child: Text('${provider.categoryIdToName[id] ?? id}'),
            ),
        ],
        onChanged: (value) {
          if (value != null) onRepair(value);
        },
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add, color: Colors.blueGrey),
        tooltip: 'Create Category',
        onPressed: () {
          // (Optional: Open dialog to add a new category)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category creation not implemented.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}

class _IngredientRepairTile extends StatelessWidget {
  final MenuItemSchemaIssue issue;
  final IngredientMetadataProvider provider;
  final ValueChanged<String> onRepair;

  const _IngredientRepairTile({
    Key? key,
    required this.issue,
    required this.provider,
    required this.onRepair,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final allIds = provider.allIngredientIds;
    return ListTile(
      leading: const Icon(Icons.egg_alt_rounded, color: Colors.brown),
      title: Text(issue.displayMessage),
      subtitle: DropdownButtonFormField<String>(
        value: null,
        hint: const Text('Select Ingredient'),
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
      trailing: IconButton(
        icon: const Icon(Icons.add, color: Colors.blueGrey),
        tooltip: 'Create Ingredient',
        onPressed: () {
          // (Optional: Open dialog to add a new ingredient)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ingredient creation not implemented.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}

class _IngredientTypeRepairTile extends StatelessWidget {
  final MenuItemSchemaIssue issue;
  final IngredientTypeProvider provider;
  final ValueChanged<String> onRepair;

  const _IngredientTypeRepairTile({
    Key? key,
    required this.issue,
    required this.provider,
    required this.onRepair,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final allIds = provider.allTypeIds;
    return ListTile(
      leading: const Icon(Icons.label_important, color: Colors.purple),
      title: Text(issue.displayMessage),
      subtitle: DropdownButtonFormField<String>(
        value: null,
        hint: const Text('Select Ingredient Type'),
        items: [
          for (final id in allIds)
            DropdownMenuItem(
              value: id,
              child: Text('${provider.typeIdToName[id] ?? id}'),
            ),
        ],
        onChanged: (value) {
          if (value != null) onRepair(value);
        },
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add, color: Colors.blueGrey),
        tooltip: 'Create Ingredient Type',
        onPressed: () {
          // (Optional: Open dialog to add a new type)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ingredient type creation not implemented.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
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
    return ListTile(
      leading: const Icon(Icons.check_circle, color: Colors.green),
      title: Text(
        issue.displayMessage,
        style: const TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Colors.green,
            fontStyle: FontStyle.italic),
      ),
      subtitle: const Text('Resolved'),
    );
  }
}
