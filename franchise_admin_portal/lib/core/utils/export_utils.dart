// File: lib/core/utils/export_utils.dart

import 'dart:convert';
import 'package:franchise_admin_portal/core/models/invoice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/analytics_summary.dart';
import 'package:franchise_admin_portal/core/models/audit_log.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:franchise_admin_portal/core/models/menu_item.dart';
import 'package:franchise_admin_portal/core/models/promo.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

/// =======================
/// ExportUtils
/// =======================
/// Helper functions for exporting lists of app models to CSV or JSON.
/// Designed for admin backup, data auditing, and export/download screens.
/// Integrates localization and error logging.
/// =======================

class ExportUtils {
  ExportUtils._();

  /// Exports a list of MenuItem objects to CSV string.
  /// Includes key fields, nutrition, tags, and customizations as JSON.
  static String menuItemsToCsv(BuildContext context, List<MenuItem> items) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[ExportUtils] loc is null! Localization not available for this context.');
      return 'Localization missing! [debug]';
    }
    final csv = StringBuffer();
    try {
      csv.writeln([
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
      ].map(_escape).join(','));

      for (final item in items) {
        csv.writeln([
          _escape(item.id),
          _escape(item.name),
          _escape(item.category),
          _escape(item.categoryId ?? ''),
          _escape(item.description),
          item.price.toStringAsFixed(2),
          item.availability ? 'TRUE' : 'FALSE',
          _escape(item.taxCategory),
          _escape(item.sku ?? ''),
          _escape(item.image ?? ''),
          _escape(item.dietaryTags.join(';')),
          _escape(item.allergens.join(';')),
          item.prepTime?.toString() ?? '',
          _escape(jsonEncode(item.nutrition?.toMap() ?? {})),
          _escape(
              jsonEncode(item.customizations.map((c) => c.toMap()).toList())),
          _escape(jsonEncode(item.customizationGroups ?? [])),
        ].join(','));
      }
    } catch (e, stack) {
      ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'ExportUtils',
        screen: 'menuItemsToCsv',
        severity: 'error',
        contextData: {'itemCount': items.length},
      );
    }
    return csv.toString();
  }

  /// Exports a list of Category objects to CSV string.
  static String categoriesToCsv(BuildContext context, List<Category> cats) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[ExportUtils] loc is null! Localization not available for this context.');
      return 'Localization missing! [debug]';
    }
    final csv = StringBuffer();
    try {
      csv.writeln([
        loc.categoryId,
        loc.categoryName,
        loc.description,
        loc.image,
      ].map(_escape).join(','));

      for (final c in cats) {
        csv.writeln([
          _escape(c.id),
          _escape(c.name),
          _escape(c.description ?? ''),
          _escape(c.image ?? ''),
        ].join(','));
      }
    } catch (e, stack) {
      ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'ExportUtils',
        screen: 'categoriesToCsv',
        severity: 'error',
        contextData: {'categoryCount': cats.length},
      );
    }
    return csv.toString();
  }

  /// Exports a list of AuditLog entries to CSV.
  static String auditLogsToCsv(BuildContext context, List<AuditLog> logs) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[ExportUtils] loc is null! Localization not available for this context.');
      return 'Localization missing! [debug]';
    }
    final csv = StringBuffer();
    try {
      csv.writeln([
        loc.auditLogId,
        loc.action,
        loc.userId,
        loc.timestamp,
        loc.ipAddress,
        loc.details,
      ].map(_escape).join(','));

      for (final log in logs) {
        csv.writeln([
          _escape(log.id),
          _escape(log.action),
          _escape(log.userId),
          _escape(log.timestamp.toIso8601String()),
          _escape(log.ipAddress ?? ''),
          _escape(jsonEncode(log.details ?? {})),
        ].join(','));
      }
    } catch (e, stack) {
      ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'ExportUtils',
        screen: 'auditLogsToCsv',
        severity: 'error',
        contextData: {'logCount': logs.length},
      );
    }
    return csv.toString();
  }

  /// Exports a list of Promo objects to CSV string.
  static String promosToCsv(BuildContext context, List<Promo> promos) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[ExportUtils] loc is null! Localization not available for this context.');
      return 'Localization missing! [debug]';
    }
    final csv = StringBuffer();
    try {
      csv.writeln([
        loc.promoId,
        loc.name,
        loc.description,
        loc.discount,
        loc.code,
        loc.active,
        loc.type,
        loc.applicableItems,
        loc.maxUses,
        loc.maxUsesType,
        loc.minOrderValue,
        loc.startDate,
        loc.endDate,
        loc.segment,
        loc.timeRules,
      ].map(_escape).join(','));

      for (final promo in promos) {
        csv.writeln([
          _escape(promo.id),
          _escape(promo.name),
          _escape(promo.description ?? ''),
          promo.discount.toStringAsFixed(2),
          _escape(promo.code ?? ''),
          promo.active ? 'TRUE' : 'FALSE',
          _escape(promo.type ?? ''),
          _escape(jsonEncode(promo.applicableItems ?? [])),
          promo.maxUses?.toString() ?? '',
          _escape(promo.maxUsesType ?? ''),
          promo.minOrderValue?.toString() ?? '',
          promo.startDate?.toIso8601String() ?? '',
          promo.endDate?.toIso8601String() ?? '',
          _escape(jsonEncode(promo.segment ?? {})),
          _escape(jsonEncode(promo.timeRules ?? {})),
        ].join(','));
      }
    } catch (e, stack) {
      ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'ExportUtils',
        screen: 'promosToCsv',
        severity: 'error',
        contextData: {'promoCount': promos.length},
      );
    }
    return csv.toString();
  }

  /// Exports a single AnalyticsSummary to CSV string (single row).
  static String analyticsSummaryToCsv(
      BuildContext context, AnalyticsSummary summary) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[ExportUtils] loc is null! Localization not available for this context.');
      return 'Localization missing! [debug]';
    }
    final csv = StringBuffer();
    try {
      csv.writeln([
        loc.period,
        loc.totalOrders,
        loc.totalRevenue,
        loc.averageOrderValue,
        loc.mostPopularItem,
        loc.retention,
        loc.uniqueCustomers,
        loc.cancelledOrders,
        loc.addOnRevenue,
        loc.toppingCounts,
        loc.comboCounts,
        loc.addOnCounts,
        loc.orderStatusBreakdown,
        loc.franchiseId,
      ].map(_escape).join(','));

      csv.writeln([
        _escape(summary.period),
        summary.totalOrders.toString(),
        summary.totalRevenue.toStringAsFixed(2),
        summary.averageOrderValue.toStringAsFixed(2),
        _escape(summary.mostPopularItem),
        summary.retention.toStringAsFixed(3),
        summary.uniqueCustomers.toString(),
        summary.cancelledOrders.toString(),
        summary.addOnRevenue.toStringAsFixed(2),
        _escape(jsonEncode(summary.toppingCounts)),
        _escape(jsonEncode(summary.comboCounts)),
        _escape(jsonEncode(summary.addOnCounts)),
        _escape(jsonEncode(summary.orderStatusBreakdown)),
        _escape(summary.franchiseId),
      ].join(','));
    } catch (e, stack) {
      ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'ExportUtils',
        screen: 'analyticsSummaryToCsv',
        severity: 'error',
      );
    }
    return csv.toString();
  }

  /// Exports multiple AnalyticsSummary objects to CSV string (multiple rows).
  static String analyticsSummariesToCsv(
      BuildContext context, List<AnalyticsSummary> summaries) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[ExportUtils] loc is null! Localization not available for this context.');
      return 'Localization missing! [debug]';
    }
    final csv = StringBuffer();
    try {
      csv.writeln([
        loc.period,
        loc.totalOrders,
        loc.totalRevenue,
        loc.averageOrderValue,
        loc.mostPopularItem,
        loc.retention,
        loc.uniqueCustomers,
        loc.cancelledOrders,
        loc.addOnRevenue,
        loc.toppingCounts,
        loc.comboCounts,
        loc.addOnCounts,
        loc.orderStatusBreakdown,
        loc.franchiseId,
      ].map(_escape).join(','));

      for (final summary in summaries) {
        csv.writeln([
          _escape(summary.period),
          summary.totalOrders.toString(),
          summary.totalRevenue.toStringAsFixed(2),
          summary.averageOrderValue.toStringAsFixed(2),
          _escape(summary.mostPopularItem),
          summary.retention.toStringAsFixed(3),
          summary.uniqueCustomers.toString(),
          summary.cancelledOrders.toString(),
          summary.addOnRevenue.toStringAsFixed(2),
          _escape(jsonEncode(summary.toppingCounts)),
          _escape(jsonEncode(summary.comboCounts)),
          _escape(jsonEncode(summary.addOnCounts)),
          _escape(jsonEncode(summary.orderStatusBreakdown)),
          _escape(summary.franchiseId),
        ].join(','));
      }
    } catch (e, stack) {
      ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'ExportUtils',
        screen: 'analyticsSummariesToCsv',
        severity: 'error',
      );
    }
    return csv.toString();
  }

  /// Escapes CSV field per RFC4180, handles nulls safely.
  static String _escape(String? s) {
    if (s == null || s.isEmpty) return '';
    if (s.contains(',') ||
        s.contains('"') ||
        s.contains('\n') ||
        s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Generic helper to convert list of maps to CSV with optional headers.
  static String mapsToCsv(List<Map<String, dynamic>> data,
      {List<String>? headers}) {
    if (data.isEmpty) return '';
    final csv = StringBuffer();
    final headerFields = headers ?? data.first.keys.toList();
    csv.writeln(headerFields.join(','));
    for (final map in data) {
      csv.writeln(
          headerFields.map((h) => _escape(map[h]?.toString() ?? '')).join(','));
    }
    return csv.toString();
  }

  static String analyticsSummaryToCsvNoContext(AnalyticsSummary summary) {
    // Use hardcoded English strings or keys instead of localized ones.
    final csv = StringBuffer();
    csv.writeln(
        "period,totalOrders,totalRevenue,averageOrderValue,mostPopularItem,retention,uniqueCustomers,cancelledOrders,addOnRevenue,toppingCounts,comboCounts,addOnCounts,orderStatusBreakdown,franchiseId");
    csv.writeln([
      summary.period,
      summary.totalOrders.toString(),
      summary.totalRevenue.toStringAsFixed(2),
      summary.averageOrderValue.toStringAsFixed(2),
      summary.mostPopularItem,
      summary.retention.toStringAsFixed(3),
      summary.uniqueCustomers.toString(),
      summary.cancelledOrders.toString(),
      summary.addOnRevenue.toStringAsFixed(2),
      jsonEncode(summary.toppingCounts),
      jsonEncode(summary.comboCounts),
      jsonEncode(summary.addOnCounts),
      jsonEncode(summary.orderStatusBreakdown),
      summary.franchiseId,
    ].join(','));
    return csv.toString();
  }

  static String invoicesToCsv(BuildContext context, List<Invoice> invoices) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[ExportUtils] loc is null! Localization not available for this context.');
      return 'Localization missing! [debug]';
    }
    final csv = StringBuffer();
    csv.writeln([
      loc.invoiceNumber,
      loc.status,
      loc.total,
      loc.currency,
      loc.issueDate,
      loc.dueDate,
      loc.paid,
    ].map(_escape).join(','));

    for (final inv in invoices) {
      csv.writeln([
        _escape(inv.invoiceNumber),
        _escape(inv.status.toString().split('.').last),
        inv.total.toStringAsFixed(2),
        _escape(inv.currency),
        _escape(inv.issuedAt != null
            ? MaterialLocalizations.of(context).formatShortDate(inv.issuedAt!)
            : ''),
        _escape(inv.dueAt != null
            ? MaterialLocalizations.of(context).formatShortDate(inv.dueAt!)
            : ''),
        inv.paidAt != null ? 'TRUE' : 'FALSE',
      ].join(','));
    }
    return csv.toString();
  }

  // ===========================
  // Future Feature Placeholders:
  // - XLSX / PDF export support
  // - Locale-aware date formatting options
  // - Export progress streaming for large data sets
  // ===========================
}
