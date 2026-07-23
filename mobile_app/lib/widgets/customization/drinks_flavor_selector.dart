import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/generated/app_localizations.dart';

class DrinksFlavorSelector extends StatelessWidget {
  final shared.MenuItem menuItem;
  final ThemeData theme;
  final AppLocalizations loc;
  final Map<String, shared.IngredientMetadata> ingredientMetadata;
  final Map<String, int> selectedSauceCounts;
  final void Function(VoidCallback fn) setState;

  const DrinksFlavorSelector({
    super.key,
    required this.menuItem,
    required this.theme,
    required this.loc,
    required this.ingredientMetadata,
    required this.selectedSauceCounts,
    required this.setState,
  });

  @override
  Widget build(BuildContext context) {
    // FranchiseProvider injected (P1 Batch 1) for franchise/{franchiseId}/ scoping centrality
    Provider.of<shared.FranchiseProvider>(context, listen: false);
    final size = menuItem.sizes?.first?.toString() ?? '';
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
                  color: shared.UiConfig.secondaryColor,
                  fontWeight: shared.UiConfig.bold,
                  fontFamily: shared.DesignTokens.fontFamily,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                size,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(width: 16),
              Text(
                shared.UiConfig.currencyFormat(price),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: shared.UiConfig.primaryColor,
                  fontWeight: shared.UiConfig.bold,
                  fontFamily: shared.DesignTokens.fontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Choose Flavors",
            style: theme.textTheme.titleMedium?.copyWith(
              color: shared.UiConfig.secondaryColor,
              fontWeight: shared.UiConfig.bold,
              fontFamily: shared.DesignTokens.fontFamily,
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
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: !outOfStock && count > 0
                        ? () => setState(() {
                              selectedSauceCounts[id] = count - 1;
                            })
                        : null,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      meta?.name ?? id,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: shared.UiConfig.textColor,
                        fontFamily: shared.DesignTokens.fontFamily,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'x$count',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: shared.UiConfig.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: !outOfStock && count < 10
                        ? () => setState(() {
                              selectedSauceCounts[id] = count + 1;
                            })
                        : null,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
