import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';

class DeveloperErrorLogsScreen extends StatefulWidget {
  const DeveloperErrorLogsScreen({Key? key}) : super(key: key);

  @override
  State<DeveloperErrorLogsScreen> createState() =>
      _DeveloperErrorLogsScreenState();
}

class _DeveloperErrorLogsScreenState extends State<DeveloperErrorLogsScreen> {
  bool _loading = true;
  String? _errorMsg;
  List<DevErrorLog> _logs = [];
  String? _franchiseId;
  String? _severity;
  String? _user;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<FranchiseProvider>(context, listen: false);
    _franchiseId = provider.franchiseId;
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      // TODO: Replace with real FirestoreService error log query, using filter fields below.
      await Future.delayed(const Duration(milliseconds: 600));
      _logs = [
        DevErrorLog(
          id: '1',
          timestamp: DateTime.now().subtract(const Duration(minutes: 16)),
          message: 'Null pointer in menu renderer',
          severity: 'error',
          screen: 'MenuScreen',
          franchiseId: _franchiseId ?? 'doughboyspizzeria',
          userEmail: 'jane@doughboys.com',
          stackTrace: 'StackTrace: ...menu_renderer.dart:89\n...',
          deviceInfo: 'Chrome 124, Windows 11',
        ),
        DevErrorLog(
          id: '2',
          timestamp:
              DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
          message: 'Firestore permission-denied error',
          severity: 'fatal',
          screen: 'CheckoutScreen',
          franchiseId: 'all',
          userEmail: 'owner@doughboys.com',
          stackTrace: 'StackTrace: ...firestore_service.dart:102\n...',
          deviceInfo: 'Safari 17, macOS',
        ),
        DevErrorLog(
          id: '3',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          message: 'Image asset not found: /assets/logo.png',
          severity: 'warning',
          screen: 'AppBarWidget',
          franchiseId: 'doughboyspizzeria',
          userEmail: 'dev@doughboys.com',
          stackTrace: 'StackTrace: ...asset_loader.dart:24\n...',
          deviceInfo: 'iPhone 14, iOS 17',
        ),
      ];
      setState(() => _loading = false);
    } catch (e, stack) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
      Provider.of<FirestoreService>(context, listen: false).logError(
        _franchiseId ?? 'unknown',
        message: 'Failed to fetch developer error logs: $e',
        stackTrace: stack.toString(),
        source: 'DeveloperErrorLogsScreen',
        screen: 'DeveloperErrorLogsScreen',
        severity: 'warning',
        contextData: {},
      );
    }
  }

  List<DevErrorLog> get _filteredLogs {
    return _logs.where((log) {
      final franchiseOk = _franchiseId == null ||
          _franchiseId == 'all' ||
          log.franchiseId == _franchiseId;
      final severityOk = _severity == null || log.severity == _severity;
      final userOk = _user == null || log.userEmail == _user;
      final dateOk = _dateRange == null ||
          (log.timestamp.isAfter(
                  _dateRange!.start.subtract(const Duration(seconds: 1))) &&
              log.timestamp
                  .isBefore(_dateRange!.end.add(const Duration(days: 1))));
      return franchiseOk && severityOk && userOk && dateOk;
    }).toList();
  }

  void _pickDateRange() async {
    final initial = _dateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initial,
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final adminUser = Provider.of<AdminUserProvider>(context).user;
    final isDeveloper = adminUser?.roles.contains('developer') ?? false;

    if (!isDeveloper) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.developerErrorLogsScreenTitle),
        ),
        body: Center(
          child: Text(
            loc.unauthorizedAccess,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Gather distinct values for filters
    final allFranchises = {'all', ..._logs.map((e) => e.franchiseId)}.toList();
    final severities = _logs.map((e) => e.severity).toSet().toList();
    final users = _logs.map((e) => e.userEmail).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.developerErrorLogsScreenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: loc.reload,
            onPressed: _fetchLogs,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterRow(
                loc, allFranchises, severities, users, theme, colorScheme),
            const SizedBox(height: 10),
            if (_loading)
              Center(
                  child: CircularProgressIndicator(color: colorScheme.primary))
            else if (_errorMsg != null)
              Card(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${loc.developerErrorLogsScreenError}\n$_errorMsg',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.error),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: colorScheme.primary),
                        tooltip: loc.reload,
                        onPressed: _fetchLogs,
                      ),
                    ],
                  ),
                ),
              )
            else if (_filteredLogs.isEmpty)
              Center(child: Text(loc.developerErrorLogsScreenEmpty))
            else
              Expanded(
                  child: _DevErrorLogList(
                      logs: _filteredLogs,
                      colorScheme: colorScheme,
                      loc: loc,
                      theme: theme)),
            const SizedBox(height: 18),
            _ComingSoonCard(
              icon: Icons.analytics_outlined,
              title: loc.developerErrorLogsScreenTrendsComingSoon,
              subtitle: loc.developerErrorLogsScreenTrendsDesc,
              colorScheme: colorScheme,
              theme: theme,
            ),
            _ComingSoonCard(
              icon: Icons.lightbulb_outline,
              title: loc.developerErrorLogsScreenAIInsightsComingSoon,
              subtitle: loc.developerErrorLogsScreenAIInsightsDesc,
              colorScheme: colorScheme,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(
    AppLocalizations loc,
    List<String> franchises,
    List<String> severities,
    List<String> users,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Defensive: Ensure _franchiseId is in franchises list to prevent DropdownButton assertion
    String? safeFranchiseId = _franchiseId;
    if (safeFranchiseId != null && !franchises.contains(safeFranchiseId)) {
      safeFranchiseId = null;
    }

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Wrap(
          spacing: 16,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Franchise filter
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${loc.developerErrorLogsScreenFranchise}: ',
                    style: theme.textTheme.titleMedium),
                DropdownButton<String>(
                  value: safeFranchiseId,
                  hint: Text(loc.allFranchisesLabel),
                  items: franchises.map((id) {
                    return DropdownMenuItem(
                      value: id,
                      child: Text(id == 'all' ? loc.allFranchisesLabel : id),
                    );
                  }).toList(),
                  onChanged: (id) => setState(() => _franchiseId = id),
                ),
              ],
            ),
            // Severity filter
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${loc.developerErrorLogsScreenSeverity}: ',
                    style: theme.textTheme.titleMedium),
                DropdownButton<String>(
                  value: _severity,
                  hint: Text(loc.developerErrorLogsScreenFilterAny),
                  items: [
                    DropdownMenuItem(
                        value: null,
                        child: Text(loc.developerErrorLogsScreenFilterAny)),
                    ...severities
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (s) => setState(() => _severity = s),
                ),
              ],
            ),
            // User filter
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${loc.developerErrorLogsScreenUser}: ',
                    style: theme.textTheme.titleMedium),
                DropdownButton<String>(
                  value: _user,
                  hint: Text(loc.developerErrorLogsScreenFilterAny),
                  items: [
                    DropdownMenuItem(
                        value: null,
                        child: Text(loc.developerErrorLogsScreenFilterAny)),
                    ...users
                        .map((u) => DropdownMenuItem(value: u, child: Text(u))),
                  ],
                  onChanged: (u) => setState(() => _user = u),
                ),
              ],
            ),
            // Date range
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${loc.developerErrorLogsScreenDateRange}: ',
                    style: theme.textTheme.titleMedium),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(_dateRange == null
                      ? loc.developerErrorLogsScreenAllDates
                      : '${_dateRange!.start.year}-${_dateRange!.start.month.toString().padLeft(2, '0')}-${_dateRange!.start.day.toString().padLeft(2, '0')} — ${_dateRange!.end.year}-${_dateRange!.end.month.toString().padLeft(2, '0')}-${_dateRange!.end.day.toString().padLeft(2, '0')}'),
                  onPressed: _pickDateRange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DevErrorLogList extends StatelessWidget {
  final List<DevErrorLog> logs;
  final ColorScheme colorScheme;
  final AppLocalizations loc;
  final ThemeData theme;

  const _DevErrorLogList({
    required this.logs,
    required this.colorScheme,
    required this.loc,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, idx) {
        final log = logs[idx];
        return ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          leading: Icon(
            log.severity == 'fatal'
                ? Icons.dangerous
                : log.severity == 'warning'
                    ? Icons.warning
                    : Icons.error,
            color: log.severity == 'fatal'
                ? Colors.deepPurple
                : log.severity == 'warning'
                    ? Colors.orange
                    : Colors.red,
          ),
          title: Text(log.message),
          subtitle: Text(
            '${loc.developerErrorLogsScreenAt}: ${log.screen}\n${_formatDateTime(log.timestamp)}',
            style: const TextStyle(fontSize: 13),
          ),
          trailing: Icon(Icons.expand_more, color: colorScheme.outline),
          children: [
            ListTile(
              dense: true,
              leading: Icon(Icons.account_circle, color: colorScheme.outline),
              title:
                  Text('${loc.developerErrorLogsScreenUser}: ${log.userEmail}'),
              subtitle: Text(
                  '${loc.developerErrorLogsScreenDevice}: ${log.deviceInfo}'),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.bug_report, color: colorScheme.outline),
              title: Text(loc.developerErrorLogsScreenStackTrace),
              subtitle: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  log.stackTrace,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.account_tree, color: colorScheme.outline),
              title: Text(
                  '${loc.developerErrorLogsScreenFranchise}: ${log.franchiseId}'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ComingSoonCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorScheme.surfaceVariant.withOpacity(0.87),
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.outline, size: 30),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DevErrorLog {
  final String id;
  final DateTime timestamp;
  final String message;
  final String severity;
  final String screen;
  final String franchiseId;
  final String userEmail;
  final String stackTrace;
  final String deviceInfo;

  DevErrorLog({
    required this.id,
    required this.timestamp,
    required this.message,
    required this.severity,
    required this.screen,
    required this.franchiseId,
    required this.userEmail,
    required this.stackTrace,
    required this.deviceInfo,
  });
}
