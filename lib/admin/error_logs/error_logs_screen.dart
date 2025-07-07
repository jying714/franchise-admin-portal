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

  @override
  Widget build(BuildContext context) {
    final userNotifier = Provider.of<UserProfileNotifier>(context);
    final appUser = userNotifier.user;
    if (appUser == null) {
      print('ErrorLogsScreen: Waiting for user profile to load...');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    const ownerEmail = 'j.ying714@gmail.com';
    print(
        'ErrorLogsScreen: appUser?.email = ${appUser.email} (expecting $ownerEmail)');
    if (appUser.email != ownerEmail) {
      print(
          'ErrorLogsScreen: User is not owner. Showing unauthorized message.');
      return const Scaffold(
        body: Center(
          child: Text(
            'You are not authorized to view this page.',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }
    print('ErrorLogsScreen: Owner verified, building error logs UI.');

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Error Logs'),
        backgroundColor: colorScheme.surface,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Use a Column with Expanded for main content, and SingleChildScrollView to prevent overflow.
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
                      return ErrorLogTable(logs: logs);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
