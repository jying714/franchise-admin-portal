import 'package:flutter/material.dart';

/// Additional Toppings: Meats + Veggies ActionChips (side-by-side).
/// Presentational — parent owns pools and add callback.
class MenuItemAdditionalToppingsSection extends StatelessWidget {
  const MenuItemAdditionalToppingsSection({
    super.key,
    required this.meatIds,
    required this.veggieIds,
    required this.labelFor,
    required this.toppingPrice,
    required this.onAdd,
  });

  final List<String> meatIds;
  final List<String> veggieIds;

  /// (id, typeId) → display name
  final String Function(String id, String typeId) labelFor;

  final double toppingPrice;
  final void Function(String id) onAdd;

  @override
  Widget build(BuildContext context) {
    if (meatIds.isEmpty && veggieIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;

    Widget chipsFor(List<String> ids, String typeId) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final id in ids)
            ActionChip(
              label: Text(() {
                final name = labelFor(id, typeId);
                if (toppingPrice > 0) {
                  return '$name (+\$${toppingPrice.toStringAsFixed(2)})';
                }
                return name;
              }()),
              onPressed: () => onAdd(id),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          'Additional Toppings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to add. Added items move to Current Toppings.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (meatIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Meats', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          chipsFor(meatIds, 'meats'),
        ],
        if (veggieIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Veggies', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          chipsFor(veggieIds, 'veggies'),
        ],
      ],
    );
  }
}
