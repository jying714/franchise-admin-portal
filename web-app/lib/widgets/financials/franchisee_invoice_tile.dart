import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'pay_invoice_dialog.dart';

class FranchiseeInvoiceTile extends StatelessWidget {
  final shared.PlatformInvoice invoice;

  const FranchiseeInvoiceTile({
    super.key,
    required this.invoice,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Literal value
      ),
      child: InkWell(
        onTap: () async {
          try {
            await showDialog(
              context: context,
              builder: (_) => PayInvoiceDialog(invoice: invoice),
            );
          } catch (e, stack) {
            shared.ErrorLogger.log(
              message: e.toString(),
              stack: stack.toString(),
              source: 'FranchiseeInvoiceTile',
              severity: 'error',
              contextData: {'invoiceId': invoice.id},
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.paddingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInvoiceInfo(loc, colorScheme),
              _buildAmountSection(loc, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceInfo(AppLocalizations loc, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${loc.invoiceNumber}: ${invoice.invoiceNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          '${loc.dueDate}: ${_formatDate(invoice.dueDate)}',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 4),
        _buildStatusChip(_parseInvoiceStatus(invoice.status), loc),
      ],
    );
  }

  Widget _buildAmountSection(AppLocalizations loc, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${invoice.amount.toStringAsFixed(2)} ${invoice.currency}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: colorScheme.primary,
          ),
        ),
        if (_parseInvoiceStatus(invoice.status) != shared.InvoiceStatus.paid)
          TextButton(
            onPressed: null,
            child: Text(loc.payNow),
          ),
      ],
    );
  }

  shared.InvoiceStatus _parseInvoiceStatus(String value) {
    return shared.InvoiceStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => shared.InvoiceStatus.unpaid,
    );
  }

  Widget _buildStatusChip(shared.InvoiceStatus status, AppLocalizations loc) {
    final label = _localizedStatus(status, loc);
    final color = _statusColor(status);

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  String _localizedStatus(shared.InvoiceStatus status, AppLocalizations loc) {
    switch (status) {
      case shared.InvoiceStatus.paid:
        return loc.statusPaid;
      case shared.InvoiceStatus.overdue:
        return loc.statusOverdue;
      case shared.InvoiceStatus.sent:
        return loc.statusSent;
      case shared.InvoiceStatus.draft:
        return loc.statusDraft;
      case shared.InvoiceStatus.refunded:
        return loc.statusRefunded;
      case shared.InvoiceStatus.voided:
        return loc.statusVoided;
      case shared.InvoiceStatus.failed:
        return loc.statusFailed;
      case shared.InvoiceStatus.unpaid:
        return loc.statusUnpaid;
      case shared.InvoiceStatus.partial:
        return loc.statusPartial;
      case shared.InvoiceStatus.open: // Added for exhaustiveness
      case shared.InvoiceStatus.viewed:
        return 'Viewed';
      default:
        return status.name;
    }
  }

  Color _statusColor(shared.InvoiceStatus status) {
    switch (status) {
      case shared.InvoiceStatus.paid:
        return Colors.green;
      case shared.InvoiceStatus.overdue:
        return Colors.red;
      case shared.InvoiceStatus.sent:
        return Colors.blue;
      case shared.InvoiceStatus.draft:
        return Colors.grey;
      case shared.InvoiceStatus.refunded:
        return Colors.orange;
      case shared.InvoiceStatus.failed:
      case shared.InvoiceStatus.voided:
        return Colors.black45;
      case shared.InvoiceStatus.unpaid:
        return Colors.orangeAccent;
      case shared.InvoiceStatus.partial:
        return Colors.amber;
      case shared.InvoiceStatus.open:
      case shared.InvoiceStatus.viewed:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final local = date.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }
}
