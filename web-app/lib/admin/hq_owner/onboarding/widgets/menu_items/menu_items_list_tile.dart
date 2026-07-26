import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';

class MenuItemListTile extends StatelessWidget {
  final shared.MenuItem item;
  final bool isSelected;
  final bool hasSchemaErrors;
  final ValueChanged<bool?>? onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MenuItemListTile({
    super.key,
    required this.item,
    required this.isSelected,
    this.hasSchemaErrors = false,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color:
          hasSchemaErrors ? colorScheme.errorContainer.withOpacity(0.35) : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: isSelected,
          onChanged: onSelect,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (hasSchemaErrors)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.error_outline,
                  color: colorScheme.error,
                  size: 20,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description.isNotEmpty) Text(item.description),
            Text('${loc.price ?? "Price"}: \$${item.price.toStringAsFixed(2)}'),
            if (item.sizes != null && item.sizes!.isNotEmpty)
              Text('${loc.sizes ?? "Sizes"}: ${item.sizes!.join(', ')}'),
            if (item.highlightTags != null && item.highlightTags!.isNotEmpty)
              Wrap(
                spacing: 4,
                children: item.highlightTags!
                    .map((tag) => Chip(
                          label: Text(tag),
                          backgroundColor: colorScheme.secondaryContainer,
                        ))
                    .toList(),
              ),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: loc.edit ?? 'Edit',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: loc.delete ?? 'Delete',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(loc.confirmDeletion ?? 'Confirm Deletion'),
                    content: Text(loc.deleteMenuItemConfirm(item.name) ??
                        'Delete ${item.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(loc.cancel ?? 'Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(loc.delete ?? 'Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    Provider.of<shared.MenuItemProvider>(context, listen: false)
                        .deleteMenuItem(item.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                loc.menuItemDeleted ?? 'Menu item deleted')),
                      );
                    }
                  } catch (e, stack) {
                    shared.ErrorLogger.log(
                      message: 'menu_item_delete_failed',
                      source: 'MenuItemListTile',
                      severity: 'error',
                      stack: stack.toString(),
                      contextData: {'itemId': item.id},
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(loc.errorGeneric ?? 'An error occurred')),
                      );
                    }
                  }
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
