import 'package:flutter/material.dart';
import 'menu_portion_chips.dart';

/// Current Toppings list: display name, Double, portion L/W/R, Remove.
/// Presentational — parent owns state and callbacks.
class MenuItemCurrentToppingsSection extends StatelessWidget {
  const MenuItemCurrentToppingsSection({
    super.key,
    required this.ingredientIds,
    required this.displayName,
    required this.isDouble,
    required this.portion,
    required this.showPortionControls,
    required this.onToggleDouble,
    required this.onSetPortion,
    required this.onRemove,
  });

  final Set<String> ingredientIds;

  /// id → display label
  final String Function(String id) displayName;

  final bool Function(String id) isDouble;

  /// id → 'whole' | 'left' | 'right'
  final String Function(String id) portion;

  final bool showPortionControls;

  final void Function(String id, bool value) onToggleDouble;
  final void Function(String id, String portion) onSetPortion;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          'Current Toppings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (ingredientIds.isEmpty)
          Text(
            'None — defaults appear here when set on the item. Add extras below.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...ingredientIds.map((id) {
            final doubled = isDouble(id);
            final p = portion(id);
            final display = displayName(id);
            final titleBits = <String>[display];
            if (doubled) titleBits.add('Double');
            if (p == 'left') titleBits.add('Left');
            if (p == 'right') titleBits.add('Right');

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            titleBits.length == 1
                                ? display
                                : '${titleBits.first} (${titleBits.skip(1).join(', ')})',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () => onToggleDouble(id, !doubled),
                          child: Text(doubled ? 'Single' : 'Double'),
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
                      const SizedBox(height: 4),
                      MenuPortionChips(
                        portion: p,
                        onSetPortion: (value) => onSetPortion(id, value),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
