import 'package:cloud_firestore/cloud_firestore.dart';

class FranchiseSubscription {
  final String id;
  final String franchiseId;
  final String planId;
  final String status; // e.g., 'active', 'paused', 'canceled', 'trialing'
  final DateTime startDate;
  final DateTime nextBillingDate;
  final bool isTrial;
  final DateTime? trialEndsAt;
  final int discountPercent;
  final String? customQuoteDetails;
  final String? lastInvoiceId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FranchiseSubscription({
    required this.id,
    required this.franchiseId,
    required this.planId,
    required this.status,
    required this.startDate,
    required this.nextBillingDate,
    required this.isTrial,
    this.trialEndsAt,
    required this.discountPercent,
    this.customQuoteDetails,
    this.lastInvoiceId,
    this.createdAt,
    this.updatedAt,
  });

  factory FranchiseSubscription.fromMap(String id, Map<String, dynamic> data) {
    return FranchiseSubscription(
      id: id,
      franchiseId: data['franchiseId'] ?? '',
      planId: data['planId'] ?? '',
      status: data['status'] ?? 'unknown',
      startDate: (data['startDate'] as Timestamp).toDate(),
      nextBillingDate: (data['nextBillingDate'] as Timestamp).toDate(),
      isTrial: data['isTrial'] ?? false,
      trialEndsAt: data['trialEndsAt'] != null
          ? (data['trialEndsAt'] as Timestamp).toDate()
          : null,
      discountPercent: data['discountPercent'] ?? 0,
      customQuoteDetails: data['customQuoteDetails'],
      lastInvoiceId: data['lastInvoiceId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'franchiseId': franchiseId,
      'planId': planId,
      'status': status,
      'startDate': Timestamp.fromDate(startDate),
      'nextBillingDate': Timestamp.fromDate(nextBillingDate),
      'isTrial': isTrial,
      'trialEndsAt':
          trialEndsAt != null ? Timestamp.fromDate(trialEndsAt!) : null,
      'discountPercent': discountPercent,
      'customQuoteDetails': customQuoteDetails,
      'lastInvoiceId': lastInvoiceId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  FranchiseSubscription copyWith({
    String? franchiseId,
    String? planId,
    String? status,
    DateTime? startDate,
    DateTime? nextBillingDate,
    bool? isTrial,
    DateTime? trialEndsAt,
    int? discountPercent,
    String? customQuoteDetails,
    String? lastInvoiceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FranchiseSubscription(
      id: id,
      franchiseId: franchiseId ?? this.franchiseId,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      isTrial: isTrial ?? this.isTrial,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      discountPercent: discountPercent ?? this.discountPercent,
      customQuoteDetails: customQuoteDetails ?? this.customQuoteDetails,
      lastInvoiceId: lastInvoiceId ?? this.lastInvoiceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
