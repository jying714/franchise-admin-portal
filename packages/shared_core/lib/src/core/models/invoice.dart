// File: lib/core/models/invoice.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/invoice_status.dart';

/// ========================
/// ENUMS
/// ========================

InvoiceStatus invoiceStatusFromString(String status) {
  switch (status) {
    case 'draft':
      return InvoiceStatus.draft;
    case 'sent':
      return InvoiceStatus.sent;
    case 'viewed':
      return InvoiceStatus.viewed;
    case 'open': // <--- add this case
      return InvoiceStatus.open;
    case 'paid':
      return InvoiceStatus.paid;
    case 'overdue':
      return InvoiceStatus.overdue;
    case 'refunded':
      return InvoiceStatus.refunded;
    case 'voided':
      return InvoiceStatus.voided;
    case 'archived':
      return InvoiceStatus.archived;
    case 'failed':
      return InvoiceStatus.failed;
    default:
      return InvoiceStatus.draft;
  }
}

String invoiceStatusToString(InvoiceStatus status) => describeEnum(status);

/// ========================
/// SUB-MODELS (Typed)
/// ========================

class InvoiceLineItem {
  final String id;
  final String description;
  final double unitPrice;
  final int quantity;
  final double? tax; // for line-specific tax (optional)
  final String? sku;
  final String? notes;

  InvoiceLineItem({
    required this.id,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    this.tax,
    this.sku,
    this.notes,
  });

  double get total => (unitPrice * quantity) + (tax ?? 0.0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'tax': tax,
      'sku': sku,
      'notes': notes,
    };
  }

  factory InvoiceLineItem.fromMap(Map<String, dynamic> map) {
    return InvoiceLineItem(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 1,
      tax: (map['tax'] as num?)?.toDouble(),
      sku: map['sku'],
      notes: map['notes'],
    );
  }
}

class InvoiceAuditEvent {
  final DateTime timestamp;
  final String eventType; // e.g. 'created', 'sent', 'paid', etc.
  final String userId;
  final String? notes;

  InvoiceAuditEvent({
    required this.timestamp,
    required this.eventType,
    required this.userId,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'eventType': eventType,
      'userId': userId,
      'notes': notes,
    };
  }

  factory InvoiceAuditEvent.fromMap(Map<String, dynamic> map) {
    return InvoiceAuditEvent(
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      eventType: map['eventType'] ?? '',
      userId: map['userId'] ?? '',
      notes: map['notes'],
    );
  }
}

class InvoiceSupportNote {
  final DateTime createdAt;
  final String userId;
  final String content;

  InvoiceSupportNote({
    required this.createdAt,
    required this.userId,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'content': content,
    };
  }

  factory InvoiceSupportNote.fromMap(Map<String, dynamic> map) {
    return InvoiceSupportNote(
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
    );
  }
}

class InvoiceAttachment {
  final String url;
  final String fileName;
  final DateTime uploadedAt;

  InvoiceAttachment({
    required this.url,
    required this.fileName,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'fileName': fileName,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  factory InvoiceAttachment.fromMap(Map<String, dynamic> map) {
    return InvoiceAttachment(
      url: map['url'] ?? '',
      fileName: map['fileName'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
    );
  }
}

/// ========================
/// MAIN INVOICE MODEL
/// ========================

class Invoice {
  final String id;
  final String invoiceNumber;
  final DocumentReference franchiseRef;
  final DocumentReference locationRef;
  final String? customerName;
  final String? customerEmail;
  final String? customerAddress;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime? issuedAt;
  final DateTime? dueAt;
  final InvoiceStatus status;
  final double subtotal;
  final double tax;
  final double total;
  final String currency;
  final String paymentMethod;
  final DateTime? paidAt;
  final String? paidBy;
  final DateTime? refundedAt;
  final DateTime? voidedAt;
  final List<InvoiceLineItem> items;
  final List<InvoiceAuditEvent> auditTrail;
  final List<InvoiceAttachment> attachedFiles;
  final List<InvoiceSupportNote> supportNotes;
  final List<DateTime> overdueReminders;
  final Map<String, dynamic> customFields;

  /// SaaS: for multi-tax, payout, integrations
  final Map<String, double>? taxBreakdown; // e.g. {'state': 1.50, 'city': 2.00}
  final String? payoutId;
  final String? accountingId;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.franchiseRef,
    required this.locationRef,
    this.customerName,
    this.customerEmail,
    this.customerAddress,
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
    this.auditTrail = const [],
    this.attachedFiles = const [],
    this.supportNotes = const [],
    this.overdueReminders = const [],
    this.customFields = const {},
    this.taxBreakdown,
    this.payoutId,
    this.accountingId,
  });

  /// ================
  /// FROM/FIRESTORE
  /// ================

  factory Invoice.fromFirestore(Map<String, dynamic> data, String id) {
    print(
        '[Invoice] fromFirestore called for doc id: $id, data keys: ${data.keys}');
    return Invoice(
      id: id,
      invoiceNumber: data['invoice_number'] ?? '',
      franchiseRef: data['franchiseId'] as DocumentReference,
      locationRef: data['locationId'] as DocumentReference,
      customerName: data['customer_name'],
      customerEmail: data['customer_email'],
      customerAddress: data['customer_address'],
      periodStart: (data['period_start'] as Timestamp).toDate(),
      periodEnd: (data['period_end'] as Timestamp).toDate(),
      issuedAt: (data['issued_at'] as Timestamp?)?.toDate(),
      dueAt: (data['due_at'] as Timestamp?)?.toDate(),
      status: invoiceStatusFromString(data['status'] ?? 'draft'),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? '',
      paymentMethod: data['payment_method'] ?? '',
      paidAt: (data['paid_at'] as Timestamp?)?.toDate(),
      paidBy: data['paid_by'],
      refundedAt: (data['refunded_at'] as Timestamp?)?.toDate(),
      voidedAt: (data['voided_at'] as Timestamp?)?.toDate(),
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => InvoiceLineItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      auditTrail: (data['audit_trail'] as List<dynamic>? ?? [])
          .map((e) => InvoiceAuditEvent.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      attachedFiles: (data['attached_files'] as List<dynamic>? ?? [])
          .map((e) => InvoiceAttachment.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      supportNotes: (data['support_notes'] as List<dynamic>? ?? [])
          .map((e) => InvoiceSupportNote.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      overdueReminders: (data['overdue_reminders'] as List<dynamic>? ?? [])
          .map((e) => (e as Timestamp).toDate())
          .toList(),
      customFields: data['custom_fields'] ?? {},
      taxBreakdown: data['tax_breakdown'] != null
          ? Map<String, double>.from(data['tax_breakdown'])
          : null,
      payoutId: data['payout_id'],
      accountingId: data['accounting_id'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'invoice_number': invoiceNumber,
      'franchiseId': franchiseRef,
      'locationId': locationRef,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_address': customerAddress,
      'period_start': Timestamp.fromDate(periodStart),
      'period_end': Timestamp.fromDate(periodEnd),
      'issued_at': issuedAt != null ? Timestamp.fromDate(issuedAt!) : null,
      'due_at': dueAt != null ? Timestamp.fromDate(dueAt!) : null,
      'status': invoiceStatusToString(status),
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
      'items': items.map((i) => i.toMap()).toList(),
      'audit_trail': auditTrail.map((a) => a.toMap()).toList(),
      'attached_files': attachedFiles.map((f) => f.toMap()).toList(),
      'support_notes': supportNotes.map((n) => n.toMap()).toList(),
      'overdue_reminders':
          overdueReminders.map((d) => Timestamp.fromDate(d)).toList(),
      'custom_fields': customFields,
      'tax_breakdown': taxBreakdown,
      'payout_id': payoutId,
      'accounting_id': accountingId,
    };
  }

  /// =================
  /// COPY WITH
  /// =================
  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    DocumentReference? franchiseRef,
    DocumentReference? locationRef,
    String? customerName,
    String? customerEmail,
    String? customerAddress,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? issuedAt,
    DateTime? dueAt,
    InvoiceStatus? status,
    double? subtotal,
    double? tax,
    double? total,
    String? currency,
    String? paymentMethod,
    DateTime? paidAt,
    String? paidBy,
    DateTime? refundedAt,
    DateTime? voidedAt,
    List<InvoiceLineItem>? items,
    List<InvoiceAuditEvent>? auditTrail,
    List<InvoiceAttachment>? attachedFiles,
    List<InvoiceSupportNote>? supportNotes,
    List<DateTime>? overdueReminders,
    Map<String, dynamic>? customFields,
    Map<String, double>? taxBreakdown,
    String? payoutId,
    String? accountingId,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      franchiseRef: franchiseRef ?? this.franchiseRef,
      locationRef: locationRef ?? this.locationRef,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerAddress: customerAddress ?? this.customerAddress,
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
      auditTrail: auditTrail ?? this.auditTrail,
      attachedFiles: attachedFiles ?? this.attachedFiles,
      supportNotes: supportNotes ?? this.supportNotes,
      overdueReminders: overdueReminders ?? this.overdueReminders,
      customFields: customFields ?? this.customFields,
      taxBreakdown: taxBreakdown ?? this.taxBreakdown,
      payoutId: payoutId ?? this.payoutId,
      accountingId: accountingId ?? this.accountingId,
    );
  }

  /// =========================
  /// UI/LOGIC CONVENIENCE GETTERS
  /// =========================

  bool get isPaid => status == InvoiceStatus.paid;
  bool get isOverdue =>
      status == InvoiceStatus.overdue ||
      (dueAt != null && DateTime.now().isAfter(dueAt!) && !isPaid);
  bool get isDraft => status == InvoiceStatus.draft;
  bool get isRefunded => status == InvoiceStatus.refunded;
  bool get isVoided => status == InvoiceStatus.voided;
  bool get isFailed => status == InvoiceStatus.failed;

  double get totalTax {
    if (taxBreakdown == null) return tax;
    return taxBreakdown!.values
        .where((v) => v != null)
        .fold(0.0, (a, b) => a + (b ?? 0));
  }

  double get outstanding => total - (isPaid ? total : 0);

  String statusLabel(BuildContext context) {
    // TODO: Use AppLocalizations when available
    switch (status) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.viewed:
        return 'Viewed';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.refunded:
        return 'Refunded';
      case InvoiceStatus.voided:
        return 'Voided';
      case InvoiceStatus.archived:
        return 'Archived';
      case InvoiceStatus.failed:
        return 'Failed';
      default:
        return invoiceStatusToString(status);
    }
  }

  // === Future Feature Placeholder ===
  // You can add logic for CSV/Excel/PDF export serialization here.
}
