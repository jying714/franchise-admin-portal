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
    final rawSizes = menuItem.sizes ?? [];

    print(
        '🔍 [SizeDropdown] build - rawSizes count: ${rawSizes.length} | selectedSize: $selectedSize');

    final List<String> sizeNames = rawSizes.map((dynamic size) {
      if (size is shared.SizeData) {
        return size.label;
      } else if (size is String) {
        return size;
      } else {
        return size
            .toString()
            .replaceAll(RegExp(r'Instance of .*?\(|\)'), '')
            .trim();
      }
    }).toList();

    print('🔍 [SizeDropdown] Extracted size names: $sizeNames');

    String? safeSelected = selectedSize?.toString();
    if (safeSelected == null || !sizeNames.contains(safeSelected)) {
      safeSelected = sizeNames.isNotEmpty ? sizeNames.first : null;
      print('🔄 [SizeDropdown] Auto-selected first valid size: $safeSelected');
    }

    if (sizeNames.isEmpty) {
      print('⚠️ [SizeDropdown] No sizes available');
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
                  fontWeight: UiConfig.fontWeightBold,
                  fontFamily: shared.DesignTokens.fontFamily,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<String>(
                  value: safeSelected,
                  isExpanded: true,
                  items: sizeNames.map((sizeStr) {
                    print(
                        '   📌 [SizeDropdown] Creating DropdownMenuItem: $sizeStr');
                    return DropdownMenuItem<String>(
                      value: sizeStr,
                      child: Text(sizeStr),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    print('🔄 [SizeDropdown] onChanged selected: $newValue');
                    if (newValue != null) {
                      onChanged(newValue);
                    }
                  },
                ),
              ),
              if (safeSelected != null &&
                  menuItem.sizePrices != null &&
                  normalizeSizeKey(safeSelected).isNotEmpty)
                Builder(
                  builder: (context) {
                    final key = normalizeSizeKey(safeSelected!);
                    final priceObj = menuItem.sizePrices![key];
                    if (priceObj == null) return const SizedBox.shrink();

                    final price = (priceObj as num).toDouble();
                    return Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Text(
                        UiConfig.currencyFormat(context, price),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: UiConfig.primaryColor,
                          fontWeight: UiConfig.fontWeightBold,
                          fontFamily: shared.DesignTokens.fontFamily,
                        ),
                      ),
                    );
                  },
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
