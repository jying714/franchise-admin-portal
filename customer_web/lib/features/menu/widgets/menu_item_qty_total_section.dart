import 'package:flutter/material.dart';

/// Qty controls, line total preview, and primary add / sign-in CTA.
/// Presentational — parent owns qty, prices, and cart action.
class MenuItemQtyTotalSection extends StatelessWidget {
  const MenuItemQtyTotalSection({
    super.key,
    required this.qty,
    required this.baseSizePrice,
    required this.unitPrice,
    required this.selectedSize,
    required this.isSignedIn,
    required this.onQtyChanged,
    required this.onPrimaryPressed,
  });

  final int qty;
  final double baseSizePrice;
  final double unitPrice;
  final String? selectedSize;
  final bool isSignedIn;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onPrimaryPressed;

  double get _linePreview => unitPrice * qty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Qty', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            IconButton(
              onPressed: qty > 1 ? () => onQtyChanged(qty - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$qty', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              onPressed: () => onQtyChanged(qty + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Line total'),
          trailing: Text(
            '\$${_linePreview.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Base \$${baseSizePrice.toStringAsFixed(2)}'
            ' + extras \$${(unitPrice - baseSizePrice).toStringAsFixed(2)}'
            ' × $qty'
            '${selectedSize != null ? ' · $selectedSize' : ''}',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onPrimaryPressed,
          child: Text(isSignedIn ? 'Add to cart' : 'Sign in to add'),
        ),
      ],
    );
  }
}
