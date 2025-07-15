import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/admin/features/alerts/alerts_repository.dart';
import 'package:franchise_admin_portal/core/models/alert_model.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/payouts_filter_bar.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/payout_detail_dialog.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/payout_note_editor.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/attachment_uploader.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/bulk_ops_bar.dart';
import 'package:franchise_admin_portal/core/providers/payout_filter_provider.dart';

class PayoutListScreen extends StatefulWidget {
  const PayoutListScreen({Key? key}) : super(key: key);

  @override
  State<PayoutListScreen> createState() => _PayoutListScreenState();
}

class _PayoutListScreenState extends State<PayoutListScreen> {
  Set<String> _selectedPayoutIds = {};
  bool _bulkLoading = false;
  String? _bulkError;

  void _retry() => setState(() {});

  // --- BULK ACTIONS ---
  Future<void> _bulkUpdateStatus(String status) async {
    if (_selectedPayoutIds.isEmpty) return;
    setState(() {
      _bulkLoading = true;
      _bulkError = null;
    });
    try {
      await FirestoreService().bulkUpdatePayoutStatus(
        _selectedPayoutIds.toList(),
        status,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.bulkStatusSuccess)),
      );
      setState(() {
        _selectedPayoutIds.clear();
        _bulkLoading = false;
      });
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Bulk update status failed: $e',
        stack: stack.toString(),
        source: 'PayoutListScreen',
        screen: 'bulkUpdateStatus',
        severity: 'error',
      );
      setState(() {
        _bulkError = e.toString();
        _bulkLoading = false;
      });
    }
  }

  Future<void> _exportSelectedPayouts() async {
    try {
      final franchiseId =
          Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
      await FirestoreService().exportPayoutsToCsv(
        franchiseId: franchiseId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.featureComingSoon('Export'))),
      );
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Export payouts failed: $e',
        stack: stack.toString(),
        source: 'PayoutListScreen',
        screen: 'exportSelectedPayouts',
        severity: 'error',
      );
    }
  }

  Future<void> _deleteSelectedPayouts() async {
    try {
      for (final id in _selectedPayoutIds) {
        await FirestoreService().deletePayout(id);
      }
      setState(() => _selectedPayoutIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deleteSuccess)),
      );
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Bulk delete payouts failed: $e',
        stack: stack.toString(),
        source: 'PayoutListScreen',
        screen: 'deleteSelectedPayouts',
        severity: 'error',
      );
    }
  }

  void _toggleRowSelected(String id, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedPayoutIds.add(id);
      } else {
        _selectedPayoutIds.remove(id);
      }
    });
  }

  void _toggleSelectAll(List<dynamic> payouts, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedPayoutIds =
            payouts.map<String>((e) => e['id'] as String).toSet();
      } else {
        _selectedPayoutIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      final loc = AppLocalizations.of(context)!;
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final filterProvider = Provider.of<PayoutFilterProvider>(context);
      final filterStatus = filterProvider.status;
      final filterSearch = filterProvider.searchQuery;

      // PROVIDERS WITH SAFETY CHECKS
      final userNotifier =
          Provider.of<UserProfileNotifier?>(context, listen: true);
      if (userNotifier == null) {
        return EmptyStateWidget(
          title: 'UserProfileNotifier not found',
          message:
              'UserProfileNotifier provider is missing from the widget tree.',
          imageAsset: BrandingConfig.bannerPlaceholder,
          onRetry: _retry,
          buttonText: AppLocalizations.of(context)?.retry ?? 'Retry',
        );
      }
      final user = userNotifier.user;
      if (user == null) {
        return EmptyStateWidget(
          title: 'Not Authenticated',
          message: 'User is not authenticated. Please log in again.',
          imageAsset: BrandingConfig.bannerPlaceholder,
          onRetry: _retry,
          buttonText: AppLocalizations.of(context)?.retry ?? 'Retry',
        );
      }

      final franchiseProvider =
          Provider.of<FranchiseProvider?>(context, listen: true);
      if (franchiseProvider == null) {
        return EmptyStateWidget(
          title: 'FranchiseProvider not found',
          message: 'FranchiseProvider is missing from the widget tree.',
          imageAsset: BrandingConfig.bannerPlaceholder,
          onRetry: _retry,
          buttonText: AppLocalizations.of(context)?.retry ?? 'Retry',
        );
      }
      final franchiseId = franchiseProvider.franchiseId;
      if (franchiseId == null || franchiseId.isEmpty) {
        return EmptyStateWidget(
          title: 'Franchise Not Selected',
          message:
              'No franchise is currently selected. Please choose a franchise and try again.',
          imageAsset: BrandingConfig.bannerPlaceholder,
          onRetry: _retry,
          buttonText: AppLocalizations.of(context)?.retry ?? 'Retry',
        );
      }

      final alertsRepo = AlertsRepository();
      final allowedRoles = ['hq_owner', 'hq_manager', 'developer'];
      if (!user.roles.any((role) => allowedRoles.contains(role))) {
        Future.microtask(() async {
          try {
            await ErrorLogger.log(
              message: "Unauthorized PayoutListScreen access attempt.",
              source: "PayoutListScreen",
              screen: "PayoutListScreen",
              severity: "warning",
              contextData: {
                'roles': user.roles,
                'attempt': 'access',
                'userId': user.id ?? "unknown",
              },
            );
          } catch (e) {}
        });
        return Scaffold(
          body: Center(
            child: Card(
              color: colorScheme.errorContainer,
              margin: const EdgeInsets.all(32),
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, color: colorScheme.error, size: 48),
                    const SizedBox(height: 18),
                    Text(loc.unauthorizedAccessTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(loc.unauthorizedAccessMessage,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onErrorContainer)),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.home),
                      onPressed: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                      label: Text(loc.returnHome),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // ------ MAIN UI -------
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFD53417),
          elevation: 0,
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null,
          title: Text(
            loc.payoutStatus,
            style: theme.textTheme.titleLarge
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: colorScheme.background,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Filter/Search Bar (PROVIDER CONTROLLED) ---
              PayoutsFilterBar(
                developerMode: user.roles.contains('developer'),
              ),
              const SizedBox(height: 10),

              // --- BulkOpsBar (always visible) ---
              BulkOpsBar(
                selectedCount: _selectedPayoutIds.length,
                onMarkSent: _selectedPayoutIds.isEmpty
                    ? null
                    : () => _bulkUpdateStatus('sent'),
                onMarkFailed: _selectedPayoutIds.isEmpty
                    ? null
                    : () => _bulkUpdateStatus('failed'),
                onResetPending: _selectedPayoutIds.isEmpty
                    ? null
                    : () => _bulkUpdateStatus('pending'),
                onExport:
                    _selectedPayoutIds.isEmpty ? null : _exportSelectedPayouts,
                onDelete:
                    _selectedPayoutIds.isEmpty ? null : _deleteSelectedPayouts,
              ),
              const SizedBox(height: 10),

              // --- Alerts ---
              StreamBuilder<List<AlertModel>>(
                stream: alertsRepo
                    .watchActiveAlerts(franchiseId: franchiseId)
                    .map((alerts) => alerts
                        .where((a) =>
                            a.type == 'payout_failed' ||
                            a.type == 'payout_pending')
                        .toList()),
                builder: (context, alertSnap) {
                  final payoutAlerts = alertSnap.data ?? [];
                  if (payoutAlerts.isNotEmpty) {
                    final alert = payoutAlerts.first;
                    final levelColor = alert.level == 'critical'
                        ? colorScheme.error
                        : (alert.level == 'warning'
                            ? colorScheme.secondary
                            : colorScheme.primary);
                    return Card(
                      color: levelColor.withOpacity(0.15),
                      margin: const EdgeInsets.only(bottom: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.adminCardRadius),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.warning_rounded, color: levelColor),
                        title: Text(
                          alert.title.isNotEmpty
                              ? alert.title
                              : (alert.body.isNotEmpty
                                  ? alert.body
                                  : loc.payoutAlert),
                        ),
                        subtitle: alert.body.isNotEmpty
                            ? Text(alert.body)
                            : (alert.createdAt != null
                                ? Text(MaterialLocalizations.of(context)
                                    .formatFullDate(alert.createdAt))
                                : null),
                        trailing: IconButton(
                          icon: Icon(Icons.close, color: theme.disabledColor),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content:
                                    Text(loc.featureComingSoon('Dismiss'))));
                          },
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // --- Main Table Fills Height ---
              Expanded(
                child: Consumer<PayoutFilterProvider>(
                  builder: (context, filterProvider, _) {
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: FirestoreService().getPayoutsForFranchise(
                        franchiseId: franchiseId,
                        status: filterProvider.status == 'all'
                            ? null
                            : filterProvider.status,
                        searchQuery: filterProvider.searchQuery.isNotEmpty
                            ? filterProvider.searchQuery
                            : null,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          try {
                            ErrorLogger.log(
                              message:
                                  'PayoutListScreen: failed to load payouts\n${snapshot.error}',
                              stack: snapshot.stackTrace?.toString(),
                            );
                          } catch (e) {}
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(loc.failedToLoadSummary,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(color: colorScheme.error)),
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: Text(loc.retry),
                                  onPressed: _retry,
                                ),
                              ],
                            ),
                          );
                        }
                        final payouts = snapshot.data ?? [];
                        if (payouts.isEmpty) {
                          return Center(
                            child: Text(loc.noPayoutsFound ??
                                "No payouts match your filters."),
                          );
                        }

                        final allRowsSelected = payouts.every(
                                (p) => _selectedPayoutIds.contains(p['id'])) &&
                            payouts.isNotEmpty;

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(
                                label: Checkbox(
                                  value: allRowsSelected,
                                  onChanged: (val) =>
                                      _toggleSelectAll(payouts, val),
                                ),
                              ),
                              DataColumn(
                                  label: Text(loc.payoutId ?? "Payout ID")),
                              DataColumn(label: Text(loc.status)),
                              DataColumn(label: Text(loc.amount)),
                              DataColumn(label: Text(loc.createdAt)),
                              DataColumn(label: Text(loc.sentAt ?? "Sent At")),
                              DataColumn(
                                  label: Text(loc.failedAt ?? "Failed At")),
                              DataColumn(
                                  label: Text(loc.payoutMethod ?? "Method")),
                              DataColumn(
                                  label: Text(loc.bankAccount ?? "Account")),
                              DataColumn(label: Text(loc.notes ?? "Notes")),
                              DataColumn(label: Icon(Icons.attachment)),
                              DataColumn(label: Icon(Icons.more_horiz)),
                            ],
                            rows: [
                              for (final payout in payouts)
                                DataRow(
                                  selected:
                                      _selectedPayoutIds.contains(payout['id']),
                                  onSelectChanged: (selected) =>
                                      _toggleRowSelected(
                                          payout['id'], selected),
                                  cells: [
                                    DataCell(Checkbox(
                                      value: _selectedPayoutIds
                                          .contains(payout['id']),
                                      onChanged: (selected) =>
                                          _toggleRowSelected(
                                              payout['id'], selected),
                                    )),
                                    DataCell(Text(payout['id'] ?? '')),
                                    DataCell(_StatusChip(
                                        status: payout['status'],
                                        theme: theme,
                                        loc: loc)),
                                    DataCell(Text(
                                        payout['amount']?.toStringAsFixed(2) ??
                                            '')),
                                    DataCell(Text(_formatDate(
                                        payout['created_at'], context))),
                                    DataCell(Text(_formatDate(
                                        payout['sent_at'], context))),
                                    DataCell(Text(_formatDate(
                                        payout['failed_at'], context))),
                                    DataCell(Text(payout['method'] ?? '')),
                                    DataCell(Text(payout[
                                                'bank_account_last4'] !=
                                            null
                                        ? '****${payout['bank_account_last4']}'
                                        : '')),
                                    DataCell(
                                      payout['comments'] != null &&
                                              payout['comments'].isNotEmpty
                                          ? Row(
                                              children: [
                                                Icon(Icons.sticky_note_2,
                                                    color: Colors.amber[800]),
                                                SizedBox(width: 4),
                                                Text(
                                                    '${payout['comments'].length}'),
                                              ],
                                            )
                                          : Icon(Icons.sticky_note_2_outlined,
                                              color: Colors.grey),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.attach_file),
                                        tooltip:
                                            loc.attachments ?? "Attachments",
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => Dialog(
                                              child: SizedBox(
                                                width: 400,
                                                child: AttachmentUploader(
                                                  payoutId: payout['id'],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      PopupMenuButton<String>(
                                        onSelected: (v) async {
                                          if (v == 'Details') {
                                            await showDialog(
                                              context: context,
                                              builder: (ctx) => Dialog(
                                                child: SizedBox(
                                                  width: 580,
                                                  child: PayoutDetailDialog(
                                                    payoutId: payout['id'],
                                                  ),
                                                ),
                                              ),
                                            );
                                            _retry();
                                          } else if (v == 'ResetPending') {
                                            await FirestoreService()
                                                .retryPayout(payout['id']);
                                            _retry();
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(loc
                                                      .featureComingSoon(v))),
                                            );
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          PopupMenuItem(
                                            value: 'Export',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.download,
                                                    size: 18),
                                                const SizedBox(width: 6),
                                                Text(loc.export ?? "Export"),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'Details',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.info_outline,
                                                    size: 18),
                                                const SizedBox(width: 6),
                                                Text(loc.details ?? "Details"),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'ResetPending',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.restart_alt,
                                                    size: 18,
                                                    color: Colors.orange),
                                                const SizedBox(width: 6),
                                                Text(loc.resetToPending ??
                                                    "Reset to Pending"),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.playlist_add_check_circle),
                      label: Text(loc.featureComingSoon('Bulk Ops')),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(loc.featureComingSoon('Bulk Ops'))),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Unexpected error in PayoutListScreen build: $e',
        stack: stack.toString(),
        source: 'PayoutListScreen',
        screen: 'build',
        severity: 'error',
      );
      return Center(
        child: Text('Unexpected error loading screen. Please try again later.'),
      );
    }
  }

  static String _formatDate(dynamic value, BuildContext context) {
    if (value == null) return '';
    if (value is DateTime) {
      return MaterialLocalizations.of(context).formatShortDate(value);
    }
    if (value is String) {
      try {
        final dt = DateTime.parse(value);
        return MaterialLocalizations.of(context).formatShortDate(dt);
      } catch (_) {
        return value;
      }
    }
    return value.toString();
  }
}

class _StatusChip extends StatelessWidget {
  final String? status;
  final ThemeData theme;
  final AppLocalizations loc;
  const _StatusChip(
      {required this.status, required this.theme, required this.loc});

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    String label;
    switch (status) {
      case 'pending':
        chipColor = theme.colorScheme.primary;
        label = loc.pending;
        break;
      case 'sent':
        chipColor = theme.colorScheme.secondary;
        label = loc.sent;
        break;
      case 'failed':
        chipColor = theme.colorScheme.error;
        label = loc.failed;
        break;
      default:
        chipColor = theme.colorScheme.outline;
        label = status ?? '';
    }
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    );
  }
}
