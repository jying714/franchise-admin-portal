import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/ingredient_creation_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/ingredient_type_creation_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/category_creation_dialog.dart';
import 'package:franchise_admin_portal/config/ui_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class SchemaIssueSidebar extends StatefulWidget {
  final List<shared.MenuItemSchemaIssue> issues;
  final void Function(shared.MenuItemSchemaIssue issue, String newValue)
      onRepair;
  final VoidCallback onFullRefresh;
  final VoidCallback? onClose;

  const SchemaIssueSidebar({
    super.key,
    required this.issues,
    required this.onRepair,
    required this.onFullRefresh,
    this.onClose,
  });

  @override
  State<SchemaIssueSidebar> createState() => _SchemaIssueSidebarState();
}

class _SchemaIssueSidebarState extends State<SchemaIssueSidebar> {
  final Map<String, String> _pendingRepairs = {};
  bool _isApplying = false;
  bool _isNormalizing = false;

  @override
  void didUpdateWidget(SchemaIssueSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.issues.length != oldWidget.issues.length) {
      setState(() => _pendingRepairs.clear());
      shared.ErrorLogger.log(
        message: 'Sidebar updated – issues: ${widget.issues.length}',
        source: 'SchemaIssueSidebar',
        severity: 'info',
      );
    }
  }

  void _handleRepair(shared.MenuItemSchemaIssue issue, String newValue) {
    setState(() => _pendingRepairs[issue.field] = newValue);
    widget.onRepair(issue, newValue);
    widget.onFullRefresh();
  }

  Future<void> _handleApplyAll() async {
    setState(() => _isApplying = true);
    for (final issue in widget.issues) {
      final pending = _pendingRepairs[issue.field];
      if (pending != null) {
        widget.onRepair(issue, pending);
      }
    }
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onFullRefresh();
    setState(() {
      _pendingRepairs.clear();
      _isApplying = false;
    });
    widget.onClose?.call();
  }

  Future<void> _normalizeAll() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Normalize All References?'),
        content: Text(
          'This will automatically fix legacy category/ingredient/type IDs '
          'by matching names to current franchise data.\n\n'
          'This action is safe and reversible via Firestore history.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Normalize All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isNormalizing = true);

    try {
      final menuProvider =
          Provider.of<shared.MenuItemProvider>(context, listen: false);
      final result = await menuProvider.normalizeSchemaReferences();

      widget.onFullRefresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Normalized ${result['menuItems'] ?? 0} menu items, '
                '${result['categories'] ?? 0} categories, etc.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Normalization failed. Check logs.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isNormalizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unresolved = widget.issues.where((i) => !i.resolved).toList();
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Text('Schema Issues', style: UiConfig.titleStyle),
                const Spacer(),
                Chip(
                  label: Text('${unresolved.length} unresolved'),
                  backgroundColor:
                      unresolved.isEmpty ? Colors.green : Colors.orange,
                ),
                IconButton(
                    icon: const Icon(Icons.close), onPressed: widget.onClose),
              ],
            ),
          ),

          if (unresolved.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ElevatedButton.icon(
                onPressed: _isNormalizing ? null : _normalizeAll,
                icon: _isNormalizing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_fix_high),
                label: Text(_isNormalizing
                    ? 'Normalizing...'
                    : 'Normalize All References'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

          Expanded(
            child: unresolved.isEmpty
                ? Center(
                    child: Text(
                      'No schema issues found',
                      style: UiConfig.bodyStyle,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: unresolved.length,
                    itemBuilder: (context, index) {
                      final issue = unresolved[index];
                      return _RepairTile(
                        issue: issue,
                        pendingValue: _pendingRepairs[issue.field],
                        onRepair: (value) => _handleRepair(issue, value),
                        onCreateNew: () => _showCreationDialog(context, issue),
                      );
                    },
                  ),
          ),

          // Bottom Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClose,
                    child: Text(l10n.cancel ?? 'Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: unresolved.isEmpty || _isApplying
                        ? null
                        : _handleApplyAll,
                    child: _isApplying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Apply All Fixes'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreationDialog(
      BuildContext context, shared.MenuItemSchemaIssue issue) {
    final l10n = AppLocalizations.of(context)!;
    final franchiseProvider = Provider.of<shared.FranchiseProvider>(
      context,
      listen: false,
    );

    if (issue.type == shared.MenuItemSchemaIssueType.category) {
      showDialog(
        context: context,
        builder: (_) => CategoryCreationDialog(
          loc: l10n,
          suggestedName: issue.label,
        ),
      ).then((newCat) {
        if (newCat != null)
          _handleRepair(issue, (newCat as shared.Category).id);
      });
    } else if (issue.type == shared.MenuItemSchemaIssueType.ingredient) {
      showDialog(
        context: context,
        builder: (_) => IngredientCreationDialog(
          loc: l10n,
          suggestedName: issue.label,
          availableTypeIds:
              franchiseProvider.currentFranchiseIngredientTypeIds ?? [],
          typeIdToName:
              franchiseProvider.currentFranchiseIngredientTypeIdToName ?? {},
        ),
      ).then((newIng) {
        if (newIng != null)
          _handleRepair(issue, (newIng as shared.IngredientMetadata).id);
      });
    } else {
      showDialog(
        context: context,
        builder: (_) => IngredientTypeCreationDialog(
          loc: l10n,
          suggestedName: issue.label,
        ),
      ).then((newType) {
        if (newType != null)
          _handleRepair(issue, (newType as shared.IngredientType).id!);
      });
    }
  }
}

class _RepairTile extends StatelessWidget {
  final shared.MenuItemSchemaIssue issue;
  final String? pendingValue;
  final ValueChanged<String> onRepair;
  final VoidCallback onCreateNew;

  const _RepairTile({
    super.key,
    required this.issue,
    required this.pendingValue,
    required this.onRepair,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(issue.displayMessage, style: UiConfig.bodyStyle),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: (pendingValue ?? issue.missingReference ?? '')
                            .isNotEmpty
                        ? (pendingValue ?? issue.missingReference)
                        : null,
                    items: _buildDropdownItems(context, issue),
                    onChanged: (v) {
                      if (v != null) onRepair(v);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Fix →',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                    onPressed: onCreateNew,
                    icon: const Icon(Icons.add_circle, color: Colors.green)),
                IconButton(
                    onPressed: () => onRepair('__MARK_RESOLVED__'),
                    icon: const Icon(Icons.check_circle, color: Colors.blue)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems(
      BuildContext context, shared.MenuItemSchemaIssue issue) {
    final items = <DropdownMenuItem<String>>[];
    final currentValue = pendingValue ?? issue.missingReference ?? '';

    // 1. Always add the current value first (prevents assertion)
    if (currentValue.isNotEmpty) {
      items.add(DropdownMenuItem(
        value: currentValue,
        child: Text(currentValue == '__MARK_RESOLVED__'
            ? '✅ Mark resolved (mobile safe)'
            : 'Current: $currentValue'),
      ));
    }

    // 2. Add real options from providers
    if (issue.type == shared.MenuItemSchemaIssueType.category) {
      final cats = Provider.of<shared.CategoryProvider>(context, listen: false)
          .categories;
      for (final c in cats) {
        if (c.id.isNotEmpty) {
          items.add(DropdownMenuItem(
              value: c.id, child: Text('${c.name} (${c.id})')));
        }
      }
    } else if (issue.type == shared.MenuItemSchemaIssueType.ingredient) {
      final ings =
          Provider.of<shared.IngredientMetadataProvider>(context, listen: false)
              .allIngredients;
      for (final i in ings) {
        if (i.id.isNotEmpty) {
          items.add(DropdownMenuItem(value: i.id, child: Text(i.name)));
        }
      }
    } else {
      final types =
          Provider.of<shared.IngredientTypeProvider>(context, listen: false)
              .ingredientTypes;
      for (final t in types) {
        if (t.id?.isNotEmpty == true) {
          items.add(DropdownMenuItem(value: t.id!, child: Text(t.name)));
        }
      }
    }

    // 3. Safety net (add only if not already present)
    if (!items.any((item) => item.value == '__MARK_RESOLVED__')) {
      items.add(const DropdownMenuItem(
        value: '__MARK_RESOLVED__',
        child: Text('✅ Mark resolved (mobile safe)'),
      ));
    }

    return items;
  }
}
