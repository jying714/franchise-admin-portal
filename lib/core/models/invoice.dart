// lib/core/models/invoice.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Invoice {
  final String id;
  final DocumentReference franchiseRef;
  final DocumentReference locationRef;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime? issuedAt;
  final DateTime? dueAt;
  final String status;
  final double subtotal;
  final double tax;
  final double total;
  final String currency;
  final String paymentMethod;
  final DateTime? paidAt;
  final String? paidBy;
  final DateTime? refundedAt;
  final DateTime? voidedAt;
  final List<Map<String, dynamic>> items;
  final List<dynamic> overdueReminders;
  final List<dynamic> attachedFiles;
  final List<dynamic> supportNotes;
  final List<dynamic> auditTrail;
  final Map<String, dynamic> customFields;

  Invoice({
    required this.id,
    required this.franchiseRef,
    required this.locationRef,
    required this.periodStart,
    required this.periodEnd,
    this.issuedAt,
    this.dueAt,
    required this.status,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.currency,
    required this.paymentMethod,
    this.paidAt,
    this.paidBy,
    this.refundedAt,
    this.voidedAt,
    this.items = const [],
    this.overdueReminders = const [],
    this.attachedFiles = const [],
    this.supportNotes = const [],
    this.auditTrail = const [],
    this.customFields = const {},
  });

  factory Invoice.fromFirestore(Map<String, dynamic> data, String id) {
    return Invoice(
      id: id,
      franchiseRef: data['franchiseId'] as DocumentReference,
      locationRef: data['locationId'] as DocumentReference,
      periodStart: (data['period_start'] as Timestamp).toDate(),
      periodEnd: (data['period_end'] as Timestamp).toDate(),
      issuedAt: (data['issued_at'] as Timestamp?)?.toDate(),
      dueAt: (data['due_at'] as Timestamp?)?.toDate(),
      status: data['status'] ?? '',
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? '',
      paymentMethod: data['payment_method'] ?? '',
      paidAt: (data['paid_at'] as Timestamp?)?.toDate(),
      paidBy: data['paid_by'],
      refundedAt: (data['refunded_at'] as Timestamp?)?.toDate(),
      voidedAt: (data['voided_at'] as Timestamp?)?.toDate(),
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      overdueReminders: data['overdue_reminders'] ?? [],
      attachedFiles: data['attached_files'] ?? [],
      supportNotes: data['support_notes'] ?? [],
      auditTrail: data['audit_trail'] ?? [],
      customFields: data['custom_fields'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'franchiseId': franchiseRef,
      'locationId': locationRef,
      'period_start': Timestamp.fromDate(periodStart),
      'period_end': Timestamp.fromDate(periodEnd),
      'issued_at': issuedAt != null ? Timestamp.fromDate(issuedAt!) : null,
      'due_at': dueAt != null ? Timestamp.fromDate(dueAt!) : null,
      'status': status,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'currency': currency,
      'payment_method': paymentMethod,
      'paid_at': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'paid_by': paidBy,
      'refunded_at':
          refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'voided_at': voidedAt != null ? Timestamp.fromDate(voidedAt!) : null,
      'items': items,
      'overdue_reminders': overdueReminders,
      'attached_files': attachedFiles,
      'support_notes': supportNotes,
      'audit_trail': auditTrail,
      'custom_fields': customFields,
    };
  }

  Invoice copyWith({
    String? id,
    DocumentReference? franchiseRef,
    DocumentReference? locationRef,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? issuedAt,
    DateTime? dueAt,
    String? status,
    double? subtotal,
    double? tax,
    double? total,
    String? currency,
    String? paymentMethod,
    DateTime? paidAt,
    String? paidBy,
    DateTime? refundedAt,
    DateTime? voidedAt,
    List<Map<String, dynamic>>? items,
    List<dynamic>? overdueReminders,
    List<dynamic>? attachedFiles,
    List<dynamic>? supportNotes,
    List<dynamic>? auditTrail,
    Map<String, dynamic>? customFields,
  }) {
    return Invoice(
      id: id ?? this.id,
      franchiseRef: franchiseRef ?? this.franchiseRef,
      locationRef: locationRef ?? this.locationRef,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      issuedAt: issuedAt ?? this.issuedAt,
      dueAt: dueAt ?? this.dueAt,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      paidBy: paidBy ?? this.paidBy,
      refundedAt: refundedAt ?? this.refundedAt,
      voidedAt: voidedAt ?? this.voidedAt,
      items: items ?? this.items,
      overdueReminders: overdueReminders ?? this.overdueReminders,
      attachedFiles: attachedFiles ?? this.attachedFiles,
      supportNotes: supportNotes ?? this.supportNotes,
      auditTrail: auditTrail ?? this.auditTrail,
      customFields: customFields ?? this.customFields,
    );
  }
}
