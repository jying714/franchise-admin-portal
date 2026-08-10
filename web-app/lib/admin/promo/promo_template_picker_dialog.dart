import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

/// Result of template selection for [PromoFormDialog].
class PromoTemplateChoice {
  final String type;
  final String label;

  /// When true, form should emphasize daypart (happy hour).
  final bool preferDaypart;

  const PromoTemplateChoice({
    required this.type,
    required this.label,
    this.preferDaypart = false,
  });
}

class PromoTemplatePickerDialog extends StatelessWidget {
  const PromoTemplatePickerDialog({super.key});

  static const _templates = <({
    String type,
    String title,
    String subtitle,
    IconData icon,
  })>[
    (
      type: shared.PromoType.bogo,
      title: 'Buy X get Y',
      subtitle: 'BOGO free or % off the second item',
      icon: Icons.looks_two_outlined,
    ),
    (
      type: shared.PromoType.percent,
      title: '% off order',
      subtitle: 'Percentage off the whole order',
      icon: Icons.percent,
    ),
    (
      type: shared.PromoType.amount,
      title: '\$ off order',
      subtitle: 'Fixed amount off with optional minimum',
      icon: Icons.attach_money,
    ),
    (
      type: shared.PromoType.itemPercent,
      title: '% off items',
      subtitle: 'Percentage off selected items / sizes',
      icon: Icons.local_pizza_outlined,
    ),
    (
      type: shared.PromoType.itemAmount,
      title: '\$ off items',
      subtitle: 'Dollar off selected items',
      icon: Icons.discount_outlined,
    ),
    (
      type: shared.PromoType.freeItem,
      title: 'Free item with purchase',
      subtitle: 'Free menu item when minimum is met',
      icon: Icons.card_giftcard_outlined,
    ),
    (
      type: shared.PromoType.delivery,
      title: 'Delivery deal',
      subtitle: 'Free or discounted delivery',
      icon: Icons.delivery_dining_outlined,
    ),
    (
      type: shared.PromoType.percent,
      title: 'Happy hour / daypart',
      subtitle: '% off during selected days & times',
      icon: Icons.schedule_outlined,
    ),
    (
      type: 'custom',
      title: 'Custom',
      subtitle: 'Full control over all deal rules',
      icon: Icons.tune,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Choose a deal template'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Start from a common restaurant promo. '
              'You can still edit every field after you pick one.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final t = _templates[i];
                  return Material(
                    color:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).pop(
                          PromoTemplateChoice(
                            type: t.type == 'custom'
                                ? shared.PromoType.percent
                                : t.type,
                            label: t.title,
                            preferDaypart: t.title.startsWith('Happy hour'),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(t.icon, color: scheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    t.subtitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
