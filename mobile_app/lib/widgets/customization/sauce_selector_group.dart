import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/portion_selector.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';

typedef GetToppingUpcharge = double Function();
typedef CurrencyFormat = String Function(BuildContext, double);

class SauceSelectorGroup extends StatelessWidget {
  final Map<String, dynamic> group;
  final ThemeData theme;
  final AppLocalizations loc;
  final bool Function() isPizza;
  final List<Map<String, dynamic>> pizzaSauceSelections;
  final Map<String, shared.IngredientMetadata> ingredientMetadata;
  final bool sauceSplitValidationError;
  final VoidCallback resetPizzaSauceSelections;
  final void Function(VoidCallback fn) setState;
  final Map<String, int> selectedSauceCounts;
  final int Function() getFreeSauceCount;
  final double Function() getExtraSauceUpcharge;

  const SauceSelectorGroup({
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    if (isPizza()) {
      final int selectedCount =
          pizzaSauceSelections.where((s) => s['selected'] == true).length;

      Portion? _takenPortion([int? ignoreIdx]) {
        for (int i = 0; i < pizzaSauceSelections.length; i++) {
          if (i == ignoreIdx) continue;
          final s = pizzaSauceSelections[i];
          if (s['selected'] == true) {
            final p = (s['portion'] as String? ?? 'whole').toLowerCase();
            if (p == 'left') return Portion.left;
            if (p == 'right') return Portion.right;
          }
        }
        return null;
      }

      final int wholeSelectedIdx = pizzaSauceSelections.indexWhere((s) {
        if (s['selected'] != true) return false;
        final p = (s['portion'] as String? ?? 'whole').toLowerCase();
        return p == 'whole';
      });

      final hasCustom =
          pizzaSauceSelections.skip(1).any((s) => s['selected'] == true) ||
              (pizzaSauceSelections.isNotEmpty &&
                  (pizzaSauceSelections[0]['portion'] as String? ?? 'whole')
                          .toLowerCase() !=
                      'whole');

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
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: shared.UiConfig.bold,
                      fontFamily: shared.DesignTokens.fontFamily,
                    ),
                  ),
                ),
                if (hasCustom)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      minimumSize: const Size(0, 32),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Clear", style: TextStyle(fontSize: 14)),
                    onPressed: resetPizzaSauceSelections,
                  ),
              ],
            ),
            ...pizzaSauceSelections.asMap().entries.map((entry) {
              final i = entry.key;
              final sauce = entry.value;
              final sauceId = sauce['id']?.toString() ?? '';
              final sauceName = sauce['name']?.toString() ?? sauceId;
              final sauceSelected = sauce['selected'] == true;
              final portionStr =
                  (sauce['portion'] as String? ?? 'whole').toLowerCase();
              final saucePortion = portionStr == 'left'
                  ? Portion.left
                  : portionStr == 'right'
                      ? Portion.right
                      : Portion.whole;
              final sauceAmount =
                  (sauce['amount'] as String? ?? 'regular').toLowerCase();
              final meta = ingredientMetadata[sauceId];
              final outOfStock = meta?.outOfStock == true;

              Portion? otherPortion = _takenPortion(i);

              Map<Portion, bool> disables = {
                Portion.left: false,
                Portion.right: false,
                Portion.whole: false,
              };

              if (sauceSelected) {
                if (otherPortion != null) {
                  disables = {
                    Portion.left: otherPortion == Portion.left,
                    Portion.right: otherPortion == Portion.right,
                    Portion.whole: true,
                  };
                } else if (selectedCount == 2) {
                  disables = {
                    Portion.left: saucePortion != Portion.left,
                    Portion.right: saucePortion != Portion.right,
                    Portion.whole: true,
                  };
                } else if (selectedCount == 1 &&
                    saucePortion != Portion.whole) {
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

              bool canSelect =
                  sauceSelected || (selectedCount < 2 && !outOfStock);
              if (wholeSelectedIdx != -1 && wholeSelectedIdx != i) {
                canSelect = false;
                disables = {
                  Portion.left: true,
                  Portion.right: true,
                  Portion.whole: true,
                };
              } else if (selectedCount == 2 && !sauceSelected) {
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
                    final nextPortion = already == Portion.left
                        ? 'right'
                        : already == Portion.right
                            ? 'left'
                            : 'whole';
                    pizzaSauceSelections[i] = {
                      ...sauce,
                      'selected': true,
                      'portion': nextPortion,
                    };
                  } else {
                    pizzaSauceSelections[i] = {
                      ...sauce,
                      'selected': false,
                      'portion': 'whole',
                      'amount': 'regular',
                    };
                  }
                });
              }

              void handlePortionChange(Portion portion) {
                if (disables[portion] == true) return;
                setState(() {
                  pizzaSauceSelections[i] = {
                    ...sauce,
                    'portion': portion.toString().split('.').last,
                  };
                });
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                elevation: 0,
                color: sauceSelected
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: sauceSelected,
                          onChanged:
                              canSelect && !outOfStock ? handleCheckbox : null,
                        ),
                        Expanded(
                          child: Text(
                            sauceName,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: outOfStock
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                  : Theme.of(context).colorScheme.onSurface,
                              fontFamily: shared.DesignTokens.fontFamily,
                            ),
                          ),
                        ),
                        if (outOfStock)
                          Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: Icon(Icons.block,
                                color: Theme.of(context).colorScheme.error,
                                size: 18),
                          ),
                      ],
                    ),
                    if (sauceSelected)
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
                                value: saucePortion,
                                onChanged: handlePortionChange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 170),
                                    child: ToggleButtons(
                                      isSelected: [
                                        sauceAmount == 'light',
                                        sauceAmount == 'regular',
                                        sauceAmount == 'extra'
                                      ],
                                      onPressed: (idx) {
                                        setState(() {
                                          pizzaSauceSelections[i] = {
                                            ...sauce,
                                            'amount': [
                                              'light',
                                              'regular',
                                              'extra'
                                            ][idx],
                                          };
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      constraints: const BoxConstraints(
                                        minWidth: 38,
                                        minHeight: 32,
                                      ),
                                      children: const [
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
                    color: Theme.of(context).colorScheme.error,
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
            "$groupLabel ($freeSauces free, +${extraSauceUpcharge.toStringAsFixed(2)} each extra)",
            style: theme.textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: shared.UiConfig.bold,
              fontFamily: shared.DesignTokens.fontFamily,
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
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: !outOfStock && count > 0
                        ? () => setState(
                            () => selectedSauceCounts[ingId] = count - 1)
                        : null,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      meta?.name ?? ingId,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontFamily: shared.DesignTokens.fontFamily,
                      ),
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
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFamily: shared.DesignTokens.fontFamily,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: !outOfStock
                        ? () => setState(
                            () => selectedSauceCounts[ingId] = count + 1)
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
