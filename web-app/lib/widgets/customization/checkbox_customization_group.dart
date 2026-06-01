import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';

typedef CategoryTapCallback = void Function(
    shared.Category category); // if needed elsewhere

typedef ConfirmCallback = void Function(
  Map<String, dynamic> customizations,
  int quantity,
  double totalPrice,
);

class CheckboxCustomizationGroup extends StatelessWidget {
  final Map<String, dynamic> group;
  final ThemeData theme;
  final AppLocalizations loc;
  final String category;
  final List<dynamic>? includedIngredients;
  final Map<String, shared.IngredientMetadata> ingredientMetadata;
  final Set<String> currentIngredients;
  final bool usesDynamicToppingPricing;
  final bool Function(String groupLabel) showPortionToggle;
  final double Function() getToppingUpcharge;
  final double Function(shared.IngredientMetadata? meta) getIngredientUpcharge;
  final void Function(String ingId, String groupLabel) toggleIngredient;
  final Widget Function(String ingId) buildPortionPillToggle;

  const CheckboxCustomizationGroup({
    super.key,
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
  });

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
              color: Colors.blue,
              fontWeight: FontWeight.bold,
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
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondary: showUpcharge
                        ? Text(
                            '+${upcharge.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
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
                        : const SizedBox.shrink(),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
