import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../packages/shared_core/lib/src/core/models/error_log.dart';
import '../../../../packages/shared_core/lib/src/core/providers/franchise_provider.dart';
import '../../../../packages/shared_core/lib/src/core/providers/admin_user_provider.dart';
import '../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class DeveloperErrorLogsScreen extends StatefulWidget {
  const DeveloperErrorLogsScreen({Key? key}) : super(key: key);

  @override
  State<DeveloperErrorLogsScreen> createState() =>
      _DeveloperErrorLogsScreenState();
}

class _DeveloperErrorLogsScreenState extends State<DeveloperErrorLogsScreen> {
  String? _franchiseId;
  String? _severity;
  String? _userEmail;
  DateTimeRange? _dateRange;

  void _pickDateRange() async {
    final initial = _dateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400, // You can adjust this value as needed
              maxHeight: 600, // This limits vertical expansion
            ),
            child: Material(
              type: MaterialType.card,
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: child!,
            ),
          ),
        );
      },
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final adminUser = Provider.of<AdminUserProvider>(context).user;

    if (!(adminUser?.isDeveloper ?? false)) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.developerErrorLogsScreenTitle)),
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

    return Scaffold(
      appBar: AppBar(title: Text(loc.developerErrorLogsScreenTitle)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Consumer<FranchiseProvider>(
          builder: (context, franchiseProvider, _) {
            final options = franchiseProvider.viewableFranchises;
            final selectedFranchiseId =
                (_franchiseId == null || _franchiseId == 'all')
                    ? null
                    : _franchiseId;

            return StreamBuilder<List<ErrorLog>>(
              stream: FirestoreService().streamErrorLogsGlobal(
                franchiseId: selectedFranchiseId,
                severity: _severity,
                userId: null,
                start: _dateRange?.start,
                end: _dateRange?.end,
                limit: 250,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint(
                      '❌ Firestore error in streamErrorLogsGlobal: ${snapshot.error}');
                  return Center(child: Text('Failed to load logs.'));
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final logs = snapshot.data ?? [];

                final filtered = logs.where((log) {
                  final userEmail = log.contextData?['userEmail'] ??
                      log.contextData?['email'];
                  return _userEmail == null || _userEmail == userEmail;
                }).toList();

                final allFranchiseIds = {
                  for (final e in logs)
                    if ((e.contextData?['franchiseId'] ?? '')
                        .toString()
                        .isNotEmpty)
                      e.contextData!['franchiseId']
                }.cast<String>();

                final allFranchises = ['all', ...allFranchiseIds.toSet()]
                  ..sort();
                final severities = logs.map((e) => e.severity).toSet().toList()
                  ..sort();
                final userEmails = logs
                    .map((e) => e.contextData?['userEmail'])
                    .whereType<String>()
                    .toSet()
                    .toList()
                  ..sort();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterRow(loc, options, severities, userEmails, theme,
                        colorScheme),
                    const SizedBox(height: 10),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      Center(
                          child: CircularProgressIndicator(
                              color: colorScheme.primary))
                    else if (filtered.isEmpty)
                      Center(child: Text(loc.developerErrorLogsScreenEmpty))
                    else
                      Expanded(
                        child: _DevErrorLogList(
                          logs: filtered,
                          colorScheme: colorScheme,
                          loc: loc,
                          theme: theme,
                          franchises: {
                            for (var f in options) f.id: f.name ?? f.id
                          },
                        ),
                      ),
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
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterRow(
    AppLocalizations loc,
    List franchises,
    List<String> severities,
    List<String> users,
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${loc.developerErrorLogsScreenFranchise}: ',
                    style: theme.textTheme.titleMedium),
                DropdownButton<String>(
                  value: _franchiseId ?? 'all',
                  hint: Text(loc.allFranchisesLabel),
                  items: [
                    DropdownMenuItem(
                        value: 'all', child: Text(loc.allFranchisesLabel)),
                    ...franchises.map((f) => DropdownMenuItem(
                          value: f.id,
                          child: Text(f.name ?? f.id),
                        )),
                  ],
                  onChanged: (val) => setState(() => _franchiseId = val),
                ),
              ],
            ),
            _buildDropdown(
              label: loc.developerErrorLogsScreenSeverity,
              value: _severity,
              options: severities,
              onChanged: (val) => setState(() => _severity = val),
              hint: loc.developerErrorLogsScreenFilterAny,
              theme: theme,
            ),
            _buildDropdown(
              label: loc.developerErrorLogsScreenUser,
              value: _userEmail,
              options: users,
              onChanged: (val) => setState(() => _userEmail = val),
              hint: loc.developerErrorLogsScreenFilterAny,
              theme: theme,
            ),
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required void Function(String?) onChanged,
    required String hint,
    required ThemeData theme,
  }) {
    final safeValue = value != null && options.contains(value) ? value : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: theme.textTheme.titleMedium),
        DropdownButton<String>(
          value: safeValue,
          hint: Text(hint),
          items: [
            DropdownMenuItem(value: null, child: Text(hint)),
            ...options.map((e) => DropdownMenuItem(value: e, child: Text(e))),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DevErrorLogList extends StatelessWidget {
  final List<ErrorLog> logs;
  final ColorScheme colorScheme;
  final AppLocalizations loc;
  final ThemeData theme;
  final Map<String, String> franchises;

  const _DevErrorLogList({
    required this.logs,
    required this.colorScheme,
    required this.loc,
    required this.theme,
    required this.franchises,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, idx) {
        final log = logs[idx];
        final email = log.contextData?['userEmail'] ?? '—';
        final device = log.deviceInfo?['deviceModel'] ??
            log.contextData?['device'] ??
            'unknown';
        final franchiseId = log.contextData?['franchiseId'];
        final franchiseLabel = franchises[franchiseId] ?? franchiseId ?? '—';
        final ts = log.timestamp;

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
            '${loc.developerErrorLogsScreenAt}: ${log.screen}\n${ts != null ? _formatDateTime(ts) : '—'}',
            style: const TextStyle(fontSize: 13),
          ),
          trailing: Icon(Icons.expand_more, color: colorScheme.outline),
          children: [
            ListTile(
              dense: true,
              leading: Icon(Icons.store, color: colorScheme.outline),
              title: Text(
                  '${loc.developerErrorLogsScreenFranchise}: $franchiseLabel'),
              subtitle: Text('${loc.developerErrorLogsScreenUser}: $email'),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.devices, color: colorScheme.outline),
              title: Text('${loc.developerErrorLogsScreenDevice}: $device'),
            ),
            if (log.stackTrace != null && log.stackTrace!.isNotEmpty)
              ListTile(
                dense: true,
                leading: Icon(Icons.bug_report, color: colorScheme.outline),
                title: Text(loc.developerErrorLogsScreenStackTrace),
                subtitle: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    log.stackTrace!,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
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
