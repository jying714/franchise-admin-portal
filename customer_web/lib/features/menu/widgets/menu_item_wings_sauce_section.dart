import 'package:flutter/material.dart';

/// Wings toss sauces — min 1, max 2 (split flavors).
class MenuItemWingsSauceSection extends StatelessWidget {
  const MenuItemWingsSauceSection({
    super.key,
    required this.selectedIds,
    required this.availableIds,
    required this.maxSauces,
    required this.labelFor,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> selectedIds;
  final List<String> availableIds;
  final int maxSauces;
  final String Function(String id) labelFor;
  final void Function(String id) onAdd;
  final void Function(String id) onRemove;

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
        Text('Wing sauce', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Choose 1–$maxSauces. Two sauces = split order.',
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
              for (final id in selectedIds)
                InputChip(
                  label: Text(labelFor(id)),
                  onDeleted: () => onRemove(id),
                  deleteIconColor: scheme.error,
                ),
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
                  label: Text(labelFor(id)),
                  onPressed: () => onAdd(id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
