// lib/src/core/models/platform_payment.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

/// A full, production-ready model for a platform-level payment from a franchisee
/// Supports one-time, split, scheduled, and recurring payments with metadata.
class PlatformPayment {
  final String id;
  final String franchiseeId;
  final String? invoiceId;
  final String? paymentGroupId;
  final String type;
  final double amount;
  final String currency;
  final String paymentMethod;
  final Map<String, dynamic>? methodDetails;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final DateTime? executedAt;
  final String? recurringRule;
  final String status;
  final int attempts;
  final String? errorCode;
  final String? note;
  final String? confirmedBy;
  final DateTime? verifiedAt;
  final String sourceSystem;
  final bool isTest;
  final String? externalTransactionId;
  final String? receiptUrl;
  final Map<String, dynamic>? taxBreakdown;
  final String? franchiseLocationId;

  PlatformPayment({
    required this.id,
    required this.franchiseeId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.createdAt,
    required this.status,
    required this.attempts,
    required this.sourceSystem,
    this.invoiceId,
    this.paymentGroupId,
    this.methodDetails,
    this.scheduledFor,
    this.executedAt,
    this.recurringRule,
    this.errorCode,
    this.note,
    this.confirmedBy,
    this.verifiedAt,
    this.isTest = false,
    this.externalTransactionId,
    this.receiptUrl,
    this.taxBreakdown,
    this.franchiseLocationId,
  });

  factory PlatformPayment.fromMap(String id, Map<String, dynamic> data) {
    try {
      return PlatformPayment(
        id: id,
        franchiseeId: data['franchiseeId'] ?? '',
        invoiceId: data['invoiceId'],
        paymentGroupId: data['paymentGroupId'],
        type: data['type'] ?? 'one_time',
        amount: (data['amount'] ?? 0).toDouble(),
        currency: data['currency'] ?? 'USD',
        paymentMethod: data['paymentMethod'] ?? 'unknown',
        methodDetails: data['methodDetails'] != null
            ? Map<String, dynamic>.from(data['methodDetails'])
            : null,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        scheduledFor: (data['scheduledFor'] as Timestamp?)?.toDate(),
        executedAt: (data['executedAt'] as Timestamp?)?.toDate(),
        recurringRule: data['recurringRule'],
        status: data['status'] ?? 'pending',
        attempts: data['attempts'] ?? 0,
        errorCode: data['errorCode'],
        note: data['note'],
        confirmedBy: data['confirmedBy'],
        verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
        sourceSystem: data['sourceSystem'] ?? 'web',
        isTest: data['isTest'] ?? false,
        externalTransactionId: data['externalTransactionId'],
        receiptUrl: data['receiptUrl'],
        taxBreakdown: data['taxBreakdown'] != null
            ? Map<String, dynamic>.from(data['taxBreakdown'])
            : null,
        franchiseLocationId: data['franchiseLocationId'],
      );
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to parse PlatformPayment: $e',
        stack: stack.toString(),
        source: 'platform_payment.fromMap',
        contextData: {'docId': id, 'error': e.toString()},
      );
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'franchiseeId': franchiseeId,
      if (invoiceId != null) 'invoiceId': invoiceId,
      if (paymentGroupId != null) 'paymentGroupId': paymentGroupId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      if (methodDetails != null) 'methodDetails': methodDetails,
      'createdAt': Timestamp.fromDate(createdAt),
      if (scheduledFor != null)
        'scheduledFor': Timestamp.fromDate(scheduledFor!),
      if (executedAt != null) 'executedAt': Timestamp.fromDate(executedAt!),
      if (recurringRule != null) 'recurringRule': recurringRule,
      'status': status,
      'attempts': attempts,
      if (errorCode != null) 'errorCode': errorCode,
      if (note != null) 'note': note,
      if (confirmedBy != null) 'confirmedBy': confirmedBy,
      if (verifiedAt != null) 'verifiedAt': Timestamp.fromDate(verifiedAt!),
      'sourceSystem': sourceSystem,
      'isTest': isTest,
      if (externalTransactionId != null)
        'externalTransactionId': externalTransactionId,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
      if (taxBreakdown != null) 'taxBreakdown': taxBreakdown,
      if (franchiseLocationId != null)
        'franchiseLocationId': franchiseLocationId,
    };
  }
}
