import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/admin/features/alerts/alerts_repository.dart';

class AlertsCard extends StatelessWidget {
  final String franchiseId;
  final String? locationId;
  final String? userId;
  final bool developerMode;
  final AlertsRepository? repository;

  const AlertsCard({
    super.key,
    required this.franchiseId,
    this.locationId,
    this.userId,
    this.developerMode = false,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const Center(child: Text('Localization missing'));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fireService =
        Provider.of<shared.FirestoreService>(context, listen: false);

    final repo = repository ??
        AlertsRepository(
          firestoreService: fireService,
        );

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      elevation: DesignTokens.adminCardElevation,
      margin: shared.UiConfig.defaultPadding,
      child: Padding(
        padding: shared.UiConfig.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: DesignTokens.primaryColor),
                const SizedBox(width: 8),
                Text(
                  loc.dashboard_active_alerts,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: DesignTokens.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.filter_alt_outlined,
                    color: colorScheme.onSurface.withOpacity(0.45),
                  ),
                  onPressed: null,
                  tooltip: loc.dashboard_alerts_filter_tooltip,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<shared.AlertModel>>(
                stream: repo.watchActiveAlerts(
                  franchiseId: franchiseId,
                  locationId: locationId,
                  developerMode: developerMode,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    shared.ErrorLogger.log(
                      message:
                          'Failed to load active alerts: ${snapshot.error}',
                      stack: snapshot.stackTrace?.toString(),
                      source: 'AlertsCard',
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
                    return _AlertLoading(color: colorScheme.primary);
                  }

                  final alerts = snapshot.data ?? [];

                  if (alerts.isEmpty) {
                    return _AlertEmpty(message: loc.dashboard_no_active_alerts);
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...alerts.take(3).map(
                              (alert) => _AlertItem(
                                alert: alert,
                                colorScheme: colorScheme,
                                loc: loc,
                              ),
                            ),
                        if (alerts.length > 3)
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/alerts'),
                            child: Text(
                              loc.dashboard_see_all_alerts,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: DesignTokens.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final shared.AlertModel alert;
  final ColorScheme colorScheme;
  final AppLocalizations loc;

  const _AlertItem({
    super.key,
    required this.alert,
    required this.colorScheme,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData icon;
    switch (alert.level.toLowerCase()) {
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
        iconColor = DesignTokens.primaryColor;
        icon = Icons.info_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: DesignTokens.iconSize),
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
  const _AlertEmpty({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: DesignTokens.primaryColor, size: DesignTokens.iconSize),
            const SizedBox(width: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.secondaryTextColor,
                  ),
            ),
          ],
        ),
      );
}

class _AlertLoading extends StatelessWidget {
  final Color color;
  const _AlertLoading({super.key, required this.color});

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
  const _AlertError({super.key, required this.message, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                color: color, size: DesignTokens.iconSize),
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
