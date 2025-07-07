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
  String? _severity;
  String? _source;
  String? _screen;
  DateTime? _start;
  DateTime? _end;
  String? _search;

  static const _allowedRoles = ['owner', 'developer', 'admin', 'manager'];

  @override
  Widget build(BuildContext context) {
    print(
        'ErrorLogsScreen build - _severity=$_severity, _source=$_source, _screen=$_screen, _start=$_start, _end=$_end, _search=$_search');
    final userNotifier = Provider.of<UserProfileNotifier>(context);
    final appUser = userNotifier.user;

    if (appUser == null) {
      // Loading state
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // --- Role-based access control ---
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

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Error Logs'),
        backgroundColor: colorScheme.surface,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                elevation: 1,
                color: colorScheme.surface,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: ErrorLogStatsBar(
                    severity: _severity,
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
                    onFilterChanged: ({
                      String? severity,
                      String? source,
                      String? screen,
                      DateTime? start,
                      DateTime? end,
                      String? search,
                    }) {
                      print(
                          'Filter callback: severity=$severity, source=$source, screen=$screen, start=$start, end=$end, search=$search');
                      setState(() {
                        _severity = severity;
                        _source = source;
                        _screen = screen;
                        _start = start;
                        _end = end;
                        _search = search;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Main logs table fills remaining space
              Expanded(
                child: Container(
                  color: colorScheme.background,
                  child: StreamBuilder<List<ErrorLog>>(
                    stream: context.read<FirestoreService>().streamErrorLogs(
                          severity: _severity,
                          source: _source,
                          screen: _screen,
                          start: _start,
                          end: _end,
                          search: _search,
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
                      print(
                          'Filter: severity=$_severity, source=$_source, screen=$_screen, start=$_start, end=$_end, search=$_search');
                      print(
                          'Severities in Firestore: ${logs.map((l) => l.severity).toSet()}');
                      print('ErrorLogTable log count: ${logs.length}');
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
