import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../../packages/shared_core/lib/src/core/models/ingredient_reference.dart';
import '../../../../../../../packages/shared_core/lib/src/core/models/ingredient_metadata.dart';
import '../../../../../../../packages/shared_core/lib/src/core/providers/ingredient_metadata_provider.dart';
import '../../../../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// A reusable multi-selector for choosing ingredients from metadata.
///
/// Usage:
/// ```dart
/// MultiIngredientSelector(
///   title: 'Included Ingredients',
///   selected: includedIngredients,
///   onChanged: (updated) => setState(() => includedIngredients = updated),
/// )
/// ```
class MultiIngredientSelector extends StatelessWidget {
  final String title;
  final List<IngredientReference> selected;
  final ValueChanged<List<IngredientReference>> onChanged;
  final bool allowEmpty;
  final bool isRequired;
  final String? warningMessage;

  const MultiIngredientSelector({
    Key? key,
    required this.title,
    required this.selected,
    required this.onChanged,
    this.allowEmpty = true,
    this.isRequired = false,
    this.warningMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final ingredientProvider = context.watch<IngredientMetadataProvider>();
    final metadataList = ingredientProvider.allIngredients;

    if (!ingredientProvider.isInitialized) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (metadataList.isEmpty) {
      return _EmptyIngredientsWarning(message: warningMessage);
    }

    final Map<String, List<IngredientMetadata>> groupedByType = {};
    for (final ingredient in metadataList) {
      groupedByType
          .putIfAbsent(
            ingredient.type ?? 'Other',
            () => [],
          )
          .add(ingredient);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: 8),
        ...groupedByType.entries.map((entry) {
          final typeName = entry.key;
          final ingredients = entry.value;

          return _IngredientTypeGroup(
            typeName: typeName,
            ingredients: ingredients,
            selected: selected,
            onChanged: onChanged,
          );
        }),
        if (isRequired && selected.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              loc.fieldRequired,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}

class _IngredientTypeGroup extends StatelessWidget {
  final String typeName;
  final List<IngredientMetadata> ingredients;
  final List<IngredientReference> selected;
  final ValueChanged<List<IngredientReference>> onChanged;

  const _IngredientTypeGroup({
    required this.typeName,
    required this.ingredients,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            typeName,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: ingredients.map((ingredient) {
              final ref = IngredientReference(
                id: ingredient.id,
                name: ingredient.name,
                typeId: ingredient.typeId ?? 'unknown',
              );

              final isSelected = selected.any((i) => i.id == ref.id);

              return FilterChip(
                label: Text(ingredient.name),
                selected: isSelected,
                onSelected: (val) {
                  final updated = [...selected];
                  if (val) {
                    updated.add(ref);
                  } else {
                    updated.removeWhere((i) => i.id == ref.id);
                  }
                  onChanged(updated);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _EmptyIngredientsWarning extends StatelessWidget {
  final String? message;

  const _EmptyIngredientsWarning({this.message});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: DesignTokens.errorColor),
          const SizedBox(height: 4),
          Text(
            message ?? loc.noIngredientsConfigured,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
