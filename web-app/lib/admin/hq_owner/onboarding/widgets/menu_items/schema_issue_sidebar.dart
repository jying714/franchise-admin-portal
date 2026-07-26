import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/ingredient_creation_dialog.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/ingredient_type_creation_dialog.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/category_creation_dialog.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class SchemaIssueSidebar extends StatefulWidget {
  final List<shared.MenuItemSchemaIssue> issues;
  final String franchiseId;
  final void Function(shared.MenuItemSchemaIssue issue, String newValue)
      onRepair;
  final VoidCallback onFullRefresh;
  final VoidCallback onNormalizeAll;

  const SchemaIssueSidebar({
    super.key,
    required this.issues,
    required this.franchiseId,
    required this.onRepair,
    required this.onFullRefresh,
    required this.onNormalizeAll,
  });

  @override
  State<SchemaIssueSidebar> createState() => _SchemaIssueSidebarState();
}

class _SchemaIssueSidebarState extends State<SchemaIssueSidebar> {
  final Map<String, String> _pendingRepairs = {};
  final Set<String> _resolvedKeys = {};

  String _compositeKey(shared.MenuItemSchemaIssue issue) =>
      '${issue.type}_${issue.field}_${issue.missingReference ?? ''}';

  void _handleRepair(shared.MenuItemSchemaIssue issue, String newValue) {
    final key = _compositeKey(issue);
    setState(() {
      _pendingRepairs[key] = newValue;
      _resolvedKeys.add(key);
    });
    widget.onRepair(issue, newValue);
    widget.onFullRefresh();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Fix applied • Issue resolved'),
        backgroundColor: Colors.green));
  }

  void _handleNormalizeAll() {
    widget.onNormalizeAll();
    // Do NOT clear resolved keys blindly — let editor recompute
    widget.onFullRefresh();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ All references normalized'),
        backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final unresolved = widget.issues
        .where((i) => !i.resolved && !_resolvedKeys.contains(_compositeKey(i)))
        .toList();
    final loc = AppLocalizations.of(context)!;

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Schema Issues', style: shared.UiConfig.titleStyle),
                const Spacer(),
                Chip(
                  label: Text('${unresolved.length} unresolved'),
                  backgroundColor:
                      unresolved.isEmpty ? Colors.green : Colors.orange,
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _handleNormalizeAll,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Normalize All References (Phase 1)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ),
          const Divider(),
          Expanded(
            child: unresolved.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 48),
                        Text('✅ All clean!',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: unresolved.length,
                    itemBuilder: (_, i) {
                      final issue = unresolved[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.orange),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      issue.displayMessage,
                                      style: shared.UiConfig.bodyStyle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Current: ${issue.missingReference ?? "unknown"}',
                                style: shared.UiConfig.bodyStyle
                                    .copyWith(fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              _RepairDropdown(
                                issue: issue,
                                currentValue:
                                    issue.missingReference ?? 'MARK_RESOLVED',
                                pendingValue:
                                    _pendingRepairs[_compositeKey(issue)],
                                franchiseId: widget.franchiseId,
                                onSelected: (v) =>
                                    v != null ? _handleRepair(issue, v) : null,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.add_circle,
                                        color: Colors.blue),
                                    label: const Text('Create New'),
                                    onPressed: () => _showCreationDialog(issue),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreationDialog(shared.MenuItemSchemaIssue issue) async {
    final loc = AppLocalizations.of(context)!;

    if (issue.type == shared.MenuItemSchemaIssueType.category) {
      final catProvider =
          Provider.of<shared.CategoryProvider>(context, listen: false);
      final newCat = await showDialog<shared.Category>(
        context: context,
        builder: (_) => CategoryCreationDialog(
          loc: loc,
          suggestedName: issue.label,
        ),
      );
      if (newCat == null || !mounted) return;
      await catProvider.createCategory(newCat);
      _handleRepair(issue, newCat.id);
      return;
    }

    if (issue.type == shared.MenuItemSchemaIssueType.ingredient) {
      final typeProvider =
          Provider.of<shared.IngredientTypeProvider>(context, listen: false);
      final ingProvider = Provider.of<shared.IngredientMetadataProvider>(
          context,
          listen: false);

      final newIng = await showDialog<shared.IngredientMetadata>(
        context: context,
        builder: (_) => IngredientCreationDialog(
          loc: loc,
          suggestedName: issue.label,
          availableTypeIds: typeProvider.allTypeIds,
          typeIdToName: typeProvider.typeIdToName,
        ),
      );
      if (newIng == null || !mounted) return;
      await ingProvider.createIngredient(newIng);
      _handleRepair(issue, newIng.id);
      return;
    }

    // Ingredient Type
    final typeProvider =
        Provider.of<shared.IngredientTypeProvider>(context, listen: false);
    final newType = await showDialog<shared.IngredientType>(
      context: context,
      builder: (_) => IngredientTypeCreationDialog(
        loc: loc,
        suggestedName: issue.label,
      ),
    );
    if (newType == null || newType.id == null || !mounted) return;
    await typeProvider.createType(widget.franchiseId, newType);
    _handleRepair(issue, newType.id!);
  }
}

// _RepairDropdown kept 100% from your latest local (conditional + always-current-value + ValueKey)
class _RepairDropdown extends StatelessWidget {
  final shared.MenuItemSchemaIssue issue;
  final String currentValue;
  final String? pendingValue;
  final String franchiseId;
  final ValueChanged<String?> onSelected;

  const _RepairDropdown({
    super.key,
    required this.issue,
    required this.currentValue,
    this.pendingValue,
    required this.franchiseId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final catProvider =
        Provider.of<shared.CategoryProvider>(context, listen: false);
    final ingProvider =
        Provider.of<shared.IngredientMetadataProvider>(context, listen: false);
    final typeProvider =
        Provider.of<shared.IngredientTypeProvider>(context, listen: false);

    final categories = catProvider.categories;
    final ingredients = ingProvider.ingredients;
    final ingredientTypes = typeProvider.ingredientTypes;

    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(
          value: currentValue, child: Text('Current: $currentValue')),
    ];

    if (issue.type == shared.MenuItemSchemaIssueType.category) {
      items.addAll(categories.map(
          (c) => DropdownMenuItem(value: c.id, child: Text('Cat: ${c.name}'))));
    } else if (issue.type == shared.MenuItemSchemaIssueType.ingredient) {
      items.addAll(ingredients.map(
          (i) => DropdownMenuItem(value: i.id, child: Text('Ing: ${i.name}'))));
    } else if (issue.type == shared.MenuItemSchemaIssueType.ingredientType) {
      items.addAll(ingredientTypes.map((t) =>
          DropdownMenuItem(value: t.id!, child: Text('Type: ${t.name}'))));
    } else {
      items.addAll([
        ...categories.map((c) =>
            DropdownMenuItem(value: c.id, child: Text('Cat: ${c.name}'))),
        ...ingredients.map((i) =>
            DropdownMenuItem(value: i.id, child: Text('Ing: ${i.name}'))),
        ...ingredientTypes.map((t) =>
            DropdownMenuItem(value: t.id!, child: Text('Type: ${t.name}'))),
      ]);
    }

    items.add(const DropdownMenuItem(
        value: 'MARK_RESOLVED', child: Text('✅ Mark Resolved')));

    final effective = pendingValue ??
        (items.any((i) => i.value == currentValue) ? currentValue : null);

    return DropdownButtonFormField<String>(
      key: ValueKey('${issue.field}_${currentValue}_${items.length}'),
      value: effective,
      items: items,
      onChanged: onSelected,
      isExpanded: true,
      decoration: const InputDecoration(
          border: InputBorder.none, contentPadding: EdgeInsets.zero),
    );
  }
}
