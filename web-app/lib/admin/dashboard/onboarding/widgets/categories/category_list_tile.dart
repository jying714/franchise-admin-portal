// lib/admin/dashboard/onboarding/widgets/categories/category_list_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import '../../../../../../../packages/shared_core/lib/src/core/models/category.dart';
import '../../../../../../../packages/shared_core/lib/src/core/providers/category_provider.dart';
import '../../../../../../../packages/shared_core/lib/src/core/providers/franchise_provider.dart';
import '../../../../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class CategoryListTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isSelected;
  final ValueChanged<bool?> onSelect;

  const CategoryListTile({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: ReorderableDragStartListener(
          index: category.sortOrder ?? 0,
          child: const Icon(Icons.drag_handle),
        ),
        title: Text(
          category.name,
          style: theme.textTheme.titleMedium,
        ),
        subtitle:
            category.description != null && category.description!.isNotEmpty
                ? Text(
                    category.description!,
                    style: theme.textTheme.bodySmall,
                  )
                : null,
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: onSelect,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: loc.edit,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: loc.delete,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(loc.confirmDeletion),
                    content:
                        Text('${loc.confirmDeleteCategory} ${category.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(loc.cancel),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text(loc.delete),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final provider = context.read<CategoryProvider>();
                  final franchiseId =
                      context.read<FranchiseProvider>().franchiseId;

                  try {
                    await context.read<FirestoreService>().deleteCategory(
                          franchiseId: franchiseId,
                          categoryId: category.id,
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.deleteSuccess)),
                    );
                  } catch (e, stack) {
                    await ErrorLogger.log(
                      message: 'Failed to delete category',
                      source: 'CategoryListTile',
                      screen: 'onboarding_categories_screen',
                      severity: 'error',
                      stack: stack.toString(),
                      contextData: {
                        'franchiseId': franchiseId,
                        'categoryId': category.id,
                      },
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.errorGeneric)),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
