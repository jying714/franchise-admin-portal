import 'package:flutter/material.dart';
import 'package:admin_portal/core/models/franchise_subscription_model.dart';
import 'package:admin_portal/core/models/franchise_info.dart';
import 'package:admin_portal/core/models/platform_invoice.dart';
import 'package:admin_portal/core/models/user.dart' as app_user;

/// Combines a franchise subscription with enriched franchise and billing data.
class EnrichedFranchiseSubscription {
  /// Raw franchise subscription object.
  final FranchiseSubscription subscription;

  /// Franchise details (display name, logo, etc.)
  final FranchiseInfo? franchise;

  /// Optional latest invoice issued to this franchise.
  final PlatformInvoice? latestInvoice;

  /// Extracted metadata
  String get franchiseId => subscription.franchiseId;
  String get subscriptionStatus => subscription.status;
  String get planId => subscription.platformPlanId;
  DateTime get nextBilling => subscription.nextBillingDate;

  /// Optional: Displayable price summary string.
  String get priceLabel {
    final formatted = subscription.priceFormatted ?? '--';
    final interval = subscription.billingIntervalFormatted;
    return '\$$formatted / $interval';
  }

  /// Optional custom note
  String? get notes => subscription.customQuoteDetails;

  /// Optional visual branding
  String? get logoUrl => franchise?.logoUrl;
  String get franchiseName => franchise?.name ?? 'Unnamed Franchise';

  /// Used for sorting
  DateTime get sortTimestamp =>
      subscription.subscribedAt ?? subscription.startDate;

  /// Optional future insights field placeholder
  final Map<String, dynamic>? futureInsights;

  /// Associated franchise owner (if available)
  final app_user.User? owner;

  EnrichedFranchiseSubscription({
    required this.subscription,
    required this.franchise,
    this.latestInvoice,
    this.futureInsights,
    this.owner,
  });

  /// Helper for creating a stub entry if something fails to load.
  factory EnrichedFranchiseSubscription.stub(FranchiseSubscription sub) {
    return EnrichedFranchiseSubscription(
      subscription: sub,
      franchise: null,
      owner: null,
    );
  }

  /// Allows basic filtering e.g., by status or name.
  bool matches(String query) {
    final lower = query.toLowerCase();
    return franchiseName.toLowerCase().contains(lower) ||
        subscription.status.toLowerCase().contains(lower);
  }

  String get ownerName => (owner?.name?.trim().isNotEmpty ?? false)
      ? owner!.name
      : franchise?.ownerName ?? '—';
  String get contactEmail => owner?.email ?? franchise?.businessEmail ?? '—';
  String get phoneNumber => owner?.phoneNumber ?? franchise?.phone ?? '—';
  String? get userId => owner?.id;

  /// Returns true if the most recent invoice is unpaid and past due
  bool get isPaymentOverdue {
    final invoice = latestInvoice;
    return invoice?.isOverdue ?? false;
  }

  bool get isInvoicePaid => latestInvoice?.isPaid ?? false;

  bool get isInvoicePartial => latestInvoice?.isPartial ?? false;

  bool get isInvoiceUnpaid => latestInvoice?.isUnpaid ?? false;

  bool get isInvoiceOverdue => latestInvoice?.isOverdue ?? false;

  /// Timestamp of the last known activity (login or menu update)
  DateTime? get lastActivity {
    // Prefer user update timestamp
    return owner?.updatedAt ?? subscription.updatedAt;
  }
}
