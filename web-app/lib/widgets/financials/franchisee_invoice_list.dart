import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../packages/shared_core/lib/src/core/models/platform_invoice.dart';
import 'package:franchise_admin_portal/widgets/financials/franchisee_invoice_tile.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_empty_state_widget.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import '../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';

class FranchiseeInvoiceList extends StatelessWidget {
  final List<PlatformInvoice> invoices;
  final String? brandId;

  const FranchiseeInvoiceList({
    super.key,
    required this.invoices,
    this.brandId,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      ErrorLogger.log(
        message: 'Localization context is null',
        source: 'FranchiseeInvoiceList',
        screen: 'franchisee_invoice_list.dart',
        severity: 'warning',
      );
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final brandColor = brandId != null
        ? BrandingConfig.brandColorFor(brandId!)
        : BrandingConfig.brandRed;

    debugPrint('[FranchiseeInvoiceList] Received ${invoices.length} invoices');
    for (var inv in invoices) {
      debugPrint(
        '[FranchiseeInvoiceList] Invoice: id=${inv.id}, amount=${inv.amount ?? inv.amount}, status=${inv.status}, dueDate=${inv.dueDate}',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.platformInvoices,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: brandColor,
              ),
        ),
        const SizedBox(height: DesignTokens.paddingMd),
        if (invoices.isEmpty)
          AdminEmptyStateWidget(
            title: loc.platformInvoices,
            message: loc.noBillingRecords,
            actionLabel: loc.tryAgain,
            onAction: () {
              ErrorLogger.log(
                message: 'User triggered retry on empty invoice list',
                source: 'FranchiseeInvoiceList',
                screen: 'franchisee_invoice_list.dart',
                severity: 'info',
              );
            },
          )
        else
          ListView.separated(
            itemCount: invoices.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) =>
                const SizedBox(height: DesignTokens.adminCardSpacing),
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              debugPrint(
                '[FranchiseeInvoiceList] Rendering tile for invoice ${invoice.id} - ${invoice.status}',
              );
              return FranchiseeInvoiceTile(invoice: invoice);
            },
          ),
      ],
    );
  }
}
