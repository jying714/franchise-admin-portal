import 'package:flutter/material.dart';

/// Left / Whole / Right portion control (web).
/// Filled primary when selected to approximate mobile PortionSelector.
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
    final scheme = Theme.of(context).colorScheme;

    Widget chip(String value, String label) {
      final selected = portion == value;
      return Material(
        color: selected ? scheme.primary : scheme.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outline,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: () => onSetPortion(value),
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 6 : 8,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? scheme.onPrimary : scheme.onSurface,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: compact ? 12 : 13,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip('left', compact ? 'L' : 'Left'),
        const SizedBox(width: 6),
        chip('whole', compact ? 'W' : 'Whole'),
        const SizedBox(width: 6),
        chip('right', compact ? 'R' : 'Right'),
      ],
    );
  }
}
