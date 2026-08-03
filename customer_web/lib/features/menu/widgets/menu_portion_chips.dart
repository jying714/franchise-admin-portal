import 'package:flutter/material.dart';

/// Shared Left / Whole / Right portion chips.
/// Compact mode uses L / W / R labels (cheeses & sauces).
class MenuPortionChips extends StatelessWidget {
  const MenuPortionChips({
    super.key,
    required this.portion,
    required this.onSetPortion,
    this.compact = false,
  });

  /// 'whole' | 'left' | 'right'
  final String portion;
  final void Function(String portion) onSetPortion;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Wrap(
        spacing: 4,
        children: [
          ChoiceChip(
            label: const Text('L'),
            selected: portion == 'left',
            onSelected: (_) => onSetPortion('left'),
            visualDensity: VisualDensity.compact,
          ),
          ChoiceChip(
            label: const Text('W'),
            selected: portion == 'whole',
            onSelected: (_) => onSetPortion('whole'),
            visualDensity: VisualDensity.compact,
          ),
          ChoiceChip(
            label: const Text('R'),
            selected: portion == 'right',
            onSelected: (_) => onSetPortion('right'),
            visualDensity: VisualDensity.compact,
          ),
        ],
      );
    }

    return Wrap(
      spacing: 6,
      children: [
        ChoiceChip(
          label: const Text('Left'),
          selected: portion == 'left',
          onSelected: (_) => onSetPortion('left'),
        ),
        ChoiceChip(
          label: const Text('Whole'),
          selected: portion == 'whole',
          onSelected: (_) => onSetPortion('whole'),
        ),
        ChoiceChip(
          label: const Text('Right'),
          selected: portion == 'right',
          onSelected: (_) => onSetPortion('right'),
        ),
      ],
    );
  }
}
