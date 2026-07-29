import 'package:flutter/material.dart';

/// A versatile chip for displaying status values (order, inventory, user, etc.).
class StatusChip extends StatelessWidget {
  final String status;
  final Map<String, Color>? statusColorMap;
  final bool useIcon;

  const StatusChip({
    Key? key,
    required this.status,
    this.statusColorMap,
    this.useIcon = false,
  }) : super(key: key);

  Color _getStatusColor() {
    final normalized = status.toLowerCase();
    if (statusColorMap != null && statusColorMap!.containsKey(normalized)) {
      return statusColorMap![normalized]!;
    }
    // Fixed feedback roles (D4) — do not bind to franchise primary/secondary.
    switch (normalized) {
      case 'pending':
        return const Color(0xFFF57C00); // warning
      case 'in progress':
      case 'processing':
        return const Color(0xFF1976D2); // info
      case 'delivered':
      case 'complete':
      case 'completed':
        return const Color(0xFF2E7D32); // success
      case 'cancelled':
      case 'canceled':
      case 'failed':
        return const Color(0xFFC62828); // error
      case 'out of stock':
        return const Color(0xFF757575); // neutral
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData? _getStatusIcon() {
    final normalized = status.toLowerCase();
    switch (normalized) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'in progress':
      case 'processing':
        return Icons.sync;
      case 'delivered':
      case 'complete':
        return Icons.check_circle;
      case 'cancelled':
      case 'canceled':
        return Icons.cancel;
      case 'failed':
        return Icons.warning;
      case 'out of stock':
        return Icons.remove_shopping_cart;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final icon = useIcon ? _getStatusIcon() : null;

    return Chip(
      label: Text(
        status,
        style: TextStyle(
          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      avatar: icon != null
          ? Icon(
              icon,
              size: 18,
              color:
                  color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    );
  }
}
