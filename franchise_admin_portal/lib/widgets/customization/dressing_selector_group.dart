import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/ingredient_metadata.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DressingSelectorGroup extends StatelessWidget {
  final Map<String, dynamic> group;
  final ThemeData theme;
  final AppLocalizations loc;
  final Map<String, int> selectedDressingCounts;
  final void Function(String ingId, int newCount) onCountChanged;
  final int Function() getFreeDressingCount;
  final double Function() getExtraDressingUpcharge;
  final Map<String, IngredientMetadata> ingredientMetadata;

  const DressingSelectorGroup({
    Key? key,
    required this.group,
    required this.theme,
    required this.loc,
    required this.selectedDressingCounts,
    required this.onCountChanged,
    required this.getFreeDressingCount,
    required this.getExtraDressingUpcharge,
    required this.ingredientMetadata,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final groupLabel = group['label'] ?? 'Dressings';
    final ingredientIds = (group['ingredientIds'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final int freeDressings = getFreeDressingCount();
    final double extraDressingUpcharge = getExtraDressingUpcharge();

    for (final id in ingredientIds) {
      selectedDressingCounts[id] ??= 0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$groupLabel ($freeDressings free, +${extraDressingUpcharge.toStringAsFixed(2)} each extra)",
            style: theme.textTheme.titleMedium?.copyWith(
              color: DesignTokens.secondaryColor,
              fontWeight: FontWeight.bold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          ...ingredientIds.map((ingId) {
            final meta = ingredientMetadata[ingId];
            final count = selectedDressingCounts[ingId] ?? 0;
            final outOfStock = meta?.outOfStock == true;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, size: 20),
                    onPressed: !outOfStock && count > 0
                        ? () => onCountChanged(ingId, count - 1)
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
                        ? () => onCountChanged(ingId, count + 1)
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
