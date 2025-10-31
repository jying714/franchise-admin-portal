import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/src/core/models/platform_invoice.dart';
import 'package:shared_core/src/core/services/firestore_service.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:franchise_admin_portal/widgets/financials/pay_invoice_dialog.dart';
import 'package:shared_core/src/core/constants/invoice_status.dart';

class FranchiseeInvoiceTile extends StatelessWidget {
  final PlatformInvoice invoice;
  final AppConfig config;

  FranchiseeInvoiceTile({
    Key? key,
    required this.invoice,
    AppConfig? config,
  })  : config = config ?? AppConfig.instance,
        super(key: key);

  InvoiceStatus parseInvoiceStatus(String value) {
    return InvoiceStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => InvoiceStatus.unpaid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          try {
            await showDialog(
              context: context,
              builder: (_) => PayInvoiceDialog(invoice: invoice),
            );
          } catch (e, stack) {
            await ErrorLogger.log(
              message: e.toString(),
              stack: stack.toString(),
              source: 'FranchiseeInvoiceTile',
              screen: 'InvoiceTile',
              severity: 'error',
              contextData: {'invoiceId': invoice.id},
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.paddingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInvoiceInfo(loc, color),
              _buildAmountSection(loc, color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceInfo(AppLocalizations loc, ColorScheme color) {
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
          style: TextStyle(color: color.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 4),
        _buildStatusChip(parseInvoiceStatus(invoice.status), loc),
      ],
    );
  }

  Widget _buildAmountSection(AppLocalizations loc, ColorScheme color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${invoice.amount.toStringAsFixed(2)} ${invoice.currency}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color.primary,
          ),
        ),
        if (parseInvoiceStatus(invoice.status) != InvoiceStatus.paid)
          TextButton(
            onPressed: null, // Actual logic handled onTap of the card
            child: Text(loc.payNow),
          ),
      ],
    );
  }

  Widget _buildStatusChip(InvoiceStatus status, AppLocalizations loc) {
    final label = _localizedStatus(status, loc);
    final color = _statusColor(status);

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  String _localizedStatus(InvoiceStatus status, AppLocalizations loc) {
    switch (status) {
      case InvoiceStatus.paid:
        return loc.statusPaid;
      case InvoiceStatus.overdue:
        return loc.statusOverdue;
      case InvoiceStatus.sent:
        return loc.statusSent;
      case InvoiceStatus.draft:
        return loc.statusDraft;
      case InvoiceStatus.refunded:
        return loc.statusRefunded;
      case InvoiceStatus.voided:
        return loc.statusVoided;
      case InvoiceStatus.failed:
        return loc.statusFailed;
      case InvoiceStatus.unpaid:
        return loc.statusUnpaid;
      case InvoiceStatus.partial:
        return loc.statusPartial;
    }
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
      case InvoiceStatus.failed:
      case InvoiceStatus.voided:
        return Colors.black45;
      case InvoiceStatus.unpaid:
        return Colors.orangeAccent;
      case InvoiceStatus.partial:
        return Colors.amber;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final local = date.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }
}


