import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../packages/shared_core/lib/src/core/models/error_log.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'error_log_detail_drawer.dart';
import '../../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../../../packages/shared_core/lib/src/core/providers/franchise_provider.dart';

class ErrorLogTable extends StatefulWidget {
  final List<ErrorLog> logs;
  const ErrorLogTable({super.key, required this.logs});

  @override
  State<ErrorLogTable> createState() => _ErrorLogTableState();
}

class _ErrorLogTableState extends State<ErrorLogTable> {
  late List<ErrorLog> _sortedLogs;
  final Set<String> _selectedIds = {};
  int? _sortColumnIndex;
  bool _sortAscending = false;
  bool _condensed = false;

  @override
  void initState() {
    super.initState();
    _sortedLogs = widget.logs;
  }

  @override
  void didUpdateWidget(ErrorLogTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sortedLogs = _applySort(widget.logs);
  }

  List<ErrorLog> _applySort(List<ErrorLog> logs) {
    if (_sortColumnIndex == null) return List.of(logs);
    List<ErrorLog> sorted = List.of(logs);
    switch (_sortColumnIndex) {
      case 0:
        sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case 1:
        sorted.sort((a, b) => a.severity.compareTo(b.severity));
        break;
      case 2:
        sorted.sort((a, b) => a.source.compareTo(b.source));
        break;
      case 3:
        sorted.sort((a, b) => a.screen.compareTo(b.screen));
        break;
      case 4:
        sorted.sort((a, b) => a.message.compareTo(b.message));
        break;
      default:
        break;
    }
    if (!_sortAscending) sorted = sorted.reversed.toList();
    return sorted;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortedLogs = _applySort(widget.logs);
    });
  }

  Future<void> _exportCsv({bool onlySelected = false}) async {
    final logsToExport = onlySelected
        ? _sortedLogs.where((log) => _selectedIds.contains(log.id)).toList()
        : _sortedLogs;
    List<List<String>> rows = [
      [
        'Time',
        'Severity',
        'Source',
        'Screen',
        'Message',
        'UserId',
        'Resolved',
        'Archived'
      ],
      ...logsToExport.map((log) => [
            DateFormat('yyyy-MM-dd HH:mm').format(log.timestamp),
            log.severity,
            log.source,
            log.screen,
            log.message.replaceAll('\n', ' '),
            log.userId ?? '',
            log.resolved.toString(),
            log.archived.toString(),
          ])
    ];

    String csv = const ListToCsvConverter().convert(rows);
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Export error logs to CSV',
      fileName: 'error_logs_export_${DateTime.now().toIso8601String()}.csv',
    );
    if (outputFile != null) {
      await File(outputFile).writeAsString(csv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exported successfully.')),
        );
      }
    }
  }

  Future<void> _exportJson({bool onlySelected = false}) async {
    final logsToExport = onlySelected
        ? _sortedLogs.where((log) => _selectedIds.contains(log.id)).toList()
        : _sortedLogs;
    List<Map<String, dynamic>> logsJson =
        logsToExport.map((log) => log.toJson()).toList();
    String jsonString = const JsonEncoder.withIndent('  ').convert(logsJson);
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Export error logs to JSON',
      fileName: 'error_logs_export_${DateTime.now().toIso8601String()}.json',
    );
    if (outputFile != null) {
      await File(outputFile).writeAsString(jsonString);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON exported successfully.')),
        );
      }
    }
  }

  void _toggleCondensed() {
    setState(() {
      _condensed = !_condensed;
    });
  }

  void _toggleSelectAll(bool? checked) {
    setState(() {
      if (checked ?? false) {
        _selectedIds.addAll(_sortedLogs.map((log) => log.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelectOne(String id, bool? checked) {
    setState(() {
      if (checked ?? false) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  Future<void> _bulkResolve(bool resolved) async {
    String franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    final service = context.read<FirestoreService>();
    final ids = _selectedIds.toList();
    for (final id in ids) {
      await service.setErrorLogStatus(franchiseId, id, resolved: resolved);
    }
    _selectedIds.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Marked ${ids.length} logs as ${resolved ? "resolved" : "unresolved"}')),
      );
    }
  }

  Future<void> _bulkArchive(bool archived) async {
    String franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    final service = context.read<FirestoreService>();
    final ids = _selectedIds.toList();
    for (final id in ids) {
      await service.setErrorLogStatus(franchiseId, id, archived: archived);
    }
    setState(() {
      _selectedIds.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Marked ${ids.length} logs as ${archived ? "archived" : "active"}'),
        ),
      );
    }
  }

  Future<void> _bulkDelete() async {
    String franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    final service = context.read<FirestoreService>();
    final ids = _selectedIds.toList();
    for (final id in ids) {
      await service.deleteErrorLog(franchiseId, id);
    }
    setState(() {
      _sortedLogs.removeWhere((log) => _selectedIds.contains(log.id));
      _selectedIds.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${ids.length} logs.')),
      );
    }
  }

  Future<void> _addComment(String logId, String text) async {
    String franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    if (text.trim().isEmpty) return;
    final comment = {
      'text': text,
      'userId': 'admin', // You may replace with currentUser
      'timestamp': DateTime.now().toIso8601String(),
    };
    await context
        .read<FirestoreService>()
        .addCommentToErrorLog(franchiseId, logId, comment);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added.')),
      );
    }
  }

  Color _severityColor(BuildContext context, String severity) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (severity.toLowerCase()) {
      case 'fatal':
      case 'critical':
        return DesignTokens.errorChipColor ?? colorScheme.error;
      case 'warning':
        return DesignTokens.warningChipColor ?? colorScheme.tertiary;
      case 'info':
        return DesignTokens.infoChipColor ?? colorScheme.secondary;
      default:
        return DesignTokens.neutralChipColor ?? colorScheme.primary;
    }
  }

  Widget _emptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded,
              color: colorScheme.onSurface.withOpacity(0.30), size: 54),
          const SizedBox(height: 12),
          Text(
            'No error logs found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.65),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Everything is running smoothly!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.45),
                ),
          ),
        ],
      ),
    );
  }

  // --- Combined Action Bar ---
  Widget _buildActionBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final isBulk = _selectedIds.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isBulk
            ? Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                color: colorScheme.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _selectedIds.length == _sortedLogs.length &&
                            _sortedLogs.isNotEmpty,
                        tristate: true,
                        onChanged: (v) => _toggleSelectAll(v),
                      ),
                      Text('${_selectedIds.length} selected',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary)),
                      const SizedBox(width: 20),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Mark Resolved"),
                        onPressed: () => _bulkResolve(true),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.radio_button_unchecked),
                        label: const Text("Mark Unresolved"),
                        onPressed: () => _bulkResolve(false),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.archive),
                        label: const Text("Archive"),
                        onPressed: () => _bulkArchive(true),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.unarchive),
                        label: const Text("Unarchive"),
                        onPressed: () => _bulkArchive(false),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_forever),
                        label: const Text("Delete"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                        ),
                        onPressed: _bulkDelete,
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.file_download),
                        label: const Text("Export (CSV)"),
                        onPressed: () => _exportCsv(onlySelected: true),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.code),
                        label: const Text("Export (JSON)"),
                        onPressed: () => _exportJson(onlySelected: true),
                      ),
                    ],
                  ),
                ),
              )
            : Row(
                children: [
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_download),
                    label: const Text("Export All CSV"),
                    onPressed: _sortedLogs.isNotEmpty ? _exportCsv : null,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.code),
                    label: const Text("Export All JSON"),
                    onPressed: _sortedLogs.isNotEmpty ? _exportJson : null,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: _condensed ? "Expanded View" : "Condensed View",
                    icon: Icon(_condensed ? Icons.zoom_out : Icons.zoom_in),
                    onPressed: _toggleCondensed,
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    print('ErrorLogTable received logs: ${widget.logs.length}');
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.logs.isEmpty) return _emptyState();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildActionBar(),
            const Divider(height: 1),
            // --- Data Table ---
            Expanded(
              child: Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 1000),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortAscending,
                        columns: [
                          DataColumn(
                            label: Checkbox(
                              value:
                                  _selectedIds.length == _sortedLogs.length &&
                                      _sortedLogs.isNotEmpty,
                              onChanged: (v) => _toggleSelectAll(v),
                            ),
                          ),
                          DataColumn(
                            label: const Text('Time'),
                            onSort: (i, asc) => _onSort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('Severity'),
                            onSort: (i, asc) => _onSort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('Source'),
                            onSort: (i, asc) => _onSort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('Screen'),
                            onSort: (i, asc) => _onSort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('Message'),
                            onSort: (i, asc) => _onSort(i, asc),
                          ),
                          const DataColumn(label: Text('Resolved')),
                          const DataColumn(label: Text('Archived')),
                          const DataColumn(label: Text('Actions')),
                        ],
                        rows: _sortedLogs.map((log) {
                          // Defensive: Provide default values for any possibly null field
                          final severity = log.severity ?? '';
                          final source = log.source ?? '';
                          final screen = log.screen ?? '';
                          final message = log.message ?? '';
                          final resolved = log.resolved ?? false;
                          final archived = log.archived ?? false;
                          final userId = log.userId ?? '';

                          final isCritical =
                              (severity.toLowerCase() == 'fatal' ||
                                  severity.toLowerCase() == 'critical');

                          return DataRow(
                            selected: _selectedIds.contains(log.id),
                            color: isCritical
                                ? WidgetStateProperty.all(
                                    _severityColor(context, severity)
                                        .withOpacity(0.12))
                                : null,
                            cells: [
                              DataCell(
                                Checkbox(
                                  value: _selectedIds.contains(log.id),
                                  onChanged: (checked) =>
                                      _toggleSelectOne(log.id, checked),
                                ),
                              ),
                              DataCell(
                                Text(
                                  DateFormat('yyyy-MM-dd HH:mm')
                                      .format(log.timestamp),
                                  style: _condensed
                                      ? const TextStyle(fontSize: 12)
                                      : null,
                                ),
                              ),
                              DataCell(
                                Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 140),
                                  child: Row(
                                    children: [
                                      Icon(
                                        severity.toLowerCase() == 'fatal'
                                            ? Icons.error
                                            : Icons.warning,
                                        color:
                                            _severityColor(context, severity),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        severity.isNotEmpty
                                            ? severity
                                            : 'unknown',
                                        style: TextStyle(
                                          color:
                                              _severityColor(context, severity),
                                          fontWeight: FontWeight.bold,
                                          fontSize: _condensed ? 12 : 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(Text(source,
                                  style: _condensed
                                      ? const TextStyle(fontSize: 12)
                                      : null)),
                              DataCell(Text(screen,
                                  style: _condensed
                                      ? const TextStyle(fontSize: 12)
                                      : null)),
                              DataCell(
                                Container(
                                  constraints: BoxConstraints(
                                      maxWidth: _condensed ? 120 : 280),
                                  child: Text(
                                    message.length > (_condensed ? 24 : 48)
                                        ? '${message.substring(0, _condensed ? 24 : 48)}…'
                                        : message,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: _condensed
                                        ? const TextStyle(fontSize: 12)
                                        : null,
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: Icon(
                                    resolved
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: resolved
                                        ? colorScheme.secondary
                                        : colorScheme.outline,
                                    size: 20,
                                  ),
                                  tooltip: resolved
                                      ? "Mark Unresolved"
                                      : "Mark Resolved",
                                  onPressed: () => context
                                      .read<FirestoreService>()
                                      .setErrorLogStatus(
                                        franchiseId,
                                        log.id,
                                        resolved: !resolved,
                                      ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: Icon(
                                    archived ? Icons.archive : Icons.unarchive,
                                    color: archived
                                        ? colorScheme.secondary
                                        : colorScheme.outline,
                                    size: 20,
                                  ),
                                  tooltip: archived ? "Unarchive" : "Archive",
                                  onPressed: () => context
                                      .read<FirestoreService>()
                                      .setErrorLogStatus(
                                        franchiseId,
                                        log.id,
                                        archived: !archived,
                                      ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 130),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.open_in_new),
                                        tooltip: "View Details",
                                        onPressed: () async {
                                          await showDialog(
                                            context: context,
                                            builder: (_) =>
                                                ErrorLogDetailDrawer(log: log),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.comment),
                                        tooltip: "Add Comment",
                                        onPressed: () async {
                                          final controller =
                                              TextEditingController();
                                          final result =
                                              await showDialog<String>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Add Comment'),
                                              content: TextField(
                                                controller: controller,
                                                decoration:
                                                    const InputDecoration(
                                                        hintText:
                                                            'Enter comment...'),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context,
                                                          controller.text),
                                                  child: const Text('Add'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (result != null &&
                                              result.trim().isNotEmpty) {
                                            await _addComment(log.id, result);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
