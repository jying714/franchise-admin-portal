import 'dart:convert';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:franchise_admin_portal/core/models/analytics_summary.dart';
import 'package:franchise_admin_portal/core/models/promo.dart';
import 'package:franchise_admin_portal/core/models/audit_log.dart';
import 'package:franchise_admin_portal/core/models/menu_item.dart';

/// =======================
/// ExportUtils
/// =======================
/// - Helper functions for exporting lists of app models to CSV or JSON.
/// - Used for admin backup, data auditing, and export/download screens.
/// =======================

class ExportUtils {
  /// Exports a list of MenuItem objects to CSV string.
  /// Includes all key fields, nutrition, tags, and customizations as JSON.
  static String menuItemsToCsv(List<MenuItem> items) {
    final csv = StringBuffer();
    csv.writeln(
      [
        "id",
        "name",
        "category",
        "categoryId",
        "description",
        "price",
        "availability",
        "taxCategory",
        "sku",
        "image",
        "dietaryTags",
        "allergens",
        "prepTime",
        "nutrition",
        "customizations",
        "customizationGroups"
      ].join(','),
    );
    for (final item in items) {
      csv.writeln([
        _escape(item.id),
        _escape(item.name),
        _escape(item.category),
        _escape(item.categoryId ?? ''),
        _escape(item.description),
        item.price.toStringAsFixed(2),
        item.availability ? "TRUE" : "FALSE",
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

  /// Exports a list of Category objects to CSV string.
  static String categoriesToCsv(List<Category> cats) {
    final csv = StringBuffer();
    csv.writeln("id,name,description,image");
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

  /// Exports a list of AuditLog entries to CSV.
  static String auditLogsToCsv(List<AuditLog> logs) {
    final csv = StringBuffer();
    csv.writeln("id,action,userId,timestamp,ipAddress,details");
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

  /// Exports a list of Promo objects to CSV string.
  static String promosToCsv(List<Promo> promos) {
    final csv = StringBuffer();
    csv.writeln(
        "id,name,description,discount,code,active,type,applicableItems,maxUses,maxUsesType,minOrderValue,startDate,endDate,segment,timeRules");
    for (final promo in promos) {
      csv.writeln([
        _escape(promo.id),
        _escape(promo.name),
        _escape(promo.description ?? ''),
        promo.discount.toStringAsFixed(2),
        _escape(promo.code ?? ''),
        promo.active ? "TRUE" : "FALSE",
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
    return csv.toString();
  }

  /// Exports a single AnalyticsSummary to CSV string (as a one-row file).
  static String analyticsSummaryToCsv(AnalyticsSummary summary) {
    final csv = StringBuffer();
    csv.writeln(
        "period,totalOrders,totalRevenue,averageOrderValue,mostPopularItem,retention,uniqueCustomers,cancelledOrders,addOnRevenue,toppingCounts,comboCounts,addOnCounts,orderStatusBreakdown,franchiseId");
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
    return csv.toString();
  }

  /// Exports a list of AnalyticsSummary objects to CSV (multi-row export).
  static String analyticsSummariesToCsv(List<AnalyticsSummary> summaries) {
    final csv = StringBuffer();
    csv.writeln(
        "date,totalOrders,totalRevenue,averageOrderValue,mostPopularItem,orderVolumeByHour,itemCounts,retention");
    for (final summary in summaries) {
      csv.writeln(
          "period,totalOrders,totalRevenue,averageOrderValue,mostPopularItem,retention,uniqueCustomers,cancelledOrders,addOnRevenue,toppingCounts,comboCounts,addOnCounts,orderStatusBreakdown,franchiseId");
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
    }
    return csv.toString();
  }

  /// Helper for escaping CSV fields, including null.
  static String _escape(String? s) {
    if (s == null) return '';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Optionally: convert any list of Map<String, dynamic> to CSV.
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
}
