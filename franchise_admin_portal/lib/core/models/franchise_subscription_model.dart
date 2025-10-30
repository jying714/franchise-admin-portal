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

  /// Billing cycle duration in days (e.g. 30, 365)
  final int? billingCycleInDays;

  /// Embedded snapshot of the plan at time of subscription
  final Map<String, dynamic>? planSnapshot;

  /// Price at time of subscription (snapshot)
  final double priceAtSubscription;

  /// Date of subscription (explicit timestamp)
  final DateTime? subscribedAt;

  /// Date of subscription cancellation
  final bool cancelAtPeriodEnd;

  /// Timestamp of last known activity (e.g., user login, menu edit)
  final DateTime? lastActivity;

  /// Whether subscription auto-renews
  final bool autoRenew;

  /// Whether any associated invoice is overdue
  final bool hasOverdueInvoice;

  /// Payment provider customer ID (e.g., Stripe customer ID)
  final String? paymentProviderCustomerId;

  /// Last 4 digits of card used (for display)
  final String? cardLast4;

  /// Card brand (e.g., Visa, MasterCard)
  final String? cardBrand;

  /// Payment method ID (e.g., Stripe PM ID)
  final String? paymentMethodId;

  /// Billing contact email used for this subscription
  final String? billingEmail;

  /// Status of last payment attempt (e.g., 'succeeded', 'failed')
  final String? paymentStatus;

  /// Most recent payment receipt URL (for user access)
  final String? receiptUrl;

  /// Payment Grace period
  final DateTime? gracePeriodEndsAt;

  /// Optional payment token ID used for merchant API (e.g. Stripe setup intent)
  final String? paymentTokenId;

  /// Last payment
  final DateTime? lastPaymentAt;

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
    required this.cancelAtPeriodEnd,
    this.lastActivity,
    this.autoRenew = true,
    this.hasOverdueInvoice = false,
    required this.billingCycleInDays,
    this.paymentProviderCustomerId,
    this.cardLast4,
    this.cardBrand,
    this.paymentMethodId,
    this.billingEmail,
    this.paymentStatus,
    this.receiptUrl,
    this.gracePeriodEndsAt,
    this.paymentTokenId,
    this.lastPaymentAt,
  });

  factory FranchiseSubscription.fromMap(String id, Map<String, dynamic> data) {
    final snapshot = data['planSnapshot'] as Map<String, dynamic>? ?? {};

    print(
        '[FranchiseSubscriptionModel] fromMap: planId=${data['platformPlanId']}, price=${data['priceAtSubscription']}');

    return FranchiseSubscription(
      id: id,
      franchiseId: data['franchiseId'] ?? '',
      platformPlanId: data['platformPlanId'] ?? '',
      status: data['status'] ?? 'inactive',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nextBillingDate:
          (data['nextBillingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      billingCycleInDays: data['billingCycleInDays'] as int?,
      isTrial: data['isTrial'] ?? false,
      trialEndsAt: (data['trialEndsAt'] as Timestamp?)?.toDate(),
      discountPercent: data['discountPercent'] ?? 0,
      customQuoteDetails: data['customQuoteDetails'],
      lastInvoiceId: data['lastInvoiceId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      billingInterval: data['billingInterval'],
      planSnapshot: {
        'name': snapshot['name'],
        'description': snapshot['description'],
        'features': snapshot['features'] ?? [],
        'currency': snapshot['currency'],
        'price': snapshot['price'],
        'billingInterval': snapshot['billingInterval'],
        'isCustom': snapshot['isCustom'] ?? false,
        'planVersion': snapshot['planVersion'] ?? 'v1',
      },
      priceAtSubscription:
          (data['priceAtSubscription'] as num?)?.toDouble() ?? 0.0,
      subscribedAt: (data['subscribedAt'] as Timestamp?)?.toDate(),
      cancelAtPeriodEnd: data['cancelAtPeriodEnd'] ?? false,
      lastActivity: (data['lastActivity'] as Timestamp?)?.toDate(),
      autoRenew: data['autoRenew'] ?? true,
      hasOverdueInvoice: data['hasOverdueInvoice'] ?? false,
      paymentProviderCustomerId: data['paymentProviderCustomerId'],
      cardLast4: data['cardLast4'],
      cardBrand: data['cardBrand'],
      paymentMethodId: data['paymentMethodId'],
      billingEmail: data['billingEmail'],
      paymentStatus: data['paymentStatus'],
      receiptUrl: data['receiptUrl'],
      gracePeriodEndsAt: (data['gracePeriodEndsAt'] as Timestamp?)?.toDate(),
      paymentTokenId: data['paymentTokenId'],
      lastPaymentAt: (data['lastPaymentAt'] as Timestamp?)?.toDate(),
    );
  }

  factory FranchiseSubscription.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final snapshot = data['planSnapshot'] as Map<String, dynamic>? ?? {};

    return FranchiseSubscription(
      id: doc.id,
      franchiseId: data['franchiseId'] ?? '',
      platformPlanId: data['platformPlanId'] ?? '',
      status: data['status'] ?? 'active',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nextBillingDate:
          (data['nextBillingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      billingCycleInDays: data['billingCycleInDays'] as int?,
      isTrial: data['isTrial'] ?? false,
      trialEndsAt: (data['trialEndsAt'] as Timestamp?)?.toDate(),
      discountPercent: data['discountPercent'] ?? 0,
      customQuoteDetails: data['customQuoteDetails'],
      lastInvoiceId: data['lastInvoiceId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      billingInterval: data['billingInterval'],
      planSnapshot: {
        'name': snapshot['name'],
        'description': snapshot['description'],
        'features': snapshot['features'] ?? [],
        'currency': snapshot['currency'],
        'price': snapshot['price'],
        'billingInterval': snapshot['billingInterval'],
        'isCustom': snapshot['isCustom'] ?? false,
        'planVersion': snapshot['planVersion'] ?? 'v1',
      },
      priceAtSubscription:
          (data['priceAtSubscription'] as num?)?.toDouble() ?? 0.0,
      subscribedAt:
          (data['subscribedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cancelAtPeriodEnd: data['cancelAtPeriodEnd'] ?? false,
      lastActivity: (data['lastActivity'] as Timestamp?)?.toDate(),
      autoRenew: data['autoRenew'] ?? true,
      hasOverdueInvoice: data['hasOverdueInvoice'] ?? false,
      paymentProviderCustomerId: data['paymentProviderCustomerId'],
      cardLast4: data['cardLast4'],
      cardBrand: data['cardBrand'],
      paymentMethodId: data['paymentMethodId'],
      billingEmail: data['billingEmail'],
      paymentStatus: data['paymentStatus'],
      receiptUrl: data['receiptUrl'],
      gracePeriodEndsAt: (data['gracePeriodEndsAt'] as Timestamp?)?.toDate(),
      paymentTokenId: data['paymentTokenId'],
      lastPaymentAt: (data['lastPaymentAt'] as Timestamp?)?.toDate(),
    );
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
      'cancelAtPeriodEnd': cancelAtPeriodEnd,
      'lastActivity':
          lastActivity != null ? Timestamp.fromDate(lastActivity!) : null,
      'autoRenew': autoRenew,
      'cancelAtPeriodEnd': cancelAtPeriodEnd,
      'hasOverdueInvoice': hasOverdueInvoice,
      'billingCycleInDays': billingCycleInDays,
      'paymentProviderCustomerId': paymentProviderCustomerId,
      'cardLast4': cardLast4,
      'cardBrand': cardBrand,
      'paymentMethodId': paymentMethodId,
      'billingEmail': billingEmail,
      'paymentStatus': paymentStatus,
      'receiptUrl': receiptUrl,
      'gracePeriodEndsAt': gracePeriodEndsAt != null
          ? Timestamp.fromDate(gracePeriodEndsAt!)
          : null,
      'paymentTokenId': paymentTokenId,
      'lastPaymentAt':
          lastPaymentAt != null ? Timestamp.fromDate(lastPaymentAt!) : null,
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
    bool? cancelAtPeriodEnd,
    DateTime? lastActivity,
    bool? autoRenew,
    bool? hasOverdueInvoice,
    int? billingCycleInDays,
    String? paymentProviderCustomerId,
    String? cardLast4,
    String? cardBrand,
    String? paymentMethodId,
    String? billingEmail,
    String? paymentStatus,
    String? receiptUrl,
    DateTime? gracePeriodEndsAt,
    String? paymentTokenId,
    DateTime? lastPaymentAt,
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
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
      lastActivity: lastActivity ?? this.lastActivity,
      autoRenew: autoRenew ?? this.autoRenew,
      hasOverdueInvoice: hasOverdueInvoice ?? this.hasOverdueInvoice,
      billingCycleInDays: billingCycleInDays ?? this.billingCycleInDays,
      paymentProviderCustomerId:
          paymentProviderCustomerId ?? this.paymentProviderCustomerId,
      cardLast4: cardLast4 ?? this.cardLast4,
      cardBrand: cardBrand ?? this.cardBrand,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      billingEmail: billingEmail ?? this.billingEmail,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      gracePeriodEndsAt: gracePeriodEndsAt ?? this.gracePeriodEndsAt,
      paymentTokenId: paymentTokenId ?? this.paymentTokenId,
      lastPaymentAt: lastPaymentAt ?? this.lastPaymentAt,
    );
  }

  bool get hasSavedPaymentToken =>
      paymentTokenId != null && paymentTokenId!.isNotEmpty;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FranchiseSubscription &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
