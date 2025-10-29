import 'package:flutter/material.dart';
import 'package:franchise_mobile_app/core/models/menu_item.dart';
import 'package:franchise_mobile_app/core/models/ingredient_metadata.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/core/utils/formatting.dart';

class DrinksFlavorSelector extends StatelessWidget {
  final MenuItem menuItem;
  final ThemeData theme;
  final AppLocalizations loc;
  final Map<String, IngredientMetadata> ingredientMetadata;
  final Map<String, int> selectedSauceCounts;
  final void Function(VoidCallback fn) setState;

  const DrinksFlavorSelector({
    Key? key,
    required this.menuItem,
    required this.theme,
    required this.loc,
    required this.ingredientMetadata,
    required this.selectedSauceCounts,
    required this.setState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = menuItem.sizes?.first ?? '';
    final price = menuItem.sizePrices != null &&
            menuItem.sizes != null &&
            menuItem.sizes!.isNotEmpty
        ? (menuItem.sizePrices![menuItem.sizes!.first] as num?)?.toDouble() ??
            menuItem.price
        : menuItem.price;

    final included = menuItem.includedIngredients ?? [];
    final flavorIds =
        included.map((e) => e['ingredientId'] ?? e['id']).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Size",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: DesignTokens.secondaryColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              SizedBox(width: 8),
              Text(
                size,
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(width: 16),
              Text(
                currencyFormat(context, price),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: DesignTokens.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "Choose Flavors",
            style: theme.textTheme.titleMedium?.copyWith(
              color: DesignTokens.secondaryColor,
              fontWeight: FontWeight.bold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          ...flavorIds.map((id) {
            final meta = ingredientMetadata[id];
            final count = selectedSauceCounts[id] ?? 0;
            final outOfStock = meta?.outOfStock == true;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, size: 20),
                    onPressed: !outOfStock && count > 0
                        ? () => setState(() {
                              selectedSauceCounts[id] = count - 1;
                            })
                        : null,
                  ),
                  SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      meta?.name ?? id,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: DesignTokens.textColor,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('x$count', style: theme.textTheme.bodyLarge),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.add, size: 20),
                    onPressed: !outOfStock && count < 10
                        ? () => setState(() {
                              selectedSauceCounts[id] = count + 1;
                            })
                        : null,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
