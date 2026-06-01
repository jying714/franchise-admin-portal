import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';

typedef ConfirmCallback = void Function(
  Map<String, dynamic> customizations,
  int quantity,
  double totalPrice,
);

class CustomizationBottomBar extends StatelessWidget {
  final shared.MenuItem menuItem;
  final ThemeData theme;
  final AppLocalizations loc;
  final double totalPrice;
  final String? error;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final ConfirmCallback onConfirm;
  final Map<String, int> drinkFlavorCounts;
  final Map<String, num>? sizePrices;
  final List<String>? sizes;
  final double? menuItemPrice;
  final int drinkMaxPerFlavor;

  const CustomizationBottomBar({
    super.key,
    required this.menuItem,
    required this.theme,
    required this.loc,
    required this.totalPrice,
    required this.error,
    required this.onCancel,
    required this.onSubmit,
    required this.onConfirm,
    required this.drinkFlavorCounts,
    required this.sizePrices,
    required this.sizes,
    required this.menuItemPrice,
    required this.drinkMaxPerFlavor,
  });

  @override
  Widget build(BuildContext context) {
    final isDrinks = menuItem.category.toLowerCase() == 'drinks';

    // DRINKS-SPECIFIC: Calculate price and display total based on flavor counts.
    final drinkPrice = (sizePrices != null && sizes?.isNotEmpty == true)
        ? (sizePrices![sizes!.first] as num).toDouble()
        : (menuItemPrice as num?)?.toDouble() ?? 0.0;

    final drinkTotalCount = isDrinks
        ? (drinkFlavorCounts.values.fold(0, (sum, v) => sum + (v ?? 0)))
        : 0;

    final total = isDrinks ? (drinkTotalCount * drinkPrice) : totalPrice;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.total,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              onPressed: onCancel,
              child: Text(loc.cancel),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isDrinks
                  ? () {
                      if (drinkTotalCount == 0) return;
                      drinkFlavorCounts.forEach((ingId, count) {
                        for (var i = 0; i < count; i++) {
                          onConfirm({
                            'flavor': ingId,
                            'size': sizes?.first,
                          }, 1, drinkPrice);
                        }
                      });
                      onCancel(); // close dialog
                    }
                  : onSubmit,
              child: Text(loc.addToCart),
            ),
          ],
        ),
      ],
    );
  }
}
