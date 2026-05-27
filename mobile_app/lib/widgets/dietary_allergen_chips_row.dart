import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';

/// Reusable row for displaying dietary tags and allergens as chips.
/// Hides itself if both lists are empty.
class DietaryAllergenChipsRow extends StatelessWidget {
  final List<String> dietaryTags;
  final List<String> allergens;

  const DietaryAllergenChipsRow({
    super.key,
    required this.dietaryTags,
    required this.allergens,
  });

  @override
  Widget build(BuildContext context) {
    if (dietaryTags.isEmpty && allergens.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: shared.DesignTokens.gridSpacing * 1.5),
      child: Row(
        children: [
          ...dietaryTags.map(
            (tag) => Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              decoration: BoxDecoration(
                color: UiConfig.successColor.withAlpha(24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  color: UiConfig.successColor,
                  fontWeight: UiConfig.fontWeightBold,
                ),
              ),
            ),
          ),
          ...allergens.map(
            (allergen) => Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              decoration: BoxDecoration(
                color: UiConfig.warningColor.withAlpha(24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                allergen,
                style: TextStyle(
                  fontSize: 12,
                  color: UiConfig.warningColor,
                  fontWeight: UiConfig.fontWeightBold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
