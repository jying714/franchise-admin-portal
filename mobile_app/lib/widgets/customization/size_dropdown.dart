import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SizeDropdown extends StatelessWidget {
  final shared.MenuItem menuItem;
  final String? selectedSize;
  final void Function(String?) onChanged;
  final Widget? toppingCostLabel;
  final String Function(String?) normalizeSizeKey;

  const SizeDropdown({
    super.key,
    required this.menuItem,
    required this.selectedSize,
    required this.onChanged,
    this.toppingCostLabel,
    required this.normalizeSizeKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final sizes = menuItem.sizes ?? [];

    print(
        '🔍 [SizeDropdown] build - selectedSize: "$selectedSize" | Available sizes: $sizes');

    // Safety: Ensure selectedSize is valid
    String? safeSelected = selectedSize;
    if (safeSelected == null || !sizes.contains(safeSelected)) {
      safeSelected = sizes.isNotEmpty ? sizes.first.toString() : null;
      print(
          '🔄 [SizeDropdown] Auto-corrected invalid selectedSize to: $safeSelected');
    }

    if (sizes.isEmpty) {
      print('⚠️ [SizeDropdown] No sizes available for this item');
      return const SizedBox.shrink();
    }

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
                  color: UiConfig.secondaryColor,
                  fontWeight: UiConfig.bold,
                  fontFamily: shared.DesignTokens.fontFamily,
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: safeSelected,
                items: sizes.map((size) {
                  final sizeStr = size.toString();
                  print('   📌 [SizeDropdown] Creating item: $sizeStr');
                  return DropdownMenuItem<String>(
                    value: sizeStr,
                    child: Text(
                      sizeStr,
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
              if (safeSelected != null &&
                  menuItem.sizePrices != null &&
                  menuItem.sizePrices![normalizeSizeKey(safeSelected)] != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(
                    UiConfig.currencyFormat(
                      context,
                      (menuItem.sizePrices![normalizeSizeKey(safeSelected)]
                              as num)
                          .toDouble(),
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: UiConfig.primaryColor,
                      fontWeight: UiConfig.bold,
                      fontFamily: shared.DesignTokens.fontFamily,
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
