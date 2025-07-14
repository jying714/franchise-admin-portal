import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/alert_model.dart';
import 'package:franchise_admin_portal/admin/features/alerts/alerts_repository.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';

class AlertsCard extends StatelessWidget {
  final String franchiseId;
  final String? locationId;
  final String? userId;
  final bool
      developerMode; // Set true to show dev-only alerts, otherwise false.
  final AlertsRepository? repository;

  const AlertsCard({
    Key? key,
    required this.franchiseId,
    this.locationId,
    this.userId,
    this.developerMode = false,
    this.repository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(
        '[AlertsCard] build: franchiseId=$franchiseId, locationId=$locationId, userId=$userId, developerMode=$developerMode');

    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appConfig = AppConfig.instance;
    final fireService = FirestoreService();

    // --- ROLE/PERMISSION DEBUGGING ---
    print(
        '[AlertsCard] Checking access: userId=$userId, developerMode=$developerMode');

    final showForDeveloper = developerMode;

    final repo = repository ??
        AlertsRepository(
          firestoreService: fireService,
          appConfig: appConfig,
        );

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.dashboard_active_alerts,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.filter_alt_outlined,
                      color: colorScheme.onSurface.withOpacity(0.45)),
                  onPressed: null, // Placeholder for future filtering
                  tooltip: loc.dashboard_alerts_filter_tooltip,
                ),
              ],
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<AlertModel>>(
              stream: repo.watchActiveAlerts(
                franchiseId: franchiseId,
                locationId: locationId,
                developerMode: showForDeveloper,
              ),
              builder: (context, snapshot) {
                print(
                    '[AlertsCard] StreamBuilder connectionState=${snapshot.connectionState}');
                if (snapshot.hasError) {
                  print('[AlertsCard] ERROR loading alerts: ${snapshot.error}');
                  fireService.logError(
                    franchiseId,
                    message: 'Failed to load active alerts: ${snapshot.error}',
                    source: 'alerts_card',
                    userId: userId,
                    screen: 'AlertsCard',
                    stackTrace: snapshot.stackTrace?.toString(),
                    errorType: snapshot.error.runtimeType.toString(),
                    severity: 'error',
                    contextData: {
                      'franchiseId': franchiseId,
                      'locationId': locationId,
                      'userId': userId,
                      'developerMode': developerMode,
                    },
                  );
                  return _AlertError(
                    message: loc.dashboard_alerts_error,
                    color: colorScheme.error,
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('[AlertsCard] Loading alerts...');
                  return _AlertLoading(color: colorScheme.primary);
                }

                final alerts = snapshot.data ?? [];
                print('[AlertsCard] Alerts loaded: count=${alerts.length}');

                if (alerts.isEmpty) {
                  print('[AlertsCard] No active alerts.');
                  return _AlertEmpty(message: loc.dashboard_no_active_alerts);
                }

                // Render list of active alerts
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...alerts.take(3).map(
                      (alert) {
                        print(
                            '[AlertsCard] Rendering alert: id=${alert.id}, title=${alert.title}, level=${alert.level}');
                        return _AlertItem(
                          alert: alert,
                          colorScheme: colorScheme,
                          loc: loc,
                        );
                      },
                    ),
                    if (alerts.length > 3)
                      TextButton(
                        onPressed: () {
                          print(
                              '[AlertsCard] See all alerts tapped - navigating to /alerts');
                          Navigator.of(context).pushNamed('/alerts');
                        },
                        child: Text(
                          loc.dashboard_see_all_alerts,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            // 🔜 Future placeholders (filter, quick-dismiss, etc.)
          ],
        ),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final AlertModel alert;
  final ColorScheme colorScheme;
  final AppLocalizations loc;

  const _AlertItem({
    Key? key,
    required this.alert,
    required this.colorScheme,
    required this.loc,
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

    print(
        '[AlertsCard] _AlertItem: id=${alert.id}, title=${alert.title}, level=${alert.level}');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (alert.body.isNotEmpty)
                  Text(
                    alert.body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertEmpty extends StatelessWidget {
  final String message;
  const _AlertEmpty({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
}

class _AlertLoading extends StatelessWidget {
  final Color color;
  const _AlertLoading({Key? key, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: CircularProgressIndicator(
            color: color,
            strokeWidth: 2.2,
          ),
        ),
      );
}

class _AlertError extends StatelessWidget {
  final String message;
  final Color color;
  const _AlertError({Key? key, required this.message, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: color, size: 24),
            const SizedBox(width: 10),
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
