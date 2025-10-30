import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin_portal/core/models/error_log.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'error_log_detail_drawer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

String _truncateTooltip(String text, [int max = 150]) {
  if (text.length <= max) return text;
  return text.substring(0, max) + '...';
}

class PaginatedErrorLogTable extends StatelessWidget {
  final List<ErrorLog> logs;
  final int rowsPerPage;
  final void Function(ErrorLog)? onRowTap;

  const PaginatedErrorLogTable({
    super.key,
    required this.logs,
    this.rowsPerPage = 5, // For best fit, adjust as needed
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }

    return PaginatedDataTable(
      showCheckboxColumn: false,
      rowsPerPage: rowsPerPage,
      availableRowsPerPage: const [5, 10, 25, 50, 100],
      columns: [
        DataColumn(
            label: Tooltip(message: loc.timeTooltip, child: Text(loc.time))),
        DataColumn(
            label: Tooltip(
                message: loc.severityTooltip, child: Text(loc.severity))),
        DataColumn(
            label:
                Tooltip(message: loc.sourceTooltip, child: Text(loc.source))),
        DataColumn(
            label:
                Tooltip(message: loc.screenTooltip, child: Text(loc.screen))),
        DataColumn(
            label:
                Tooltip(message: loc.messageTooltip, child: Text(loc.message))),
        DataColumn(
            label:
                Tooltip(message: loc.userIdTooltip, child: Text(loc.userId))),
        DataColumn(
            label: Tooltip(
                message: loc.resolvedTooltip, child: Text(loc.resolved))),
        DataColumn(
            label: Tooltip(
                message: loc.archivedTooltip, child: Text(loc.archived))),
      ],
      source: _ErrorLogDataSource(logs, context, onRowTap, loc),
      headingRowColor: MaterialStateProperty.all(colorScheme.surfaceVariant),
      dividerThickness: 1,
      columnSpacing: 18,
    );
  }
}

class _ErrorLogDataSource extends DataTableSource {
  final List<ErrorLog> logs;
  final BuildContext context;
  final void Function(ErrorLog)? onRowTap;
  final AppLocalizations loc;

  _ErrorLogDataSource(this.logs, this.context, this.onRowTap, this.loc);

  @override
  DataRow getRow(int index) {
    final log = logs[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(log.timestamp))),
        DataCell(Tooltip(
          message: log.severity,
          child: Text(log.severity),
        )),
        DataCell(Tooltip(
          message: _truncateTooltip(log.source ?? ''),
          child: Text(log.source, maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
        DataCell(Tooltip(
          message: _truncateTooltip(log.screen ?? ''),
          child: Text(log.screen, maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
        DataCell(Tooltip(
          message: _truncateTooltip(log.message ?? ''),
          child:
              Text(log.message, maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
        DataCell(Tooltip(
          message: _truncateTooltip(log.userId ?? ''),
          child: Text(log.userId ?? '',
              maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
        DataCell(
          Tooltip(
            message: log.resolved ? loc.resolved : loc.unresolvedOnly,
            child: Icon(
              log.resolved ? Icons.check_circle : Icons.radio_button_unchecked,
              color: log.resolved ? Colors.green : Colors.grey,
              semanticLabel: log.resolved ? loc.resolved : loc.unresolvedOnly,
            ),
          ),
        ),
        DataCell(
          Tooltip(
            message: log.archived ? loc.archived : loc.notArchived,
            child: Icon(
              log.archived ? Icons.archive : Icons.unarchive,
              color: log.archived ? Colors.blueGrey : Colors.grey,
              semanticLabel: log.archived ? loc.archived : loc.notArchived,
            ),
          ),
        ),
      ],
      onSelectChanged: (_) {
        if (onRowTap != null) {
          onRowTap!(log);
        } else {
          showDialog(
            context: context,
            builder: (_) => ErrorLogDetailDrawer(log: log),
          );
        }
      },
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => logs.length;
  @override
  int get selectedRowCount => 0;
}
