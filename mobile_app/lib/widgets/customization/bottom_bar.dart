import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    print(
        '🔍 [CustomizationBottomBar] build - totalPrice: $totalPrice | isDrinks: ${menuItem.category.toLowerCase() == "drinks"}');

    final isDrinks = menuItem.category.toLowerCase() == 'drinks';

    // Safe price calculation
    double drinkPrice = 0.0;
    if (isDrinks) {
      drinkPrice = (sizePrices != null &&
              sizes?.isNotEmpty == true &&
              sizePrices![sizes!.first] != null)
          ? (sizePrices![sizes!.first] as num).toDouble()
          : (menuItemPrice ?? 0.0).toDouble();
      print('🔍 [CustomizationBottomBar] Drinks price: $drinkPrice');
    }

    final drinkTotalCount = isDrinks
        ? drinkFlavorCounts.values.fold(0, (sum, v) => sum + (v ?? 0))
        : 0;

    final displayTotal =
        isDrinks ? (drinkTotalCount * drinkPrice) : (totalPrice ?? 0.0);

    print('🔍 [CustomizationBottomBar] Final displayTotal: $displayTotal');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UiConfig.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.total,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: UiConfig.bold,
                    fontFamily: shared.DesignTokens.fontFamily,
                  ),
                ),
                Text(
                  UiConfig.currencyFormat(context, displayTotal),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: UiConfig.primaryColor,
                    fontWeight: UiConfig.bold,
                    fontFamily: shared.DesignTokens.fontFamily,
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
                    color: UiConfig.errorTextColor,
                    fontFamily: shared.DesignTokens.fontFamily,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: UiConfig.secondaryColor,
                  ),
                  onPressed: onCancel,
                  child: Text(
                    loc.cancel,
                    style:
                        TextStyle(fontFamily: shared.DesignTokens.fontFamily),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UiConfig.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          shared.DesignTokens.buttonRadius),
                    ),
                  ),
                  onPressed: isDrinks
                      ? () {
                          if (drinkTotalCount == 0) return;
                          // ... existing drink logic
                          drinkFlavorCounts.forEach((ingId, count) {
                            for (var i = 0; i < count; i++) {
                              onConfirm({'flavor': ingId, 'size': sizes?.first},
                                  1, drinkPrice);
                            }
                          });
                          onCancel();
                        }
                      : onSubmit,
                  child: Text(
                    loc.addToCart,
                    style:
                        TextStyle(fontFamily: shared.DesignTokens.fontFamily),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
