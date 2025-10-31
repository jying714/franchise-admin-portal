import 'package:franchise_admin_portal/admin/hq_owner/widgets/alert_detail_dialog.dart';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/admin/features/alerts/alerts_repository.dart';
import 'package:shared_core/src/core/models/alert_model.dart';
import 'package:shared_core/src/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/src/core/providers/role_guard.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/src/core/providers/admin_user_provider.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

class AlertListScreen extends StatelessWidget {
  final String franchiseId;
  final String? locationId;
  final bool developerMode;

  const AlertListScreen({
    Key? key,
    required this.franchiseId,
    this.locationId,
    this.developerMode = false,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appConfig = AppConfig.instance;
    final fireService = FirestoreService();
    final user = Provider.of<AdminUserProvider>(context, listen: false).user;
    final isDeveloper = user?.isDeveloper ?? false;

    final repo = AlertsRepository(
      firestoreService: fireService,
      appConfig: appConfig,
    );

    return RoleGuard(
      allowedRoles: [
        'hq_owner',
        'hq_manager',
        'admin',
        'owner',
        'manager',
        'developer'
      ],
      developerBypass: true,
      featureName: 'Full Alert List',
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.dashboard_active_alerts),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: loc.dashboard_alerts_filter_tooltip,
              onPressed: () {
                // ðŸ”œ Future: Add filter or refresh logic here
              },
            ),
          ],
        ),
        body: SafeArea(
          child: StreamBuilder<List<AlertModel>>(
            stream: repo.watchActiveAlerts(
              franchiseId: franchiseId,
              locationId: locationId,
              developerMode: developerMode || isDeveloper,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                ErrorLogger.log(
                  message: 'Failed to load alert list: ${snapshot.error}',
                  source: 'alert_list_screen',
                  screen: 'AlertListScreen',
                  stack: snapshot.stackTrace?.toString(),
                  severity: 'error',
                  contextData: {
                    'franchiseId': franchiseId,
                    'locationId': locationId,
                    'userId': user?.id,
                    'errorType': snapshot.error.runtimeType.toString(),
                  },
                );
                return _AlertListError(
                    message: loc.dashboard_alerts_error,
                    color: colorScheme.error);
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _AlertListLoading(color: colorScheme.primary);
              }
              final alerts = snapshot.data ?? [];

              if (alerts.isEmpty) {
                return Center(
                  child: Text(
                    loc.dashboard_no_active_alerts,
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: alerts.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 16, thickness: 0.4),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return _AlertListTile(
                    alert: alert,
                    colorScheme: colorScheme,
                    loc: loc,
                    onDismiss: () async {
                      try {
                        await repo.dismissAlert(
                          franchiseId,
                          alert.id,
                          user?.id ?? '',
                          screen: 'AlertListScreen',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.alert_dismissed_success)),
                        );
                      } catch (e, stack) {
                        await ErrorLogger.log(
                          message: 'Failed to dismiss alert: $e',
                          source: 'alert_list_screen',
                          screen: 'AlertListScreen',
                          stack: stack.toString(),
                          severity: 'error',
                          contextData: {
                            'franchiseId': franchiseId,
                            'alertId': alert.id,
                            'userId': user?.id,
                            'errorType': e.runtimeType.toString(),
                          },
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.alert_dismissed_error)),
                        );
                      }
                    },
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDetailDialog(
                          alert: alert,
                          franchiseId: franchiseId,
                          canDismiss: true,
                          onDismissed: () {
                            // Optionally refresh or callback
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'alert_list_fab',
          onPressed: () {
            // ðŸ”œ Future: Add alert filter dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.dashboard_alerts_filter_tooltip)),
            );
          },
          label: Text(loc.dashboard_alerts_filter_tooltip),
          icon: const Icon(Icons.filter_list),
        ),
      ),
    );
  }
}

// Alert tile for list view.
class _AlertListTile extends StatelessWidget {
  final AlertModel alert;
  final ColorScheme colorScheme;
  final AppLocalizations loc;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const _AlertListTile({
    Key? key,
    required this.alert,
    required this.colorScheme,
    required this.loc,
    this.onDismiss,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData icon;
    switch (alert.level) {
      case 'warning':
        iconColor = colorScheme.error;
        icon = Icons.warning_amber_rounded;
        break;
      case 'error':
        iconColor = colorScheme.error;
        icon = Icons.error_rounded;
        break;
      case 'info':
      default:
        iconColor = colorScheme.primary;
        icon = Icons.info_outline_rounded;
    }

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor, size: 32),
        title: Text(alert.title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: alert.body.isNotEmpty
            ? Text(alert.body, style: Theme.of(context).textTheme.bodySmall)
            : null,
        trailing: onDismiss != null
            ? IconButton(
                icon: const Icon(Icons.close),
                color: colorScheme.error,
                tooltip: loc.alert_dismiss_button,
                onPressed: onDismiss,
              )
            : null,
        // ðŸ”œ Future: add onTap for detail dialog
      ),
    );
  }
}

// Loading state for alert list.
class _AlertListLoading extends StatelessWidget {
  final Color color;
  const _AlertListLoading({Key? key, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(
            color: color,
            strokeWidth: 2.6,
          ),
        ),
      );
}

// Error state for alert list.
class _AlertListError extends StatelessWidget {
  final String message;
  final Color color;
  const _AlertListError({Key? key, required this.message, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: color, size: 28),
            const SizedBox(width: 12),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color),
            ),
          ],
        ),
      );
}


