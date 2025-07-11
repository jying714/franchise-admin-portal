// lib/core/models/payout.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Payout {
  final String id;
  final DocumentReference franchiseRef;
  final DocumentReference locationRef;
  final DocumentReference bankAccountRef;
  final double amount;
  final String currency;
  final String status; // pending, sent, failed, on_hold
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final String? failureReason;
  final Map<String, dynamic> customFields;

  Payout({
    required this.id,
    required this.franchiseRef,
    required this.locationRef,
    required this.bankAccountRef,
    required this.amount,
    required this.currency,
    required this.status,
    this.scheduledAt,
    this.sentAt,
    this.failureReason,
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
      scheduledAt: (data['scheduled_at'] as Timestamp?)?.toDate(),
      sentAt: (data['sent_at'] as Timestamp?)?.toDate(),
      failureReason: data['failure_reason'],
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
      'scheduled_at':
          scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'sent_at': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'failure_reason': failureReason,
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
    DateTime? scheduledAt,
    DateTime? sentAt,
    String? failureReason,
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
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      failureReason: failureReason ?? this.failureReason,
      customFields: customFields ?? this.customFields,
    );
  }
}
