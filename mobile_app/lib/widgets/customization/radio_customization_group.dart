import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RadioCustomizationGroup extends StatelessWidget {
  final Map<String, dynamic> group;
  final ThemeData theme;
  final AppLocalizations loc;
  final Map<String, shared.IngredientMetadata> ingredientMetadata;
  final Map<String, String?> radioSelections;
  final double Function(shared.IngredientMetadata? meta) getIngredientUpcharge;
  final void Function(String groupLabel, String? ingId) handleRadioSelect;

  const RadioCustomizationGroup({
    super.key,
    required this.group,
    required this.theme,
    required this.loc,
    required this.ingredientMetadata,
    required this.radioSelections,
    required this.getIngredientUpcharge,
    required this.handleRadioSelect,
  });

  @override
  Widget build(BuildContext context) {
    // FranchiseProvider injected (P1 Batch 1) for franchise/{franchiseId}/ scoping centrality
    Provider.of<shared.FranchiseProvider>(context, listen: false);
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
              color: shared.UiConfig.secondaryColor,
              fontWeight: shared.UiConfig.bold,
              fontFamily: shared.DesignTokens.fontFamily,
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
                  color: shared.UiConfig.textColor,
                  fontFamily: shared.DesignTokens.fontFamily,
                ),
              ),
              secondary: upcharge > 0
                  ? Text(
                      '+${shared.UiConfig.currencyFormat(upcharge)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: shared.UiConfig.secondaryColor,
                        fontWeight: shared.UiConfig.bold,
                        fontFamily: shared.DesignTokens.fontFamily,
                      ),
                    )
                  : null,
            );
          }),
        ],
      ),
    );
  }
}
