import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_portal/core/services/firestore_service.dart';

class DynamicArrayEditor extends StatefulWidget {
  final String title;
  final String arrayKey;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> template;
  final void Function(List<Map<String, dynamic>> updated) onChanged;
  final String franchiseId;

  const DynamicArrayEditor({
    super.key,
    required this.title,
    required this.arrayKey,
    required this.items,
    required this.template,
    required this.onChanged,
    required this.franchiseId,
  });

  @override
  State<DynamicArrayEditor> createState() => _DynamicArrayEditorState();
}

class _DynamicArrayEditorState extends State<DynamicArrayEditor> {
  late List<Map<String, dynamic>> _items;
  int? _expandedIndex;
  List<Map<String, dynamic>> _ingredientMetadataList = [];
  List<TextEditingController> _typeControllers = [];
  @override
  void initState() {
    super.initState();
    _items = List<Map<String, dynamic>>.from(widget.items);

    _typeControllers = List.generate(_items.length, (i) {
      return TextEditingController(text: _items[i]['type'] ?? '');
    });

    // Load ingredient metadata if available via Provider or FirestoreService
    Future.microtask(() async {
      final fs = Provider.of<FirestoreService>(context, listen: false);
      final result = await fs.fetchIngredientMetadataAsMaps(widget.franchiseId);
      if (mounted) {
        setState(() {
          _ingredientMetadataList = result;
        });
      }
    });
  }

  Map<String, dynamic>? _findIngredientByName(String name) {
    try {
      final found = _ingredientMetadataList.firstWhere(
        (ing) => ing['name'].toString().toLowerCase() == name.toLowerCase(),
      );
      print('[DEBUG] Ingredient found for "$name": $found');
      return found;
    } catch (e) {
      print('[DEBUG] Ingredient not found for "$name".');
      return null;
    }
  }

  void _onItemChanged(int index, String field, dynamic value) {
    setState(() {
      _items[index][field] = value;
    });
    widget.onChanged(_items);
  }

  void _addItem() {
    setState(() {
      final newItem = <String, dynamic>{};
      widget.template.forEach((key, config) {
        final defaultVal =
            (config is Map<String, dynamic>) ? config['default'] : null;
        newItem[key] = _sanitizeValue(defaultVal ?? '');
      });
      _items.add(newItem);
      _typeControllers
          .add(TextEditingController(text: _items.last['type'] ?? ''));
      _expandedIndex = _items.length - 1;
    });
    widget.onChanged(_items);
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _typeControllers.removeAt(index);
      if (_expandedIndex == index) _expandedIndex = null;
    });
    widget.onChanged(_items);
  }

  bool _isInvalid(Map<String, dynamic> item) {
    final mustHave = ['ingredientId', 'name', 'type'];
    for (final key in mustHave) {
      final val = item[key];
      if (val == null || (val is String && val.trim().isEmpty)) {
        return true;
      }
    }
    return false;
  }

  dynamic _sanitizeValue(dynamic value) {
    if (value is Map && value.containsKey('en')) {
      return value['en'].toString();
    } else if (value is Map) {
      return jsonEncode(value);
    } else if (value is List) {
      return value.map(_sanitizeValue).toList();
    } else {
      return value?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: "Add item",
              onPressed: _addItem,
            ),
          ],
        ),
        const SizedBox(height: 6),
        // The following column is safe: it does not cause scroll overflow.
        Column(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final isInvalid = _isInvalid(item);
            final isExpanded = index == _expandedIndex;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                side: isInvalid
                    ? BorderSide(
                        color: Colors.redAccent.withOpacity(0.6), width: 1.2)
                    : BorderSide.none,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ExpansionTile(
                key: Key('item_$index'),
                initiallyExpanded: isExpanded,
                onExpansionChanged: (val) {
                  setState(() {
                    _expandedIndex = val ? index : null;
                  });
                },
                title: Text(
                  item['name']?.toString().trim().isEmpty ?? true
                      ? 'Unnamed ${widget.title.toLowerCase()}'
                      : item['name'].toString(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                trailing: IconButton(
                  icon:
                      const Icon(Icons.delete_forever, color: Colors.redAccent),
                  tooltip: 'Remove',
                  onPressed: () => _removeItem(index),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        // Ingredient Name Dropdown/Autocomplete
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Autocomplete<String>(
                            initialValue:
                                TextEditingValue(text: item['name'] ?? ''),
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                              if (textEditingValue.text == '') {
                                return const Iterable<String>.empty();
                              }
                              return _ingredientMetadataList
                                  .map((e) => e['name'].toString())
                                  .where((option) => option
                                      .toLowerCase()
                                      .contains(
                                          textEditingValue.text.toLowerCase()))
                                  .toList();
                            },
                            onSelected: (String selected) {
                              final found = _findIngredientByName(selected);
                              setState(() {
                                item['name'] = selected;
                                if (found != null) {
                                  item['ingredientId'] = found['id'];
                                  item['type'] = found['type'];
                                  item['typeLocked'] = true;
                                  _typeControllers[index].text =
                                      found['type'] ?? '';
                                } else {
                                  item['ingredientId'] = null;
                                  item['type'] = '';
                                  item['typeLocked'] = false;
                                  _typeControllers[index].text = '';
                                }
                              });
                              widget.onChanged(_items);
                            },
                            fieldViewBuilder: (context, controller, focusNode,
                                onFieldSubmitted) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                    labelText: 'Ingredient Name'),
                                onChanged: (val) {
                                  final found = _findIngredientByName(val);
                                  setState(() {
                                    item['name'] = val;
                                    if (found != null) {
                                      item['ingredientId'] = found['id'];
                                      item['type'] = found['type'];
                                      item['typeLocked'] = true;
                                      _typeControllers[index].text =
                                          found['type'] ?? '';
                                    } else {
                                      item['ingredientId'] = null;
                                      item['type'] = '';
                                      item['typeLocked'] = false;
                                      _typeControllers[index].text = '';
                                    }
                                  });
                                  widget.onChanged(_items);
                                },
                              );
                            },
                          ),
                        ),
                        // Type Field (locked/unlocked)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TextFormField(
                            enabled: !(item['typeLocked'] == true),
                            controller: _typeControllers[index],
                            decoration:
                                const InputDecoration(labelText: 'Type'),
                            onChanged: (val) {
                              item['type'] = val;
                              widget.onChanged(_items);
                            },
                          ),
                        ),
                        // Removable Checkbox (if present in template)
                        if (widget.template.containsKey('removable'))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                const Text("Removable"),
                                Checkbox(
                                  value: item['removable'] ?? true,
                                  onChanged: (val) {
                                    setState(() {
                                      item['removable'] = val ?? true;
                                    });
                                    widget.onChanged(_items);
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  )
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final c in _typeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _inferType(dynamic templateVal, dynamic realVal) {
    final v = realVal ?? templateVal;
    if (v is bool) return 'boolean';
    if (v is num) return 'number';
    if (v is List) return 'array';
    if (v is Map) return 'map';
    return 'string';
  }

  String _prettifyKey(String key) {
    return key[0].toUpperCase() +
        key
            .substring(1)
            .replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}');
  }
}
