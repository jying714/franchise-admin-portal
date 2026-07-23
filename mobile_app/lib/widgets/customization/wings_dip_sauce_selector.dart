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
  final int wingsDipSauceTabIndex;
  final void Function(VoidCallback fn) setState;
  final void Function(int newIndex) onTabChanged;

  const WingsDipSauceSelector({
    super.key,
    required this.menuItem,
    required this.theme,
    required this.loc,
    required this.ingredientMetadata,
    required this.sideDipCounts,
    required this.wingsDipSauceTabIndex,
    required this.setState,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dipsIds = menuItem.dippingSauceOptions ?? [];
    final saucesAddOns = (menuItem.optionalAddOns ?? [])
        .where((addOn) => addOn['type']?.toString().toLowerCase() == 'sauces')
        .toList();

    final upcharge = menuItem.sideDipUpcharge != null
        ? menuItem.sideDipUpcharge![menuItem.sizes?.first?.toString()] ?? 0.95
        : 0.95;
    final freeDipCups = menuItem.freeDipCupCount != null
        ? menuItem.freeDipCupCount![menuItem.sizes?.first?.toString()] ?? 0
        : 0;

    int getCount(String id) => sideDipCounts[id] ?? 0;

    List<Widget> buildDipRows() => dipsIds.map<Widget>((dipId) {
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
                      ? () => setState(() => sideDipCounts[dipId] = count - 1)
                      : null,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    meta?.name ?? dipId,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: shared.UiConfig.textColor,
                      fontFamily: shared.DesignTokens.fontFamily,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('x$count', style: theme.textTheme.bodyLarge),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: !outOfStock
                      ? () => setState(() => sideDipCounts[dipId] = count + 1)
                      : null,
                ),
              ],
            ),
          );
        }).toList();

    List<Widget> buildSauceRows() => saucesAddOns.map<Widget>((addOn) {
          final ingId = addOn['ingredientId'] ?? addOn['id'];
          final meta = ingredientMetadata[ingId];
          final count = getCount(ingId);
          final outOfStock = meta?.outOfStock == true;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: !outOfStock && count > 0
                      ? () => setState(() => sideDipCounts[ingId] = count - 1)
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
                Text('x$count', style: theme.textTheme.bodyLarge),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: !outOfStock
                      ? () => setState(() => sideDipCounts[ingId] = count + 1)
                      : null,
                ),
              ],
            ),
          );
        }).toList();

    final List<String> tabs = ["Dips", "Sauces"];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dips & Sauces",
            style: theme.textTheme.titleMedium?.copyWith(
              color: shared.UiConfig.secondaryColor,
              fontWeight: shared.UiConfig.bold,
              fontFamily: shared.DesignTokens.fontFamily,
            ),
          ),
          Text(
            "$freeDipCups free included. Additional dips +${shared.UiConfig.currencyFormat(upcharge)} each.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: shared.UiConfig.secondaryTextColor,
              fontStyle: FontStyle.italic,
              fontFamily: shared.DesignTokens.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          // Tab bar
          Row(
            children: List.generate(tabs.length, (i) {
              final selected = wingsDipSauceTabIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTabChanged(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? shared.UiConfig.primaryColor.withOpacity(0.11)
                          : shared.UiConfig.cardColor.withValues(alpha: 0.0),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? shared.UiConfig.primaryColor
                            : shared.UiConfig.secondaryTextColor
                                .withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    child: Text(
                      tabs[i],
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: selected
                            ? shared.UiConfig.primaryColor
                            : shared.UiConfig.textColor,
                        fontWeight:
                            selected ? shared.UiConfig.bold : FontWeight.normal,
                        fontFamily: shared.DesignTokens.fontFamily,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          if (wingsDipSauceTabIndex == 0)
            ...(dipsIds.isNotEmpty
                ? buildDipRows()
                : [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      child: Text(
                        "No dips available.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: shared.UiConfig.secondaryTextColor,
                          fontFamily: shared.DesignTokens.fontFamily,
                        ),
                      ),
                    )
                  ]),
          if (wingsDipSauceTabIndex == 1)
            ...(saucesAddOns.isNotEmpty
                ? buildSauceRows()
                : [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      child: Text(
                        "No sauces available.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: shared.UiConfig.secondaryTextColor,
                          fontFamily: shared.DesignTokens.fontFamily,
                        ),
                      ),
                    )
                  ]),
        ],
      ),
    );
  }
}
