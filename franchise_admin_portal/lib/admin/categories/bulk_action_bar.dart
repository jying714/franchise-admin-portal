import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class BulkActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onBulkDelete;
  final VoidCallback? onBulkExport;
  final VoidCallback? onBulkEdit; // (Optional)
  final VoidCallback? onClearSelection;

  const BulkActionBar({
    Key? key,
    required this.selectedCount,
    this.onBulkDelete,
    this.onBulkExport,
    this.onBulkEdit,
    this.onClearSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final colorScheme = Theme.of(context).colorScheme;

    if (selectedCount == 0) return const SizedBox.shrink();

    return Material(
      elevation: 6,
      color: colorScheme.secondary.withOpacity(0.09),
      borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.select_all, color: colorScheme.secondary, size: 24),
            const SizedBox(width: 12),
            Text(
              loc.selectedCount(selectedCount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(width: 28),
            ElevatedButton.icon(
              icon: Icon(Icons.delete_outline, color: colorScheme.onError),
              label: Text(loc.delete),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error.withOpacity(0.88),
                foregroundColor: colorScheme.onError,
                elevation: DesignTokens.adminButtonElevation,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.adminButtonRadius),
                ),
              ),
              onPressed: onBulkDelete,
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.file_download, color: colorScheme.onSecondary),
              label: Text(loc.export),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary.withOpacity(0.92),
                foregroundColor: colorScheme.onSecondary,
                elevation: DesignTokens.adminButtonElevation,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.adminButtonRadius),
                ),
              ),
              onPressed: onBulkExport,
            ),
            if (onBulkEdit != null) ...[
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: Icon(Icons.edit, color: colorScheme.onSecondary),
                label: Text(loc.edit),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary.withOpacity(0.7),
                  foregroundColor: colorScheme.onSecondary,
                  elevation: DesignTokens.adminButtonElevation,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.adminButtonRadius),
                  ),
                ),
                onPressed: onBulkEdit,
              ),
            ],
            const Spacer(),
            OutlinedButton.icon(
              icon: Icon(Icons.clear, color: colorScheme.outline),
              label: Text(loc.clearSelection),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outline, width: 1),
                foregroundColor: colorScheme.outline,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.adminButtonRadius),
                ),
              ),
              onPressed: onClearSelection,
            ),
          ],
        ),
      ),
    );
  }
}
