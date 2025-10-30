// lib/models/platform_invoice.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin_portal/core/utils/error_logger.dart';

/// A production-grade model representing an invoice issued by the platform
/// to a franchisee (e.g. SaaS fees, royalties, services).
class PlatformInvoice {
  /// Document ID
  final String id;

  /// ID of the franchisee receiving the invoice
  final String franchiseeId;

  /// Optional: associated store (for franchisees with multiple locations)
  final String? franchiseLocationId;

  /// Human-readable invoice number
  final String invoiceNumber;

  /// Total amount due
  final double amount;

  /// ISO currency (e.g. 'USD')
  final String currency;

  /// Date the invoice was created
  final DateTime createdAt;

  /// Date the invoice is due
  final DateTime dueDate;

  /// Invoice status
  /// 'unpaid', 'paid', 'overdue', 'partial'
  final String status;

  /// Optional list of payment IDs made toward this invoice
  final List<String> paymentIds;

  /// Optional metadata describing charges
  final Map<String, dynamic>? lineItems;

  /// Optional note for context (e.g. "September Royalty Fee")
  final String? note;

  /// Optional URL to downloadable PDF
  final String? pdfUrl;

  /// Origin tag
  final String issuedBy; // 'platform'

  /// If this invoice is for a specific billing plan
  final String? planId;

  /// Optional breakdown of taxes/fees
  final Map<String, dynamic>? taxBreakdown;

  /// Optional sandbox/test invoice flag
  final bool isTest;

  /// True if the invoice has been marked paid
  bool get isPaid => status.toLowerCase() == 'paid';

  /// True if the invoice is unpaid and past the due date
  bool get isOverdue =>
      status.toLowerCase() == 'unpaid' && dueDate.isBefore(DateTime.now());

  /// True if invoice is partially paid
  bool get isPartial => status.toLowerCase() == 'partial';

  /// True if invoice is unpaid (not paid or partial)
  bool get isUnpaid => status.toLowerCase() == 'unpaid';

  /// Optional: Associated subscription (for recurring invoices)
  final String? subscriptionId;

  /// Timestamp when the invoice was paid (for audit / reconciliation)
  final DateTime? paidAt;

  /// Optional: External payment processor ID (e.g., Stripe invoice ID)
  final String? externalInvoiceId;

  /// Optional: External payment provider name (e.g., 'stripe')
  final String? paymentProvider;

  /// Optional: Method used (e.g. 'card', 'ach')
  final String? paymentMethod;

  /// Optional log of payment attempts with metadata
  final List<Map<String, dynamic>>? paymentAttempts;

  /// Last known status of payment attempt
  final String? lastAttemptStatus;

  /// Optional public receipt URL (if available from provider)
  final String? receiptUrl;

  PlatformInvoice({
    required this.id,
    required this.franchiseeId,
    required this.invoiceNumber,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.dueDate,
    required this.status,
    required this.issuedBy,
    this.franchiseLocationId,
    this.paymentIds = const [],
    this.lineItems,
    this.note,
    this.pdfUrl,
    this.planId,
    this.taxBreakdown,
    this.isTest = false,
    this.subscriptionId,
    this.paidAt,
    this.externalInvoiceId,
    this.paymentProvider,
    this.paymentMethod,
    this.paymentAttempts,
    this.lastAttemptStatus,
    this.receiptUrl,
  });

  /// Deserializes from Firestore document
  factory PlatformInvoice.fromMap(String id, Map<String, dynamic> data) {
    try {
      return PlatformInvoice(
        id: id,
        franchiseeId: data['franchiseeId'] ?? '',
        franchiseLocationId: data['franchiseLocationId'],
        invoiceNumber: data['invoiceNumber'] ?? '',
        amount: (data['amount'] ?? 0).toDouble(),
        currency: data['currency'] ?? 'USD',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        dueDate: (data['dueDate'] as Timestamp).toDate(),
        status: data['status'] ?? 'unpaid',
        issuedBy: data['issuedBy'] ?? 'platform',
        paymentIds: List<String>.from(data['paymentIds'] ?? []),
        lineItems: data['lineItems'] != null
            ? Map<String, dynamic>.from(data['lineItems'])
            : null,
        note: data['note'],
        pdfUrl: data['pdfUrl'],
        planId: data['planId'],
        taxBreakdown: data['taxBreakdown'] != null
            ? Map<String, dynamic>.from(data['taxBreakdown'])
            : null,
        isTest: data['isTest'] ?? false,
        subscriptionId: data['subscriptionId'],
        paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
        externalInvoiceId: data['externalInvoiceId'],
        paymentProvider: data['paymentProvider'],
        paymentMethod: data['paymentMethod'],
        paymentAttempts: data['paymentAttempts'] != null
            ? List<Map<String, dynamic>>.from(data['paymentAttempts'])
            : null,
        lastAttemptStatus: data['lastAttemptStatus'],
        receiptUrl: data['receiptUrl'],
      );
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to parse PlatformInvoice: $e',
        stack: stack.toString(),
        source: 'platform_invoice.fromMap',
        screen: 'platform_invoice',
      );
      rethrow;
    }
  }

  /// Converts to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'franchiseeId': franchiseeId,
      if (franchiseLocationId != null)
        'franchiseLocationId': franchiseLocationId,
      'invoiceNumber': invoiceNumber,
      'amount': amount,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'issuedBy': issuedBy,
      'paymentIds': paymentIds,
      if (lineItems != null) 'lineItems': lineItems,
      if (note != null) 'note': note,
      if (pdfUrl != null) 'pdfUrl': pdfUrl,
      if (planId != null) 'planId': planId,
      if (taxBreakdown != null) 'taxBreakdown': taxBreakdown,
      'isTest': isTest,
      if (subscriptionId != null) 'subscriptionId': subscriptionId,
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
      if (externalInvoiceId != null) 'externalInvoiceId': externalInvoiceId,
      if (paymentProvider != null) 'paymentProvider': paymentProvider,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paymentAttempts != null) 'paymentAttempts': paymentAttempts,
      if (lastAttemptStatus != null) 'lastAttemptStatus': lastAttemptStatus,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
    };
  }

  Map<String, dynamic> toWebhookPayload() {
    return {
      'invoiceId': id,
      'franchiseeId': franchiseeId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'receiptUrl': receiptUrl,
      'paymentProvider': paymentProvider,
      'externalInvoiceId': externalInvoiceId,
      'subscriptionId': subscriptionId,
      'invoiceNumber': invoiceNumber,
      'paidAt': paidAt?.toIso8601String(),
    };
  }

  /// Parses invoice data from a Stripe invoice webhook payload.
  factory PlatformInvoice.fromStripeWebhook(
    Map<String, dynamic> eventData,
    String invoiceId,
  ) {
    final invoice = eventData['data']['object'];

    return PlatformInvoice(
      id: invoiceId,
      franchiseeId: invoice['metadata']['franchiseeId'] ?? '',
      invoiceNumber: invoice['number'] ?? invoiceId,
      amount: (invoice['amount_due'] ?? 0) / 100, // Stripe uses cents
      currency: invoice['currency']?.toUpperCase() ?? 'USD',
      createdAt: DateTime.fromMillisecondsSinceEpoch(invoice['created'] * 1000),
      dueDate: invoice['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(invoice['due_date'] * 1000)
          : DateTime.fromMillisecondsSinceEpoch(invoice['created'] * 1000)
              .add(const Duration(days: 30)),
      status: invoice['status'] ?? 'unpaid',
      issuedBy: 'stripe',
      paymentIds:
          invoice['payment_intent'] != null ? [invoice['payment_intent']] : [],
      lineItems: invoice['lines'] != null
          ? {
              'raw': invoice['lines'],
            }
          : null,
      note: invoice['description'],
      pdfUrl: invoice['invoice_pdf'],
      receiptUrl:
          invoice['hosted_invoice_url'], // This is Stripe’s receipt page
      planId: invoice['metadata']['planId'],
      externalInvoiceId: invoice['id'],
      paymentProvider: 'stripe',
      paymentMethod:
          invoice['payment_settings']?['payment_method_types'] != null
              ? invoice['payment_settings']['payment_method_types'].join(', ')
              : null,
      isTest: invoice['livemode'] == false,
      subscriptionId: invoice['subscription'],
      paidAt: invoice['status_transitions']?['paid_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              invoice['status_transitions']['paid_at'] * 1000)
          : null,
    );
  }
}
