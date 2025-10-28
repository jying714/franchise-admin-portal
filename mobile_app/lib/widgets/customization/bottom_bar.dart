import 'package:flutter/material.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';
import 'package:doughboys_pizzeria_final/core/models/menu_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:doughboys_pizzeria_final/core/utils/formatting.dart';

typedef ConfirmCallback = void Function(
  Map<String, dynamic> customizations,
  int quantity,
  double totalPrice,
);

class CustomizationBottomBar extends StatelessWidget {
  final MenuItem menuItem;
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
    Key? key,
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
  }) : super(key: key);

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
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            Text(
              // You must import your currencyFormat function!
              currencyFormat(context, total),
              style: theme.textTheme.titleLarge?.copyWith(
                color: DesignTokens.primaryColor,
                fontWeight: FontWeight.bold,
                fontFamily: DesignTokens.fontFamily,
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
                color: DesignTokens.errorTextColor,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.secondaryColor,
              ),
              onPressed: onCancel,
              child: Text(
                loc.cancel,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ),
            SizedBox(width: DesignTokens.gridSpacing),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.buttonRadius),
                ),
              ),
              onPressed: isDrinks
                  ? () {
                      // Only proceed if at least one drink selected
                      if (drinkTotalCount == 0) {
                        // This assumes parent will handle error state!
                        // (You could also pass a setError callback)
                        return;
                      }
                      // For each flavor with count > 0, call onConfirm once per drink
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
              child: Text(
                loc.addToCart,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
