import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class MultiIngredientSelector extends StatefulWidget {
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
  State<MultiIngredientSelector> createState() =>
      _MultiIngredientSelectorState();
}

class _MultiIngredientSelectorState extends State<MultiIngredientSelector> {
  /// Group key = display type name (same as before).
  String? _activeTypeName;

  @override
  Widget build(BuildContext context) {
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

    final foodOnly = metadataList.where((ingredient) {
      return !shared.StructuralIngredientTypes.isStructuralType(
        typeId: ingredient.typeId,
        typeName: ingredient.type,
        types: types,
      );
    }).toList();

    if (foodOnly.isEmpty) {
      return _EmptyIngredientsWarning(message: widget.warningMessage);
    }

    final Map<String, List<shared.IngredientMetadata>> groupedByType = {};
    for (final ingredient in foodOnly) {
      // Prefer foundation type name when typeId resolves.
      var label = (ingredient.type ?? '').trim();
      final tid = (ingredient.typeId ?? '').trim();
      if (tid.isNotEmpty) {
        for (final t in types) {
          if (t.id == tid && t.name.trim().isNotEmpty) {
            label = t.name.trim();
            break;
          }
        }
      }
      if (label.isEmpty) label = 'Other';
      groupedByType.putIfAbsent(label, () => []).add(ingredient);
    }

    final typeNames = groupedByType.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final active =
        (_activeTypeName != null && groupedByType.containsKey(_activeTypeName))
            ? _activeTypeName!
            : typeNames.first;

    if (_activeTypeName != active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _activeTypeName = active);
      });
    }

    final selectedInActive = widget.selected.where((s) {
      final ings = groupedByType[active] ?? const [];
      return ings.any((i) => i.id == s.id);
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: shared.UiConfig.titleStyle),
        const SizedBox(height: 8),
        if (widget.selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${widget.selected.length} selected'
              '${widget.selected.isNotEmpty ? ': ${widget.selected.map((e) => e.name).join(', ')}' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        DropdownButtonFormField<String>(
          value: active,
          decoration: const InputDecoration(
            labelText: 'Ingredient type',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: typeNames
              .map(
                (name) => DropdownMenuItem<String>(
                  value: name,
                  child: Text(name),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _activeTypeName = v);
          },
        ),
        const SizedBox(height: 8),
        Text(
          '$selectedInActive selected in $active',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 6),
        _IngredientTypeGroup(
          typeName: active,
          ingredients: groupedByType[active] ?? const [],
          selected: widget.selected,
          onChanged: widget.onChanged,
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
