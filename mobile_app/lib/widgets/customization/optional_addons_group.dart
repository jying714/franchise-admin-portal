import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/generated/app_localizations.dart';

typedef DoubleAddOnCallback = void Function(String ingId, bool value);

class OptionalAddOnsGroup extends StatelessWidget {
  final shared.MenuItem menuItem;
  final ThemeData theme;
  final AppLocalizations loc;
  final Map<String, shared.IngredientMetadata> ingredientMetadata;
  final Set<String> selectedAddOns;

  /// Ingredients already on Current Toppings — hide from optional pool.
  final Set<String> currentIngredientIds;
  final Map<String, bool> doubleAddOns;
  final Map<String, int> selectedSauceCounts;
  final bool usesDynamicToppingPricing;
  final double Function() getToppingUpcharge;
  final double Function(shared.IngredientMetadata? meta) getIngredientUpcharge;
  final void Function(String ingId, bool? value) onToggleAddOn;
  final void Function(String ingId, int delta) onChangeSauceCount;
  final Widget Function(String ingId, bool isDouble, VoidCallback onTap)
      buildAddOnDoublePill;
  final int maxFreeSauces;
  final double extraSauceUpcharge;

  const OptionalAddOnsGroup({
    super.key,
    required this.menuItem,
    required this.theme,
    required this.loc,
    required this.ingredientMetadata,
    required this.selectedAddOns,
    this.currentIngredientIds = const {},
    required this.doubleAddOns,
    required this.selectedSauceCounts,
    required this.usesDynamicToppingPricing,
    required this.getToppingUpcharge,
    required this.getIngredientUpcharge,
    required this.onToggleAddOn,
    required this.onChangeSauceCount,
    required this.buildAddOnDoublePill,
    required this.maxFreeSauces,
    required this.extraSauceUpcharge,
  });

  @override
  Widget build(BuildContext context) {
    final toppingUpcharge = getToppingUpcharge();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              child: Text(
                loc.optionalAddOnsLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ...() {
            // Pool = optionalAddOns ∪ includedIngredients, minus what's on Current
            final byId = <String, Map<String, dynamic>>{};
            for (final addOn in menuItem.optionalAddOns ?? const []) {
              final id =
                  (addOn['ingredientId'] ?? addOn['id'] ?? '').toString();
              if (id.isEmpty) continue;
              byId[id] = Map<String, dynamic>.from(addOn);
            }
            for (final inc in menuItem.includedIngredients ?? const []) {
              final id = (inc['ingredientId'] ?? inc['id'] ?? '').toString();
              if (id.isEmpty) continue;
              byId.putIfAbsent(id, () => Map<String, dynamic>.from(inc));
            }
            return byId.entries
                .where((e) => !currentIngredientIds.contains(e.key))
                .map((e) => e.value);
          }()
              .map((addOn) {
            final ingId = addOn['ingredientId'] ?? addOn['id'];
            final meta = ingredientMetadata[ingId];
            final isSauce = (meta?.type?.toLowerCase() == "sauces") ||
                (addOn['type']?.toString()?.toLowerCase() == "sauces");
            final upcharge = usesDynamicToppingPricing
                ? toppingUpcharge
                : (meta != null &&
                        meta.upcharge != null &&
                        meta.upcharge!.isNotEmpty)
                    ? getIngredientUpcharge(meta)
                    : (addOn['price'] as num?)?.toDouble() ?? 0.0;

            if (isSauce) {
              final count = selectedSauceCounts[ingId] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: count > 0
                          ? () => onChangeSauceCount(ingId, -1)
                          : null,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        meta?.name ?? addOn['name'] ?? ingId,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontFamily: shared.DesignTokens.fontFamily,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      alignment: Alignment.center,
                      child: Text(
                        'x$count',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: shared.UiConfig.bold,
                          color: count > 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontFamily: shared.DesignTokens.fontFamily,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => onChangeSauceCount(ingId, 1),
                    ),
                  ],
                ),
              );
            } else {
              // Same card + "Click to Add" pattern as Additional Toppings
              if (selectedAddOns.contains(ingId)) {
                return const SizedBox.shrink();
              }
              final outOfStock = meta?.outOfStock == true;
              final priceDisplay = upcharge > 0
                  ? '+${shared.UiConfig.currencyFormat(upcharge)}'
                  : '';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          meta?.name ?? addOn['name'] ?? ingId,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontFamily: shared.DesignTokens.fontFamily,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (priceDisplay.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            priceDisplay,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: shared.UiConfig.bold,
                              fontFamily: shared.DesignTokens.fontFamily,
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: outOfStock
                            ? null
                            : () => onToggleAddOn(ingId, true),
                        child: Text(
                          'Click to Add',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }),
          if (() {
            final fromOptional = (menuItem.optionalAddOns ?? const []).any(
                (a) =>
                    (ingredientMetadata[a['ingredientId'] ?? a['id']]
                            ?.type
                            ?.toLowerCase() ==
                        "sauces") ||
                    (a['type']?.toString().toLowerCase() == "sauces"));
            final fromIncluded = (menuItem.includedIngredients ?? const []).any(
                (a) =>
                    (ingredientMetadata[a['ingredientId'] ?? a['id']]
                            ?.type
                            ?.toLowerCase() ==
                        "sauces") ||
                    (a['type']?.toString().toLowerCase() == "sauces"));
            return fromOptional || fromIncluded;
          }())
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                "$maxFreeSauces free sauces, +${shared.UiConfig.currencyFormat(extraSauceUpcharge)} each extra.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontFamily: shared.DesignTokens.fontFamily,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
