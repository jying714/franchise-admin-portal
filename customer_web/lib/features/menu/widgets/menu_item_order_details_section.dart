import 'package:flutter/material.dart';

/// Structural Order Details — collapsed ExpansionTile with primary header
/// and left-aligned radio options (mobile parity).
class MenuItemOrderDetailsSection extends StatelessWidget {
  const MenuItemOrderDetailsSection({
    super.key,
    required this.groups,
    required this.selections,
    required this.isSub,
    required this.onSelected,
  });

  final List<Map<String, dynamic>> groups;
  final Map<String, String?> selections;
  final bool isSub;
  final void Function(String groupLabel, String optionId) onSelected;

  String get _summary {
    final parts = <String>[];
    for (final g in groups) {
      final label = (g['label'] ?? '').toString();
      if (label.isEmpty) continue;
      final selected = selections[label];
      if (selected == null || selected.isEmpty) continue;
      final labels =
          (g['optionLabels'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          const <String, String>{};
      final name = labels[selected] ?? selected;
      parts.add('$label: $name');
    }
    if (parts.isEmpty) {
      return isSub
          ? 'Choose how your sub is cooked — Regular or Crispy.'
          : 'Customize crust, cook, and cut.';
    }
    return parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final subtitle = isSub
        ? 'Choose how your sub is cooked — Regular or Crispy.'
        : 'Tap to customize crust, cook, or cut.';

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
            'Order Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ExpansionTile(
          initiallyExpanded: false,
          tilePadding: EdgeInsets.zero,
          title: Text(
            _summary,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          children: [
            for (final g in groups) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    (g['label'] ?? '').toString(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final id in ids)
                        RadioListTile<String>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: id,
                          groupValue: selected,
                          onChanged: (v) {
                            if (v != null) onSelected(label, v);
                          },
                          title: Text(
                            labels[id] ?? id,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ],
    );
  }
}
