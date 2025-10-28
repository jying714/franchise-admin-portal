import 'package:flutter/material.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';

/// Reusable row for displaying dietary tags and allergens as chips.
/// Hides itself if both lists are empty.
class DietaryAllergenChipsRow extends StatelessWidget {
  final List<String> dietaryTags;
  final List<String> allergens;

  const DietaryAllergenChipsRow({
    Key? key,
    required this.dietaryTags,
    required this.allergens,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dietaryTags.isEmpty && allergens.isEmpty)
      return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.gridSpacing * 1.5),
      child: Row(
        children: [
          ...dietaryTags.map(
            (tag) => Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              decoration: BoxDecoration(
                color: DesignTokens.successColor.withAlpha(24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 12,
                  color: DesignTokens.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ...allergens.map(
            (allergen) => Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              decoration: BoxDecoration(
                color: DesignTokens.warningColor.withAlpha(24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                allergen,
                style: const TextStyle(
                  fontSize: 12,
                  color: DesignTokens.warningColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
