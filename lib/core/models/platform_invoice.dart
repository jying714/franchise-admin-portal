// lib/models/platform_invoice.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

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
    };
  }
}
