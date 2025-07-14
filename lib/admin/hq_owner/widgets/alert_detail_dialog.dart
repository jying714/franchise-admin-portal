import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/alert_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/admin/features/alerts/alerts_repository.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';

class AlertDetailDialog extends StatelessWidget {
  final AlertModel alert;
  final String franchiseId;
  final bool canDismiss;
  final AlertsRepository? repository;
  final VoidCallback? onDismissed;
  final VoidCallback? onAcknowledge; // For future: acknowledge flow

  const AlertDetailDialog({
    Key? key,
    required this.alert,
    required this.franchiseId,
    this.canDismiss = true,
    this.repository,
    this.onDismissed,
    this.onAcknowledge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final appConfig = AppConfig.instance;
    final fireService = FirestoreService();
    final user = Provider.of<AdminUserProvider>(context, listen: false).user;

    final repo = repository ??
        AlertsRepository(
          firestoreService: fireService,
          appConfig: appConfig,
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
                            screen: "AlertDetailDialog",
                          );
                          onDismissed?.call();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.alert_dismissed_success),
                            ),
                          );
                        } catch (e, stack) {
                          fireService.logError(
                            user?.defaultFranchise,
                            message: 'Failed to dismiss alert: $e',
                            source: 'alert_detail_dialog',
                            userId: user?.id,
                            screen: "AlertDetailDialog",
                            stackTrace: stack.toString(),
                            errorType: e.runtimeType.toString(),
                            severity: 'error',
                            contextData: {
                              'franchiseId': franchiseId,
                              'alertId': alert.id,
                            },
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.alert_dismissed_error),
                            ),
                          );
                        }
                      },
                      label: Text(loc.alert_dismiss_button),
                    ),
                  // 🔜 Future: Acknowledge, view related invoice, etc.
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
    switch (level) {
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
    final loc = AppLocalizations.of(context)!;
    final d = dateTime;
    return "${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}";
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}

/// Simple detail line row for alert properties.
class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailLine({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.5),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 9),
            Text(
              "$label: ",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}
