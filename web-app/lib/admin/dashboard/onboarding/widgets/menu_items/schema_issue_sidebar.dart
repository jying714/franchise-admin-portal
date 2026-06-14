import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/ingredient_creation_dialog.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/ingredient_type_creation_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/category_creation_dialog.dart';

class SchemaIssueSidebar extends StatefulWidget {
  final List<shared.MenuItemSchemaIssue> issues;
  final void Function(shared.MenuItemSchemaIssue issue, String newValue)
      onRepair;
  final VoidCallback? onClose;

  const SchemaIssueSidebar({
    Key? key,
    required this.issues,
    required this.onRepair,
    this.onClose,
  }) : super(key: key);

  @override
  State<SchemaIssueSidebar> createState() => _SchemaIssueSidebarState();
}

class _SchemaIssueSidebarState extends State<SchemaIssueSidebar> {
  final Map<String, String> _pendingRepairs = {};

  @override
  void didUpdateWidget(SchemaIssueSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    print(
        '[DEBUG Sidebar] didUpdateWidget - Old count: ${oldWidget.issues.length} New count: ${widget.issues.length} | real data now flowing');
  }

  @override
  Widget build(BuildContext context) {
    final unresolvedCount = widget.issues.where((e) => !e.resolved).length;
    print(
        '[DEBUG Sidebar] build called with real issues count: ${widget.issues.length} (unresolved: $unresolvedCount)');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: unresolvedCount > 0 ? 460 : 64,
      constraints: BoxConstraints(maxWidth: unresolvedCount > 0 ? 480 : 96),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: const Offset(-4, 0))
        ],
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      child: unresolvedCount > 0
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.red.shade700,
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              'Schema Issues • $unresolvedCount remaining',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      if (widget.onClose != null)
                        IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 20),
                            onPressed: widget.onClose),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.issues.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final issue = widget.issues[index];
                        print(
                            '[DEBUG Sidebar] Rendering #${index}: ${issue.displayMessage} resolved=${issue.resolved}');
                        if (issue.resolved)
                          return _ResolvedIssueTile(issue: issue);
                        return _RepairTile(
                          issue: issue,
                          onApply: (newValue) {
                            print(
                                '[DEBUG Sidebar] Apply → ${issue.displayMessage} value=$newValue');
                            widget.onRepair(issue, newValue);
                            setState(() =>
                                _pendingRepairs[issue.missingReference] =
                                    newValue);
                          },
                          onCreateNew: () => _handleCreateNew(context, issue),
                          pendingValue: _pendingRepairs[issue.missingReference],
                        );
                      },
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 8),
                RotatedBox(
                    quarterTurns: 3,
                    child: Text('NO ISSUES',
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold))),
              ]),
            ),
    );
  }

  void _handleCreateNew(
      BuildContext context, shared.MenuItemSchemaIssue issue) async {
    print('[DEBUG Sidebar] Create New for: ${issue.displayMessage}');
    final loc = AppLocalizations.of(context)!;
    dynamic result;

    if (issue.type == shared.MenuItemSchemaIssueType.category) {
      result = await showDialog(
          context: context,
          builder: (_) => CategoryCreationDialog(
              loc: loc, suggestedName: issue.label ?? issue.missingReference));
    } else if (issue.type == shared.MenuItemSchemaIssueType.ingredient) {
      result = await showDialog(
          context: context,
          builder: (_) => IngredientCreationDialog(
              loc: loc,
              suggestedName: issue.label ?? issue.missingReference,
              availableTypeIds: [],
              typeIdToName: {}));
    } else {
      result = await showDialog(
          context: context,
          builder: (_) => IngredientTypeCreationDialog(
              loc: loc, suggestedName: issue.label ?? issue.missingReference));
    }

    if (result != null && mounted) {
      print('[DEBUG Sidebar] Create New result: ${result.id ?? result.name}');
      widget.onRepair(issue, result.id ?? result.name ?? '');
      setState(() => _pendingRepairs.clear());
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('✅ Created & Applied')));
    }
  }
}

class _RepairTile extends StatelessWidget {
  final shared.MenuItemSchemaIssue issue;
  final ValueChanged<String> onApply;
  final VoidCallback onCreateNew;
  final String? pendingValue;

  const _RepairTile({
    Key? key,
    required this.issue,
    required this.onApply,
    required this.onCreateNew,
    this.pendingValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    print('[DEBUG RepairTile] Building for: ${issue.displayMessage}');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  issue.type == shared.MenuItemSchemaIssueType.category
                      ? Icons.category
                      : Icons.egg,
                  color: Colors.orange,
                  size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  issue.displayMessage,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blueGrey, size: 16),
                tooltip: 'Create New (last resort)',
                onPressed: onCreateNew,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: DropdownButtonFormField<String>(
                  value: pendingValue,
                  isExpanded: true,
                  hint: Text(
                    issue.type == shared.MenuItemSchemaIssueType.category
                        ? 'Select category'
                        : 'Select ingredient/type',
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: const TextStyle(fontSize: 11),
                  items: _buildDropdownItems(context, issue),
                  onChanged: (val) {
                    print('[DEBUG RepairTile] Dropdown changed: $val');
                    if (val != null) {
                      onApply(
                          val); // Parent Stateful handles pending update and rebuild
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    textStyle: const TextStyle(fontSize: 11),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    print(
                        '[DEBUG RepairTile] Apply pressed - value: $pendingValue');
                    if (pendingValue != null) onApply(pendingValue!);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Applied')));
                    // Force sidebar to stay open until user closes
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems(
      BuildContext context, shared.MenuItemSchemaIssue issue) {
    final items = <DropdownMenuItem<String>>[];

    if (issue.type == shared.MenuItemSchemaIssueType.category) {
      final categories =
          Provider.of<shared.CategoryProvider>(context, listen: false)
              .categories;
      for (final c in categories) {
        items.add(DropdownMenuItem(
            value: c.id,
            child: Text(c.name, style: const TextStyle(fontSize: 12))));
      }
    } else {
      final metadataProvider = Provider.of<shared.IngredientMetadataProvider>(
          context,
          listen: false);
      final allItems = metadataProvider.allIngredients;
      for (final i in allItems) {
        items.add(DropdownMenuItem(
            value: i.id,
            child: Text(i.name, style: const TextStyle(fontSize: 12))));
      }
    }

    // Add pending value for ALL types to prevent assertion + support staged repairs
    if (pendingValue != null &&
        !items.any((item) => item.value == pendingValue)) {
      items.add(DropdownMenuItem(
        value: pendingValue,
        child: Text(pendingValue!,
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
      ));
    }

    return items;
  }
}

class _ResolvedIssueTile extends StatelessWidget {
  final shared.MenuItemSchemaIssue issue;
  const _ResolvedIssueTile({Key? key, required this.issue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              issue.displayMessage,
              style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.green,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
