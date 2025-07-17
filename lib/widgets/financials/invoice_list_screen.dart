import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/invoice.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_search_bar.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_empty_state_widget.dart';
import 'package:franchise_admin_portal/admin/hq_owner/invoice_search_bar.dart';

/// InvoiceListScreen
/// Displays a searchable, filterable list of invoices for the selected franchise(s).
/// Supports CSV export via ExportUtils (not shown here, call from UI as needed).
///
/// Features:
/// - Uses FirestoreService to stream invoice data.
/// - Includes error logging.
/// - Responsive UI with theming from DesignTokens.
/// - Localization for all user-visible strings.
/// - Modular and extensible for future feature additions.
/// - Role-guarded at routing level (not shown here).

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late final FranchiseProvider _franchiseProvider;
  InvoiceSortOrder _selectedSortOrder = InvoiceSortOrder.dateDesc;

  String? _searchTerm;
  String? _statusFilter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _franchiseProvider = Provider.of<FranchiseProvider>(context);
    print(
        '[InvoiceListScreen] didChangeDependencies called, franchiseId=${_franchiseProvider.franchiseId}');
  }

  void _onSearchChanged(String value) {
    print('[InvoiceListScreen] Search term changed: "$value"');
    setState(() {
      _searchTerm = value.trim().isEmpty ? null : value.trim();
    });
  }

  void _onStatusFilterChanged(String? value) {
    print('[InvoiceListScreen] Status filter changed: $value');
    setState(() {
      _statusFilter = value;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Filters the list of invoices client-side based on _searchTerm.
  /// For large datasets, prefer server-side filtering.
  List<Invoice> _applySearchFilter(List<Invoice> invoices) {
    List<Invoice> filtered = invoices;

    if (_searchTerm != null && _searchTerm!.isNotEmpty) {
      final lowerSearch = _searchTerm!.toLowerCase();
      filtered = filtered.where((inv) {
        return inv.invoiceNumber.toLowerCase().contains(lowerSearch) ||
            inv.status
                .toString()
                .split('.')
                .last
                .toLowerCase()
                .contains(lowerSearch);
      }).toList();
    }

    // Sort invoices based on _selectedSortOrder
    filtered.sort((a, b) {
      switch (_selectedSortOrder) {
        case InvoiceSortOrder.dateAsc:
          return a.issuedAt?.compareTo(b.issuedAt ?? DateTime.now()) ?? 0;
        case InvoiceSortOrder.dateDesc:
          return b.issuedAt?.compareTo(a.issuedAt ?? DateTime.now()) ?? 0;
        case InvoiceSortOrder.totalAsc:
          return a.total.compareTo(b.total);
        case InvoiceSortOrder.totalDesc:
          return b.total.compareTo(a.total);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[InvoiceListScreen] loc is null! Localization not available for this context.');
      return const SizedBox.shrink();
    }
    final franchiseId = _franchiseProvider.franchiseId;
    print(
        '[InvoiceListScreen] build called with franchiseId=$franchiseId, searchTerm=$_searchTerm, statusFilter=$_statusFilter');

    if (franchiseId == null) {
      print('[InvoiceListScreen] No franchise selected.');
      return Center(child: Text(loc.noFranchiseSelected));
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.invoiceListTitle)),
      body: Padding(
        padding: const EdgeInsets.all(DesignTokens.paddingLg),
        child: Column(
          children: [
            InvoiceSearchBar(
              initialSearchTerm: _searchTerm,
              initialStatusFilter: _statusFilter,
              initialSortOrder: _selectedSortOrder,
              onSearchChanged: (term) {
                print('[InvoiceListScreen] onSearchChanged triggered: $term');
                setState(() {
                  _searchTerm = term;
                });
              },
              onStatusFilterChanged: (status) {
                print(
                    '[InvoiceListScreen] onStatusFilterChanged triggered: $status');
                setState(() {
                  _statusFilter = status;
                });
              },
              onSortOrderChanged: (order) {
                print(
                    '[InvoiceListScreen] onSortOrderChanged triggered: $order');
                setState(() {
                  _selectedSortOrder = order;
                });
              },
            ),
            const SizedBox(height: DesignTokens.paddingMd),
            Expanded(
              child: StreamBuilder<List<Invoice>>(
                stream: _firestoreService.invoicesStream(
                  franchiseId: franchiseId,
                  status: _statusFilter,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print(
                        '[InvoiceListScreen] StreamBuilder error: ${snapshot.error}');
                    ErrorLogger.log(
                      message: snapshot.error.toString(),
                      source: 'InvoiceListScreen',
                      screen: 'StreamBuilder',
                    );
                    return Center(child: Text(loc.errorLoadingInvoices));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    print(
                        '[InvoiceListScreen] StreamBuilder waiting for data...');
                    return const Center(child: CircularProgressIndicator());
                  }
                  print(
                      '[InvoiceListScreen] StreamBuilder received ${snapshot.data?.length ?? 0} invoices');

                  final invoices = _applySearchFilter(snapshot.data ?? []);
                  print(
                      '[InvoiceListScreen] After applying search & sort, ${invoices.length} invoices remain');

                  if (invoices.isEmpty) {
                    print(
                        '[InvoiceListScreen] No invoices to show after filtering');
                    return AdminEmptyStateWidget(
                      title: loc.noInvoices,
                      message: loc.noInvoicesFound,
                    );
                  }
                  return _buildInvoiceListView(invoices, loc);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceListView(List<Invoice> invoices, AppLocalizations loc) {
    return ListView.separated(
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return ListTile(
          title: Text('${loc.invoiceNumber}: ${invoice.invoiceNumber}'),
          subtitle: Text(
            '${loc.status}: ${invoice.status}, ${loc.total}: ${invoice.total.toStringAsFixed(2)} ${invoice.currency}',
          ),
          trailing:
              _buildStatusChip(invoice.status.toString().split('.').last, loc),
          onTap: () {
            Navigator.of(context)
                .pushNamed('/hq/invoice_detail', arguments: invoice.id);
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status, AppLocalizations loc) {
    final color = _statusColor(status);
    final label = _localizedStatus(status, loc);
    return Chip(
      label: Text(label),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'sent':
        return Colors.blue;
      case 'draft':
        return Colors.grey;
      case 'refunded':
        return Colors.orange;
      case 'voided':
      case 'failed':
        return Colors.black45;
      default:
        return Colors.grey;
    }
  }

  String _localizedStatus(String status, AppLocalizations loc) {
    switch (status.toLowerCase()) {
      case 'paid':
        return loc.paid;
      case 'overdue':
        return loc.overdue;
      case 'sent':
        return loc.sent;
      case 'draft':
        return loc.draft;
      case 'refunded':
        return loc.refunded;
      case 'voided':
        return loc.voided;
      case 'failed':
        return loc.failed;
      default:
        return status;
    }
  }
}
