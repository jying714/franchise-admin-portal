import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../packages/shared_core/lib/src/core/models/platform_invoice.dart';
import '../../../../../packages/shared_core/lib/src/core/providers/franchise_provider.dart';
import '../../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import '../../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_search_bar.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_empty_state_widget.dart';
import 'package:franchise_admin_portal/admin/hq_owner/invoice_search_bar.dart';

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

  List<PlatformInvoice> _applySearchFilter(List<PlatformInvoice> invoices) {
    List<PlatformInvoice> filtered = invoices;

    if (_searchTerm != null && _searchTerm!.isNotEmpty) {
      final lowerSearch = _searchTerm!.toLowerCase();
      filtered = filtered.where((inv) {
        return inv.invoiceNumber.toLowerCase().contains(lowerSearch) ||
            inv.status.toLowerCase().contains(lowerSearch);
      }).toList();
    }

    filtered.sort((a, b) {
      switch (_selectedSortOrder) {
        case InvoiceSortOrder.dateAsc:
          return a.createdAt.compareTo(b.createdAt);
        case InvoiceSortOrder.dateDesc:
          return b.createdAt.compareTo(a.createdAt);
        case InvoiceSortOrder.totalAsc:
          return a.amount.compareTo(b.amount);
        case InvoiceSortOrder.totalDesc:
          return b.amount.compareTo(a.amount);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print('[InvoiceListScreen] loc is null!');
      return const SizedBox.shrink();
    }
    final franchiseId = _franchiseProvider.franchiseId;
    print(
        '[InvoiceListScreen] build called with franchiseId=$franchiseId, searchTerm=$_searchTerm, statusFilter=$_statusFilter');

    if (franchiseId == null) {
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
              child: StreamBuilder<List<PlatformInvoice>>(
                stream: _firestoreService.platformInvoicesStream(
                  franchiseeId: franchiseId,
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
                    return const Center(child: CircularProgressIndicator());
                  }

                  final invoices = _applySearchFilter(snapshot.data ?? []);
                  if (invoices.isEmpty) {
                    return AdminEmptyStateWidget(
                      title: loc.noInvoices,
                      message: _searchTerm != null || _statusFilter != null
                          ? loc.noMatchingInvoices
                          : loc.noInvoicesFound,
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

  Widget _buildInvoiceListView(
      List<PlatformInvoice> invoices, AppLocalizations loc) {
    return ListView.separated(
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return ListTile(
          title: Text('${loc.invoiceNumber}: ${invoice.invoiceNumber}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${loc.status}: ${invoice.status}, ${loc.total}: ${invoice.amount.toStringAsFixed(2)} ${invoice.currency}',
              ),
              if (invoice.paymentMethod != null)
                Text(
                  '${loc.paymentMethod}: ${invoice.paymentMethod}',
                  style: const TextStyle(fontSize: 12),
                ),
              if (invoice.receiptUrl != null)
                Text(
                  '${loc.receipt}: ${invoice.receiptUrl}',
                  style: const TextStyle(
                      fontSize: 12, fontStyle: FontStyle.italic),
                ),
            ],
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusChip(invoice.status, loc, dueDate: invoice.dueDate),
              if (invoice.pdfUrl != null)
                TextButton(
                  onPressed: () async {
                    final url = invoice.pdfUrl!;
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    } else {
                      ErrorLogger.log(
                        message: 'Could not launch PDF: $url',
                        source: 'InvoiceListScreen',
                        screen: '_buildInvoiceListView',
                      );
                    }
                  },
                  child: Text(loc.downloadPdf,
                      style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
          onTap: () {
            Navigator.of(context)
                .pushNamed('/hq/invoice_detail', arguments: invoice.id);
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status, AppLocalizations loc,
      {DateTime? dueDate}) {
    final color = _statusColor(status, dueDate: dueDate);
    final label = _localizedStatus(status, loc);
    return Chip(
      label: Text(label),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  Color _statusColor(String status, {DateTime? dueDate}) {
    final now = DateTime.now();
    if (status.toLowerCase() == 'unpaid' &&
        dueDate != null &&
        dueDate.isBefore(now)) {
      return Colors.redAccent;
    }

    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'partial':
        return Colors.orange;
      case 'unpaid':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _localizedStatus(String status, AppLocalizations loc) {
    switch (status.toLowerCase()) {
      case 'paid':
        return loc.paid;
      case 'overdue':
        return loc.overdue;
      case 'partial':
        return loc.partial;
      case 'unpaid':
        return loc.unpaid;
      default:
        return status;
    }
  }
}
