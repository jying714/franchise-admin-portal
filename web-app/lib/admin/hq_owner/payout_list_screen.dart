import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/admin/features/alerts/alerts_repository.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/widgets/financials/payouts_filter_bar.dart';
import 'package:franchise_admin_portal/widgets/financials/payout_detail_dialog.dart';
import 'package:franchise_admin_portal/widgets/financials/payout_note_editor.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/attachment_uploader.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/bulk_ops_bar.dart';

class PayoutListScreen extends StatefulWidget {
  const PayoutListScreen({super.key});

  @override
  State<PayoutListScreen> createState() => _PayoutListScreenState();
}

class _PayoutListScreenState extends State<PayoutListScreen> {
  Set<String> _selectedPayoutIds = {};
  bool _bulkLoading = false;
  String? _bulkError;

  void _retry() => setState(() {});

  Future<void> _bulkUpdateStatus(String status) async {
    if (_selectedPayoutIds.isEmpty) return;
    setState(() {
      _bulkLoading = true;
      _bulkError = null;
    });
    try {
      final service =
          Provider.of<shared.FirestoreService>(context, listen: false);
      await service.bulkUpdatePayoutStatus(
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
      shared.ErrorLogger.log(
        message: 'Bulk update status failed: $e',
        stack: stack.toString(),
        source: 'PayoutListScreen',
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
          Provider.of<shared.FranchiseProvider>(context, listen: false)
              .franchiseId;
      final service =
          Provider.of<shared.FirestoreService>(context, listen: false);
      await service.exportPayoutsToCsv(franchiseId: franchiseId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.featureComingSoon('Export'))),
      );
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Export payouts failed: $e',
        stack: stack.toString(),
        source: 'PayoutListScreen',
        severity: 'error',
      );
    }
  }

  Future<void> _deleteSelectedPayouts() async {
    try {
      final service =
          Provider.of<shared.FirestoreService>(context, listen: false);
      for (final id in _selectedPayoutIds) {
        await service.deletePayout(id);
      }
      setState(() => _selectedPayoutIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deleteSuccess)),
      );
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Bulk delete payouts failed: $e',
        stack: stack.toString(),
        source: 'PayoutListScreen',
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
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filterProvider = Provider.of<shared.PayoutFilterProvider>(context);
    final franchiseProvider = Provider.of<shared.FranchiseProvider>(context);
    final user = Provider.of<shared.AdminUserProvider>(context).user;

    final franchiseId = franchiseProvider.franchiseId ?? '';

    if (franchiseId.isEmpty) {
      return EmptyStateWidget(
        title: 'Franchise Not Selected',
        message: 'Please select a franchise to view payouts.',
        onRetry: _retry,
      );
    }

    final alertsRepo = AlertsRepository(
        firestoreService:
            Provider.of<shared.FirestoreService>(context, listen: false));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD53417),
        title: Text(loc.payoutStatus,
            style: theme.textTheme.titleLarge
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PayoutsFilterBar(developerMode: user?.isDeveloper == true),
            const SizedBox(height: 10),
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
            Expanded(
              child: Consumer<shared.PayoutFilterProvider>(
                builder: (context, filterProvider, _) {
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: Provider.of<shared.FirestoreService>(context,
                            listen: false)
                        .getPayoutsForFranchise(
                      franchiseId: franchiseId,
                      status: filterProvider.status == 'all'
                          ? null
                          : filterProvider.status,
                      searchQuery: filterProvider.searchQuery.isNotEmpty
                          ? filterProvider.searchQuery
                          : null,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        shared.ErrorLogger.log(
                          message: 'Failed to load payouts: ${snapshot.error}',
                          stack: snapshot.stackTrace?.toString(),
                          source: 'PayoutListScreen',
                          severity: 'error',
                        );
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
                            child: Text(
                                loc.noPayoutsFound ?? "No payouts found."));
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
                                        _toggleSelectAll(payouts, val))),
                            const DataColumn(label: Text('Payout ID')),
                            const DataColumn(label: Text('Status')),
                            const DataColumn(label: Text('Amount')),
                            const DataColumn(label: Text('Created')),
                            const DataColumn(label: Text('Sent')),
                            const DataColumn(label: Text('Failed')),
                            const DataColumn(label: Text('Method')),
                            const DataColumn(label: Text('Account')),
                            const DataColumn(label: Text('Notes')),
                            const DataColumn(label: Icon(Icons.attachment)),
                            const DataColumn(label: Icon(Icons.more_horiz)),
                          ],
                          rows: payouts.map((payout) {
                            final id = payout['id'] as String;
                            return DataRow(
                              selected: _selectedPayoutIds.contains(id),
                              onSelectChanged: (selected) =>
                                  _toggleRowSelected(id, selected),
                              cells: [
                                DataCell(Checkbox(
                                    value: _selectedPayoutIds.contains(id),
                                    onChanged: (selected) =>
                                        _toggleRowSelected(id, selected))),
                                DataCell(Text(id)),
                                DataCell(_StatusChip(
                                    status: payout['status'],
                                    theme: theme,
                                    loc: loc)),
                                DataCell(Text((payout['amount'] ?? 0)
                                    .toStringAsFixed(2))),
                                DataCell(Text(_formatDate(
                                    payout['created_at'], context))),
                                DataCell(Text(
                                    _formatDate(payout['sent_at'], context))),
                                DataCell(Text(
                                    _formatDate(payout['failed_at'], context))),
                                DataCell(Text(payout['method'] ?? '')),
                                DataCell(Text(
                                    payout['bank_account_last4'] != null
                                        ? '****${payout['bank_account_last4']}'
                                        : '')),
                                DataCell(Text(
                                    payout['comments']?.length?.toString() ??
                                        '')),
                                DataCell(IconButton(
                                  icon: const Icon(Icons.attach_file),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (ctx) => Dialog(
                                      child: SizedBox(
                                        width: 420,
                                        child: AttachmentUploader(payoutId: id),
                                      ),
                                    ),
                                  ),
                                )),
                                DataCell(PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'Details') {
                                      await showDialog(
                                        context: context,
                                        builder: (ctx) => Dialog(
                                          child: SizedBox(
                                            width: 580,
                                            child: PayoutDetailDialog(
                                                payoutId: id),
                                          ),
                                        ),
                                      );
                                      _retry();
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                        value: 'Details',
                                        child: Text('Details')),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(dynamic value, BuildContext context) {
    if (value == null) return '';
    try {
      final dt = value is DateTime ? value : DateTime.parse(value.toString());
      return MaterialLocalizations.of(context).formatShortDate(dt);
    } catch (_) {
      return value.toString();
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String? status;
  final ThemeData theme;
  final AppLocalizations loc;

  const _StatusChip(
      {super.key,
      required this.status,
      required this.theme,
      required this.loc});

  @override
  Widget build(BuildContext context) {
    Color chipColor = theme.colorScheme.outline;
    String label = status?.toUpperCase() ?? 'UNKNOWN';

    switch (status?.toLowerCase()) {
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
    }

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    );
  }
}
