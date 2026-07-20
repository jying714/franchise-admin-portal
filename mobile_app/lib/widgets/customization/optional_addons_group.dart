import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

typedef DoubleAddOnCallback = void Function(String ingId, bool value);

class OptionalAddOnsGroup extends StatelessWidget {
  final shared.MenuItem menuItem;
  final ThemeData theme;
  final AppLocalizations loc;
  final Map<String, shared.IngredientMetadata> ingredientMetadata;
  final Set<String> selectedAddOns;
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
          Text(
            loc.optionalAddOnsLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: shared.UiConfig.secondaryColor,
              fontWeight: shared.UiConfig.bold,
              fontFamily: shared.DesignTokens.fontFamily,
            ),
          ),
          ...menuItem.optionalAddOns!.map((addOn) {
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
                          color: shared.UiConfig.textColor,
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
                              ? shared.UiConfig.primaryColor
                              : shared.UiConfig.secondaryTextColor,
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
              final checked = selectedAddOns.contains(ingId);
              final isDouble = doubleAddOns[ingId] == true;
              final priceDisplay = upcharge > 0
                  ? '+${shared.UiConfig.currencyFormat(upcharge * (isDouble ? 2 : 1))}'
                  : '';
              return Row(
                children: [
                  Checkbox(
                    value: checked,
                    onChanged: meta?.outOfStock == true
                        ? null
                        : (val) => onToggleAddOn(ingId, val),
                  ),
                  Expanded(
                    child: Text(
                      meta?.name ?? addOn['name'] ?? ingId,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: shared.UiConfig.textColor,
                        fontFamily: shared.DesignTokens.fontFamily,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (checked && upcharge > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        priceDisplay,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: shared.UiConfig.secondaryColor,
                          fontWeight: shared.UiConfig.bold,
                          fontFamily: shared.DesignTokens.fontFamily,
                        ),
                      ),
                    ),
                  if (checked)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                      child: buildAddOnDoublePill(
                        ingId,
                        isDouble,
                        () => onToggleAddOn(ingId, !isDouble),
                      ),
                    ),
                ],
              );
            }
          }),
          if (menuItem.optionalAddOns!.any((a) =>
              (ingredientMetadata[a['ingredientId'] ?? a['id']]
                      ?.type
                      ?.toLowerCase() ==
                  "sauces") ||
              (a['type']?.toString()?.toLowerCase() == "sauces")))
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                "$maxFreeSauces free sauces, +${shared.UiConfig.currencyFormat(extraSauceUpcharge)} each extra.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: shared.UiConfig.secondaryTextColor,
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
