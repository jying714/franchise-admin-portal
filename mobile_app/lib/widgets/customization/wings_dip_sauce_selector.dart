import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/generated/app_localizations.dart';

class WingsDipSauceSelector extends StatelessWidget {
  final shared.MenuItem menuItem;
  final ThemeData theme;
  final AppLocalizations loc;
  final Map<String, shared.IngredientMetadata> ingredientMetadata;
  final Map<String, int> sideDipCounts;
  final String? selectedSize;
  final void Function(VoidCallback fn) setState;

  const WingsDipSauceSelector({
    super.key,
    required this.menuItem,
    required this.theme,
    required this.loc,
    required this.ingredientMetadata,
    required this.sideDipCounts,
    this.selectedSize,
    required this.setState,
  });

  @override
  Widget build(BuildContext context) {
    // Product: one list for side cups. Prefer sideDipSauceOptions; fall back to
    // dippingSauceOptions (HQ may bind once and project both on save).
    final dipsIds = (menuItem.sideDipSauceOptions?.isNotEmpty == true)
        ? menuItem.sideDipSauceOptions!
        : (menuItem.dippingSauceOptions ?? const <String>[]);

    // Use selected size when parent passes it via size key on the maps.
    // Parent rebuilds this widget when size changes; maps are keyed by size label.
    final sizeKey = selectedSize ??
        (menuItem.sizes?.isNotEmpty == true
            ? menuItem.sizes!.first.label
            : null);

    final upcharge =
        (sizeKey != null) ? (menuItem.sideDipUpcharge?[sizeKey] ?? 0.95) : 0.95;
    final freeDipCups =
        (sizeKey != null) ? (menuItem.freeDipCupCount?[sizeKey] ?? 0) : 0;

    int getCount(String id) => sideDipCounts[id] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dipping sauces",
            style: theme.textTheme.titleMedium?.copyWith(
              color: shared.UiConfig.secondaryColor,
              fontWeight: shared.UiConfig.bold,
              fontFamily: shared.DesignTokens.fontFamily,
            ),
          ),
          Text(
            "$freeDipCups free included. Additional cups +${shared.UiConfig.currencyFormat(upcharge)} each.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: shared.UiConfig.secondaryTextColor,
              fontStyle: FontStyle.italic,
              fontFamily: shared.DesignTokens.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          if (dipsIds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Text(
                "No dipping sauces configured for this item.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: shared.UiConfig.secondaryTextColor,
                  fontFamily: shared.DesignTokens.fontFamily,
                ),
              ),
            )
          else
            ...dipsIds.map((dipId) {
              final meta = ingredientMetadata[dipId];
              final count = getCount(dipId);
              final outOfStock = meta?.outOfStock == true;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        meta?.name ?? dipId,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: shared.UiConfig.textColor,
                          fontFamily: shared.DesignTokens.fontFamily,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: !outOfStock && count > 0
                          ? () =>
                              setState(() => sideDipCounts[dipId] = count - 1)
                          : null,
                    ),
                    Text('x$count', style: theme.textTheme.bodyLarge),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: !outOfStock
                          ? () =>
                              setState(() => sideDipCounts[dipId] = count + 1)
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
