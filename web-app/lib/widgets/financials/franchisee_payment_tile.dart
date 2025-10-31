import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/src/core/models/platform_payment.dart';
import 'package:intl/intl.dart';

class FranchiseePaymentTile extends StatelessWidget {
  final PlatformPayment payment;

  const FranchiseePaymentTile({
    Key? key,
    required this.payment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final date =
        payment.executedAt ?? payment.scheduledFor ?? payment.createdAt;
    final formattedDate = date != null ? DateFormat.yMMMd().format(date) : '-';

    final methodIcon = _buildMethodIcon(payment.paymentMethod);
    final statusColor = _statusColor(payment.status, colorScheme);
    final isRecurring = payment.type == 'recurring';
    final isSplit = payment.type == 'split';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.paddingMd),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.surfaceVariant,
              radius: 20,
              child: methodIcon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${payment.amount.toStringAsFixed(2)} ${payment.currency}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${loc.paymentMethod}: ${payment.paymentMethod}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  if (isRecurring || isSplit)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          if (isRecurring)
                            _buildChip(loc.recurringRule, Icons.loop,
                                colorScheme.secondary),
                          if (isSplit)
                            _buildChip(loc.splitPayment, Icons.call_split,
                                colorScheme.tertiary),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Chip(
                  label: Text(payment.status,
                      style: const TextStyle(color: Colors.white)),
                  backgroundColor: statusColor,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodIcon(String method) {
    final icon = switch (method.toLowerCase()) {
      'paypal' => Icons.account_balance_wallet,
      'credit_card' || 'debit_card' => Icons.credit_card,
      'check' => Icons.receipt_long,
      'ach' => Icons.swap_horiz,
      _ => Icons.payment,
    };

    return Icon(icon, size: 20);
  }

  Color _statusColor(String status, ColorScheme scheme) {
    switch (status.toLowerCase()) {
      case 'pending':
        return scheme.secondary;
      case 'completed':
        return Colors.green;
      case 'failed':
      case 'error':
        return scheme.error;
      default:
        return scheme.outline;
    }
  }

  Widget _buildChip(String? label, IconData icon, Color color) {
    if (label == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}


