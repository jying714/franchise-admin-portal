import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

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
      padding: EdgeInsets.only(bottom: DesignTokens.gridSpacing * 1.5),
      child: Row(
        children: [
          ...dietaryTags.map(
            (tag) => Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              decoration: BoxDecoration(
                color: DesignTokens.successColor.withValues(alpha: 24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tag,
                style: TextStyle(
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
                color: DesignTokens.warningColor.withValues(alpha: 24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                allergen,
                style: TextStyle(
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
