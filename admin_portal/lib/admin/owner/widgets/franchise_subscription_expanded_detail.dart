import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:admin_portal/core/models/enriched/enriched_franchise_subscription.dart';
import 'package:admin_portal/core/models/platform_invoice.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:provider/provider.dart';
import 'package:admin_portal/config/app_config.dart';

class FranchiseSubscriptionExpandedDetail extends StatefulWidget {
  final EnrichedFranchiseSubscription enriched;

  const FranchiseSubscriptionExpandedDetail({
    super.key,
    required this.enriched,
  });

  @override
  State<FranchiseSubscriptionExpandedDetail> createState() =>
      _FranchiseSubscriptionExpandedDetailState();
}

class _FranchiseSubscriptionExpandedDetailState
    extends State<FranchiseSubscriptionExpandedDetail> {
  List<PlatformInvoice> _invoices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      final firestore = context.read<FirestoreService>();
      final invoices = await firestore.getPlatformInvoicesForFranchisee(
        widget.enriched.franchiseId,
      );
      setState(() {
        _invoices = invoices;
        _loading = false;
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'invoice_fetch_failed',
        screen: 'franchise_subscription_expanded_detail',
        source: 'ExpandedDetailInit',
        stack: stack.toString(),
        contextData: {
          'franchiseId': widget.enriched.franchiseId,
          'subscriptionId': widget.enriched.subscription.id,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enriched = widget.enriched;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30),
        _infoRow(loc.ownerLabel, enriched.ownerName),
        _infoRow(loc.contactEmailLabel, enriched.contactEmail),
        _infoRow(loc.phoneNumberLabel, enriched.phoneNumber),
        if (enriched.userId != null)
          _infoRow(loc.linkedUserIdLabel, enriched.userId!),
        _infoRow(loc.billingIntervalLabel,
            enriched.subscription.billingInterval ?? '—'),
        _infoRow(loc.statusLabel, enriched.subscriptionStatus),
        _infoRow(loc.invoiceStatusLabel, _resolveInvoiceStatus(enriched)),
        _infoRow(
            loc.discountLabel, '${enriched.subscription.discountPercent}%'),
        _infoRow(
          loc.trialEndLabel,
          enriched.subscription.trialEndsAt != null
              ? AppConfig.formatDate(enriched.subscription.trialEndsAt)
              : loc.notAvailable,
        ),
        _infoRow(
          loc.nextBillingLabel,
          AppConfig.formatDate(enriched.subscription.nextBillingDate),
        ),
        _infoRow(
          loc.subscriptionCreated,
          AppConfig.formatDate(enriched.subscription.startDate),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.linkedInvoices, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ..._invoices.map((inv) => ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title:
                        Text('${loc.invoiceNumberLabel}: ${inv.invoiceNumber}'),
                    subtitle: Text(
                        '${loc.amountLabel}: \$${inv.amount.toStringAsFixed(2)}'),
                    trailing: Icon(Icons.receipt_long_outlined,
                        color: colorScheme.primary),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/hq/invoices/${inv.id}',
                      );
                    },
                  )),
            ],
          ),
        const SizedBox(height: 20),
        Text(loc.featureComingSoon(loc.subscriptionAnalytics),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: colorScheme.outline)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
              flex: 4,
              child: Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600))),
          Expanded(
              flex: 6, child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  String _resolveInvoiceStatus(EnrichedFranchiseSubscription enriched) {
    if (enriched.latestInvoice == null) return '—';
    if (enriched.isInvoicePaid) return AppLocalizations.of(context)!.paid;
    if (enriched.isInvoicePartial) return AppLocalizations.of(context)!.partial;
    if (enriched.isInvoiceOverdue) return AppLocalizations.of(context)!.overdue;
    if (enriched.isInvoiceUnpaid) return AppLocalizations.of(context)!.unpaid;
    return enriched.latestInvoice!.status;
  }
}
