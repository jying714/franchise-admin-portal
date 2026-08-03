import 'package:flutter/material.dart';

/// Wings build: always two halves; each Plain or a sauce (mobile parity).
class MenuItemWingsSauceSection extends StatelessWidget {
  const MenuItemWingsSauceSection({
    super.key,
    required this.optionIds,
    required this.leftId,
    required this.rightId,
    required this.labelFor,
    required this.onLeftSelected,
    required this.onRightSelected,
  });

  final List<String> optionIds;
  final String leftId;
  final String rightId;
  final String Function(String id) labelFor;
  final void Function(String id) onLeftSelected;
  final void Function(String id) onRightSelected;

  Widget _halfColumn({
    required BuildContext context,
    required String title,
    required String selectedId,
    required void Function(String id) onSelected,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in optionIds)
                ChoiceChip(
                  label: Text(labelFor(id)),
                  selected: selectedId == id,
                  onSelected: (_) => onSelected(id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (optionIds.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          'Build your wings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Each half is Plain or a sauce. Two sauces = split order.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _halfColumn(
              context: context,
              title: 'Left half',
              selectedId: leftId,
              onSelected: onLeftSelected,
            ),
            const SizedBox(width: 12),
            _halfColumn(
              context: context,
              title: 'Right half',
              selectedId: rightId,
              onSelected: onRightSelected,
            ),
          ],
        ),
      ],
    );
  }
}
