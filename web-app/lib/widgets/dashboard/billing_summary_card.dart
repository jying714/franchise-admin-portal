import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_section_card.dart';
import '../../../../packages/shared_core/lib/src/core/services/invoice_service.dart';
import '../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';
import '../../../../packages/shared_core/lib/src/core/providers/franchise_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class BillingSummaryCard extends StatefulWidget {
  const BillingSummaryCard({Key? key}) : super(key: key);

  @override
  State<BillingSummaryCard> createState() => _BillingSummaryCardState();
}

class _BillingSummaryCardState extends State<BillingSummaryCard> {
  late Future<BillingSummaryData> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _fetchSummary(context);
  }

  Future<BillingSummaryData> _fetchSummary(BuildContext context) async {
    try {
      final franchiseId =
          Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
      return await InvoiceService.getBillingSummary(franchiseId: franchiseId);
    } catch (error, stackTrace) {
      await ErrorLogger.log(
        message: 'BillingSummaryCard: failed to load summary\n$error',
        stack: stackTrace?.toString(),
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
        return FutureBuilder<BillingSummaryData>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return _ErrorWidget(
                errorMessage: localize.failedToLoadSummary,
                onRetry: () =>
                    setState(() => _summaryFuture = _fetchSummary(context)),
              );
            }
            final data = snapshot.data!;
            return _BillingSummaryContent(
                data: data, localize: localize, theme: theme);
          },
        );
      },
    );
  }
}

class _BillingSummaryContent extends StatelessWidget {
  final BillingSummaryData data;
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
        locale: Localizations.localeOf(context).toString());
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
            // OutlinedButton.icon(
            //   icon: const Icon(Icons.download_rounded),
            //   label: Text(localize.downloadSummary),
            //   onPressed: () => _onDownloadSummary(context),
            // ),
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
    Navigator.of(context)
        .pushNamed('/hq/invoices', arguments: {'payNow': true});
  }

  void _onDownloadSummary(BuildContext context) async {
    try {
      final franchiseId =
          Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
      final result = await InvoiceService.downloadSummary(
          franchiseId: franchiseId, context: context);
      String msg;
      if (kIsWeb) {
        // Use a web download handler here if you want (e.g. anchor element).
        msg = AppLocalizations.of(context)!.downloadStarted;
      } else {
        msg = 'Saved to: $result';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e, s) {
      await ErrorLogger.log(
        message: 'BillingSummaryCard: failed to download summary\n$e',
        stack: s.toString(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.downloadFailed)),
      );
    }
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

// --- DATA MODEL ---

class BillingSummaryData {
  final double totalOutstanding;
  final int overdueCount;
  final double paidLast30Days;
  final bool hasOutstanding;

  BillingSummaryData({
    required this.totalOutstanding,
    required this.overdueCount,
    required this.paidLast30Days,
  }) : hasOutstanding = totalOutstanding > 0;
}
