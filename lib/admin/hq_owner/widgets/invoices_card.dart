import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:franchise_admin_portal/config/design_tokens.dart';

class InvoicesCard extends StatelessWidget {
  final int totalInvoices;
  final int openInvoiceCount;
  final int overdueInvoiceCount;
  final double overdueAmount;
  final int paidInvoiceCount;
  final double outstandingBalance;
  final DateTime? lastInvoiceDate;

  final VoidCallback onViewAllPressed;
  final VoidCallback? onCreateInvoicePressed;

  const InvoicesCard({
    Key? key,
    required this.totalInvoices,
    required this.openInvoiceCount,
    required this.overdueInvoiceCount,
    required this.overdueAmount,
    required this.paidInvoiceCount,
    required this.outstandingBalance,
    this.lastInvoiceDate,
    required this.onViewAllPressed,
    this.onCreateInvoicePressed,
  }) : super(key: key);

  String _formatNumber(int number) {
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '-';
    return MaterialLocalizations.of(context).formatShortDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: loc.invoices ?? "Invoices Summary",
      child: Card(
        color: colorScheme.surfaceVariant,
        elevation: DesignTokens.adminCardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title + Actions
              Row(
                children: [
                  Icon(Icons.description_outlined, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(loc.invoices ?? "Invoices",
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  if (onCreateInvoicePressed != null)
                    IconButton(
                      icon: Icon(Icons.add_circle_outline,
                          color: colorScheme.primary),
                      tooltip: loc.createInvoice ?? "Create Invoice",
                      onPressed: onCreateInvoicePressed,
                      splashRadius: 20,
                    ),
                  Tooltip(
                    message: loc.viewAllInvoices ?? "View All Invoices",
                    child: IconButton(
                      icon: Icon(Icons.open_in_new, color: colorScheme.primary),
                      onPressed: onViewAllPressed,
                      tooltip: loc.viewAllInvoices ?? "View All Invoices",
                      splashRadius: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Stats Rows
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: [
                  _StatTile(
                    label: loc.totalInvoices ?? "Total Invoices",
                    value: _formatNumber(totalInvoices),
                    icon: Icons.format_list_numbered,
                    color: colorScheme.primary,
                  ),
                  _StatTile(
                    label: loc.openInvoices ?? "Open",
                    value: _formatNumber(openInvoiceCount),
                    icon: Icons.pending_actions,
                    color: Colors.orange.shade700,
                  ),
                  _StatTile(
                    label: loc.overdueInvoices ?? "Overdue",
                    value:
                        '$overdueInvoiceCount (${overdueAmount.toStringAsFixed(2)})',
                    icon: Icons.error_outline,
                    color: colorScheme.error,
                  ),
                  _StatTile(
                    label: loc.paidInvoices ?? "Paid",
                    value: _formatNumber(paidInvoiceCount),
                    icon: Icons.check_circle_outline,
                    color: Colors.green.shade600,
                  ),
                  _StatTile(
                    label: loc.outstandingBalance ?? "Outstanding",
                    value: '\$${outstandingBalance.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.red.shade700,
                  ),
                  _StatTile(
                    label: loc.lastInvoiceDate ?? "Last Invoice",
                    value: _formatDate(context, lastInvoiceDate),
                    icon: Icons.calendar_today_outlined,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: 140,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
            radius: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13, color: textColor.withOpacity(0.7))),
                Text(value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
