import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// A chip selector widget for choosing ingredient tags (e.g., allergens, dietary flags).
/// Used in onboarding or editing IngredientMetadata.
/// Fully compatible with highlight scrolling via `fieldGlobalKeys`.
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

  /// Centralized master tag list for allergens/dietary markers.
  /// Keep consistent with backend schema.
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
            return Tooltip(
              message: _localizedTagDescription(tag, loc),
              waitDuration: const Duration(milliseconds: 400),
              child: FilterChip(
                label: Text(
                  _formatTagLabel(tag),
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
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Formats a tag into a human-friendly label.
  String _formatTagLabel(String tag) {
    return tag.replaceAll('_', ' ').toUpperCase();
  }

  /// Provides a localized description for tooltips, fallback to formatted label.
  String _localizedTagDescription(String tag, AppLocalizations loc) {
    switch (tag) {
      case 'dairy':
        return loc.tagDairyDescription;
      case 'gluten':
        return loc.tagGlutenDescription;
      case 'nuts':
        return loc.tagNutsDescription;
      case 'soy':
        return loc.tagSoyDescription;
      case 'eggs':
        return loc.tagEggsDescription;
      case 'fish':
        return loc.tagFishDescription;
      case 'shellfish':
        return loc.tagShellfishDescription;
      case 'vegan':
        return loc.tagVeganDescription;
      case 'vegetarian':
        return loc.tagVegetarianDescription;
      case 'halal':
        return loc.tagHalalDescription;
      case 'kosher':
        return loc.tagKosherDescription;
      case 'sugar_free':
        return loc.tagSugarFreeDescription;
      case 'low_sodium':
        return loc.tagLowSodiumDescription;
      case 'spicy':
        return loc.tagSpicyDescription;
      case 'organic':
        return loc.tagOrganicDescription;
      default:
        return _formatTagLabel(tag);
    }
  }
}
