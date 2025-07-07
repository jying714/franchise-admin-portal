import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/error_log.dart';
import 'error_log_detail_drawer.dart';
import 'package:intl/intl.dart';

class ErrorLogTable extends StatefulWidget {
  final List<ErrorLog> logs;
  const ErrorLogTable({Key? key, required this.logs}) : super(key: key);

  @override
  State<ErrorLogTable> createState() => _ErrorLogTableState();
}

class _ErrorLogTableState extends State<ErrorLogTable> {
  ErrorLog? _selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.logs.isEmpty) {
      return const Center(child: Text('No error logs found.'));
    }
    // Full overflow-safe, scrollable table:
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Severity')),
            DataColumn(label: Text('Source')),
            DataColumn(label: Text('Screen')),
            DataColumn(label: Text('Message')),
            DataColumn(label: Text('Actions')),
          ],
          rows: widget.logs.map((log) {
            final isCritical = log.severity.toLowerCase() == 'fatal' ||
                log.severity.toLowerCase() == 'critical';
            return DataRow(
              color: isCritical
                  ? MaterialStateProperty.all(
                      colorScheme.error.withOpacity(0.10))
                  : null,
              cells: [
                DataCell(
                  Text(DateFormat('yyyy-MM-dd HH:mm').format(log.timestamp)),
                ),
                DataCell(
                  Row(
                    children: [
                      Icon(
                        log.severity.toLowerCase() == 'fatal'
                            ? Icons.error
                            : Icons.warning,
                        color: isCritical
                            ? colorScheme.error
                            : colorScheme.secondary,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.severity,
                        style: TextStyle(
                          color: isCritical
                              ? colorScheme.error
                              : colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(log.source)),
                DataCell(Text(log.screen)),
                DataCell(
                  Text(
                    log.message.length > 48
                        ? '${log.message.substring(0, 48)}…'
                        : log.message,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    tooltip: "View Details",
                    onPressed: () {
                      setState(() => _selected = log);
                      showDialog(
                        context: context,
                        builder: (_) => ErrorLogDetailDrawer(log: log),
                      );
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
