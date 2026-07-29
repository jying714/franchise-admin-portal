import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared;

class ErrorLogsSection extends StatefulWidget {
  final String? franchiseId;

  const ErrorLogsSection({super.key, this.franchiseId});

  @override
  State<ErrorLogsSection> createState() => _ErrorLogsSectionState();
}

enum _ErrorLogSourceMode { franchise, global }

bool _isConcreteFranchiseId(String? id) =>
    id != null &&
    id.isNotEmpty &&
    id != 'unknown' &&
    id != 'default' &&
    id != 'all';

class _ErrorLogsSectionState extends State<ErrorLogsSection> {
  String? _filterSeverity;
  _ErrorLogSourceMode _sourceMode = _ErrorLogSourceMode.franchise;

  void _onSeverityFilterChanged(String? newValue) {
    setState(() {
      _filterSeverity = newValue;
    });
  }

  void _onSourceModeChanged(_ErrorLogSourceMode mode) {
    setState(() {
      _sourceMode = mode;
    });
  }

  Stream<List<shared.ErrorLog>>? _logsStream(shared.FirestoreService fs) {
    if (_sourceMode == _ErrorLogSourceMode.global) {
      return fs.streamErrorLogsGlobal(
        severity: _filterSeverity,
        limit: 100,
      );
    }
    if (!_isConcreteFranchiseId(widget.franchiseId)) {
      return null;
    }
    return fs.streamErrorLogs(
      widget.franchiseId!,
      limit: 100,
      severity: _filterSeverity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const Scaffold(
        body: Center(child: Text('Localization missing')),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final adminUser = Provider.of<shared.AdminUserProvider>(context).user;
    final isDeveloper = adminUser?.roles.contains('developer') ?? false;

    if (!isDeveloper) {
      return Center(
        child: Text(
          loc.unauthorizedAccess,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final firestore =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final needsFranchise = _sourceMode == _ErrorLogSourceMode.franchise &&
        !_isConcreteFranchiseId(widget.franchiseId);
    final modeLabel = _sourceMode == _ErrorLogSourceMode.global
        ? 'Global'
        : (_isConcreteFranchiseId(widget.franchiseId)
            ? widget.franchiseId!
            : 'Select a franchise');

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.errorLogsSectionTitle} — $modeLabel',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              loc.errorLogsSectionDesc,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            SegmentedButton<_ErrorLogSourceMode>(
              segments: const [
                ButtonSegment<_ErrorLogSourceMode>(
                  value: _ErrorLogSourceMode.franchise,
                  label: Text('Franchise'),
                  icon: Icon(Icons.store_outlined),
                ),
                ButtonSegment<_ErrorLogSourceMode>(
                  value: _ErrorLogSourceMode.global,
                  label: Text('Global'),
                  icon: Icon(Icons.public),
                ),
              ],
              selected: {_sourceMode},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  _onSourceModeChanged(set.first);
                }
              },
            ),
            const SizedBox(height: 18),
            _buildFilterRow(loc, colorScheme, theme),
            const SizedBox(height: 18),
            if (needsFranchise)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select a franchise to view franchise error logs.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              StreamBuilder<List<shared.ErrorLog>>(
                stream: _logsStream(firestore),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    shared.ErrorLogger.log(
                      message: 'Failed to stream error logs: ${snapshot.error}',
                      source: 'ErrorLogsSection',
                      severity: 'warning',
                      contextData: {
                        'franchiseId': widget.franchiseId,
                        'sourceMode': _sourceMode.name,
                      },
                    );
                    return Card(
                      color: colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          '${loc.errorLogsSectionError}\n${snapshot.error}',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.error),
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    );
                  }
                  final logs = snapshot.data ?? const <shared.ErrorLog>[];
                  if (logs.isEmpty) {
                    return Center(child: Text(loc.errorLogsSectionEmpty));
                  }
                  return _ErrorLogList(
                    logs: logs,
                    colorScheme: colorScheme,
                    loc: loc,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(
      AppLocalizations loc, ColorScheme colorScheme, ThemeData theme) {
    return Row(
      children: [
        Text(loc.errorLogsSectionSeverityFilter,
            style: theme.textTheme.titleMedium),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: _filterSeverity,
          hint: Text(loc.errorLogsSectionFilterAny),
          items: [
            DropdownMenuItem(
                value: null, child: Text(loc.errorLogsSectionFilterAny)),
            DropdownMenuItem(
                value: 'error', child: Text(loc.errorLogsSectionSeverityError)),
            DropdownMenuItem(
                value: 'warning',
                child: Text(loc.errorLogsSectionSeverityWarning)),
            DropdownMenuItem(
                value: 'fatal', child: Text(loc.errorLogsSectionSeverityFatal)),
          ],
          onChanged: _onSeverityFilterChanged,
        ),
      ],
    );
  }
}

class _ErrorLogList extends StatelessWidget {
  final List<shared.ErrorLog> logs;
  final ColorScheme colorScheme;
  final AppLocalizations loc;

  const _ErrorLogList({
    required this.logs,
    required this.colorScheme,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final log = logs[idx];
          final ts = log.timestamp;
          final screen = log.screen.isEmpty ? '—' : log.screen;
          final source = log.source.isEmpty ? log.message : log.source;
          return ExpansionTile(
            leading: Icon(
              _iconForSeverity(log.severity),
              color: _colorForSeverity(log.severity),
            ),
            title: Text(log.message),
            subtitle: Text(
              '${loc.errorLogsSectionAt} $screen — ${_formatDateTime(ts)}'
              '${source.isNotEmpty ? " — $source" : ""}',
            ),
            children: [
              if (log.stackTrace != null && log.stackTrace!.isNotEmpty)
                ListTile(
                  dense: true,
                  title: const Text('Stack'),
                  subtitle: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      log.stackTrace!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              if (log.contextData != null && log.contextData!.isNotEmpty)
                ListTile(
                  dense: true,
                  title: const Text('Context'),
                  subtitle: Text(log.contextData.toString()),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

IconData _iconForSeverity(String severity) {
  switch (severity) {
    case 'error':
      return Icons.error;
    case 'warning':
      return Icons.warning;
    case 'fatal':
      return Icons.dangerous;
    default:
      return Icons.bug_report;
  }
}

Color _colorForSeverity(String severity) {
  switch (severity) {
    case 'error':
      return Colors.red;
    case 'warning':
      return Colors.orange;
    case 'fatal':
      return Colors.deepPurple;
    default:
      return Colors.grey;
  }
}
