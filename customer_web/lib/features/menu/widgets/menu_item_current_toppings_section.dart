import 'package:flutter/material.dart';
import 'portion_selector.dart';
import 'portion_pill_toggle.dart';

/// Current Toppings list (mobile parity layout).
/// Name + Remove on first row; circular portion + Regular/Double pill on second.
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
  final String Function(String id) displayName;
  final bool Function(String id) isDouble;
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
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          child: Text(
            'Current Toppings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                    // Label row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            display,
                            style: Theme.of(context).textTheme.bodyLarge,
                            overflow: TextOverflow.ellipsis,
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
                    // Portion + amount directly under the label
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
    );
  }
}
