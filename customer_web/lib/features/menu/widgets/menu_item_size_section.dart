import 'package:flutter/material.dart';

/// Size ChoiceChips for menu item detail (presentational).
class MenuItemSizeSection extends StatelessWidget {
  const MenuItemSizeSection({
    super.key,
    required this.sizeLabels,
    required this.selectedSize,
    required this.onSizeSelected,
  });

  final List<String> sizeLabels;
  final String? selectedSize;
  final ValueChanged<String> onSizeSelected;

  @override
  Widget build(BuildContext context) {
    if (sizeLabels.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text('Size', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in sizeLabels)
              ChoiceChip(
                label: Text(label),
                selected: selectedSize == label,
                onSelected: (_) => onSizeSelected(label),
              ),
          ],
        ),
      ],
    );
  }
}
