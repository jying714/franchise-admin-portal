import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/generated/app_localizations.dart';

class WingsPortionSelector extends StatelessWidget {
  final shared.MenuItem menuItem;
  final ThemeData theme;
  final AppLocalizations loc;
  final String? selectedSize;
  final Map<String, shared.IngredientMetadata> ingredientMetadata;
  final Map<String, String> selectedDippedSauces;
  final void Function(void Function()) setState;

  /// Parent owns the real map; must update it (not a build-time copy).
  final void Function(String splitKey, String sauceId) onPortionChanged;

  const WingsPortionSelector({
    super.key,
    required this.menuItem,
    required this.theme,
    required this.loc,
    required this.selectedSize,
    required this.ingredientMetadata,
    required this.selectedDippedSauces,
    required this.setState,
    required this.onPortionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final splitCount = menuItem.dippingSplits?[selectedSize] ?? 2;
    final sauceOptions = menuItem.dippingSauceOptions ?? [];

    if (splitCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Build Your Wings",
            style: theme.textTheme.titleMedium?.copyWith(
              color: shared.UiConfig.secondaryColor,
              fontWeight: shared.UiConfig.bold,
              fontFamily: shared.DesignTokens.fontFamily,
            ),
          ),
          Text(
            "Choose a sauce for each portion below. 'Plain' means no sauce—just crispy wings.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: shared.UiConfig.secondaryTextColor,
              fontStyle: FontStyle.italic,
              fontFamily: shared.DesignTokens.fontFamily,
            ),
          ),
          ...List.generate(splitCount, (i) {
            final key = 'split_$i';
            final value = selectedDippedSauces[key] ?? "plain";
            return Padding(
              padding: const EdgeInsets.only(top: 6.0, left: 8.0),
              child: DropdownButtonFormField<String>(
                value: value,
                decoration: InputDecoration(
                  labelText: "Portion ${i + 1}",
                ),
                items: [
                  const DropdownMenuItem(
                    value: "plain",
                    child: Text("Plain (no sauce)"),
                  ),
                  ...sauceOptions.map((sauceId) => DropdownMenuItem(
                        value: sauceId,
                        child:
                            Text(ingredientMetadata[sauceId]?.name ?? sauceId),
                      )),
                ],
                onChanged: (val) {
                  onPortionChanged(key, val ?? "plain");
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
