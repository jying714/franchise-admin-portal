import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/generated/app_localizations.dart';

class WingsDipSauceSelector extends StatelessWidget {
  final shared.MenuItem menuItem;
  final ThemeData theme;
  final AppLocalizations loc;
  final Map<String, shared.IngredientMetadata> ingredientMetadata;
  final Map<String, int> sideDipCounts;
  final String? selectedSize;
  final void Function(void Function()) setState;

  const WingsDipSauceSelector({
    Key? key,
    required this.menuItem,
    required this.theme,
    required this.loc,
    required this.ingredientMetadata,
    required this.sideDipCounts,
    this.selectedSize,
    required this.setState,
  }) : super(key: key);

  @override
  @override
  Widget build(BuildContext context) {
    final dipsIds = (menuItem.sideDipSauceOptions?.isNotEmpty == true)
        ? menuItem.sideDipSauceOptions!
        : (menuItem.dippingSauceOptions ?? const <String>[]);

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
              color: DesignTokens.secondaryColor,
              fontWeight: FontWeight.bold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          Text(
            "$freeDipCups free included. Additional cups +\$${upcharge.toStringAsFixed(2)} each.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: DesignTokens.secondaryTextColor,
              fontStyle: FontStyle.italic,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          if (dipsIds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Text(
                "No dipping sauces configured for this item.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.secondaryTextColor,
                  fontFamily: DesignTokens.fontFamily,
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
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: !outOfStock && count > 0
                          ? () =>
                              setState(() => sideDipCounts[dipId] = count - 1)
                          : null,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        meta?.name ?? dipId,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: DesignTokens.textColor,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('x$count', style: theme.textTheme.bodyLarge),
                    const SizedBox(width: 8),
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
