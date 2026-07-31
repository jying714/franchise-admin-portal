import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// InvoiceDetailScreen
/// Displays full invoice detail: line items, totals, status, notes, audit trail.
///
/// Features:
/// - Fetches invoice by ID via shared.FirestoreService.
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
  late final shared.FirestoreService _firestoreService;

  late Future<shared.Invoice?> _invoiceFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
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
      body: FutureBuilder<shared.Invoice?>(
        future: _invoiceFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            shared.ErrorLogger.log(
              message: snapshot.error.toString(),
              source: 'InvoiceDetailScreen',
              severity: 'error',
              contextData: {'invoiceId': widget.invoiceId},
            );
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.errorLoadingInvoice,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _invoiceFuture =
                            _firestoreService.getInvoiceById(widget.invoiceId);
                      });
                    },
                    child: Text(loc.retry),
                  ),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final invoice = snapshot.data;
          if (invoice == null) {
            return Center(
              child: Text(
                loc.invoiceNotFound,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return _buildInvoiceDetail(context, invoice, loc);
        },
      ),
    );
  }

  Widget _buildInvoiceDetail(
      BuildContext context, shared.Invoice invoice, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(shared.DesignTokens.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInvoiceHeader(invoice, loc),
          const SizedBox(height: shared.DesignTokens.paddingMd),
          _buildLineItemsList(invoice, loc),
          const SizedBox(height: shared.DesignTokens.paddingMd),
          _buildTotalsSection(invoice, loc),
          const SizedBox(height: shared.DesignTokens.paddingMd),
          _buildStatusSection(invoice, loc),
          const SizedBox(height: shared.DesignTokens.paddingMd),
          _buildAuditTrail(invoice, loc),
          const SizedBox(height: shared.DesignTokens.paddingMd),
          _buildSupportNotes(invoice, loc),
        ],
      ),
    );
  }

  Widget _buildInvoiceHeader(shared.Invoice invoice, AppLocalizations loc) {
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

  Widget _buildLineItemsList(shared.Invoice invoice, AppLocalizations loc) {
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

  Widget _buildLineItemRow(shared.InvoiceLineItem item, AppLocalizations loc) {
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

  Widget _buildTotalsSection(shared.Invoice invoice, AppLocalizations loc) {
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

  Widget _buildStatusSection(shared.Invoice invoice, AppLocalizations loc) {
    return Row(
      children: [
        Text('${loc.status}: ', style: _headerStyle()),
        _buildStatusChip(invoice.status, loc),
      ],
    );
  }

  Widget _buildStatusChip(shared.InvoiceStatus status, AppLocalizations loc) {
    final color = _statusColor(status);
    final label = _localizedStatus(status, loc);
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  Widget _buildAuditTrail(shared.Invoice invoice, AppLocalizations loc) {
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

  Widget _buildAuditEventRow(
      shared.InvoiceAuditEvent event, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '${_formatDateTime(event.timestamp)} - ${event.eventType} - ${event.userId} ${event.notes ?? ''}',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSupportNotes(shared.Invoice invoice, AppLocalizations loc) {
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

  Widget _buildSupportNoteRow(
      shared.InvoiceSupportNote note, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '${_formatDateTime(note.createdAt)} - ${note.userId}: ${note.content}',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface,
        ),
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

  Color _statusColor(shared.InvoiceStatus status) {
    switch (status) {
      case shared.InvoiceStatus.paid:
        return Colors.green;
      case shared.InvoiceStatus.unpaid:
        return Colors.orange;
      case shared.InvoiceStatus.overdue:
        return Colors.red;
      case shared.InvoiceStatus.sent:
        return Colors.blue;
      case shared.InvoiceStatus.draft:
        return Colors.grey;
      case shared.InvoiceStatus.refunded:
        return Colors.orange;
      case shared.InvoiceStatus.voided:
      case shared.InvoiceStatus.failed:
        return Colors.black45;
      case shared.InvoiceStatus.archived:
        return Colors.grey.shade600;
      case shared.InvoiceStatus.viewed:
        return Colors.lightBlue;
      case shared.InvoiceStatus.open:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _localizedStatus(shared.InvoiceStatus status, AppLocalizations loc) {
    switch (status) {
      case shared.InvoiceStatus.paid:
        return loc.paid;
      case shared.InvoiceStatus.unpaid:
        return loc.unpaid ?? 'Unpaid';
      case shared.InvoiceStatus.overdue:
        return loc.overdue;
      case shared.InvoiceStatus.sent:
        return loc.sent;
      case shared.InvoiceStatus.draft:
        return loc.draft;
      case shared.InvoiceStatus.refunded:
        return loc.refunded;
      case shared.InvoiceStatus.voided:
        return loc.voided;
      case shared.InvoiceStatus.failed:
        return loc.failed;
      case shared.InvoiceStatus.archived:
        return loc.archived;
      case shared.InvoiceStatus.viewed:
        return loc.viewed;
      case shared.InvoiceStatus.open:
        return loc.open ?? "Open";
      default:
        return status.toString();
    }
  }
}
