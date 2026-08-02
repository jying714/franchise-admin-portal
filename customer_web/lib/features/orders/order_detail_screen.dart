// customer_web/lib/features/orders/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

import '../../widgets/branding_shell.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final shared.Order order;

  String _fmtWhen(DateTime when) {
    return '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')} '
        '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
  }

  String _lineMods(shared.OrderItem line) {
    final raw = line.customizations;
    if (raw == null || raw.isEmpty) {
      return line.specialInstructions ?? '';
    }
    final groups = raw['groups'];
    if (groups is! List || groups.isEmpty) {
      return line.specialInstructions ?? '';
    }
    final parts = <String>[];
    for (final e in groups) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final name = (m['name'] ?? '').toString();
      if (name.isEmpty) continue;
      final group = (m['group'] ?? '').toString();
      final price = (m['price'] is num) ? (m['price'] as num).toDouble() : 0.0;
      final label = group.isNotEmpty ? '$group: $name' : name;
      parts.add(price > 0 ? '$label (+\$${price.toStringAsFixed(2)})' : label);
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BrandingShell(
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            order.status.isNotEmpty ? order.status : 'Order',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            [
              _fmtWhen(order.timestamp),
              if (order.source != null && order.source!.isNotEmpty)
                order.source!,
              order.deliveryType,
            ].where((s) => s.toString().isNotEmpty).join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            'Order ID: ${order.id}',
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: 32),
          ...order.items.map((line) {
            final mods = _lineMods(line);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(line.name),
              subtitle: Text(
                [
                  '×${line.quantity} · \$${line.price.toStringAsFixed(2)} each',
                  if (mods.isNotEmpty) mods,
                ].join('\n'),
              ),
              isThreeLine: mods.isNotEmpty,
              trailing: Text(
                '\$${(line.price * line.quantity).toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall,
              ),
            );
          }),
          const Divider(height: 32),
          _row(context, 'Subtotal', order.subtotal),
          _row(context, 'Tax', order.tax),
          if (order.deliveryFee > 0)
            _row(context, 'Delivery', order.deliveryFee),
          if ((order.discount) > 0) _row(context, 'Discount', -order.discount),
          _row(context, 'Total', order.total, bold: true),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    double value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
          ),
        ],
      ),
    );
  }
}
