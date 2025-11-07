// packages/shared_core/lib/src/core/services/invoice_service.dart

import '../models/invoice.dart';
import '../models/platform_invoice.dart';

/// Pure interface — no Firebase, no Flutter
abstract class InvoiceService {
  /// Creates a new invoice for a franchise
  Future<Invoice> createInvoice({
    required String franchiseId,
    required double amount,
    required String currency,
    required String status,
    String? description,
    DateTime? dueDate,
  });

  /// Updates an existing invoice
  Future<Invoice> updateInvoice({
    required String invoiceId,
    required String franchiseId,
    double? amount,
    String? currency,
    String? status,
    String? description,
    DateTime? dueDate,
  });

  /// Marks an invoice as paid
  Future<Invoice> markAsPaid({
    required String invoiceId,
    required String franchiseId,
    required String paymentMethod,
    double? amountPaid,
  });

  /// Sends invoice via email (triggers Cloud Function)
  Future<void> sendInvoice({
    required String invoiceId,
    required String franchiseId,
    required String recipientEmail,
  });

  /// Streams invoices for a franchise (filterable by status/date)
  Stream<List<Invoice>> streamInvoices({
    required String franchiseId,
    List<String>? statuses,
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Gets invoices once (filterable by status/date)
  Future<List<Invoice>> getInvoices({
    required String franchiseId,
    List<String>? statuses,
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Generates PDF for invoice (returns base64 or URL)
  Future<String> generateInvoicePdf({
    required String invoiceId,
    required String franchiseId,
  });

  /// Exports invoices as CSV
  Future<String> exportInvoicesToCsv({
    required String franchiseId,
    List<String>? statuses,
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Calculates overdue invoices summary
  Future<Map<String, dynamic>> getOverdueSummary(String franchiseId);

  /// Platform-level: Creates platform invoice (for HQ/platform fees)
  Future<PlatformInvoice> createPlatformInvoice({
    required String platformId,
    required double amount,
    required String currency,
    required String status,
    String? description,
    DateTime? dueDate,
  });

  /// Platform-level: Streams platform invoices
  Stream<List<PlatformInvoice>> streamPlatformInvoices({
    required String platformId,
    List<String>? statuses,
    DateTime? fromDate,
    DateTime? toDate,
  });
}
