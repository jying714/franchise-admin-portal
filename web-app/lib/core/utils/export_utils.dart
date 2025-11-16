// web_app/lib/core/utils/export_utils.dart

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';

class ExportUtils {
  ExportUtils._();

  static String menuItemsToCsv(BuildContext context, List<MenuItem> items) {
    final loc = AppLocalizations.of(context)!;
    final headers = [
      loc.menuItemId,
      loc.menuItemName,
      loc.category,
      loc.categoryId,
      loc.description,
      loc.price,
      loc.availability,
      loc.taxCategory,
      loc.sku,
      loc.image,
      loc.dietaryTags,
      loc.allergens,
      loc.prepTime,
      loc.nutrition,
      loc.customizations,
      loc.customizationGroups,
    ];
    final rawCsv = ExportUtilsCore.menuItemsToCsv(items);
    final headerLine =
        headers.map((h) => '"${(h ?? '').replaceAll('"', '""')}"').join(',');
    return '$headerLine\n${rawCsv.split('\n').skip(1).join('\n')}';
  }

  static String invoicesToCsv(BuildContext context, List<Invoice> invoices) {
    final loc = AppLocalizations.of(context)!;
    final ml = MaterialLocalizations.of(context);
    final csv = StringBuffer();

    csv.writeln([
      loc.invoiceNumber,
      loc.status,
      loc.total,
      loc.currency,
      loc.issueDate,
      loc.dueDate,
      loc.paid,
    ].map((s) => '"${(s ?? '').replaceAll('"', '""')}"').join(','));

    for (final inv in invoices) {
      csv.writeln([
        inv.invoiceNumber,
        inv.status.toString().split('.').last,
        inv.total.toStringAsFixed(2),
        inv.currency,
        inv.issuedAt != null ? ml.formatShortDate(inv.issuedAt!) : '',
        inv.dueAt != null ? ml.formatShortDate(inv.dueAt!) : '',
        inv.paidAt != null ? 'TRUE' : 'FALSE',
      ]
          .map((s) => '"${(s ?? '').toString().replaceAll('"', '""')}"')
          .join(','));
    }
    return csv.toString();
  }
}
