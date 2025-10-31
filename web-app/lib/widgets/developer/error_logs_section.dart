import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import '../../../../packages/shared_core/lib/src/core/providers/franchise_provider.dart';
import '../../../../packages/shared_core/lib/src/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/admin/developer/developer_error_logs_screen.dart';
import '../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';

class ErrorLogsSection extends StatefulWidget {
  final String? franchiseId;
  const ErrorLogsSection({Key? key, this.franchiseId}) : super(key: key);

  @override
  State<ErrorLogsSection> createState() => _ErrorLogsSectionState();
}

class _ErrorLogsSectionState extends State<ErrorLogsSection> {
  bool _loading = true;
  String? _errorMsg;
  List<ErrorLogSummary> _logs = [];
  String? _filterSeverity;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  @override
  void didUpdateWidget(covariant ErrorLogsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.franchiseId != widget.franchiseId) {
      _fetchLogs();
    }
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final allLogs = await FirestoreService().getErrorLogSummaries();

      print('✅ Retrieved ${allLogs.length} logs from Firestore');
      for (final log in allLogs) {
        print(
            '[DEBUG] Log => ${log.timestamp} | ${log.severity} | ${log.message}');
      }

      final filteredLogs = _filterSeverity == null
          ? allLogs
          : allLogs.where((log) => log.severity == _filterSeverity).toList();
      print('👀 Setting logs: ${filteredLogs.length} logs');
      setState(() {
        _logs = filteredLogs;
        _loading = false;
      });
    } catch (e, stack) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });

      await ErrorLogger.log(
        message: 'Failed to load error logs: $e',
        stack: stack.toString(),
        source: 'ErrorLogsSection',
        screen: 'DeveloperDashboardScreen',
        severity: 'warning',
        contextData: {'franchiseId': widget.franchiseId},
      );
    }
  }

  void _onSeverityFilterChanged(String? newValue) {
    setState(() {
      _filterSeverity = newValue;
    });
    _fetchLogs(); // Refetch based on new severity filter
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Loaded error_logs_section');
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
    final isDeveloper = adminUser?.roles.contains('developer') ?? false;

    // Developer-only access guard
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

    final isAllFranchises = widget.franchiseId == 'all';
    final titleFranchiseLabel = isAllFranchises
        ? (loc.allFranchisesLabel ?? "All Franchises")
        : (widget.franchiseId ?? "Unknown Franchise");

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.errorLogsSectionTitle} — $titleFranchiseLabel',
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
            _buildFilterRow(loc, colorScheme, theme),
            const SizedBox(height: 18),
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
                          '${loc.errorLogsSectionError}\n$_errorMsg',
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
            else ...[
              if (_logs.isEmpty) Center(child: Text(loc.errorLogsSectionEmpty)),
              _ErrorLogList(
                logs: _logs,
                filterSeverity: _filterSeverity,
                colorScheme: colorScheme,
                loc: loc,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: Text(loc.errorLogsSectionViewAll),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DeveloperErrorLogsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              _ComingSoonCard(
                icon: Icons.query_stats,
                title: loc.errorLogsSectionAnalyticsComingSoon,
                subtitle: loc.errorLogsSectionAnalyticsDesc,
                colorScheme: colorScheme,
                theme: theme,
              ),
              _ComingSoonCard(
                icon: Icons.lightbulb_outline,
                title: loc.errorLogsSectionAIInsightsComingSoon,
                subtitle: loc.errorLogsSectionAIInsightsDesc,
                colorScheme: colorScheme,
                theme: theme,
              ),
            ],
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
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: loc.reload,
          onPressed: _fetchLogs,
        ),
      ],
    );
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

class _ErrorLogList extends StatelessWidget {
  final List<ErrorLogSummary> logs;
  final String? filterSeverity;
  final ColorScheme colorScheme;
  final AppLocalizations loc;

  const _ErrorLogList({
    required this.logs,
    required this.filterSeverity,
    required this.colorScheme,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = filterSeverity == null
        ? logs
        : logs.where((log) => log.severity == filterSeverity).toList();
    if (filtered.isEmpty) {
      return Center(child: Text(loc.errorLogsSectionEmpty));
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final log = filtered[idx];
          return ListTile(
            leading: Icon(
              _iconForSeverity(log.severity),
              color: _colorForSeverity(log.severity),
            ),
            title: Text(log.message),
            subtitle: Text(
              '${loc.errorLogsSectionAt} ${log.screen} — ${_formatDateTime(log.timestamp)}'
              '${log.franchiseId != null ? " — Franchise: ${log.franchiseId}" : ""}',
            ),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
            ),
            onTap: () {
              // TODO: Show detailed error log modal
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.comingSoon)),
              );
            },
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

// Simple DTO for demonstration; replace with your error log model
class ErrorLogSummary {
  final String id;
  final DateTime timestamp;
  final String message;
  final String severity;
  final String screen;
  final String? franchiseId;

  ErrorLogSummary({
    required this.id,
    required this.timestamp,
    required this.message,
    required this.severity,
    required this.screen,
    this.franchiseId,
  });
}
