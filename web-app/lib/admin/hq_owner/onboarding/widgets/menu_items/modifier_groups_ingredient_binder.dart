import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

/// Binds franchise catalog ingredients onto [ModifierGroup.options].
/// Structural groups (crust/cook/cut) stay label-only and are not shown.
class ModifierGroupsIngredientBinder extends StatelessWidget {
  final List<shared.ModifierGroup> groups;
  final ValueChanged<List<shared.ModifierGroup>> onChanged;

  const ModifierGroupsIngredientBinder({
    super.key,
    required this.groups,
    required this.onChanged,
  });

  static bool _isStructuralGroup(shared.ModifierGroup g) {
    final id = g.id.toLowerCase().trim();
    final label = g.label.toLowerCase().trim();
    return id == 'crust' ||
        id == 'cook' ||
        id == 'cut' ||
        label == 'crust' ||
        label == 'cook' ||
        label == 'cut';
  }

  static bool _isWingsGroup(shared.ModifierGroup g) {
    final id = g.id.toLowerCase().trim();
    final label = g.label.toLowerCase().trim();
    return id == 'wing_sauce' ||
        id == 'wing_dips' ||
        label == 'sauce' && id.contains('wing') ||
        label.contains('dipping');
  }

  /// Prefer stable id; if legacy empty id, slug from label.
  static String _stableId(shared.ModifierGroup g, int index) {
    final id = g.id.trim();
    if (id.isNotEmpty) return id;
    final slug =
        g.label.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return slug.isNotEmpty ? slug : 'group_$index';
  }

  /// Limit chips to ingredients whose type matches the group (Meats → meats, etc.).
  static bool _ingredientMatchesGroup(
    shared.IngredientMetadata ing,
    shared.ModifierGroup group, {
    List<shared.IngredientType> types = const [],
  }) {
    final gLabel = group.label.toLowerCase().trim();
    final gId = group.id.toLowerCase().trim();

    // Resolve human type name (type field and/or typeId → IngredientType.name).
    var typeName = (ing.type).toLowerCase().trim();
    final typeId = (ing.typeId ?? '').trim();
    if (typeId.isNotEmpty) {
      for (final t in types) {
        if (t.id == typeId) {
          final n = t.name.toLowerCase().trim();
          if (n.isNotEmpty) typeName = n;
          break;
        }
      }
    }

    bool typeMatches(List<String> keys) {
      for (final key in keys) {
        if (typeName == key || typeName.contains(key)) return true;
        // slug typeIds only (not random firestore ids)
        final tid = typeId.toLowerCase();
        if (tid == key || (tid.length < 24 && tid.contains(key))) return true;
      }
      return false;
    }

    bool groupIs(List<String> keys) {
      for (final key in keys) {
        if (gLabel.contains(key) || gId.contains(key)) return true;
      }
      return false;
    }

    if (groupIs(['meat'])) {
      return typeMatches(['meat']);
    }
    if (groupIs(['veggie', 'vegetable', 'produce'])) {
      return typeMatches(['veggie', 'vegetable', 'produce']);
    }
    if (groupIs(['cheese'])) {
      return typeMatches(['cheese']);
    }
    if (groupIs(['sauce', 'dressing', 'dip'])) {
      return typeMatches(['sauce', 'dressing', 'dip']);
    }

    // Unknown group: do NOT show entire catalog — require type name ≈ group label.
    if (typeName.isEmpty) return false;
    return typeName == gLabel ||
        typeName.contains(gLabel) ||
        gLabel.contains(typeName);
  }

  @override
  Widget build(BuildContext context) {
    final ingredientProvider =
        context.watch<shared.IngredientMetadataProvider>();
    final typeProvider = context.watch<shared.IngredientTypeProvider>();
    final types = typeProvider.ingredientTypes;

    if (!ingredientProvider.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final foodIngredients = ingredientProvider.allIngredients.where((ing) {
      return !shared.StructuralIngredientTypes.isStructuralType(
        typeId: ing.typeId,
        typeName: ing.type,
        types: types,
      );
    }).toList();

    // Work off a normalized copy with stable ids (fixes empty-id collision).
    final normalized = <shared.ModifierGroup>[
      for (var i = 0; i < groups.length; i++)
        groups[i].id.trim().isEmpty
            ? groups[i].copyWith(id: _stableId(groups[i], i))
            : groups[i],
    ];

    final bindableIndexes = <int>[
      for (var i = 0; i < normalized.length; i++)
        if (!_isStructuralGroup(normalized[i])) i,
    ];

    if (bindableIndexes.isEmpty) {
      return const ListTile(
        dense: true,
        title: Text('No ingredient groups to bind'),
        subtitle: Text(
          'Pizza Crust/Cook/Cut are label-only. Add meats/veggies or use standard add-ons.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + help text live on the parent form (profile-aware).
        ...bindableIndexes.map((index) {
          final group = normalized[index];
          final chipsForGroup = foodIngredients
              .where(
                (ing) => _ingredientMatchesGroup(
                  ing,
                  group,
                  types: types,
                ),
              )
              .toList();

          final selectedIds = group.options
              .map((o) => o.ingredientId)
              .whereType<String>()
              .where((id) => id.isNotEmpty)
              .toSet();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (_isWingsGroup(group)) ...[
                    const SizedBox(height: 4),
                    Text(
                      group.id.toLowerCase().contains('dip')
                          ? 'Side cups — free count and extra-cup price are set per size below. Bind sauces here (or reuse the Sauce list on save).'
                          : 'Toss / flavor — customer picks up to 2 portions (Plain allowed). Bind sauces from the catalog.',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                  ] else ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('min_${group.id}_$index'),
                            initialValue: '${group.min}',
                            decoration: const InputDecoration(
                              labelText: 'Min',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final n = int.tryParse(v.trim());
                              if (n == null || n < 0) return;
                              final next = [
                                for (var i = 0; i < normalized.length; i++)
                                  if (i == index)
                                    normalized[i].copyWith(min: n)
                                  else
                                    normalized[i],
                              ];
                              onChanged(next);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('max_${group.id}_$index'),
                            initialValue: '${group.max}',
                            decoration: const InputDecoration(
                              labelText: 'Max',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final n = int.tryParse(v.trim());
                              if (n == null || n < 0) return;
                              final next = [
                                for (var i = 0; i < normalized.length; i++)
                                  if (i == index)
                                    normalized[i].copyWith(max: n)
                                  else
                                    normalized[i],
                              ];
                              onChanged(next);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('maxFree_${group.id}_$index'),
                            initialValue: '${group.maxFree ?? 0}',
                            decoration: const InputDecoration(
                              labelText: 'Max free',
                              helperText: 'Then size topping upcharge',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final n = int.tryParse(v.trim());
                              if (n == null || n < 0) return;
                              final next = [
                                for (var i = 0; i < normalized.length; i++)
                                  if (i == index)
                                    normalized[i].copyWith(maxFree: n)
                                  else
                                    normalized[i],
                              ];
                              onChanged(next);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (chipsForGroup.isEmpty)
                    const Text(
                      'No matching ingredients for this group type.',
                      style: TextStyle(fontSize: 12),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: chipsForGroup.map((ing) {
                        final selected = selectedIds.contains(ing.id);
                        return FilterChip(
                          label: Text(ing.name),
                          selected: selected,
                          onSelected: (on) {
                            // Update by INDEX so empty/duplicate ids cannot leak.
                            final next = <shared.ModifierGroup>[
                              for (var i = 0; i < normalized.length; i++)
                                if (i != index)
                                  normalized[i]
                                else
                                  () {
                                    final opts =
                                        List<shared.ModifierOption>.from(
                                      normalized[i].options,
                                    );
                                    if (on) {
                                      if (!opts.any(
                                          (o) => o.ingredientId == ing.id)) {
                                        opts.add(
                                          shared.ModifierOption(
                                            id: '${normalized[i].id}_${ing.id}',
                                            label: ing.name,
                                            ingredientId: ing.id,
                                          ),
                                        );
                                      }
                                    } else {
                                      opts.removeWhere(
                                          (o) => o.ingredientId == ing.id);
                                    }
                                    return normalized[i].copyWith(
                                      id: normalized[i].id,
                                      options: opts,
                                    );
                                  }(),
                            ];
                            onChanged(next);
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
