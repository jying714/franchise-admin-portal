/// Utility class to validate menu item customization groups
class MenuItemValidator {
  /// Returns a list of required customization groups that are missing from the current item.
  static List<String> getMissingRequiredGroups({
    required List<Map<String, dynamic>> customizations,
    required List requiredGroups,
  }) {
    final Set<String> present = customizations
        .map((g) {
          final label = g['label'];
          if (label is String) return label.toLowerCase().trim();
          if (label is Map && label.containsKey('en'))
            return label['en'].toLowerCase().trim();
          return null;
        })
        .whereType<String>()
        .toSet();

    return requiredGroups
        .map((r) => r.toString().toLowerCase().trim())
        .where((r) => !present.contains(r))
        .toList();
  }

  static List<String> getMissingRequiredFields({
    required List<Map<String, dynamic>> includedIngredients,
    required List<Map<String, dynamic>> optionalAddOns,
    required List fieldKeys,
  }) {
    final List<String> missing = [];

    if (fieldKeys.contains('includedIngredients') &&
        includedIngredients.isEmpty) {
      missing.add('includedIngredients');
    }

    if (fieldKeys.contains('optionalAddOns') && optionalAddOns.isEmpty) {
      missing.add('optionalAddOns');
    }

    return missing;
  }
}


