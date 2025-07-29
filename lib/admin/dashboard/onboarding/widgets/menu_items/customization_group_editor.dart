import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/customization_group.dart';
import 'package:franchise_admin_portal/core/models/ingredient_reference.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/multi_ingredient_selector.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Allows devs to define multiple customization groups (e.g. Sauce, Toppings, Bread)
/// within a menu item. Each group can specify label, limit, and list of ingredients.
///
/// This is NOT a live schema editor. It's used to select from pre-created ingredients
/// and assemble logical groups for a menu item's customization flow.
class CustomizationGroupEditor extends StatefulWidget {
  final List<CustomizationGroup> value;
  final void Function(List<CustomizationGroup>) onChanged;

  const CustomizationGroupEditor({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<CustomizationGroupEditor> createState() =>
      _CustomizationGroupEditorState();
}

class _CustomizationGroupEditorState extends State<CustomizationGroupEditor> {
  late List<CustomizationGroup> _groups;

  @override
  void initState() {
    super.initState();
    _groups = List<CustomizationGroup>.from(widget.value);
  }

  void _updateGroup(int index, CustomizationGroup updated) {
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
        CustomizationGroup(
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
    final ingredientProvider = context.read<IngredientMetadataProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.customizationGroups,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._groups.asMap().entries.map((entry) {
          final index = entry.key;
          final group = entry.value;

          // Validation
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
                  // 🔤 Group Label Input
                  TextFormField(
                    initialValue: group.label,
                    decoration: InputDecoration(
                      labelText: loc.customizationGroupLabel,
                    ),
                    onChanged: (val) => _updateGroup(
                      index,
                      group.copyWith(label: val),
                    ),
                  ),

                  // Validation after label
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

                  // 🔢 Selection Limit Input
                  Row(
                    children: [
                      Text(loc.selectionLimit),
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

                  // 🧀 Ingredient Selector
                  MultiIngredientSelector(
                    title: group.label.isNotEmpty
                        ? group.label
                        : loc.customizationGroupLabel,
                    selected: group.ingredients,
                    onChanged: (ingredients) {
                      _updateGroup(
                          index, group.copyWith(ingredients: ingredients));
                    },
                  ),

                  // Validation after ingredient selection
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
                      label: Text(loc.removeGroup),
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
          label: Text(loc.addCustomizationGroup),
        ),
      ],
    );
  }
}
