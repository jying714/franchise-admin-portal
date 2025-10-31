import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../packages/shared_core/lib/src/core/models/invoice.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';

/// InvoiceDataTable
/// Responsive, paginated, sortable data table for invoices.
/// Supports multi-selection, bulk actions, and contextual menus.
/// Uses localization for all labels and messages.
/// Applies theming and spacing from DesignTokens.
/// Designed for desktop and mobile with adaptive UI.
/// Logs errors using error_logger.
/// Modular for integration in HQ/Owner dashboard sections.

typedef InvoiceSelectionChanged = void Function(List<Invoice> selectedInvoices);
typedef InvoiceActionCallback = Future<void> Function(List<Invoice> invoices);

class InvoiceDataTable extends StatefulWidget {
  final List<Invoice> invoices;
  final InvoiceSelectionChanged? onSelectionChanged;
  final InvoiceActionCallback? onBulkMarkPaid;
  final InvoiceActionCallback? onBulkSendReminder;

  const InvoiceDataTable({
    Key? key,
    required this.invoices,
    this.onSelectionChanged,
    this.onBulkMarkPaid,
    this.onBulkSendReminder,
  }) : super(key: key);

  @override
  State<InvoiceDataTable> createState() => _InvoiceDataTableState();
}

class _InvoiceDataTableState extends State<InvoiceDataTable> {
  final Set<Invoice> _selectedInvoices = {};
  late List<Invoice> _sortedInvoices;
  int _sortColumnIndex = 3; // default sort by Total
  bool _sortAscending = false;
  static const int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _sortedInvoices = List.of(widget.invoices);
    _sortInvoices();
  }

  @override
  void didUpdateWidget(covariant InvoiceDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoices != widget.invoices) {
      _sortedInvoices = List.of(widget.invoices);
      _sortInvoices();
      _selectedInvoices.clear();
      widget.onSelectionChanged?.call(_selectedInvoices.toList());
    }
  }

  void _sortInvoices() {
    _sortedInvoices.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.invoiceNumber.compareTo(b.invoiceNumber);
          break;
        case 1:
          cmp = a.status.toString().compareTo(b.status.toString());
          break;
        case 2:
          cmp = a.issuedAt?.compareTo(b.issuedAt ?? DateTime(0)) ?? 0;
          break;
        case 3:
          cmp = a.total.compareTo(b.total);
          break;
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortInvoices();
    });
  }

  void _onSelectAll(bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedInvoices.addAll(_sortedInvoices);
      } else {
        _selectedInvoices.clear();
      }
      widget.onSelectionChanged?.call(_selectedInvoices.toList());
    });
  }

  void _onSelectRow(bool? selected, Invoice invoice) {
    setState(() {
      if (selected == true) {
        _selectedInvoices.add(invoice);
      } else {
        _selectedInvoices.remove(invoice);
      }
      widget.onSelectionChanged?.call(_selectedInvoices.toList());
    });
  }

  Future<void> _handleBulkAction(
      Future<void> Function(List<Invoice>)? action) async {
    if (action == null) return;
    try {
      await action(_selectedInvoices.toList());
      setState(() {
        _selectedInvoices.clear();
        widget.onSelectionChanged?.call(_selectedInvoices.toList());
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.actionCompleted)),
      );
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'InvoiceDataTable',
        screen: '_handleBulkAction',
        severity: 'error',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.actionFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }

    if (_sortedInvoices.isEmpty) {
      return Center(
        child: Text(loc.noInvoicesFound),
      );
    }

    final columns = [
      DataColumn(
        label: Text(loc.invoiceNumber),
        onSort: _onSort,
        numeric: false,
      ),
      DataColumn(
        label: Text(loc.status),
        onSort: _onSort,
      ),
      DataColumn(
        label: Text(loc.issueDate),
        onSort: _onSort,
      ),
      DataColumn(
        label: Text(loc.total),
        onSort: _onSort,
        numeric: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedInvoices.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: DesignTokens.paddingMd),
            child: Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: Text(loc.markSelectedPaid),
                  onPressed: () => _handleBulkAction(widget.onBulkMarkPaid),
                ),
                const SizedBox(width: DesignTokens.paddingMd),
                ElevatedButton.icon(
                  icon: const Icon(Icons.email),
                  label: Text(loc.sendPaymentReminder),
                  onPressed: () => _handleBulkAction(widget.onBulkSendReminder),
                ),
              ],
            ),
          ),
        PaginatedDataTable(
          header: Text(loc.invoices),
          columns: columns,
          source: _InvoiceDataSource(
            invoices: _sortedInvoices,
            selectedInvoices: _selectedInvoices,
            onSelectRow: _onSelectRow,
            context: context,
          ),
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          rowsPerPage: _rowsPerPage,
          onSelectAll: _onSelectAll,
          showCheckboxColumn: true,
          columnSpacing: DesignTokens.paddingMd,
          horizontalMargin: DesignTokens.paddingMd,
        ),
      ],
    );
  }
}

class _InvoiceDataSource extends DataTableSource {
  final List<Invoice> invoices;
  final Set<Invoice> selectedInvoices;
  final Function(bool?, Invoice) onSelectRow;
  final BuildContext context;

  _InvoiceDataSource({
    required this.invoices,
    required this.selectedInvoices,
    required this.onSelectRow,
    required this.context,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= invoices.length) return null;
    final invoice = invoices[index];
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[InvoiceDataTable] loc is null! Localization not available for this context.');
      // Just skip the row to prevent type errors:
      return null;
    }

    String statusString = invoice.status.toString().split('.').last;
    String issuedDateString = invoice.issuedAt != null
        ? MaterialLocalizations.of(context).formatShortDate(invoice.issuedAt!)
        : '';

    return DataRow.byIndex(
      index: index,
      selected: selectedInvoices.contains(invoice),
      onSelectChanged: (selected) => onSelectRow(selected, invoice),
      cells: [
        DataCell(Text(invoice.invoiceNumber)),
        DataCell(Text(statusString)),
        DataCell(Text(issuedDateString)),
        DataCell(
            Text('${invoice.total.toStringAsFixed(2)} ${invoice.currency}')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => invoices.length;

  @override
  int get selectedRowCount => selectedInvoices.length;
}
