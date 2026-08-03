import 'package:flutter/material.dart';
import 'menu_portion_chips.dart';

/// Sauces section: selected InputChips + available ActionChips + L/W/R.
/// Presentational — parent owns state and callbacks (including 2-sauce split rules).
class MenuItemSaucesSection extends StatelessWidget {
  const MenuItemSaucesSection({
    super.key,
    required this.selectedIds,
    required this.availableIds,
    required this.maxSauces,
    required this.labelFor,
    required this.isDouble,
    required this.portion,
    required this.isOriginallyIncluded,
    required this.toppingPrice,
    required this.showPortionControls,
    required this.onToggleDouble,
    required this.onSetPortion,
    required this.onRemove,
    required this.onAdd,
  });

  final List<String> selectedIds;
  final List<String> availableIds;
  final int maxSauces;

  /// (id, typeId) → display name
  final String Function(String id, String typeId) labelFor;

  final bool Function(String id) isDouble;
  final String Function(String id) portion;
  final bool Function(String id) isOriginallyIncluded;
  final double toppingPrice;
  final bool showPortionControls;

  final void Function(String id, bool value) onToggleDouble;
  final void Function(String id, String portion) onSetPortion;
  final void Function(String id) onRemove;
  final void Function(String id) onAdd;

  @override
  Widget build(BuildContext context) {
    if (selectedIds.isEmpty && availableIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text('Sauces', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Up to $maxSauces. Included sauces stay selected here (not under Current Toppings).',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (selectedIds.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Selected', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in selectedIds) ...[
                InputChip(
                  label: Text(() {
                    final bits = <String>[labelFor(id, 'sauces')];
                    if (isDouble(id)) bits.add('Double');
                    final p = portion(id);
                    if (p == 'left') bits.add('Left');
                    if (p == 'right') bits.add('Right');
                    return bits.length == 1
                        ? bits.first
                        : '${bits.first} (${bits.skip(1).join(', ')})';
                  }()),
                  onPressed: () => onToggleDouble(id, !isDouble(id)),
                  onDeleted: () => onRemove(id),
                  deleteIconColor: scheme.error,
                ),
                if (showPortionControls)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: MenuPortionChips(
                      portion: portion(id),
                      onSetPortion: (value) => onSetPortion(id, value),
                      compact: true,
                    ),
                  ),
              ],
            ],
          ),
        ],
        if (availableIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Available', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in availableIds)
                ActionChip(
                  label: Text(() {
                    final name = labelFor(id, 'sauces');
                    final free = isOriginallyIncluded(id);
                    if (free || toppingPrice <= 0) return name;
                    return '$name (+\$${toppingPrice.toStringAsFixed(2)})';
                  }()),
                  onPressed: () => onAdd(id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
