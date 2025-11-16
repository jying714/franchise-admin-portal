// packages/shared_core/lib/src/core/utils/export_utils_core.dart

import 'dart:convert';
import '../models/invoice.dart';
import '../models/analytics_summary.dart';
import '../models/audit_log.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../models/promo.dart';

/// =======================
/// ExportUtilsCore (PURE DART)
/// =======================
/// CSV/JSON export logic with **NO Flutter dependencies**.
/// Uses **field keys** (English) or **Map<String, dynamic>** input.
/// UI layer wraps this with localization.
/// =======================

class ExportUtilsCore {
  ExportUtilsCore._();

  // === Menu Items ===
  static String menuItemsToCsv(List<MenuItem> items) {
    final csv = StringBuffer();
    csv.writeln([
      'id',
      'name',
      'category',
      'categoryId',
      'description',
      'price',
      'availability',
      'taxCategory',
      'sku',
      'image',
      'dietaryTags',
      'allergens',
      'prepTime',
      'nutrition',
      'customizations',
      'customizationGroups'
    ].map(_escape).join(','));

    for (final item in items) {
      csv.writeln([
        _escape(item.id),
        _escape(item.name),
        _escape(item.category),
        _escape(item.categoryId ?? ''),
        _escape(item.description),
        item.price.toStringAsFixed(2),
        item.availability.toString(),
        _escape(item.taxCategory),
        _escape(item.sku ?? ''),
        _escape(item.image ?? ''),
        _escape(item.dietaryTags.join(';')),
        _escape(item.allergens.join(';')),
        item.prepTime?.toString() ?? '',
        _escape(jsonEncode(item.nutrition?.toMap() ?? {})),
        _escape(jsonEncode(item.customizations.map((c) => c.toMap()).toList())),
        _escape(jsonEncode(item.customizationGroups ?? [])),
      ].join(','));
    }
    return csv.toString();
  }

  // === Categories ===
  static String categoriesToCsv(List<Category> cats) {
    final csv = StringBuffer();
    csv.writeln(['id', 'name', 'description', 'image'].map(_escape).join(','));
    for (final c in cats) {
      csv.writeln([
        _escape(c.id),
        _escape(c.name),
        _escape(c.description ?? ''),
        _escape(c.image ?? ''),
      ].join(','));
    }
    return csv.toString();
  }

  // === Audit Logs ===
  static String auditLogsToCsv(List<AuditLog> logs) {
    final csv = StringBuffer();
    csv.writeln(['id', 'action', 'userId', 'timestamp', 'ipAddress', 'details']
        .map(_escape)
        .join(','));
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
    return csv.toString();
  }

  // === Promos ===
  static String promosToCsv(List<Promo> promos) {
    final csv = StringBuffer();
    csv.writeln([
      'id',
      'name',
      'description',
      'discount',
      'code',
      'active',
      'type',
      'applicableItems',
      'maxUses',
      'maxUsesType',
      'minOrderValue',
      'startDate',
      'endDate',
      'segment',
      'timeRules'
    ].map(_escape).join(','));

    for (final p in promos) {
      csv.writeln([
        _escape(p.id),
        _escape(p.name),
        _escape(p.description ?? ''),
        p.discount.toStringAsFixed(2),
        _escape(p.code ?? ''),
        p.active.toString(),
        _escape(p.type ?? ''),
        _escape(jsonEncode(p.applicableItems ?? [])),
        p.maxUses?.toString() ?? '',
        _escape(p.maxUsesType ?? ''),
        p.minOrderValue?.toString() ?? '',
        p.startDate?.toIso8601String() ?? '',
        p.endDate?.toIso8601String() ?? '',
        _escape(jsonEncode(p.segment ?? {})),
        _escape(jsonEncode(p.timeRules ?? {})),
      ].join(','));
    }
    return csv.toString();
  }

  // === Analytics Summary (Single) ===
  static String analyticsSummaryToCsv(AnalyticsSummary summary) {
    final csv = StringBuffer();
    csv.writeln([
      'period',
      'totalOrders',
      'totalRevenue',
      'averageOrderValue',
      'mostPopularItem',
      'retention',
      'uniqueCustomers',
      'cancelledOrders',
      'addOnRevenue',
      'toppingCounts',
      'comboCounts',
      'addOnCounts',
      'orderStatusBreakdown',
      'franchiseId'
    ].join(','));

    csv.writeln([
      summary.period,
      summary.totalOrders,
      summary.totalRevenue.toStringAsFixed(2),
      summary.averageOrderValue.toStringAsFixed(2),
      summary.mostPopularItem,
      summary.retention.toStringAsFixed(3),
      summary.uniqueCustomers,
      summary.cancelledOrders,
      summary.addOnRevenue.toStringAsFixed(2),
      jsonEncode(summary.toppingCounts),
      jsonEncode(summary.comboCounts),
      jsonEncode(summary.addOnCounts),
      jsonEncode(summary.orderStatusBreakdown),
      summary.franchiseId,
    ].join(','));
    return csv.toString();
  }

  // === Invoices (No Date Formatting) ===
  static String invoicesToCsvRaw(List<Invoice> invoices) {
    final csv = StringBuffer();
    csv.writeln([
      'invoiceNumber',
      'status',
      'total',
      'currency',
      'issuedAt',
      'dueAt',
      'paidAt'
    ].map(_escape).join(','));

    for (final inv in invoices) {
      csv.writeln([
        _escape(inv.invoiceNumber),
        _escape(inv.status.toString().split('.').last),
        inv.total.toStringAsFixed(2),
        _escape(inv.currency),
        _escape(inv.issuedAt?.toIso8601String() ?? ''),
        _escape(inv.dueAt?.toIso8601String() ?? ''),
        _escape(inv.paidAt?.toIso8601String() ?? ''),
      ].join(','));
    }
    return csv.toString();
  }

  // === Generic Map Export ===
  static String mapsToCsv(List<Map<String, dynamic>> data,
      {List<String>? headers}) {
    if (data.isEmpty) return '';
    final csv = StringBuffer();
    final headerFields = headers ?? data.first.keys.toList();
    csv.writeln(headerFields.map(_escape).join(','));
    for (final map in data) {
      csv.writeln(
          headerFields.map((h) => _escape(map[h]?.toString())).join(','));
    }
    return csv.toString();
  }

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
}
