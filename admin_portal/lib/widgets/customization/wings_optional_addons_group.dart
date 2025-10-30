import 'package:flutter/material.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:admin_portal/core/models/menu_item.dart';
import 'package:admin_portal/core/models/ingredient_metadata.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WingsOptionalAddOnsGroup extends StatelessWidget {
  final MenuItem menuItem;
  final ThemeData theme;
  final AppLocalizations loc;
  final Map<String, IngredientMetadata> ingredientMetadata;
  final Set<String> selectedAddOns;
  final Map<String, bool> doubleAddOns;
  final void Function(void Function()) setState;

  /// Callback: (ingId, checked)
  final void Function(String ingId, bool checked) onChanged;

  const WingsOptionalAddOnsGroup({
    Key? key,
    required this.menuItem,
    required this.theme,
    required this.loc,
    required this.ingredientMetadata,
    required this.selectedAddOns,
    required this.doubleAddOns,
    required this.setState,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filter non-sauce add-ons only
    final nonSauceAddOns = (menuItem.optionalAddOns ?? []).where((addOn) {
      final meta = ingredientMetadata[addOn['ingredientId'] ?? addOn['id']];
      final isSauce = (meta?.type?.toLowerCase() == "sauces") ||
          (addOn['type']?.toString()?.toLowerCase() == "sauces");
      return !isSauce;
    }).toList();

    if (nonSauceAddOns.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Other Add-Ons",
            style: theme.textTheme.titleMedium?.copyWith(
              color: DesignTokens.secondaryColor,
              fontWeight: FontWeight.bold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          ...nonSauceAddOns.map((addOn) {
            final ingId = addOn['ingredientId'] ?? addOn['id'];
            final meta = ingredientMetadata[ingId];
            final checked = selectedAddOns.contains(ingId);
            final upcharge = (meta != null &&
                    meta.upcharge != null &&
                    meta.upcharge!.isNotEmpty)
                ? meta.upcharge!.values.first
                : (addOn['price'] as num?)?.toDouble() ?? 0.0;

            return Row(
              children: [
                Checkbox(
                  value: checked,
                  onChanged: meta?.outOfStock == true
                      ? null
                      : (val) {
                          setState(() {
                            onChanged(ingId, val ?? false);
                          });
                        },
                ),
                Expanded(
                  child: Text(
                    meta?.name ?? addOn['name'] ?? ingId,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: DesignTokens.textColor,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (checked && upcharge > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      '+${upcharge.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DesignTokens.secondaryColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
