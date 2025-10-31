import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/src/core/services/firestore_service.dart';
import 'package:shared_core/src/core/providers/franchise_provider.dart';
import 'package:shared_core/src/core/providers/admin_user_provider.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

class AdminErrorLogsScreen extends StatefulWidget {
  const AdminErrorLogsScreen({Key? key}) : super(key: key);

  @override
  State<AdminErrorLogsScreen> createState() => _AdminErrorLogsScreenState();
}

class _AdminErrorLogsScreenState extends State<AdminErrorLogsScreen> {
  bool _loading = true;
  String? _errorMsg;
  List<AdminErrorLog> _logs = [];
  String? _severity;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      // TODO: Replace with real FirestoreService error log query scoped to this franchise.
      await Future.delayed(const Duration(milliseconds: 500));
      final franchiseId =
          Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
      _logs = [
        AdminErrorLog(
          id: '1',
          timestamp: DateTime.now().subtract(const Duration(minutes: 14)),
          message: 'Customer order failed during checkout.',
          severity: 'error',
          screen: 'CheckoutScreen',
          franchiseId: franchiseId,
        ),
        AdminErrorLog(
          id: '2',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          message: 'Receipt printer not responding.',
          severity: 'warning',
          screen: 'OrderScreen',
          franchiseId: franchiseId,
        ),
        AdminErrorLog(
          id: '3',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          message: 'Loyalty points failed to sync for customer.',
          severity: 'error',
          screen: 'CustomerLoyaltyScreen',
          franchiseId: franchiseId,
        ),
      ];
      setState(() => _loading = false);
    } catch (e, stack) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
      final franchiseId = context.watch<FranchiseProvider>().franchiseId;
      await ErrorLogger.log(
        message: 'Failed to fetch admin error logs: $e',
        stack: stack.toString(),
        source: 'AdminErrorLogsScreen',
        screen: 'AdminErrorLogsScreen',
        severity: 'warning',
        contextData: {
          'franchiseId': franchiseId,
        },
      );
    }
  }

  List<AdminErrorLog> get _filteredLogs {
    return _logs.where((log) {
      final severityOk = _severity == null || log.severity == _severity;
      final dateOk = _dateRange == null ||
          (log.timestamp.isAfter(
                  _dateRange!.start.subtract(const Duration(seconds: 1))) &&
              log.timestamp
                  .isBefore(_dateRange!.end.add(const Duration(days: 1))));
      return severityOk && dateOk;
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
    debugPrint('[admin_error_logs_screen] Loaded');
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final adminUser = Provider.of<AdminUserProvider>(context).user;
    final roles = adminUser?.roles ?? [];
    final isAdmin = roles.contains('owner') ||
        roles.contains('manager') ||
        roles.contains('staff') ||
        roles.contains('developer');

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.adminErrorLogsScreenTitle),
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

    final severities = _logs.map((e) => e.severity).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.adminErrorLogsScreenTitle),
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
            _buildFilterRow(loc, severities, theme, colorScheme),
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
                          '${loc.adminErrorLogsScreenError}\n$_errorMsg',
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
              Center(child: Text(loc.adminErrorLogsScreenEmpty))
            else
              Expanded(
                  child: _AdminErrorLogList(
                      logs: _filteredLogs,
                      colorScheme: colorScheme,
                      loc: loc,
                      theme: theme)),
            const SizedBox(height: 18),
            _ComingSoonCard(
              icon: Icons.support_agent,
              title: loc.adminErrorLogsScreenSupportComingSoon,
              subtitle: loc.adminErrorLogsScreenSupportDesc,
              colorScheme: colorScheme,
              theme: theme,
            ),
            _ComingSoonCard(
              icon: Icons.analytics,
              title: loc.adminErrorLogsScreenTrendsComingSoon,
              subtitle: loc.adminErrorLogsScreenTrendsDesc,
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
    List<String> severities,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
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
            // Severity filter
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${loc.adminErrorLogsScreenSeverity}: ',
                    style: theme.textTheme.titleMedium),
                DropdownButton<String>(
                  value: _severity,
                  hint: Text(loc.adminErrorLogsScreenFilterAny),
                  items: [
                    DropdownMenuItem(
                        value: null,
                        child: Text(loc.adminErrorLogsScreenFilterAny)),
                    ...severities
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (s) => setState(() => _severity = s),
                ),
              ],
            ),
            // Date range
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${loc.adminErrorLogsScreenDateRange}: ',
                    style: theme.textTheme.titleMedium),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(_dateRange == null
                      ? loc.adminErrorLogsScreenAllDates
                      : '${_dateRange!.start.year}-${_dateRange!.start.month.toString().padLeft(2, '0')}-${_dateRange!.start.day.toString().padLeft(2, '0')} â€” ${_dateRange!.end.year}-${_dateRange!.end.month.toString().padLeft(2, '0')}-${_dateRange!.end.day.toString().padLeft(2, '0')}'),
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

class _AdminErrorLogList extends StatelessWidget {
  final List<AdminErrorLog> logs;
  final ColorScheme colorScheme;
  final AppLocalizations loc;
  final ThemeData theme;

  const _AdminErrorLogList({
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
        return ListTile(
          leading: Icon(
            log.severity == 'error'
                ? Icons.error
                : log.severity == 'warning'
                    ? Icons.warning
                    : Icons.info,
            color: log.severity == 'error'
                ? Colors.red
                : log.severity == 'warning'
                    ? Colors.orange
                    : colorScheme.outline,
          ),
          title: Text(log.message),
          subtitle: Text(
            '${loc.adminErrorLogsScreenAt}: ${log.screen}\n${_formatDateTime(log.timestamp)}',
            style: const TextStyle(fontSize: 13),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
          ),
          onTap: () {
            // Placeholder for future detail dialog/modal
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.comingSoon)),
            );
          },
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

class AdminErrorLog {
  final String id;
  final DateTime timestamp;
  final String message;
  final String severity;
  final String screen;
  final String franchiseId;

  AdminErrorLog({
    required this.id,
    required this.timestamp,
    required this.message,
    required this.severity,
    required this.screen,
    required this.franchiseId,
  });
}


