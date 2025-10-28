import 'package:flutter/material.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';
import 'package:doughboys_pizzeria_final/core/models/menu_item.dart';
import 'package:doughboys_pizzeria_final/core/utils/formatting.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SizeDropdown extends StatelessWidget {
  final MenuItem menuItem;
  final String? selectedSize;
  final void Function(String?) onChanged;
  final Widget? toppingCostLabel;
  final String Function(String?) normalizeSizeKey;

  const SizeDropdown({
    Key? key,
    required this.menuItem,
    required this.selectedSize,
    required this.onChanged,
    this.toppingCostLabel,
    required this.normalizeSizeKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final sizes = menuItem.sizes!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                loc.sizeLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: DesignTokens.secondaryColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              SizedBox(width: 16),
              DropdownButton<String>(
                value: selectedSize,
                items: sizes
                    .map((size) => DropdownMenuItem<String>(
                          value: size,
                          child: Text(
                            size,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
              if (selectedSize != null &&
                  menuItem.sizePrices != null &&
                  menuItem.sizePrices![normalizeSizeKey(selectedSize)] != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(
                    currencyFormat(
                        context,
                        (menuItem.sizePrices![normalizeSizeKey(selectedSize)]
                                as num)
                            .toDouble()),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: DesignTokens.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ),
            ],
          ),
          if (toppingCostLabel != null)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, top: 2.0, bottom: 2.0),
              child: toppingCostLabel,
            ),
        ],
      ),
    );
  }
}
