import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/models/error_log.dart';
import 'widgets/error_log_table.dart';
import 'widgets/error_log_filter_bar.dart';
import 'widgets/error_log_stats_bar.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';

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
  bool? _showResolved =
      false; // false = only unresolved, true = only resolved, null = all
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

  @override
  Widget build(BuildContext context) {
    final userNotifier = Provider.of<UserProfileNotifier>(context);
    final appUser = userNotifier.user;

    if (appUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_allowedRoles.contains(appUser.role)) {
      return const Scaffold(
        body: Center(
          child: Text(
            'You are not authorized to view this page.',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    // Map 'all' to null for Firestore query
    final String? querySeverity =
        (_severity == 'all' || _severity == 'null') ? null : _severity;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        toolbarHeight:
            0, // <-- Hide default AppBar UI, but keep elevation if needed
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------- SCREEN LABEL START --------
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                child: Text(
                  'Error Log Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                ),
              ),
              // -------- SCREEN LABEL END --------
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
                        // Hide Archived Toggle
                        Row(
                          children: [
                            Switch(
                              value: _showArchived,
                              onChanged: (val) =>
                                  setState(() => _showArchived = val),
                            ),
                            Text(
                              _showArchived
                                  ? "Showing Archived"
                                  : "Hide Archived",
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        // Resolved Filter Dropdown
                        Row(
                          children: [
                            const Text("Resolved:  "),
                            DropdownButton<bool?>(
                              value: _showResolved,
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text("All"),
                                ),
                                DropdownMenuItem(
                                  value: false,
                                  child: Text("Unresolved Only"),
                                ),
                                DropdownMenuItem(
                                  value: true,
                                  child: Text("Resolved Only"),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _showResolved = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Container(
                  color: colorScheme.background,
                  child: StreamBuilder<List<ErrorLog>>(
                    stream: context.read<FirestoreService>().streamErrorLogs(
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
                        return Center(
                          child: Text(
                            'Error loading error logs',
                            style: TextStyle(color: colorScheme.error),
                          ),
                        );
                      }
                      final logs = snapshot.data ?? [];
                      return ErrorLogTable(logs: logs);
                    },
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
