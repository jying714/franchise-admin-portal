import 'package:cloud_firestore/cloud_firestore.dart';

class Payout {
  final String id;
  final DocumentReference franchiseRef;
  final DocumentReference locationRef;
  final DocumentReference bankAccountRef;
  final double amount;
  final String currency;
  final String status; // pending, sent, failed, on_hold
  final String method;
  final String? bankAccountLast4;
  final String? notes;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? failedAt;
  final DateTime? confirmedAt;
  final DateTime? createdAt;
  final String? failureReason;
  final String? errorCode;
  final String? errorMessage;
  final List<Map<String, dynamic>> attachments;
  final List<Map<String, dynamic>> auditTrail;
  final Map<String, dynamic> customFields;

  Payout({
    required this.id,
    required this.franchiseRef,
    required this.locationRef,
    required this.bankAccountRef,
    required this.amount,
    required this.currency,
    required this.status,
    required this.method,
    this.bankAccountLast4,
    this.notes,
    this.scheduledAt,
    this.sentAt,
    this.failedAt,
    this.confirmedAt,
    this.createdAt,
    this.failureReason,
    this.errorCode,
    this.errorMessage,
    this.attachments = const [],
    this.auditTrail = const [],
    this.customFields = const {},
  });

  factory Payout.fromFirestore(Map<String, dynamic> data, String id) {
    return Payout(
      id: id,
      franchiseRef: data['franchiseId'] as DocumentReference,
      locationRef: data['locationId'] as DocumentReference,
      bankAccountRef: data['bank_account_id'] as DocumentReference,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? '',
      status: data['status'] ?? '',
      method: data['method'] ?? '',
      bankAccountLast4: data['bank_account_last4'],
      notes: data['notes'],
      scheduledAt: (data['scheduled_at'] as Timestamp?)?.toDate(),
      sentAt: (data['sent_at'] as Timestamp?)?.toDate(),
      failedAt: (data['failed_at'] as Timestamp?)?.toDate(),
      confirmedAt: (data['confirmed_at'] as Timestamp?)?.toDate(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      failureReason: data['failure_reason'] ?? data['error_message'],
      errorCode: data['error_code'],
      errorMessage: data['error_message'],
      attachments: (data['attachments'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      auditTrail: (data['audit_trail'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      customFields: data['custom_fields'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'franchiseId': franchiseRef,
      'locationId': locationRef,
      'bank_account_id': bankAccountRef,
      'amount': amount,
      'currency': currency,
      'status': status,
      'method': method,
      'bank_account_last4': bankAccountLast4,
      'notes': notes,
      'scheduled_at':
          scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'sent_at': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'failed_at': failedAt != null ? Timestamp.fromDate(failedAt!) : null,
      'confirmed_at':
          confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'failure_reason': failureReason,
      'error_code': errorCode,
      'error_message': errorMessage,
      'attachments': attachments,
      'audit_trail': auditTrail,
      'custom_fields': customFields,
    };
  }

  Payout copyWith({
    String? id,
    DocumentReference? franchiseRef,
    DocumentReference? locationRef,
    DocumentReference? bankAccountRef,
    double? amount,
    String? currency,
    String? status,
    String? method,
    String? bankAccountLast4,
    String? notes,
    DateTime? scheduledAt,
    DateTime? sentAt,
    DateTime? failedAt,
    DateTime? confirmedAt,
    DateTime? createdAt,
    String? failureReason,
    String? errorCode,
    String? errorMessage,
    List<Map<String, dynamic>>? attachments,
    List<Map<String, dynamic>>? auditTrail,
    Map<String, dynamic>? customFields,
  }) {
    return Payout(
      id: id ?? this.id,
      franchiseRef: franchiseRef ?? this.franchiseRef,
      locationRef: locationRef ?? this.locationRef,
      bankAccountRef: bankAccountRef ?? this.bankAccountRef,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      method: method ?? this.method,
      bankAccountLast4: bankAccountLast4 ?? this.bankAccountLast4,
      notes: notes ?? this.notes,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      failedAt: failedAt ?? this.failedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      createdAt: createdAt ?? this.createdAt,
      failureReason: failureReason ?? this.failureReason,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      attachments: attachments ?? this.attachments,
      auditTrail: auditTrail ?? this.auditTrail,
      customFields: customFields ?? this.customFields,
    );
  }
}
