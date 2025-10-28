import 'package:flutter/material.dart';
import 'package:doughboys_pizzeria_final/core/models/menu_item.dart';
import 'package:doughboys_pizzeria_final/core/models/ingredient_metadata.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';
import 'package:doughboys_pizzeria_final/widgets/portion_selector.dart';
import 'package:doughboys_pizzeria_final/widgets/customization/portion_pill_toggle.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

typedef CurrencyFormat = String Function(BuildContext context, num value);
typedef GetSaladToppingUpcharge = double Function();
typedef ToggleIngredient = void Function(String, String);
typedef CanDoubleCurrentIngredient = bool Function(String? groupLabel);
typedef IsDoughIngredient = bool Function(String);
typedef IsRadioGroup = bool Function(String);
typedef GetPortion = Portion Function(String);

class CurrentIngredients extends StatelessWidget {
  final List<String> currentIngredients;
  final MenuItem menuItem;
  final Map<String, IngredientMetadata> ingredientMetadata;
  final Map<String, int> selectedSauceCounts;
  final Map<String, int> selectedDressingCounts;
  final Map<String, String> radioSelections;
  final Map<String, Portion> ingredientPortions;
  final Map<String, bool> doubleToppings;
  final Map<String, double> ingredientAmounts;
  final int doublesCount;
  final int maxDoubles;
  final bool Function(String? groupLabel) canDoubleCurrentIngredient;
  final bool Function(String) isDoughIngredient;
  final bool Function(String) isRadioGroup;
  final double Function() getSaladToppingUpcharge;
  final CurrencyFormat currencyFormat;
  final void Function(void Function()) setState;
  final ToggleIngredient toggleIngredient;

  const CurrentIngredients({
    Key? key,
    required this.currentIngredients,
    required this.menuItem,
    required this.ingredientMetadata,
    required this.selectedSauceCounts,
    required this.selectedDressingCounts,
    required this.radioSelections,
    required this.ingredientPortions,
    required this.doubleToppings,
    required this.ingredientAmounts,
    required this.doublesCount,
    required this.maxDoubles,
    required this.canDoubleCurrentIngredient,
    required this.isDoughIngredient,
    required this.isRadioGroup,
    required this.getSaladToppingUpcharge,
    required this.currencyFormat,
    required this.setState,
    required this.toggleIngredient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    if (currentIngredients.isEmpty) return const SizedBox.shrink();

    final isDinner = menuItem.category.toLowerCase().contains('dinner');
    final isSalad = menuItem.category.toLowerCase().contains('salad');

    // Salad upcharge annotation (always visible for salads)
    final upchargeAnnotation = isSalad
        ? Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              'Add extra toppings or double any ingredient for just +${currencyFormat(context, getSaladToppingUpcharge())}.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: DesignTokens.secondaryTextColor,
                fontStyle: FontStyle.italic,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          )
        : const SizedBox.shrink();

    final showIngIds = currentIngredients.where((id) {
      final meta = ingredientMetadata[id];
      if (isDinner) {
        if (meta?.type?.toLowerCase() == 'sauces' &&
            (meta?.amountSelectable ?? false)) {
          return true;
        }
        return (meta?.removable ?? false);
      }
      if (isDoughIngredient(id)) return false;
      if (selectedSauceCounts.containsKey(id)) return false;
      if (selectedDressingCounts.containsKey(id)) return false;
      if (menuItem.customizationGroups != null) {
        for (final group in menuItem.customizationGroups!) {
          if ((group['ingredientIds'] as List).contains(id)) {
            final groupLabel = group['label'] as String;
            if (isRadioGroup(groupLabel)) {
              if (radioSelections[groupLabel] == id) return false;
            }
          }
        }
      }
      return true;
    }).toList();

    if (showIngIds.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSalad) upchargeAnnotation,
          Text(
            loc.currentIngredientsLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: DesignTokens.primaryColor,
              fontWeight: FontWeight.bold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          ...showIngIds.map((ingId) {
            final meta = ingredientMetadata[ingId];
            String? groupLabel;
            if (menuItem.customizationGroups != null) {
              for (final group in menuItem.customizationGroups!) {
                if ((group['ingredientIds'] as List).contains(ingId)) {
                  groupLabel = group['label'];
                  break;
                }
              }
            }
            final removable = meta?.removable ?? true;
            final outOfStock = meta?.outOfStock == true;
            final cat = menuItem.category.toLowerCase();
            final isPizza = cat.contains('pizza');
            final showPortionSelector = isPizza &&
                groupLabel != null &&
                (groupLabel == "Meats" ||
                    groupLabel == "Veggies" ||
                    groupLabel == "Cheeses");
            final canDouble = canDoubleCurrentIngredient(groupLabel);
            final isSauceWithDropdown = isDinner &&
                (meta?.type?.toLowerCase() == 'sauces' &&
                    (meta?.amountSelectable ?? false));
            final isRemoved = removable && !currentIngredients.contains(ingId);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isDinner && isSauceWithDropdown)
                      const SizedBox(width: 18),
                    if (isDinner && !isSauceWithDropdown && removable)
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
                    if (!isDinner)
                      Checkbox(
                        value: true,
                        onChanged: removable &&
                                groupLabel != null &&
                                !isRadioGroup(groupLabel) &&
                                groupLabel.toLowerCase() != 'sauces' &&
                                groupLabel.toLowerCase() != 'dressings'
                            ? (val) => toggleIngredient(ingId, groupLabel!)
                            : null,
                      ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              meta?.name ?? ingId,
                              style: TextStyle(
                                fontWeight: removable
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: outOfStock
                                    ? DesignTokens.secondaryTextColor
                                    : DesignTokens.textColor,
                              ),
                            ),
                          ),
                          if (isSauceWithDropdown)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: DropdownButton<String>(
                                value: ingredientAmounts[ingId] != null
                                    ? ingredientAmounts[ingId].toString()
                                    : meta?.amountOptions?.first,
                                items: List<String>.from(
                                  meta?.amountOptions ?? [],
                                )
                                    .map((opt) => DropdownMenuItem<String>(
                                          value: opt,
                                          child: Text(opt),
                                        ))
                                    .toList(),
                                onChanged: outOfStock
                                    ? null
                                    : (val) {
                                        setState(() {
                                          ingredientAmounts[ingId] =
                                              double.parse(val!);
                                        });
                                      },
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isDinner && !isSauceWithDropdown && isRemoved)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          loc.ingredientRemovedLabel,
                          style: TextStyle(
                            color: DesignTokens.primaryColor,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (!isDinner && !showPortionSelector && canDouble) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          "Amount",
                          style: const TextStyle(
                            fontSize: 13,
                            color: DesignTokens.secondaryColor,
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PortionPillToggle(
                        isDouble: doubleToppings[ingId] == true,
                        onTap: () {
                          setState(() {
                            if (doubleToppings[ingId] == true) {
                              doubleToppings[ingId] = false;
                            } else {
                              if (doublesCount < maxDoubles)
                                doubleToppings[ingId] = true;
                            }
                          });
                        },
                      ),
                    ],
                  ],
                ),
                if (!isDinner && showPortionSelector)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 40),
                        PortionSelector(
                          value: ingredientPortions[ingId] ?? Portion.whole,
                          onChanged: (portion) {
                            setState(() {
                              ingredientPortions[ingId] = portion;
                            });
                          },
                          size: 22,
                        ),
                        const Spacer(),
                        PortionPillToggle(
                          isDouble: doubleToppings[ingId] == true,
                          onTap: () {
                            setState(() {
                              if (doubleToppings[ingId] == true) {
                                doubleToppings[ingId] = false;
                              } else {
                                if (doublesCount < maxDoubles)
                                  doubleToppings[ingId] = true;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                if (!removable && !isDinner)
                  Padding(
                    padding: const EdgeInsets.only(left: 44.0, top: 2),
                    child: Text(
                      loc.cannotBeRemoved,
                      style: const TextStyle(
                        color: DesignTokens.hintTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (showIngIds.last != ingId)
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
