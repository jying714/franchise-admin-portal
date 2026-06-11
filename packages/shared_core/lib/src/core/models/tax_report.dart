import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

/// Production-grade TaxReport model for franchise tax compliance and reporting.
/// Fully aligns with schema patterns (franchise-scoped, timestamps, attachments, reminders).
class TaxReport {
  final String id;
  final String franchiseId;
  final String? franchiseLocationId;
  final String reportType; // quarterly, annual, sales_tax, etc.
  final String status; // draft, filed, pending, approved, rejected
  final String taxAuthority;
  final DateTime filingPeriodStart;
  final DateTime filingPeriodEnd;
  final DateTime? dueDate;
  final DateTime? filedAt;
  final double amount;
  final String currency;
  final Map<String, dynamic>? taxBreakdown;
  final List<Map<String, dynamic>> attachments;
  final List<Map<String, dynamic>> reminders;
  final String? notes;
  final String? confirmedBy;
  final DateTime? verifiedAt;
  final bool isTest;
  final String? externalReportId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaxReport({
    required this.id,
    required this.franchiseId,
    required this.reportType,
    required this.status,
    required this.taxAuthority,
    required this.filingPeriodStart,
    required this.filingPeriodEnd,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    this.franchiseLocationId,
    this.dueDate,
    this.filedAt,
    this.taxBreakdown,
    this.attachments = const [],
    this.reminders = const [],
    this.notes,
    this.confirmedBy,
    this.verifiedAt,
    this.isTest = false,
    this.externalReportId,
  });

  factory TaxReport.fromMap(String id, Map<String, dynamic> data) {
    try {
      return TaxReport(
        id: id,
        franchiseId: data['franchiseId'] ?? '',
        franchiseLocationId: data['franchiseLocationId'],
        reportType: data['reportType'] ?? '',
        status: data['status'] ?? 'draft',
        taxAuthority: data['taxAuthority'] ?? '',
        filingPeriodStart: (data['filingPeriodStart'] as Timestamp).toDate(),
        filingPeriodEnd: (data['filingPeriodEnd'] as Timestamp).toDate(),
        dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
        filedAt: (data['filedAt'] as Timestamp?)?.toDate(),
        amount: (data['amount'] ?? 0).toDouble(),
        currency: data['currency'] ?? 'USD',
        taxBreakdown: data['taxBreakdown'] != null
            ? Map<String, dynamic>.from(data['taxBreakdown'])
            : null,
        attachments: (data['attachments'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            const [],
        reminders: (data['reminders'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            const [],
        notes: data['notes'],
        confirmedBy: data['confirmedBy'],
        verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
        isTest: data['isTest'] ?? false,
        externalReportId: data['externalReportId'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to parse TaxReport: $e',
        stack: stack.toString(),
        source: 'tax_report.fromMap',
        contextData: {'docId': id, 'error': e.toString()},
      );
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'franchiseId': franchiseId,
      if (franchiseLocationId != null)
        'franchiseLocationId': franchiseLocationId,
      'reportType': reportType,
      'status': status,
      'taxAuthority': taxAuthority,
      'filingPeriodStart': Timestamp.fromDate(filingPeriodStart),
      'filingPeriodEnd': Timestamp.fromDate(filingPeriodEnd),
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      if (filedAt != null) 'filedAt': Timestamp.fromDate(filedAt!),
      'amount': amount,
      'currency': currency,
      if (taxBreakdown != null) 'taxBreakdown': taxBreakdown,
      'attachments': attachments,
      'reminders': reminders,
      if (notes != null) 'notes': notes,
      if (confirmedBy != null) 'confirmedBy': confirmedBy,
      if (verifiedAt != null) 'verifiedAt': Timestamp.fromDate(verifiedAt!),
      'isTest': isTest,
      if (externalReportId != null) 'externalReportId': externalReportId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TaxReport copyWith({
    String? id,
    String? franchiseId,
    String? franchiseLocationId,
    String? reportType,
    String? status,
    String? taxAuthority,
    DateTime? filingPeriodStart,
    DateTime? filingPeriodEnd,
    DateTime? dueDate,
    DateTime? filedAt,
    double? amount,
    String? currency,
    Map<String, dynamic>? taxBreakdown,
    List<Map<String, dynamic>>? attachments,
    List<Map<String, dynamic>>? reminders,
    String? notes,
    String? confirmedBy,
    DateTime? verifiedAt,
    bool? isTest,
    String? externalReportId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaxReport(
      id: id ?? this.id,
      franchiseId: franchiseId ?? this.franchiseId,
      franchiseLocationId: franchiseLocationId ?? this.franchiseLocationId,
      reportType: reportType ?? this.reportType,
      status: status ?? this.status,
      taxAuthority: taxAuthority ?? this.taxAuthority,
      filingPeriodStart: filingPeriodStart ?? this.filingPeriodStart,
      filingPeriodEnd: filingPeriodEnd ?? this.filingPeriodEnd,
      dueDate: dueDate ?? this.dueDate,
      filedAt: filedAt ?? this.filedAt,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      taxBreakdown: taxBreakdown ?? this.taxBreakdown,
      attachments: attachments ?? this.attachments,
      reminders: reminders ?? this.reminders,
      notes: notes ?? this.notes,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      isTest: isTest ?? this.isTest,
      externalReportId: externalReportId ?? this.externalReportId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
