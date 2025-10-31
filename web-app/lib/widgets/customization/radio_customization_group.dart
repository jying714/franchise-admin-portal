import 'package:flutter/material.dart';
import 'package:shared_core/src/core/models/ingredient_metadata.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/src/core/utils/formatting.dart';

class RadioCustomizationGroup extends StatelessWidget {
  final Map<String, dynamic> group;
  final ThemeData theme;
  final AppLocalizations loc;
  final Map<String, IngredientMetadata> ingredientMetadata;
  final Map<String, String?> radioSelections;
  final double Function(IngredientMetadata? meta) getIngredientUpcharge;
  final void Function(String groupLabel, String? ingId) handleRadioSelect;

  const RadioCustomizationGroup({
    Key? key,
    required this.group,
    required this.theme,
    required this.loc,
    required this.ingredientMetadata,
    required this.radioSelections,
    required this.getIngredientUpcharge,
    required this.handleRadioSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String groupLabel = group['label'] ?? '';
    final List<String> ingredientIds =
        (group['ingredientIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
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
          ...ingredientIds.map((ingId) {
            final meta = ingredientMetadata[ingId];
            final double upcharge = getIngredientUpcharge(meta);

            return RadioListTile<String>(
              dense: true,
              value: ingId,
              groupValue: radioSelections[groupLabel],
              onChanged: (v) => handleRadioSelect(groupLabel, v),
              title: Text(
                meta?.name ?? ingId,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: DesignTokens.textColor,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              secondary: upcharge > 0
                  ? Text(
                      '+${currencyFormat(context, upcharge)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DesignTokens.secondaryColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    )
                  : null,
            );
          }).toList(),
        ],
      ),
    );
  }
}


