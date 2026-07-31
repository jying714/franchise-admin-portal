import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

/// Minimal POS modifier picker. Returns selection map or null if cancelled.
class PosModifierDialog extends StatefulWidget {
  final MenuItem item;

  const PosModifierDialog({super.key, required this.item});

  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    MenuItem item,
  ) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => PosModifierDialog(item: item),
    );
  }

  @override
  State<PosModifierDialog> createState() => _PosModifierDialogState();
}

class _PosModifierDialogState extends State<PosModifierDialog> {
  final Map<String, Set<String>> _selected = {};

  List<ModifierGroup> get _groups => widget.item.effectiveModifierGroups;

  String _groupKey(ModifierGroup g) => g.id.isNotEmpty ? g.id : g.label;

  String _optionKey(ModifierOption o) => o.id.isNotEmpty ? o.id : o.label;

  @override
  void initState() {
    super.initState();
    for (final g in _groups) {
      final key = _groupKey(g);
      _selected[key] = {};
      for (final opt in g.options) {
        if (opt.defaultSelected) {
          _selected[key]!.add(_optionKey(opt));
        }
      }
    }
  }

  bool get _valid {
    for (final g in _groups) {
      final count = _selected[_groupKey(g)]?.length ?? 0;
      if (count < g.min) return false;
      if (count > g.max) return false;
    }
    return true;
  }

  void _toggle(ModifierGroup g, ModifierOption opt) {
    final groupKey = _groupKey(g);
    final optionKey = _optionKey(opt);
    final set = _selected[groupKey] ?? <String>{};

    if (set.contains(optionKey)) {
      set.remove(optionKey);
    } else {
      if (g.selectMode == ModifierSelectMode.single || g.max == 1) {
        set.clear();
        set.add(optionKey);
      } else if (set.length >= g.max) {
        return;
      } else {
        set.add(optionKey);
      }
    }
    setState(() => _selected[groupKey] = set);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.item.name),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final g in _groups) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    g.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final opt in g.options)
                      FilterChip(
                        label: Text(opt.label),
                        selected: (_selected[_groupKey(g)] ?? {}).contains(
                          _optionKey(opt),
                        ),
                        onSelected: (_) => _toggle(g, opt),
                      ),
                  ],
                ),
              ],
              if (widget.item.allergens.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Allergens: ${widget.item.allergens.join(', ')}',
                  style: TextStyle(color: scheme.error, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _valid
              ? () {
                  final out = <String, dynamic>{
                    for (final e in _selected.entries)
                      if (e.value.isNotEmpty) e.key: e.value.toList(),
                  };
                  Navigator.pop(context, out);
                }
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
