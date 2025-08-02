import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/order.dart' as order_model;
import 'package:franchise_admin_portal/config/design_tokens.dart';

class OrderDetailDialog extends StatelessWidget {
  final order_model.Order order;

  const OrderDetailDialog({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colorScheme.surface,
      title: Text(
        "Order #${order.id}",
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Customer: ${order.userNameDisplay}",
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                )),
            const SizedBox(height: 12),
            Text("Items:",
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                )),
            const SizedBox(height: 4),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  "- ${item.name} x${item.quantity} "
                  "(\$${(item.price * item.quantity).toStringAsFixed(2)})",
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Total: \$${order.total.toStringAsFixed(2)}",
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text("Status: ${order.status}",
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                )),
            Text("Placed: ${order.timestamp}",
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                )),
            if (order.refundStatus != null)
              Text("Refund: ${order.refundStatus}",
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  )),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 10),
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text("Close"),
          ),
        )
      ],
    );
  }
}
