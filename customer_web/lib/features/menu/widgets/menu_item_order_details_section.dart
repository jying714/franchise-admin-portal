import 'package:flutter/material.dart';

/// Structural Order Details (Crust / Cook / Cut, or Cook-only for sub).
/// Presentational — parent owns [_structuralSelections] and group data.
class MenuItemOrderDetailsSection extends StatelessWidget {
  const MenuItemOrderDetailsSection({
    super.key,
    required this.groups,
    required this.selections,
    required this.isSub,
    required this.onSelected,
  });

  /// Each map: id, label, ingredientIds (List), optionLabels (Map).
  final List<Map<String, dynamic>> groups;

  /// group label → selected option id
  final Map<String, String?> selections;

  final bool isSub;

  /// (groupLabel, optionId)
  final void Function(String groupLabel, String optionId) onSelected;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text('Order Details', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          isSub ? 'Choose how your sub is cooked.' : 'Crust, cook, and cut.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        for (final g in groups) ...[
          Text(
            (g['label'] ?? '').toString(),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Builder(
            builder: (context) {
              final label = (g['label'] ?? '').toString();
              final ids = (g['ingredientIds'] as List? ?? [])
                  .map((e) => e.toString())
                  .where((id) => id.isNotEmpty)
                  .toList();
              final labels =
                  (g['optionLabels'] as Map?)?.map(
                    (k, v) => MapEntry(k.toString(), v.toString()),
                  ) ??
                  const <String, String>{};
              final selected = selections[label];
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in ids)
                    ChoiceChip(
                      label: Text(labels[id] ?? id),
                      selected: selected == id,
                      onSelected: (_) => onSelected(label, id),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
