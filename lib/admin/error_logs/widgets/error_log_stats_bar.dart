import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/models/error_log.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class ErrorLogStatsBar extends StatelessWidget {
  final String? severity;
  final DateTime? start;
  final DateTime? end;

  const ErrorLogStatsBar({super.key, this.severity, this.start, this.end});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              Chip(
                label: Text('Total: $total'),
                backgroundColor: _chipBg(
                    DesignTokens.neutralChipColor, colorScheme.surfaceVariant),
                labelStyle: TextStyle(
                  color: _chipText(DesignTokens.neutralChipTextColor,
                      colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('Critical: $critical'),
                backgroundColor:
                    _chipBg(DesignTokens.errorChipColor, colorScheme.error),
                labelStyle: TextStyle(
                  color: _chipText(
                      DesignTokens.errorChipTextColor, colorScheme.onError),
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('Warnings: $warning'),
                backgroundColor: _chipBg(
                    DesignTokens.warningChipColor, colorScheme.tertiary),
                labelStyle: TextStyle(
                  color: _chipText(DesignTokens.warningChipTextColor,
                      colorScheme.onTertiary),
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('Info: $info'),
                backgroundColor:
                    _chipBg(DesignTokens.infoChipColor, colorScheme.secondary),
                labelStyle: TextStyle(
                  color: _chipText(
                      DesignTokens.infoChipTextColor, colorScheme.onSecondary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
