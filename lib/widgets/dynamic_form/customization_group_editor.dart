import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';

class CustomizationGroupEditor extends StatefulWidget {
  final List<Map<String, dynamic>> customizations;
  final void Function(List<Map<String, dynamic>>) onChanged;

  const CustomizationGroupEditor({
    super.key,
    required this.customizations,
    required this.onChanged,
  });

  @override
  State<CustomizationGroupEditor> createState() =>
      _CustomizationGroupEditorState();
}

class _CustomizationGroupEditorState extends State<CustomizationGroupEditor> {
  int? _expandedIndex;
  late List<Map<String, dynamic>> _groups;
  List<Map<String, dynamic>> _templates = [];
  List<Map<String, dynamic>> _ingredientMetadataList = [];
  bool _loadingTemplates = false;
  bool _loadingIngredients = false;

  @override
  void initState() {
    super.initState();
    _groups = List<Map<String, dynamic>>.from(widget.customizations);
    _loadTemplatesAndIngredients();
  }

  Future<void> _loadTemplatesAndIngredients() async {
    setState(() {
      _loadingTemplates = true;
      _loadingIngredients = true;
    });

    final fs = Provider.of<FirestoreService>(context, listen: false);

    // Await both futures first
    final results = await Future.wait([
      fs.fetchCustomizationTemplatesAsMaps(),
      fs.fetchIngredientMetadataAsMaps(),
    ]);

    // Now you can safely print using results[0]
    print('[DEBUG] Customization templates loaded: ${results[0].length}');
    for (final tpl in results[0]) {
      print(
          '[DEBUG] Template: ${tpl['label']} | ingredientIds: ${tpl['ingredientIds']}');
    }

    if (!mounted) return;
    setState(() {
      _templates = List<Map<String, dynamic>>.from(results[0]);
      _ingredientMetadataList = List<Map<String, dynamic>>.from(results[1]);
      _loadingTemplates = false;
      _loadingIngredients = false;
    });
  }

  Map<String, dynamic>? _findTemplateByLabel(String label) {
    try {
      return _templates.firstWhere((tpl) {
        final l = (tpl['label'] is Map ? tpl['label']['en'] : tpl['label'])
            ?.toString();
        return l?.toLowerCase() == label.toLowerCase();
      });
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _findIngredientByName(String name) {
    try {
      return _ingredientMetadataList.firstWhere(
        (ing) => ing['name'].toString().toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  String _getIngredientNameById(String id) {
    final found = _ingredientMetadataList.firstWhere(
      (ing) => ing['id'].toString() == id,
      orElse: () => {},
    );
    print(
        '[DEBUG][UI] Resolving ingredientId "$id": ${found['name'] ?? 'NOT FOUND'}');
    return found['name'] ?? id;
  }

  void _addGroup() {
    setState(() {
      _groups.add({
        'label': '',
        'ingredientIds': <String>[],
      });
    });
    _expandedIndex = _groups.length - 1; // Expand the new group
    print(
        '[DEBUG] Added new group: ${_groups.isNotEmpty ? _groups.last : 'EMPTY'}');
    widget.onChanged(_groups);
  }

  void _removeGroup(int index) {
    setState(() {
      _groups.removeAt(index);
      print('[DEBUG] Removed group at index $index. Groups now: $_groups');
    });
    widget.onChanged(_groups);
  }

  void _updateGroupLabel(int index, String value) {
    setState(() {
      _groups[index]['label'] = value.trim();
      // Auto-populate from template if found
      final tpl = _findTemplateByLabel(value.trim());
      _expandedIndex = index; // Always expand group after label/template change
      if (tpl != null) {
        print('[DEBUG] Template found for label "$value": $tpl');
        _groups[index]['ingredientIds'] =
            List<String>.from(tpl['ingredientIds'] ?? []);
        _groups[index]['inputMode'] = tpl['inputMode'];
        _groups[index]['optionsSource'] = tpl['optionsSource'];
        _groups[index]['locked'] = tpl['locked'];
        print('[DEBUG] Group $index after template applied: ${_groups[index]}');
      } else {
        print('[DEBUG] No template found for label "$value".');
      }
    });
    widget.onChanged(_groups);
  }

  void _addIngredientToGroup(int groupIndex, String ingredientName) {
    final found = _findIngredientByName(ingredientName);
    if (found == null) return;
    setState(() {
      print(
          '[DEBUG] Added ingredient "${found['id']}" to group $groupIndex: ${_groups[groupIndex]['ingredientIds']}');
      final ingredientIds =
          List<String>.from(_groups[groupIndex]['ingredientIds'] ?? []);
      if (!ingredientIds.contains(found['id'])) {
        ingredientIds.add(found['id']);
        _groups[groupIndex]['ingredientIds'] = ingredientIds;
      }
    });
    widget.onChanged(_groups);
  }

  void _removeIngredientFromGroup(int groupIndex, int ingredientIndex) {
    setState(() {
      print(
          '[DEBUG] Removed ingredient at index $ingredientIndex from group $groupIndex: ${_groups[groupIndex]['ingredientIds']}');
      final ingredientIds =
          List<String>.from(_groups[groupIndex]['ingredientIds'] ?? []);
      if (ingredientIndex >= 0 && ingredientIndex < ingredientIds.length) {
        ingredientIds.removeAt(ingredientIndex);
        _groups[groupIndex]['ingredientIds'] = ingredientIds;
      }
    });
    widget.onChanged(_groups);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Customizations",
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_loadingTemplates || _loadingIngredients)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!_loadingTemplates && !_loadingIngredients && _groups.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              "No customization groups added.",
              style: TextStyle(
                  fontStyle: FontStyle.italic, color: Colors.grey[600]),
            ),
          ),
        ...List.generate(_groups.length, (groupIndex) {
          final group = _groups[groupIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              margin: EdgeInsets.zero,
              child: ExpansionTile(
                key: Key('group_$groupIndex'),
                initiallyExpanded: _expandedIndex == groupIndex,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _expandedIndex = expanded ? groupIndex : null;
                  });
                },
                title: DropdownButtonFormField<String>(
                  value: (group['label'] is Map
                                  ? group['label']['en']
                                  : group['label'])
                              ?.toString()
                              .isNotEmpty ==
                          true
                      ? (group['label'] is Map
                              ? group['label']['en']
                              : group['label'])
                          ?.toString()
                      : null,
                  items: _templates.map((tpl) {
                    final label = (tpl['label'] is Map
                            ? tpl['label']['en']
                            : tpl['label'])
                        .toString();
                    return DropdownMenuItem(value: label, child: Text(label));
                  }).toList(),
                  onChanged: (String? selectedLabel) {
                    if (selectedLabel == null) return;
                    _updateGroupLabel(groupIndex, selectedLabel);
                    setState(() {
                      _expandedIndex = groupIndex; // Auto-expand on selection
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Group Label (Template)',
                  ),
                ),
                trailing: IconButton(
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Remove Group',
                  onPressed: () => _removeGroup(groupIndex),
                ),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // List each ingredient in the group with remove button
                      ...(() {
                        final ingredientIds =
                            List<String>.from(group['ingredientIds'] ?? []);
                        return List.generate(ingredientIds.length,
                            (ingredientIdx) {
                          final ingredientId = ingredientIds[ingredientIdx];
                          return Row(
                            children: [
                              Expanded(
                                child:
                                    Text(_getIngredientNameById(ingredientId)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                tooltip: 'Remove',
                                onPressed: () => _removeIngredientFromGroup(
                                    groupIndex, ingredientIdx),
                              ),
                            ],
                          );
                        });
                      })(),
                      // Add Ingredient Autocomplete
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, right: 24.0),
                        child: Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            return _ingredientMetadataList
                                .map((e) => e['name'].toString())
                                .where((option) => option
                                    .toLowerCase()
                                    .contains(
                                        textEditingValue.text.toLowerCase()))
                                .toList();
                          },
                          onSelected: (String selectedName) {
                            _addIngredientToGroup(groupIndex, selectedName);
                          },
                          fieldViewBuilder: (context, controller, focusNode,
                              onFieldSubmitted) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                  labelText: 'Add Ingredient by Name'),
                              onFieldSubmitted: (_) => onFieldSubmitted(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _addGroup,
            icon: Icon(Icons.add, color: colorScheme.primary),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.primary),
            ),
            label: Text(
              "Add Customization Group",
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
