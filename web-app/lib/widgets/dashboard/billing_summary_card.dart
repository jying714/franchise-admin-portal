import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_section_card.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:intl/intl.dart';

class BillingSummaryCard extends StatefulWidget {
  const BillingSummaryCard({super.key});

  @override
  State<BillingSummaryCard> createState() => _BillingSummaryCardState();
}

class _BillingSummaryCardState extends State<BillingSummaryCard> {
  late Future<shared.BillingSummaryData> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _fetchSummary();
  }

  Future<shared.BillingSummaryData> _fetchSummary() async {
    try {
      final franchiseProvider = Provider.of<shared.FranchiseProvider>(
        context,
        listen: false,
      );

      final invoiceService = Provider.of<shared.InvoiceService>(
        context,
        listen: false,
      );

      final invoices = await invoiceService.getInvoices(
        franchiseId: franchiseProvider.franchiseId,
        statuses: ['unpaid', 'partial', 'open'],
      );

      double totalOutstanding = 0.0;
      int overdueCount = 0;
      double paidLast30Days = 0.0;

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      for (final invoice in invoices) {
        if (!invoice.isPaid) {
          totalOutstanding += invoice.total;
          if (invoice.isOverdue) overdueCount++;
        } else if (invoice.paidAt != null &&
            invoice.paidAt!.isAfter(thirtyDaysAgo)) {
          paidLast30Days += invoice.total;
        }
      }

      return shared.BillingSummaryData(
        totalOutstanding: totalOutstanding,
        overdueCount: overdueCount,
        paidLast30Days: paidLast30Days,
      );
    } catch (error, stackTrace) {
      shared.ErrorLogger.log(
        message: 'BillingSummaryCard: failed to load summary\n$error',
        stack: stackTrace.toString(),
        source: 'BillingSummaryCard',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localize = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return DashboardSectionCard(
      title: localize.billingSummary,
      icon: Icons.receipt_long,
      builder: (context) {
        return FutureBuilder<shared.BillingSummaryData>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return _ErrorWidget(
                errorMessage: localize.failedToLoadSummary,
                onRetry: () => setState(() => _summaryFuture = _fetchSummary()),
              );
            }

            final data = snapshot.data!;
            return _BillingSummaryContent(
              data: data,
              localize: localize,
              theme: theme,
            );
          },
        );
      },
    );
  }
}

class _BillingSummaryContent extends StatelessWidget {
  final shared.BillingSummaryData data;
  final AppLocalizations localize;
  final ThemeData theme;

  const _BillingSummaryContent({
    required this.data,
    required this.localize,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryRow(
          label: localize.totalOutstanding,
          value: currencyFormat.format(data.totalOutstanding),
          valueColor: data.totalOutstanding > 0
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
        ),
        const SizedBox(height: 10),
        _SummaryRow(
          label: localize.overdueInvoices,
          value: '${data.overdueCount}',
          valueColor: data.overdueCount > 0
              ? theme.colorScheme.error
              : theme.textTheme.bodyMedium?.color,
        ),
        const SizedBox(height: 10),
        _SummaryRow(
          label: localize.paidLastNDays(30),
          value: currencyFormat.format(data.paidLast30Days),
          valueColor: theme.colorScheme.secondary,
        ),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.payment_rounded),
              label: Text(localize.payNow),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    BrandingConfig.accentColor ?? theme.colorScheme.primary,
              ),
              onPressed: data.hasOutstanding ? () => _onPayNow(context) : null,
            ),
            TextButton(
              child: Text(localize.viewAllInvoices),
              onPressed: () => Navigator.of(context).pushNamed('/hq/invoices'),
            ),
          ],
        ),
      ],
    );
  }

  void _onPayNow(BuildContext context) {
    Navigator.of(context).pushNamed(
      '/hq/invoices',
      arguments: {'payNow': true},
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color:
                    valueColor ?? Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.retry),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
