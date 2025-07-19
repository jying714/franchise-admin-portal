import 'package:cloud_firestore/cloud_firestore.dart';

class FranchiseSubscription {
  /// Firestore document ID
  final String id;

  /// Associated franchise ID
  final String franchiseId;

  /// Platform plan ID (linked to platform_plans collection)
  final String platformPlanId;

  /// Subscription status: 'active', 'paused', 'canceled', 'trialing', etc.
  final String status;

  /// Date the subscription started
  final DateTime startDate;

  /// Next billing cycle date
  final DateTime nextBillingDate;

  /// Whether the subscription is currently in trial mode
  final bool isTrial;

  /// Trial expiration (if applicable)
  final DateTime? trialEndsAt;

  /// Optional percentage discount applied
  final int discountPercent;

  /// Optional custom quote override
  final String? customQuoteDetails;

  /// ID of the last invoice (if applicable)
  final String? lastInvoiceId;

  /// Firestore creation timestamp
  final DateTime? createdAt;

  /// Firestore update timestamp
  final DateTime? updatedAt;

  /// e.g., 'monthly', 'yearly'
  final String? billingInterval;

  /// Embedded snapshot of the plan at time of subscription
  final Map<String, dynamic>? planSnapshot;

  /// Price at time of subscription (snapshot)
  final double priceAtSubscription;

  /// Date of subscription (explicit timestamp)
  final DateTime? subscribedAt;

  const FranchiseSubscription({
    required this.id,
    required this.franchiseId,
    required this.platformPlanId,
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
    final this.billingInterval,
    final this.planSnapshot,
    required this.priceAtSubscription,
    this.subscribedAt,
  });

  factory FranchiseSubscription.fromMap(String id, Map<String, dynamic> data) {
    print(
        '[FranchiseSubscriptionModel] fromMap: planId=${data['planId']}, price=${data['priceAtSubscription']}');

    return FranchiseSubscription(
      id: id,
      franchiseId: data['franchiseId'] ?? '',
      platformPlanId: data['platformPlanId'] ?? '',
      status: data['status'] ?? 'inactive',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nextBillingDate:
          (data['nextBillingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isTrial: data['isTrial'] ?? false,
      trialEndsAt: (data['trialEndsAt'] as Timestamp?)?.toDate(),
      discountPercent: data['discountPercent'] ?? 0,
      customQuoteDetails: data['customQuoteDetails'],
      lastInvoiceId: data['lastInvoiceId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      billingInterval: data['billingInterval'],
      planSnapshot: data['planSnapshot'] != null
          ? Map<String, dynamic>.from(data['planSnapshot'])
          : null,
      priceAtSubscription:
          (data['priceAtSubscription'] as num?)?.toDouble() ?? 0.0,
      subscribedAt: (data['subscribedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory FranchiseSubscription.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return FranchiseSubscription.fromMap(doc.id, data);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'franchiseId': franchiseId,
      'platformPlanId': platformPlanId,
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
      'billingInterval': billingInterval,
      'planSnapshot': planSnapshot,
      'priceAtSubscription': priceAtSubscription,
      'subscribedAt': subscribedAt != null
          ? Timestamp.fromDate(subscribedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  FranchiseSubscription copyWith({
    String? franchiseId,
    String? platformPlanId,
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
    double? priceAtSubscription,
    DateTime? subscribedAt,
  }) {
    return FranchiseSubscription(
      id: id,
      franchiseId: franchiseId ?? this.franchiseId,
      platformPlanId: platformPlanId ?? this.platformPlanId,
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
      priceAtSubscription: priceAtSubscription ?? this.priceAtSubscription,
      subscribedAt: subscribedAt ?? this.subscribedAt,
    );
  }

  /// Returns a readable formatted summary of the current plan for display purposes.
  String get displaySummary {
    final priceString =
        '\$${priceFormatted ?? 'N/A'} / $billingIntervalFormatted';
    return '$planName – $priceString';
  }

  /// Extracted snapshot plan name (if available)
  String? get planName => platformPlanId;

  /// Formats billing interval
  String get billingIntervalFormatted {
    switch (billingInterval?.toLowerCase()) {
      case 'monthly':
        return 'mo';
      case 'yearly':
        return 'yr';
      default:
        return billingInterval ?? 'N/A';
    }
  }

  /// Returns the price at time of subscription (if available)
  String? get priceFormatted {
    final snapshot = planSnapshot;
    if (snapshot != null && snapshot['price'] != null) {
      return (snapshot['price'] as num).toStringAsFixed(2);
    }
    return null;
  }
}
