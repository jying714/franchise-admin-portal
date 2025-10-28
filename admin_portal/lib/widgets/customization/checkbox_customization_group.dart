import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/ingredient_metadata.dart';
import 'package:franchise_admin_portal/core/utils/formatting.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CheckboxCustomizationGroup extends StatelessWidget {
  final Map<String, dynamic> group;
  final ThemeData theme;
  final AppLocalizations loc;
  final String category;
  final List<dynamic>? includedIngredients;
  final Map<String, IngredientMetadata> ingredientMetadata;
  final Set<String> currentIngredients;
  final bool usesDynamicToppingPricing;
  final bool Function(String groupLabel) showPortionToggle;
  final double Function() getToppingUpcharge;
  final double Function(IngredientMetadata? meta) getIngredientUpcharge;
  final void Function(String ingId, String groupLabel) toggleIngredient;
  final Widget Function(String ingId) buildPortionPillToggle;

  const CheckboxCustomizationGroup({
    Key? key,
    required this.group,
    required this.theme,
    required this.loc,
    required this.category,
    required this.includedIngredients,
    required this.ingredientMetadata,
    required this.currentIngredients,
    required this.usesDynamicToppingPricing,
    required this.showPortionToggle,
    required this.getToppingUpcharge,
    required this.getIngredientUpcharge,
    required this.toggleIngredient,
    required this.buildPortionPillToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String groupLabel = group['label'] ?? '';
    final List<String> ingredientIds =
        (group['ingredientIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();

    final bool isSalad = category.toLowerCase().contains('salad');

    final List<String> unselectedIds = ingredientIds
        .where((ingId) => !currentIngredients.contains(ingId))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            groupLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: DesignTokens.secondaryColor,
              fontWeight: FontWeight.bold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          ...unselectedIds.map((ingId) {
            final meta = ingredientMetadata[ingId];
            final bool checked = currentIngredients.contains(ingId);
            final double upcharge = usesDynamicToppingPricing
                ? getToppingUpcharge()
                : getIngredientUpcharge(meta);

            final bool wasIncluded = (includedIngredients?.any(
                  (e) => (e['ingredientId'] ?? e['id']) == ingId,
                ) ??
                false);

            final bool showUpcharge = isSalad ? !wasIncluded : (upcharge > 0);

            return Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    dense: true,
                    value: checked,
                    onChanged: meta?.outOfStock == true
                        ? null
                        : (v) => toggleIngredient(ingId, groupLabel),
                    title: Text(
                      meta?.name ?? ingId,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: DesignTokens.textColor,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondary: showUpcharge
                        ? Text(
                            '+${currencyFormat(context, upcharge)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: DesignTokens.secondaryColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: DesignTokens.fontFamily,
                            ),
                          )
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                if (showPortionToggle(groupLabel))
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: checked
                        ? buildPortionPillToggle(ingId)
                        : SizedBox.shrink(),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
