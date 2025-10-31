import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import '../../../../packages/shared_core/lib/src/core/models/error_log.dart';
import 'widgets/paginated_error_log_table.dart';
import 'widgets/error_log_filter_bar.dart';
import 'widgets/error_log_stats_bar.dart';
import '../../../../packages/shared_core/lib/src/core/providers/user_profile_notifier.dart';
import 'package:franchise_admin_portal/widgets/clear_filters_button.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_empty_state_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../packages/shared_core/lib/src/core/providers/franchise_provider.dart';
import '../../../../packages/shared_core/lib/src/core/providers/admin_user_provider.dart';

class ErrorLogsScreen extends StatefulWidget {
  const ErrorLogsScreen({super.key});

  @override
  State<ErrorLogsScreen> createState() => _ErrorLogsScreenState();
}

class _ErrorLogsScreenState extends State<ErrorLogsScreen> {
  String? _severity = 'all';
  String? _source;
  String? _screen;
  DateTime? _start;
  DateTime? _end;
  String? _search;
  bool _showArchived = false;
  bool? _showResolved = false;
  static const _allowedRoles = ['owner', 'developer', 'admin', 'manager'];

  void _updateFilters({
    String? severity,
    String? source,
    String? screen,
    DateTime? start,
    DateTime? end,
    String? search,
  }) {
    setState(() {
      _severity = (severity == null || severity == 'null') ? 'all' : severity;
      _source = source;
      _screen = screen;
      _start = start;
      _end = end;
      _search = search;
    });
  }

  void _clearFilters() {
    setState(() {
      _severity = 'all';
      _source = null;
      _screen = null;
      _start = null;
      _end = null;
      _search = null;
      // Optionally: _showArchived = false; _showResolved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final adminUserProvider = Provider.of<AdminUserProvider>(context);
    final appUser = adminUserProvider.user;

    if (appUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!appUser.roles.any((r) => _allowedRoles.contains(r))) {
      return Scaffold(
        body: AdminEmptyStateWidget(
          title: loc.unauthorizedAccessTitle,
          message: loc.unauthorizedAccessMessage,
          icon: Icons.lock_outline,
          actionLabel: loc.returnHome,
          onAction: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final String? querySeverity =
        (_severity == 'all' || _severity == 'null') ? null : _severity;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(loc.errorLogManagementTitle),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stats bar
          Material(
            elevation: 1,
            color: colorScheme.surface,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
              child: ErrorLogStatsBar(
                severity: querySeverity,
                start: _start,
                end: _end,
              ),
            ),
          ),
          // Filter bar
          Material(
            elevation: 1,
            color: colorScheme.surface,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
              child: ErrorLogFilterBar(
                severity: _severity,
                source: _source,
                screen: _screen,
                start: _start,
                end: _end,
                search: _search,
                onFilterChanged: _updateFilters,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: loc.toggleArchivedTooltip,
                      child: Row(
                        children: [
                          Switch(
                            value: _showArchived,
                            onChanged: (val) =>
                                setState(() => _showArchived = val),
                          ),
                          Text(
                            _showArchived
                                ? loc.showingArchived
                                : loc.hideArchived,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Tooltip(
                      message: loc.resolvedFilterTooltip,
                      child: Row(
                        children: [
                          Text("${loc.resolved}:  "),
                          DropdownButton<bool?>(
                            value: _showResolved,
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(loc.all),
                              ),
                              DropdownMenuItem(
                                value: false,
                                child: Text(loc.unresolvedOnly),
                              ),
                              DropdownMenuItem(
                                value: true,
                                child: Text(loc.resolvedOnly),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _showResolved = val),
                            underline: const SizedBox(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ClearFiltersButton(
                      onClear: _clearFilters,
                      enabled: _severity != 'all' ||
                          _source != null ||
                          _screen != null ||
                          _start != null ||
                          _end != null ||
                          (_search != null && _search!.isNotEmpty),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Error log paginated table
          Expanded(
            child: Container(
              color: colorScheme.background,
              child: StreamBuilder<List<ErrorLog>>(
                stream: context.read<FirestoreService>().streamErrorLogs(
                      franchiseId,
                      severity: querySeverity,
                      source: _source,
                      screen: _screen,
                      start: _start,
                      end: _end,
                      search: _search,
                      archived: _showArchived,
                      showResolved: _showResolved,
                    ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return AdminEmptyStateWidget(
                      title: loc.errorLoadingTitle,
                      message: loc.errorLoadingMessage,
                      icon: Icons.error_outline,
                      actionLabel: loc.retry,
                      onAction: () => setState(() {}),
                    );
                  }
                  final logs = snapshot.data ?? [];
                  if (logs.isEmpty) {
                    return AdminEmptyStateWidget(
                      title: loc.noErrorLogsTitle,
                      message: loc.noErrorLogsMessage,
                      icon: Icons.inbox_rounded,
                    );
                  }
                  // Always use paginated table, regardless of count
                  return PaginatedErrorLogTable(
                    logs: logs,
                    rowsPerPage:
                        5, // Use a small value for best fit, adjust as needed
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
