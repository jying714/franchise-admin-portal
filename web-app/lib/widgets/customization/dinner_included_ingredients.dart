import 'package:flutter/material.dart';
import '../../../../packages/shared_core/lib/src/core/models/menu_item.dart';
import '../../../../packages/shared_core/lib/src/core/models/ingredient_metadata.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DinnerIncludedIngredients extends StatelessWidget {
  final MenuItem menuItem;
  final ThemeData theme;
  final AppLocalizations loc;
  final Map<String, IngredientMetadata> ingredientMetadata;
  final Set<String> currentIngredients;
  final Map<String, String> ingredientAmounts;
  final void Function(VoidCallback fn) setState;

  const DinnerIncludedIngredients({
    Key? key,
    required this.menuItem,
    required this.theme,
    required this.loc,
    required this.ingredientMetadata,
    required this.currentIngredients,
    required this.ingredientAmounts,
    required this.setState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if ((menuItem.category.toLowerCase() != 'dinners') ||
        menuItem.includedIngredients == null ||
        menuItem.includedIngredients!.isEmpty) {
      return SizedBox.shrink();
    }

    final visibleIngs = menuItem.includedIngredients!.where((ing) {
      final ingId = ing['ingredientId'] ?? ing['id'];
      final meta = ingredientMetadata[ingId];
      final removable = meta?.removable ?? ing['removable'] ?? false;
      final isSauce = meta?.type?.toLowerCase() == 'sauces';
      final amountSelectable =
          meta?.amountSelectable ?? ing['amountSelectable'] == true;
      // Only show if removable, or if sauce with amountSelectable
      return removable || (isSauce && amountSelectable);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.currentIngredientsLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: DesignTokens.primaryColor,
              fontWeight: FontWeight.bold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          ...visibleIngs.asMap().entries.map((entry) {
            final index = entry.key;
            final ing = entry.value;
            final ingId = ing['ingredientId'] ?? ing['id'];
            final meta = ingredientMetadata[ingId];
            final name = meta?.name ?? ing['name'] ?? ingId;
            final removable = meta?.removable ?? ing['removable'] ?? false;
            final outOfStock = meta?.outOfStock ?? false;
            final isSauce = meta?.type?.toLowerCase() == 'sauces';
            final amountSelectable =
                meta?.amountSelectable ?? ing['amountSelectable'] == true;
            final List<String> amountOptions =
                meta?.amountOptions?.cast<String>() ??
                    (ing['amountOptions'] is List
                        ? List<String>.from(ing['amountOptions'])
                        : []);
            final String? amountValue = ingredientAmounts[ingId] ??
                (amountOptions.isNotEmpty
                    ? amountOptions.firstWhere(
                        (opt) => opt.toLowerCase() == 'regular',
                        orElse: () => amountOptions.first)
                    : null);

            final isRemoved = removable && !currentIngredients.contains(ingId);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Only show checkbox if removable and not amount-selectable sauce
                    if (removable && !(isSauce && amountSelectable))
                      Checkbox(
                        value: !isRemoved,
                        onChanged: outOfStock
                            ? null
                            : (val) {
                                setState(() {
                                  if (val == true) {
                                    currentIngredients.add(ingId);
                                  } else {
                                    currentIngredients.remove(ingId);
                                  }
                                });
                              },
                      ),
                    if (!removable || (isSauce && amountSelectable))
                      SizedBox(width: 18), // align w/ checkbox

                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: outOfStock
                                    ? DesignTokens.secondaryTextColor
                                    : DesignTokens.textColor,
                                fontWeight: outOfStock
                                    ? FontWeight.normal
                                    : FontWeight.w500,
                                fontFamily: DesignTokens.fontFamily,
                              ),
                            ),
                          ),
                          // If amount is selectable, always show dropdown
                          if (isSauce &&
                              amountSelectable &&
                              amountOptions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: DropdownButton<String>(
                                value: amountValue,
                                items: amountOptions.map((opt) {
                                  return DropdownMenuItem<String>(
                                    value: opt,
                                    child: Text(opt),
                                  );
                                }).toList(),
                                onChanged: outOfStock
                                    ? null
                                    : (val) {
                                        setState(() {
                                          ingredientAmounts[ingId] = val!;
                                        });
                                      },
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Out of Stock Annotation
                    if (outOfStock)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          loc.outOfStockLabel ?? "Out of Stock",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: DesignTokens.errorTextColor,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // "Removed" annotation for removable non-sauce ingredients
                    if (removable &&
                        !(isSauce && amountSelectable) &&
                        isRemoved)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          loc.ingredientRemovedLabel ?? "Removed",
                          style: TextStyle(
                            color: DesignTokens.primaryColor,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (index < visibleIngs.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Divider(
                      thickness: 1.0,
                      color: Colors.grey[300],
                      height: 1,
                    ),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
