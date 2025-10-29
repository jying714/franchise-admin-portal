import 'package:flutter/material.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/widgets/portion_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/core/models/ingredient_metadata.dart';
import 'package:franchise_mobile_app/widgets/customization/customization_modal.dart'; // for PizzaSauceSelection (or use correct path)

// Add any additional imports your project structure requires.

class SauceSelectorGroup extends StatelessWidget {
  final Map<String, dynamic> group;
  final ThemeData theme;
  final AppLocalizations loc;
  final bool Function() isPizza;
  final List<PizzaSauceSelection> pizzaSauceSelections;
  final Map<String, IngredientMetadata> ingredientMetadata;
  final bool sauceSplitValidationError;
  final VoidCallback resetPizzaSauceSelections;
  final void Function(VoidCallback fn) setState;
  final Map<String, int> selectedSauceCounts;
  final int Function() getFreeSauceCount;
  final double Function() getExtraSauceUpcharge;

  const SauceSelectorGroup({
    Key? key,
    required this.group,
    required this.theme,
    required this.loc,
    required this.isPizza,
    required this.pizzaSauceSelections,
    required this.ingredientMetadata,
    required this.sauceSplitValidationError,
    required this.resetPizzaSauceSelections,
    required this.setState,
    required this.selectedSauceCounts,
    required this.getFreeSauceCount,
    required this.getExtraSauceUpcharge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isPizza()) {
      int selectedCount = pizzaSauceSelections.where((s) => s.selected).length;

      Portion? _takenPortion([int? ignoreIdx]) {
        for (int i = 0; i < pizzaSauceSelections.length; i++) {
          if (i == ignoreIdx) continue;
          final s = pizzaSauceSelections[i];
          if (s.selected && s.portion != Portion.whole) {
            return s.portion;
          }
        }
        return null;
      }

      final int wholeSelectedIdx = pizzaSauceSelections.indexWhere(
        (s) => s.selected && s.portion == Portion.whole,
      );

      final hasCustom = pizzaSauceSelections.skip(1).any((s) => s.selected) ||
          (pizzaSauceSelections.isNotEmpty &&
              pizzaSauceSelections[0].portion != Portion.whole);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group['label'] ?? 'Sauces',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: DesignTokens.secondaryColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ),
                if (hasCustom)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.primaryColor,
                      side: BorderSide(color: DesignTokens.primaryColor),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size(0, 32),
                    ),
                    icon: Icon(Icons.refresh, size: 18),
                    label: Text("Clear", style: TextStyle(fontSize: 14)),
                    onPressed: resetPizzaSauceSelections,
                  ),
              ],
            ),
            ...pizzaSauceSelections.asMap().entries.map((entry) {
              final i = entry.key;
              final sauce = entry.value;
              final meta = ingredientMetadata[sauce.id];
              final outOfStock = meta?.outOfStock == true;

              Portion? otherPortion = _takenPortion(i);

              Map<Portion, bool> disables = {
                Portion.left: false,
                Portion.right: false,
                Portion.whole: false,
              };

              if (sauce.selected) {
                if (otherPortion != null) {
                  disables = {
                    Portion.left: otherPortion == Portion.left,
                    Portion.right: otherPortion == Portion.right,
                    Portion.whole: true,
                  };
                } else if (selectedCount == 2) {
                  disables = {
                    Portion.left: sauce.portion != Portion.left,
                    Portion.right: sauce.portion != Portion.right,
                    Portion.whole: true,
                  };
                } else if (selectedCount == 1 &&
                    sauce.portion != Portion.whole) {
                  disables[Portion.whole] = true;
                }
              } else {
                if (otherPortion != null) {
                  disables = {
                    Portion.left: otherPortion == Portion.left,
                    Portion.right: otherPortion == Portion.right,
                    Portion.whole: true,
                  };
                }
              }

              // Disable this sauce if a different sauce is selected as 'whole'
              bool canSelect =
                  sauce.selected || (selectedCount < 2 && !outOfStock);
              if (wholeSelectedIdx != -1 && wholeSelectedIdx != i) {
                canSelect = false; // Only allow selection of the 'whole' sauce
                disables = {
                  Portion.left: true,
                  Portion.right: true,
                  Portion.whole: true,
                };
              } else if (selectedCount == 2 && !sauce.selected) {
                disables = {
                  Portion.left: true,
                  Portion.right: true,
                  Portion.whole: true,
                };
                canSelect = false;
              }

              void handleCheckbox(bool? val) {
                setState(() {
                  if (val == true) {
                    Portion? already = _takenPortion(i);
                    if (already == Portion.left) {
                      sauce.selected = true;
                      sauce.portion = Portion.right;
                    } else if (already == Portion.right) {
                      sauce.selected = true;
                      sauce.portion = Portion.left;
                    } else {
                      sauce.selected = true;
                      sauce.portion = Portion.whole;
                    }
                  } else {
                    sauce.selected = false;
                    sauce.portion = Portion.whole;
                    sauce.amount = 'regular';
                  }
                });
              }

              void handlePortionChange(Portion portion) {
                if (disables[portion] == true) return;
                setState(() {
                  sauce.portion = portion;
                });
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                elevation: 0,
                color: sauce.selected
                    ? DesignTokens.surfaceColor
                    : Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: sauce.selected,
                          onChanged:
                              canSelect && !outOfStock ? handleCheckbox : null,
                        ),
                        Expanded(
                          child: Text(
                            sauce.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: outOfStock
                                  ? DesignTokens.secondaryTextColor
                                  : DesignTokens.textColor,
                              fontFamily: DesignTokens.fontFamily,
                            ),
                          ),
                        ),
                        if (outOfStock)
                          Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: Icon(Icons.block,
                                color: DesignTokens.errorTextColor, size: 18),
                          ),
                      ],
                    ),
                    if (sauce.selected)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 20.0, top: 4.0, right: 0.0, bottom: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Flexible(
                              flex: 0,
                              child: PortionSelector(
                                value: sauce.portion,
                                onChanged: handlePortionChange,
                                size: 24,
                                disables: disables,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: 170,
                                    ),
                                    child: ToggleButtons(
                                      isSelected: [
                                        sauce.amount == 'light',
                                        sauce.amount == 'regular',
                                        sauce.amount == 'extra'
                                      ],
                                      onPressed: (idx) {
                                        setState(() {
                                          sauce.amount = [
                                            'light',
                                            'regular',
                                            'extra'
                                          ][idx];
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      constraints: BoxConstraints(
                                        minWidth: 38,
                                        minHeight: 32,
                                      ),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 2),
                                          child: Text('Light',
                                              style: TextStyle(fontSize: 11)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 2),
                                          child: Text('Regular',
                                              style: TextStyle(fontSize: 11)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 2),
                                          child: Text('Extra',
                                              style: TextStyle(fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            if (sauceSplitValidationError)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                child: Text(
                  "For half & half, both sides must have a sauce (including 'No Sauce').",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: DesignTokens.errorTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // --- Non-pizza fallback logic ---
    final groupLabel = group['label'] ?? '';
    final ingredientIds = (group['ingredientIds'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final int freeSauces = getFreeSauceCount();
    final double extraSauceUpcharge = getExtraSauceUpcharge();

    for (final id in ingredientIds) {
      selectedSauceCounts[id] ??= 0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$groupLabel ($freeSauces free, +\$${extraSauceUpcharge.toStringAsFixed(2)} each extra)",
            style: theme.textTheme.titleMedium?.copyWith(
              color: DesignTokens.secondaryColor,
              fontWeight: FontWeight.bold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          ...ingredientIds.map((ingId) {
            final meta = ingredientMetadata[ingId];
            final count = selectedSauceCounts[ingId] ?? 0;
            final outOfStock = meta?.outOfStock == true;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, size: 20),
                    onPressed: !outOfStock && count > 0
                        ? () => setState(
                            () => selectedSauceCounts[ingId] = count - 1)
                        : null,
                  ),
                  SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      meta?.name ?? ingId,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: DesignTokens.textColor,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: 28,
                    alignment: Alignment.center,
                    child: Text(
                      'x$count',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: count > 0
                            ? DesignTokens.primaryColor
                            : DesignTokens.secondaryTextColor,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.add, size: 20),
                    onPressed: !outOfStock
                        ? () => setState(
                            () => selectedSauceCounts[ingId] = count + 1)
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
