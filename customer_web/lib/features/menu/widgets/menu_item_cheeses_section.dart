import 'package:flutter/material.dart';
import 'portion_selector.dart';
import 'portion_pill_toggle.dart';

/// Cheeses section — collapsed ExpansionTile (mobile parity).
class MenuItemCheesesSection extends StatelessWidget {
  const MenuItemCheesesSection({
    super.key,
    required this.selectedIds,
    required this.availableIds,
    required this.maxCheeses,
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
  final int maxCheeses;
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

  String get _summary {
    if (selectedIds.isEmpty) return 'None';
    return selectedIds
        .map((id) {
          final bits = <String>[labelFor(id, 'cheeses')];
          if (isDouble(id)) bits.add('Double');
          final p = portion(id);
          if (p == 'left') bits.add('Left');
          if (p == 'right') bits.add('Right');
          return bits.length == 1
              ? bits.first
              : '${bits.first} (${bits.skip(1).join(', ')})';
        })
        .join(', ');
  }

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
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          child: Text(
            'Cheeses',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ExpansionTile(
          initiallyExpanded: false,
          tilePadding: EdgeInsets.zero,
          title: Text(
            _summary,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Up to $maxCheeses. Add extra cheeses for an additional charge.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          children: [
            if (selectedIds.isNotEmpty) ...[
              ...selectedIds.map((id) {
                final doubled = isDouble(id);
                final p = portion(id);
                final name = labelFor(id, 'cheeses');
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: scheme.error,
                              ),
                              onPressed: () => onRemove(id),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                        if (showPortionControls) ...[
                          const SizedBox(height: 8),
                          PortionSelector(
                            portion: p,
                            onChanged: (value) => onSetPortion(id, value),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: PortionPillToggle(
                              isDouble: doubled,
                              onTap: () => onToggleDouble(id, !doubled),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
            if (availableIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Available', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              ...availableIds.map((id) {
                final name = labelFor(id, 'cheeses');
                final free = isOriginallyIncluded(id);
                final label = (free || toppingPrice <= 0)
                    ? name
                    : '$name (+\$${toppingPrice.toStringAsFixed(2)})';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: () => onAdd(id),
                          child: Text(
                            'Click to Add',
                            style: TextStyle(color: scheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ],
    );
  }
}
