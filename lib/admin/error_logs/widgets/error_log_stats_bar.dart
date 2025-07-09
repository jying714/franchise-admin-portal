import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/models/error_log.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ErrorLogStatsBar extends StatelessWidget {
  final String? severity;
  final DateTime? start;
  final DateTime? end;

  const ErrorLogStatsBar({super.key, this.severity, this.start, this.end});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    Color _chipBg(Color? token, Color fallback) =>
        token ?? fallback.withOpacity(0.12);

    Color _chipText(Color? token, Color fallback) => token ?? fallback;

    return StreamBuilder<List<ErrorLog>>(
      stream: context.read<FirestoreService>().streamErrorLogs(
            severity: severity,
            start: start,
            end: end,
            limit: 1000,
          ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 48);
        final logs = snapshot.data!;
        final total = logs.length;
        final critical = logs
            .where((l) =>
                l.severity.toLowerCase() == 'fatal' ||
                l.severity.toLowerCase() == 'critical')
            .length;
        final warning =
            logs.where((l) => l.severity.toLowerCase() == 'warning').length;
        final info =
            logs.where((l) => l.severity.toLowerCase() == 'info').length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Tooltip(
                message: loc.totalErrorsTooltip(total),
                child: Chip(
                  label: Text('${loc.total}: $total'),
                  backgroundColor: _chipBg(DesignTokens.neutralChipColor,
                      colorScheme.surfaceVariant),
                  labelStyle: TextStyle(
                    color: _chipText(DesignTokens.neutralChipTextColor,
                        colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: loc.criticalErrorsTooltip(critical),
                child: Chip(
                  label: Text('${loc.critical}: $critical'),
                  backgroundColor:
                      _chipBg(DesignTokens.errorChipColor, colorScheme.error),
                  labelStyle: TextStyle(
                    color: _chipText(
                        DesignTokens.errorChipTextColor, colorScheme.onError),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: loc.warningErrorsTooltip(warning),
                child: Chip(
                  label: Text('${loc.warnings}: $warning'),
                  backgroundColor: _chipBg(
                      DesignTokens.warningChipColor, colorScheme.tertiary),
                  labelStyle: TextStyle(
                    color: _chipText(DesignTokens.warningChipTextColor,
                        colorScheme.onTertiary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: loc.infoErrorsTooltip(info),
                child: Chip(
                  label: Text('${loc.info}: $info'),
                  backgroundColor: _chipBg(
                      DesignTokens.infoChipColor, colorScheme.secondary),
                  labelStyle: TextStyle(
                    color: _chipText(DesignTokens.infoChipTextColor,
                        colorScheme.onSecondary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
