import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../package:shared_core/src/core/models/menu_item.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../package:shared_core/src/core/providers/menu_item_provider.dart';
import '../package:shared_core/src/core/services/firestore_service.dart';
import '../package:shared_core/src/core/utils/error_logger.dart';

class MenuItemListTile extends StatelessWidget {
  final MenuItem item;
  final bool isSelected;
  final ValueChanged<bool?>? onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MenuItemListTile({
    super.key,
    required this.item,
    required this.isSelected,
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: isSelected,
          onChanged: onSelect,
        ),
        title: Text(
          item.name,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description.isNotEmpty) Text(item.description),
            Text('${loc.price}: \$${item.price.toStringAsFixed(2)}'),
            if (item.sizes != null && item.sizePrices != null)
              Text('${loc.sizes}: ${item.sizes!.join(', ')}'),
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
                    content: Text(loc.deleteMenuItemConfirm(item.name)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(loc.cancel),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(loc.delete),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await context
                        .read<MenuItemProvider>()
                        .deleteFromFirestore(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.menuItemDeleted)),
                    );
                  } catch (e, stack) {
                    await ErrorLogger.log(
                      message: 'menu_item_delete_failed',
                      source: 'MenuItemListTile',
                      screen: 'menu_item_list_tile.dart',
                      severity: 'error',
                      stack: stack.toString(),
                      contextData: {'itemId': item.id},
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.errorGeneric)),
                    );
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


