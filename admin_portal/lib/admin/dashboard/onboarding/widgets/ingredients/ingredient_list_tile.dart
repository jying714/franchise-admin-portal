import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:admin_portal/config/branding_config.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:admin_portal/core/models/ingredient_metadata.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:admin_portal/widgets/network_image_widget.dart';
import 'ingredient_form_card.dart';

class IngredientListTile extends StatelessWidget {
  final IngredientMetadata ingredient;
  final String franchiseId;
  final VoidCallback onRefresh;
  final VoidCallback? onEdited;

  // New parameters for bulk select
  final bool isSelectable;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;

  const IngredientListTile({
    super.key,
    required this.ingredient,
    required this.franchiseId,
    required this.onRefresh,
    this.onEdited,
    this.isSelectable = false,
    this.isSelected = false,
    this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final theme = Theme.of(context);
      final t = AppLocalizations.of(context)!;
      final colorScheme = theme.colorScheme;
      final firestore = context.read<FirestoreService>();

      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isSelectable)
                Checkbox(
                  value: isSelected,
                  onChanged: onSelectChanged,
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: ingredient.imageUrl != null
                      ? NetworkImageWidget(
                          imageUrl: ingredient.imageUrl ?? '',
                          fallbackAsset: BrandingConfig.defaultPizzaIcon,
                          width: 64,
                          height: 64,
                        )
                      : const Icon(Icons.fastfood,
                          size: 28, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (ingredient.outOfStock)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Out of Stock',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.red[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (ingredient.allergens.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              ingredient.allergens.join(', '),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    )
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: t.edit,
                onPressed: () {
                  final loc = AppLocalizations.of(context);
                  if (loc == null) {
                    debugPrint(
                        '[IngredientListTile] ERROR: loc is null when opening IngredientFormCard');
                    return;
                  }

                  showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return Localizations.override(
                        context: dialogContext,
                        child: Builder(
                          builder: (innerContext) {
                            return IngredientFormCard(
                              loc: loc,
                              initialData: ingredient,
                              onSaved: () {
                                onRefresh();
                                if (onEdited != null) onEdited!();
                              },
                              parentContext: context,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: t.delete,
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(t.deleteIngredient),
                      content: Text(t.confirmDeleteIngredient),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(t.cancel),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.dangerColor,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(t.delete),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await firestore.deleteIngredient(
                        franchiseId: franchiseId,
                        ingredientId: ingredient.id,
                      );
                      onRefresh();
                    } catch (e, stack) {
                      ErrorLogger.log(
                        message: 'Failed to delete ingredient: $e',
                        stack: stack.toString(),
                        screen: 'IngredientListTile',
                        source: 'deleteIngredientMetadata',
                        contextData: {
                          'ingredientId': ingredient.id,
                          'franchiseId': franchiseId,
                        },
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.errorDeletingIngredient)),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      print('[IngredientListTile] FATAL build error: $e\n$stack');
      return Center(
          child: Text('Build error in IngredientListTile: $e\n$stack'));
    }
  }
}
