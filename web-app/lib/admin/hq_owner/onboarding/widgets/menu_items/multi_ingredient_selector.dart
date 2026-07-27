import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class MultiIngredientSelector extends StatelessWidget {
  final String title;
  final List<shared.IngredientReference> selected;
  final ValueChanged<List<shared.IngredientReference>> onChanged;
  final bool allowEmpty;
  final bool isRequired;
  final String? warningMessage;

  const MultiIngredientSelector({
    super.key,
    required this.title,
    required this.selected,
    required this.onChanged,
    this.allowEmpty = true,
    this.isRequired = false,
    this.warningMessage,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final ingredientProvider =
        context.watch<shared.IngredientMetadataProvider>();
    final typeProvider = context.watch<shared.IngredientTypeProvider>();
    final metadataList = ingredientProvider.allIngredients;
    final types = typeProvider.ingredientTypes;

    if (!ingredientProvider.isInitialized) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Decision 10: Cook/Cut/Crust are modifier options, not catalog ingredients.
    final foodOnly = metadataList.where((ingredient) {
      final typeName = ingredient.type;
      return !shared.StructuralIngredientTypes.isStructuralType(
        typeId: ingredient.typeId,
        typeName: typeName,
        types: types,
      );
    }).toList();

    if (foodOnly.isEmpty) {
      return _EmptyIngredientsWarning(message: warningMessage);
    }

    final Map<String, List<shared.IngredientMetadata>> groupedByType = {};
    for (final ingredient in foodOnly) {
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
        Text(
          title,
          style: shared.UiConfig.titleStyle,
        ),
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
              loc.fieldRequired ?? 'This field is required',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}

class _IngredientTypeGroup extends StatelessWidget {
  final String typeName;
  final List<shared.IngredientMetadata> ingredients;
  final List<shared.IngredientReference> selected;
  final ValueChanged<List<shared.IngredientReference>> onChanged;

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
              final ref = shared.IngredientReference(
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
            message ??
                loc.noIngredientsConfigured ??
                'No ingredients configured yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
