import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

/// BulkOpsBar: Modular bulk action bar for Payouts/Invoices/Admin Tables.
/// Uses: Localization, Theme, Config tokens, ErrorLogger, Modular design, Developer access.
class BulkOpsBar extends StatelessWidget {
  final int selectedCount;
  final bool developerMode;
  final bool loading;
  final VoidCallback? onExport;
  final VoidCallback? onMarkSent;
  final VoidCallback? onMarkFailed;
  final VoidCallback? onDelete;
  final VoidCallback? onAddAttachment;
  final VoidCallback? onAddNote;
  final VoidCallback? onApprove;
  final VoidCallback? onCustomAction; // For future/feature toggles
  final VoidCallback? onResetPending;

  const BulkOpsBar({
    Key? key,
    required this.selectedCount,
    this.developerMode = false,
    this.loading = false,
    this.onExport,
    this.onMarkSent,
    this.onMarkFailed,
    this.onDelete,
    this.onAddAttachment,
    this.onAddNote,
    this.onApprove,
    this.onCustomAction,
    this.onResetPending,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (selectedCount == 0) {
      // Placeholder for empty state (future: maybe show tips)
      return const SizedBox.shrink();
    }

    return Card(
      color: colorScheme.surfaceVariant,
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
        child: Row(
          children: [
            Icon(Icons.playlist_add_check_circle, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              loc.selectedItemsCount(selectedCount),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),

            // EXPORT
            Tooltip(
              message: loc.exportSelected,
              child: IconButton(
                icon: const Icon(Icons.file_download),
                onPressed: onExport,
              ),
            ),
            // MARK SENT
            Tooltip(
              message: loc.markAsSent,
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: onMarkSent,
              ),
            ),
            // MARK FAILED
            Tooltip(
              message: loc.markAsFailed,
              child: IconButton(
                icon: const Icon(Icons.error),
                onPressed: onMarkFailed,
              ),
            ),
            Tooltip(
              message: loc.resetToPending ?? "Reset status to pending",
              child: IconButton(
                icon: const Icon(Icons.restart_alt, color: Colors.orange),
                onPressed: loading ? null : onResetPending,
              ),
            ),
            // ADD ATTACHMENT
            Tooltip(
              message: loc.addAttachment,
              child: IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: onAddAttachment,
              ),
            ),
            // ADD NOTE
            Tooltip(
              message: loc.addNote,
              child: IconButton(
                icon: const Icon(Icons.sticky_note_2),
                onPressed: onAddNote,
              ),
            ),
            // APPROVE (toggle, only for developer/admin, guarded)
            if (developerMode)
              Tooltip(
                message: loc.approveSelected,
                child: IconButton(
                  icon: const Icon(Icons.verified_user),
                  onPressed: onApprove,
                ),
              ),
            // DELETE
            Tooltip(
              message: loc.deleteSelected,
              child: IconButton(
                icon: const Icon(Icons.delete_forever),
                color: colorScheme.error,
                onPressed: onDelete,
              ),
            ),
            // FUTURE FEATURE (placeholder for toggles)
            if (onCustomAction != null)
              Tooltip(
                message: loc.featureComingSoon('Custom Action'),
                child: IconButton(
                  icon: const Icon(Icons.construction),
                  onPressed: () {
                    try {
                      onCustomAction?.call();
                    } catch (e, stack) {
                      ErrorLogger.log(
                        message: 'BulkOpsBar: CustomAction failed: $e',
                        stack: stack.toString(),
                        source: 'BulkOpsBar',
                        screen: 'bulk_ops_bar.dart',
                        severity: 'error',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(loc.featureComingSoon('Custom Action'))),
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
