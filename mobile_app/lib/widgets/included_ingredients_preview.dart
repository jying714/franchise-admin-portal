import 'package:flutter/material.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Displays a list of included ingredients for a menu item as labeled chips.
/// If the list is empty or null, shows nothing.
/// This widget is fully localizable.
class IncludedIngredientsPreview extends StatelessWidget {
  /// The included ingredients as a list of maps (matching Firestore structure).
  final List<dynamic>? includedIngredients;

  /// Optionally override the label (otherwise uses localization).
  final String? label;

  const IncludedIngredientsPreview({
    super.key,
    required this.includedIngredients,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (includedIngredients == null || includedIngredients!.isEmpty) {
      return const SizedBox.shrink();
    }
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.gridSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label ?? loc.includedIngredientsLabel,
            style: TextStyle(
              fontSize: DesignTokens.captionFontSize,
              fontWeight: FontWeight.bold,
              color: DesignTokens.secondaryTextColor,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: includedIngredients!
                .map((i) => Chip(
                      label: Text(
                        (i is Map && i['name'] != null)
                            ? i['name'].toString()
                            : '',
                        style: const TextStyle(fontSize: 13),
                      ),
                      backgroundColor: DesignTokens.surfaceColor,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}


