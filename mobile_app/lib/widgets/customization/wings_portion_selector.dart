import 'package:flutter/material.dart';
import 'package:franchise_mobile_app/core/models/menu_item.dart';
import 'package:franchise_mobile_app/core/models/ingredient_metadata.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WingsPortionSelector extends StatelessWidget {
  final MenuItem menuItem;
  final ThemeData theme;
  final AppLocalizations loc;
  final String? selectedSize;
  final Map<String, dynamic> ingredientMetadata;
  final Map<String, String> selectedDippedSauces;
  final void Function(void Function()) setState;

  const WingsPortionSelector({
    Key? key,
    required this.menuItem,
    required this.theme,
    required this.loc,
    required this.selectedSize,
    required this.ingredientMetadata,
    required this.selectedDippedSauces,
    required this.setState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final splitCount = menuItem.dippingSplits?[selectedSize] ?? 2;
    final sauceOptions = menuItem.dippingSauceOptions ?? [];

    if (splitCount == 0) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Build Your Wings",
            style: theme.textTheme.titleMedium?.copyWith(
              color: DesignTokens.secondaryColor,
              fontWeight: FontWeight.bold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          Text(
            "Choose a sauce for each portion below. 'Plain' means no sauceâ€”just crispy wings.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: DesignTokens.secondaryTextColor,
              fontStyle: FontStyle.italic,
              fontFamily: DesignTokens.fontFamily,
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
                  setState(() {
                    selectedDippedSauces[key] = val ?? "plain";
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}


