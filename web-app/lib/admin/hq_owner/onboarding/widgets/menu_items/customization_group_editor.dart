import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/multi_ingredient_selector.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';

class CustomizationGroupEditor extends StatefulWidget {
  final List<shared.CustomizationGroup> value;
  final void Function(List<shared.CustomizationGroup>) onChanged;

  const CustomizationGroupEditor({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<CustomizationGroupEditor> createState() =>
      _CustomizationGroupEditorState();
}

class _CustomizationGroupEditorState extends State<CustomizationGroupEditor> {
  late List<shared.CustomizationGroup> _groups;

  @override
  void initState() {
    super.initState();
    _groups = List<shared.CustomizationGroup>.from(widget.value);
  }

  void _updateGroup(int index, shared.CustomizationGroup updated) {
    setState(() {
      _groups[index] = updated;
    });
    widget.onChanged(_groups);
  }

  void _removeGroup(int index) {
    setState(() {
      _groups.removeAt(index);
    });
    widget.onChanged(_groups);
  }

  void _addGroup() {
    setState(() {
      _groups.add(
        shared.CustomizationGroup(
          id: UniqueKey().toString(),
          label: '',
          selectionLimit: 1,
          ingredients: [],
        ),
      );
    });
    widget.onChanged(_groups);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.customizationGroups ?? 'Customization Groups',
          style: shared.UiConfig.titleStyle,
        ),
        const SizedBox(height: 8),
        ..._groups.asMap().entries.map((entry) {
          final index = entry.key;
          final group = entry.value;

          final duplicateLabel = _groups
                  .where((g) =>
                      g.label.trim().toLowerCase() ==
                      group.label.trim().toLowerCase())
                  .length >
              1;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: group.label,
                    decoration: InputDecoration(
                      labelText: loc.customizationGroupLabel ?? 'Group Label',
                    ),
                    onChanged: (val) => _updateGroup(
                      index,
                      group.copyWith(label: val),
                    ),
                  ),
                  if (group.label.trim().isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 0),
                      child: Text(
                        'Group label required',
                        style:
                            TextStyle(color: Colors.red.shade600, fontSize: 12),
                      ),
                    ),
                  if (duplicateLabel)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 0),
                      child: Text(
                        'Duplicate group label',
                        style:
                            TextStyle(color: Colors.red.shade600, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(loc.selectionLimit ?? 'Selection Limit'),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: group.selectionLimit,
                        onChanged: (val) {
                          if (val != null) {
                            _updateGroup(
                                index, group.copyWith(selectionLimit: val));
                          }
                        },
                        items: List.generate(
                          6,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text('${i + 1}'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MultiIngredientSelector(
                    title: group.label.isNotEmpty
                        ? group.label
                        : (loc.customizationGroupLabel ??
                            'Customization Group'),
                    selected: group.ingredients,
                    onChanged: (ingredients) {
                      _updateGroup(
                          index, group.copyWith(ingredients: ingredients));
                    },
                  ),
                  if (group.ingredients.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 0),
                      child: Text(
                        'Select at least one ingredient',
                        style:
                            TextStyle(color: Colors.red.shade600, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeGroup(index),
                      label: Text(loc.removeGroup ?? 'Remove Group'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addGroup,
          icon: const Icon(Icons.add),
          label: Text(loc.addCustomizationGroup ?? 'Add Customization Group'),
        ),
      ],
    );
  }
}
