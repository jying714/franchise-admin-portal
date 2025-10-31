import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../../../../../../../packages/shared_core/lib/src/core/models/ingredient_metadata.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class IngredientMetadataJsonPreviewTable extends StatelessWidget {
  final String rawJson;
  final List<IngredientMetadata>? previewIngredients;
  final AppLocalizations loc;
  final ScrollController? scrollController;

  const IngredientMetadataJsonPreviewTable({
    super.key,
    required this.rawJson,
    required this.previewIngredients,
    required this.loc,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (rawJson.trim().isEmpty) {
      return Center(
        child: Text(
          loc.noDataToPreview,
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    if (previewIngredients == null) {
      return Center(
        child: Text(
          loc.invalidJsonFormat,
          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
        ),
      );
    }

    if (previewIngredients!.isEmpty) {
      return Center(
        child: Text(
          loc.noIngredientsFound,
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowColor: MaterialStateProperty.all(
            colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          columns: [
            DataColumn(
              label: Text(
                loc.ingredientName,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                loc.ingredientType,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                loc.allergens,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                loc.removable,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              numeric: false,
            ),
            DataColumn(
              label: Text(
                loc.outOfStock,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              numeric: false,
            ),
          ],
          rows: previewIngredients!.map((ingredient) {
            final allergensStr = ingredient.allergens.isNotEmpty
                ? ingredient.allergens.map((a) => a.toUpperCase()).join(', ')
                : loc.none;

            return DataRow(
              cells: [
                DataCell(Text(ingredient.name)),
                DataCell(Text(ingredient.type)),
                DataCell(Text(allergensStr)),
                DataCell(
                  Icon(
                    ingredient.removable ? Icons.check_circle : Icons.cancel,
                    color: ingredient.removable ? Colors.green : Colors.red,
                  ),
                ),
                DataCell(
                  Icon(
                    ingredient.outOfStock ? Icons.cancel : Icons.check_circle,
                    color: ingredient.outOfStock ? Colors.red : Colors.green,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
