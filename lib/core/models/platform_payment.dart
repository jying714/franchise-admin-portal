// lib/models/platform_payment.dart
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A full, production-ready model for a platform-level payment from a franchisee
/// Supports one-time, split, scheduled, and recurring payments with metadata.
class PlatformPayment {
  /// Document ID
  final String id;

  /// ID of the franchisee making this payment
  final String franchiseeId;

  /// Optional: linked invoice
  final String? invoiceId;

  /// Optional: group ID for split/recurring payments
  final String? paymentGroupId;

  /// Type of payment behavior
  final String type; // 'one_time' | 'split' | 'scheduled' | 'recurring'

  /// Payment amount
  final double amount;

  /// ISO currency code (e.g. 'USD')
  final String currency;

  /// Method used for payment (e.g. PayPal, check)
  final String paymentMethod;

  /// Arbitrary details depending on method (e.g. masked card)
  final Map<String, dynamic>? methodDetails;

  /// When the payment record was created
  final DateTime createdAt;

  /// If scheduled, when it’s intended to occur
  final DateTime? scheduledFor;

  /// When the payment was actually processed
  final DateTime? executedAt;

  /// Optional recurrence rule (monthly, custom cron, etc.)
  final String? recurringRule;

  /// Current status of the payment
  final String
      status; // 'pending' | 'processing' | 'completed' | 'failed' | 'cancelled'

  /// Retry attempts (e.g. for failed charges)
  final int attempts;

  /// Error or rejection code if applicable
  final String? errorCode;

  /// Optional note or memo
  final String? note;

  /// If verified manually or by processor
  final String? confirmedBy;
  final DateTime? verifiedAt;

  /// System that originated the payment
  final String
      sourceSystem; // 'web' | 'mobile' | 'external_api' | 'admin_portal'

  /// Optional: sandbox/test payment flag
  final bool isTest;

  /// Optional: processor reference
  final String? externalTransactionId;

  /// Optional: downloadable receipt link
  final String? receiptUrl;

  /// Optional: jurisdiction-based tax/fee breakdown
  final Map<String, dynamic>? taxBreakdown;

  /// Optional: Store within the franchise (if applicable)
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

  /// Construct from Firestore doc
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
        methodDetails: Map<String, dynamic>.from(data['methodDetails'] ?? {}),
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
        taxBreakdown: Map<String, dynamic>.from(data['taxBreakdown'] ?? {}),
        franchiseLocationId: data['franchiseLocationId'],
      );
    } catch (e, stack) {
      // Ensure your error_logger.dart supports log() with both error and stacktrace.
      ErrorLogger.log(
        message: 'Failed to parse PlatformPayment: $e',
        stack: stack.toString(),
        source: 'platform_payment.fromMap',
        screen: 'platform_payment',
      );
      rethrow;
    }
  }

  /// Serialize for Firestore
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
