import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/admin/features/alerts/alerts_repository.dart';

class AlertDetailDialog extends StatelessWidget {
  final shared.AlertModel alert;
  final String franchiseId;
  final bool canDismiss;
  final AlertsRepository? repository;
  final VoidCallback? onDismissed;
  final VoidCallback? onAcknowledge;

  const AlertDetailDialog({
    super.key,
    required this.alert,
    required this.franchiseId,
    this.canDismiss = true,
    this.repository,
    this.onDismissed,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final fireService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final user =
        Provider.of<shared.AdminUserProvider>(context, listen: false).user;

    final repo = repository ??
        AlertsRepository(
          firestoreService: fireService,
        );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _iconForLevel(alert.level, colorScheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alert.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              if (alert.body.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  alert.body,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 18),
              _DetailLine(
                icon: Icons.access_time,
                label: loc.alert_time,
                value: _formatDateTime(context, alert.createdAt),
              ),
              if (alert.dismissedAt != null)
                _DetailLine(
                  icon: Icons.check_circle_outline,
                  label: loc.alert_dismissed_on,
                  value: _formatDateTime(context, alert.dismissedAt!),
                ),
              _DetailLine(
                icon: Icons.info_outline_rounded,
                label: loc.alert_type,
                value:
                    alert.type.isNotEmpty ? alert.type : loc.alert_type_generic,
              ),
              if (alert.customFields.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    loc.alert_custom_fields,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ...alert.customFields.entries.map(
                (e) => _DetailLine(
                  icon: Icons.label_important_outline,
                  label: e.key,
                  value: e.value?.toString() ?? '',
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canDismiss && alert.dismissedAt == null)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                      onPressed: () async {
                        try {
                          await repo.dismissAlert(
                            franchiseId,
                            alert.id,
                            user?.id ?? '',
                          );
                          onDismissed?.call();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(loc.alert_dismissed_success)),
                            );
                          }
                        } catch (e, stack) {
                          shared.ErrorLogger.log(
                            message: 'Failed to dismiss alert: $e',
                            stack: stack.toString(),
                            source: 'AlertDetailDialog',
                            severity: 'error',
                            contextData: {
                              'franchiseId': franchiseId,
                              'alertId': alert.id,
                              'userId': user?.id,
                            },
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(loc.alert_dismissed_error)),
                            );
                          }
                        }
                      },
                      label: Text(loc.alert_dismiss_button),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(loc.close),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _iconForLevel(String level, ColorScheme colorScheme) {
    switch (level.toLowerCase()) {
      case 'warning':
        return Icon(Icons.warning_amber_rounded,
            color: colorScheme.error, size: 32);
      case 'error':
        return Icon(Icons.error_rounded, color: colorScheme.error, size: 32);
      case 'info':
      default:
        return Icon(Icons.info_outline_rounded,
            color: colorScheme.primary, size: 32);
    }
  }

  static String _formatDateTime(BuildContext context, DateTime dateTime) {
    return "${dateTime.year}-${_two(dateTime.month)}-${_two(dateTime.day)} "
        "${_two(dateTime.hour)}:${_two(dateTime.minute)}";
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailLine({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 9),
          Text(
            "$label: ",
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
