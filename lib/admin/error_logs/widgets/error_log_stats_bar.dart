import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/models/error_log.dart';

class ErrorLogStatsBar extends StatelessWidget {
  final String? severity;
  final DateTime? start;
  final DateTime? end;

  const ErrorLogStatsBar({super.key, this.severity, this.start, this.end});

  @override
  Widget build(BuildContext context) {
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
                backgroundColor: Colors.grey.shade300,
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('Critical: $critical'),
                backgroundColor: Colors.red.shade100,
                labelStyle: const TextStyle(color: Colors.red),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('Warnings: $warning'),
                backgroundColor: Colors.amber.shade100,
                labelStyle: const TextStyle(color: Colors.amber),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('Info: $info'),
                backgroundColor: Colors.blue.shade100,
                labelStyle: const TextStyle(color: Colors.blue),
              ),
            ],
          ),
        );
      },
    );
  }
}
