import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../../packages/shared_core/lib/src/core/models/invoice.dart';
import '../../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import '../../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// InvoiceDetailScreen
/// Displays full invoice detail: line items, totals, status, notes, audit trail.
///
/// Features:
/// - Fetches invoice by ID via FirestoreService.
/// - Shows detailed line items with quantities and prices.
/// - Displays invoice metadata: invoice number, dates, status, totals.
/// - Shows audit trail with timestamps and user actions.
/// - Error handling and loading states with error logging.
/// - Localized UI strings.
/// - Styled using centralized DesignTokens.
/// - Modular for future enhancements.

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({Key? key, required this.invoiceId})
      : super(key: key);

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  late Future<Invoice?> _invoiceFuture;

  @override
  void initState() {
    super.initState();
    _invoiceFuture = _firestoreService.getInvoiceById(widget.invoiceId);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[InvoiceDetailScreen] loc is null! Localization not available for this context.');
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${loc.invoice} ${widget.invoiceId}'),
      ),
      body: FutureBuilder<Invoice?>(
        future: _invoiceFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            ErrorLogger.log(
              message: snapshot.error.toString(),
              source: 'InvoiceDetailScreen',
              screen: 'FutureBuilder',
              severity: 'error',
              contextData: {'invoiceId': widget.invoiceId},
            );
            return Center(child: Text(loc.errorLoadingInvoice));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final invoice = snapshot.data;
          if (invoice == null) {
            return Center(child: Text(loc.invoiceNotFound));
          }
          return _buildInvoiceDetail(context, invoice, loc);
        },
      ),
    );
  }

  Widget _buildInvoiceDetail(
      BuildContext context, Invoice invoice, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInvoiceHeader(invoice, loc),
          const SizedBox(height: DesignTokens.paddingMd),
          _buildLineItemsList(invoice, loc),
          const SizedBox(height: DesignTokens.paddingMd),
          _buildTotalsSection(invoice, loc),
          const SizedBox(height: DesignTokens.paddingMd),
          _buildStatusSection(invoice, loc),
          const SizedBox(height: DesignTokens.paddingMd),
          _buildAuditTrail(invoice, loc),
          const SizedBox(height: DesignTokens.paddingMd),
          _buildSupportNotes(invoice, loc),
        ],
      ),
    );
  }

  Widget _buildInvoiceHeader(Invoice invoice, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${loc.invoiceNumber}: ${invoice.invoiceNumber}',
            style: _headerStyle()),
        Text('${loc.issueDate}: ${_formatDate(invoice.issuedAt)}'),
        Text('${loc.dueDate}: ${_formatDate(invoice.dueAt)}'),
        Text('${loc.currency}: ${invoice.currency}'),
      ],
    );
  }

  Widget _buildLineItemsList(Invoice invoice, AppLocalizations loc) {
    if (invoice.items.isEmpty) {
      return Text(loc.noLineItems);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.lineItems, style: _headerStyle()),
        const SizedBox(height: 8),
        ...invoice.items.map((item) => _buildLineItemRow(item, loc)).toList(),
      ],
    );
  }

  Widget _buildLineItemRow(InvoiceLineItem item, AppLocalizations loc) {
    final total = (item.unitPrice * item.quantity) + (item.tax ?? 0.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(item.description)),
          Expanded(flex: 1, child: Text('${item.quantity}')),
          Expanded(flex: 2, child: Text(item.unitPrice.toStringAsFixed(2))),
          Expanded(flex: 2, child: Text(total.toStringAsFixed(2))),
        ],
      ),
    );
  }

  Widget _buildTotalsSection(Invoice invoice, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.totals, style: _headerStyle()),
        const SizedBox(height: 8),
        _buildTotalRow(loc.subtotal, invoice.subtotal),
        _buildTotalRow(loc.tax, invoice.tax),
        _buildTotalRow(loc.total, invoice.total, isBold: true),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    final style = isBold
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        : const TextStyle(fontSize: 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(amount.toStringAsFixed(2), style: style),
        ],
      ),
    );
  }

  Widget _buildStatusSection(Invoice invoice, AppLocalizations loc) {
    return Row(
      children: [
        Text('${loc.status}: ', style: _headerStyle()),
        _buildStatusChip(invoice.status, loc),
      ],
    );
  }

  Widget _buildStatusChip(InvoiceStatus status, AppLocalizations loc) {
    final color = _statusColor(status);
    final label = _localizedStatus(status, loc);
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  Widget _buildAuditTrail(Invoice invoice, AppLocalizations loc) {
    if (invoice.auditTrail.isEmpty) {
      return Text(loc.noAuditTrail);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.auditTrail, style: _headerStyle()),
        const SizedBox(height: 8),
        ...invoice.auditTrail.map((event) => _buildAuditEventRow(event, loc)),
      ],
    );
  }

  Widget _buildAuditEventRow(InvoiceAuditEvent event, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '${_formatDateTime(event.timestamp)} - ${event.eventType} - ${event.userId} ${event.notes ?? ''}',
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  Widget _buildSupportNotes(Invoice invoice, AppLocalizations loc) {
    if (invoice.supportNotes.isEmpty) {
      return Text(loc.noSupportNotes);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.supportNotes, style: _headerStyle()),
        const SizedBox(height: 8),
        ...invoice.supportNotes.map((note) => _buildSupportNoteRow(note, loc)),
      ],
    );
  }

  Widget _buildSupportNoteRow(InvoiceSupportNote note, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '${_formatDateTime(note.createdAt)} - ${note.userId}: ${note.content}',
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }

  TextStyle _headerStyle() =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return MaterialLocalizations.of(context).formatShortDate(date);
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final dateStr = MaterialLocalizations.of(context).formatShortDate(local);
    final timeStr = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: false,
    );
    return '$dateStr $timeStr';
  }

  Color _statusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.sent:
        return Colors.blue;
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.refunded:
        return Colors.orange;
      case InvoiceStatus.voided:
      case InvoiceStatus.failed:
        return Colors.black45;
      case InvoiceStatus.archived:
        return Colors.grey.shade600;
      case InvoiceStatus.viewed:
        return Colors.lightBlue;
      case InvoiceStatus.open: // <--- add this case
        return Colors.teal;
    }
  }

  String _localizedStatus(InvoiceStatus status, AppLocalizations loc) {
    switch (status) {
      case InvoiceStatus.paid:
        return loc.paid;
      case InvoiceStatus.overdue:
        return loc.overdue;
      case InvoiceStatus.sent:
        return loc.sent;
      case InvoiceStatus.draft:
        return loc.draft;
      case InvoiceStatus.refunded:
        return loc.refunded;
      case InvoiceStatus.voided:
        return loc.voided;
      case InvoiceStatus.failed:
        return loc.failed;
      case InvoiceStatus.archived:
        return loc.archived;
      case InvoiceStatus.viewed:
        return loc.viewed;
      case InvoiceStatus.open: // <--- add this case
        return loc.open ?? "Open";
    }
  }
}
