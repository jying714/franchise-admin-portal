import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/core/providers/franchise_provider.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/config/branding_config.dart';
import 'package:admin_portal/widgets/dashboard/dashboard_section_card.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:admin_portal/admin/features/alerts/alerts_repository.dart';
import 'package:admin_portal/core/models/alert_model.dart';
import 'package:admin_portal/core/models/dashboard_section.dart';
import 'package:admin_portal/core/providers/user_profile_notifier.dart';

/// Dashboard card: At-a-glance payout summary + live payout-related alerts.
class PayoutStatusCard extends StatelessWidget {
  const PayoutStatusCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[PayoutStatusCard] loc is null! Localization not available for this context.');
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    final colorScheme = theme.colorScheme;

    // 🧑‍💻 Developer-only access guard (example: show only for owners/managers/dev)
    final user = Provider.of<UserProfileNotifier>(context, listen: false).user;
    if (user == null ||
        !user.roles.any(
            (role) => ['hq_owner', 'hq_manager', 'developer'].contains(role))) {
      return const SizedBox.shrink();
    }

    return DashboardSectionCard(
      title: loc.payoutStatus,
      icon: Icons.payments_rounded,
      builder: (context) => _PayoutCardContent(
        franchiseId: franchiseId,
        loc: loc,
        theme: theme,
      ),
    );
  }
}

class _PayoutCardContent extends StatefulWidget {
  final String franchiseId;
  final AppLocalizations loc;
  final ThemeData theme;

  const _PayoutCardContent({
    required this.franchiseId,
    required this.loc,
    required this.theme,
  });

  @override
  State<_PayoutCardContent> createState() => _PayoutCardContentState();
}

class _PayoutCardContentState extends State<_PayoutCardContent> {
  late Future<Map<String, int>> _future;

  @override
  void initState() {
    super.initState();
    _future = FirestoreService().getPayoutStatsForFranchise(widget.franchiseId);
  }

  void _retry() {
    setState(() {
      _future =
          FirestoreService().getPayoutStatsForFranchise(widget.franchiseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertsRepo = AlertsRepository();
    return StreamBuilder<List<AlertModel>>(
      stream: alertsRepo.watchActiveAlerts(franchiseId: widget.franchiseId).map(
          (alerts) => alerts
              .where((a) =>
                  a.type == 'payout_failed' || a.type == 'payout_pending')
              .toList()),
      builder: (context, alertSnap) {
        return FutureBuilder<Map<String, int>>(
          future: _future,
          builder: (context, payoutSnap) {
            if (payoutSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (payoutSnap.hasError) {
              ErrorLogger.log(
                message:
                    'PayoutStatusCard: failed to load payout stats\n${payoutSnap.error}',
                stack: payoutSnap.stackTrace?.toString(),
              );
              return _ErrorWidget(
                message: widget.loc.failedToLoadSummary,
                onRetry: _retry,
              );
            }
            final payoutStats = payoutSnap.data ?? {};
            final pending = payoutStats['pending'] ?? 0;
            final sent = payoutStats['sent'] ?? 0;
            final failed = payoutStats['failed'] ?? 0;

            final payoutAlerts = alertSnap.data ?? [];
            final hasAlert = payoutAlerts.isNotEmpty;
            final topAlert = hasAlert ? payoutAlerts.first : null;

            return Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasAlert) ...[
                    _AlertBanner(
                        alert: topAlert!, theme: widget.theme, loc: widget.loc),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      _StatusDot(color: widget.theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text("${widget.loc.pending}: $pending",
                          style: TextStyle(
                              color: widget.theme.colorScheme.primary)),
                      const SizedBox(width: 14),
                      _StatusDot(color: widget.theme.colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text("${widget.loc.sent}: $sent",
                          style: TextStyle(
                              color: widget.theme.colorScheme.secondary)),
                      const SizedBox(width: 14),
                      _StatusDot(color: widget.theme.colorScheme.error),
                      const SizedBox(width: 4),
                      Text("${widget.loc.failed}: $failed",
                          style:
                              TextStyle(color: widget.theme.colorScheme.error)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(widget.loc.viewPayouts),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/hq/payouts');
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(radius: 6, backgroundColor: color);
  }
}

class _AlertBanner extends StatelessWidget {
  final AlertModel alert;
  final ThemeData theme;
  final AppLocalizations loc;
  const _AlertBanner(
      {required this.alert, required this.theme, required this.loc});

  @override
  Widget build(BuildContext context) {
    final levelColor = alert.level == 'critical'
        ? theme.colorScheme.error
        : (alert.level == 'warning'
            ? theme.colorScheme.secondary
            : theme.colorScheme.primary);

    return Card(
        color: levelColor.withOpacity(0.12),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        child: ListTile(
          leading: Icon(Icons.warning_rounded, color: levelColor),
          title: Text(
            alert.title.isNotEmpty
                ? alert.title
                : (alert.body.isNotEmpty
                    ? alert.body
                    : loc.payoutAlert ?? "Payout alert"),
          ),
          subtitle: alert.body.isNotEmpty
              ? Text(alert.body)
              : (alert.createdAt != null
                  ? Text(MaterialLocalizations.of(context)
                      .formatFullDate(alert.createdAt))
                  : null),
          trailing: IconButton(
            icon: Icon(Icons.close, color: theme.disabledColor),
            onPressed: () {
              // Placeholder for dismiss
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(loc.featureComingSoon('Payout History'))));
            },
          ),
        ));
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.retry),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
