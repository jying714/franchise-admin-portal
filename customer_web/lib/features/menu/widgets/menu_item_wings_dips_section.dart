import 'package:flutter/material.dart';

/// Wings side dip cups — free by size, then upcharge per extra cup.
class MenuItemWingsDipsSection extends StatelessWidget {
  const MenuItemWingsDipsSection({
    super.key,
    required this.optionIds,
    required this.counts,
    required this.freeCups,
    required this.upcharge,
    required this.maxCups,
    required this.labelFor,
    required this.onSetCount,
  });

  final List<String> optionIds;
  final Map<String, int> counts;
  final int freeCups;
  final double upcharge;
  final int maxCups;
  final String Function(String id) labelFor;
  final void Function(String id, int count) onSetCount;

  int get _total => counts.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    if (optionIds.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final paid = _total > freeCups ? _total - freeCups : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text('Dipping cups', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Up to $maxCups. $freeCups free with this size'
          '${upcharge > 0 ? ' · extras +\$${upcharge.toStringAsFixed(2)} each' : ''}'
          '${paid > 0 ? ' · $paid paid' : ''}.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        for (final id in optionIds) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  labelFor(id),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                onPressed: (counts[id] ?? 0) > 0
                    ? () => onSetCount(id, (counts[id] ?? 0) - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '${counts[id] ?? 0}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                onPressed: _total >= maxCups
                    ? null
                    : () => onSetCount(id, (counts[id] ?? 0) + 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
