import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/core/models/platform_payment.dart';
import 'package:admin_portal/widgets/financials/franchisee_payment_tile.dart';

class FranchiseePaymentList extends StatelessWidget {
  final List<PlatformPayment> payments;

  const FranchiseePaymentList({
    super.key,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '[FranchiseePaymentList] Received payments: ${payments.map((p) => "${p.id}:${p.amount} ${p.currency}").toList()}');

    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.platformPayments,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (payments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              loc.noBillingRecords,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final payment = payments[index];
              debugPrint(
                  '[FranchiseePaymentList] Rendering tile for payment ${payment.id} (${payment.amount} ${payment.currency})');

              return FranchiseePaymentTile(payment: payment);
            },
          ),
        const SizedBox(height: 12),
        Text(
          '[${loc.featureComingSoon("Filters / Search")}]',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
