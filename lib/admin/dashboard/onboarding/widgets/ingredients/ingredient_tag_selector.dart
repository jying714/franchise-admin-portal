import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// A chip selector widget for choosing ingredient tags (e.g., allergens).
/// Used in onboarding or editing IngredientMetadata.
class IngredientTagSelector extends StatelessWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onChanged;
  final AppLocalizations loc;

  const IngredientTagSelector({
    Key? key,
    required this.selectedTags,
    required this.onChanged,
    required this.loc,
  }) : super(key: key);

  static const List<String> _allTags = [
    'dairy',
    'gluten',
    'nuts',
    'soy',
    'eggs',
    'fish',
    'shellfish',
    'vegan',
    'vegetarian',
    'halal',
    'kosher',
    'sugar_free',
    'low_sodium',
    'spicy',
    'organic',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.allergenTags,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allTags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return FilterChip(
              label: Text(
                tag.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                final updatedTags = List<String>.from(selectedTags);
                if (selected) {
                  if (!updatedTags.contains(tag)) {
                    updatedTags.add(tag);
                  }
                } else {
                  updatedTags.remove(tag);
                }
                onChanged(updatedTags);
              },
              selectedColor: DesignTokens.primaryColor,
              backgroundColor: colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
