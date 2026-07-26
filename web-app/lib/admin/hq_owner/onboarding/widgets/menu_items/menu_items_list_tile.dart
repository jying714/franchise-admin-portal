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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      color:
          hasSchemaErrors ? colorScheme.errorContainer.withOpacity(0.35) : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: const Icon(Icons.drag_handle),
        title: Text(
          item.name,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description.isNotEmpty)
              Text(
                item.description,
                style: theme.textTheme.bodySmall,
              ),
            Text(
              '${loc.price ?? "Price"}: \$${item.price.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall,
            ),
            if (item.sizes != null && item.sizes!.isNotEmpty)
              Text(
                '${loc.sizes ?? "Sizes"}: ${item.sizes!.join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
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
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (hasSchemaErrors)
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 20,
              ),
            Checkbox(
              value: isSelected,
              onChanged: onSelect,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: loc.edit ?? 'Edit',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: loc.delete ?? 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
