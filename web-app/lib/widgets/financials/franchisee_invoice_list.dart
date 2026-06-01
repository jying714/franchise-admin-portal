import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/widgets/financials/franchisee_invoice_tile.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_empty_state_widget.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';

class FranchiseeInvoiceList extends StatelessWidget {
  final List<shared.PlatformInvoice> invoices;
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
      shared.ErrorLogger.log(
        message: 'Localization context is null',
        source: 'FranchiseeInvoiceList',
        severity: 'warning',
      );
      return const SizedBox.shrink();
    }

    final brandColor = brandId != null
        ? BrandingConfig.brandColorFor(brandId!)
        : BrandingConfig.brandRed;

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
        SizedBox(height: DesignTokens.paddingMd),
        if (invoices.isEmpty)
          AdminEmptyStateWidget(
            title: loc.platformInvoices,
            message: loc.noBillingRecords,
            actionLabel: loc.tryAgain,
            onAction: () {
              shared.ErrorLogger.log(
                message: 'User triggered retry on empty invoice list',
                source: 'FranchiseeInvoiceList',
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
                SizedBox(height: DesignTokens.adminCardSpacing),
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return FranchiseeInvoiceTile(invoice: invoice);
            },
          ),
      ],
    );
  }
}
