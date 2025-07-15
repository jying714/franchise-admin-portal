// File: lib/core/services/invoice_service.dart
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/invoice.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/widgets/dashboard/billing_summary_card.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service class handling all Invoice-related Firestore operations.
/// Integrates error logging, supports filtering, streaming, and atomic updates.
/// Designed for franchise SaaS billing system.

class InvoiceService {
  final FirebaseFirestore _db;

  InvoiceService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Adds a new invoice or updates existing invoice document.
  Future<void> addOrUpdateInvoice(Invoice invoice) async {
    try {
      await _db
          .collection('invoices')
          .doc(invoice.id)
          .set(invoice.toFirestore(), SetOptions(merge: true));
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'InvoiceService',
        screen: 'addOrUpdateInvoice',
        severity: 'error',
        contextData: {'invoiceId': invoice.id},
      );
      rethrow;
    }
  }

  /// Retrieves invoice by ID, or null if not found.
  Future<Invoice?> getInvoiceById(String id) async {
    try {
      final doc = await _db.collection('invoices').doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return Invoice.fromFirestore(doc.data()!, doc.id);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'InvoiceService',
        screen: 'getInvoiceById',
        severity: 'error',
        contextData: {'invoiceId': id},
      );
      rethrow;
    }
  }

  /// Deletes invoice document by ID.
  Future<void> deleteInvoice(String id) async {
    try {
      await _db.collection('invoices').doc(id).delete();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'InvoiceService',
        screen: 'deleteInvoice',
        severity: 'error',
        contextData: {'invoiceId': id},
      );
      rethrow;
    }
  }

  /// Streams invoices with optional filters.
  /// Supports filtering by franchiseId, brandId, locationId, status, date ranges.
  Stream<List<Invoice>> invoicesStream({
    String? franchiseId,
    String? brandId,
    String? locationId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _db.collection('invoices');

    if (franchiseId != null) {
      query = query.where('franchiseId', isEqualTo: franchiseId);
    }
    if (brandId != null) {
      query = query.where('brandId', isEqualTo: brandId);
    }
    if (locationId != null) {
      query = query.where('locationId', isEqualTo: locationId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (startDate != null) {
      query = query.where('period_start',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('period_end',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.snapshots().map((snap) => snap.docs
        .map((doc) =>
            Invoice.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  /// Updates the dunning state of an invoice.
  Future<void> updateInvoiceDunningState(
      String invoiceId, String dunningState) async {
    try {
      await _db.collection('invoices').doc(invoiceId).update({
        'dunning_state': dunningState,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'InvoiceService',
        screen: 'updateInvoiceDunningState',
        severity: 'error',
        contextData: {'invoiceId': invoiceId, 'dunningState': dunningState},
      );
      rethrow;
    }
  }

  /// Adds an overdue reminder to the invoice (atomic arrayUnion).
  Future<void> addInvoiceOverdueReminder(
      String invoiceId, Map<String, dynamic> reminder) async {
    try {
      await _db.collection('invoices').doc(invoiceId).update({
        'overdue_reminders': FieldValue.arrayUnion([reminder]),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'InvoiceService',
        screen: 'addInvoiceOverdueReminder',
        severity: 'error',
        contextData: {'invoiceId': invoiceId},
      );
      rethrow;
    }
  }

  /// Sets or updates a payment plan object for an invoice.
  Future<void> setInvoicePaymentPlan(
      String invoiceId, Map<String, dynamic> paymentPlan) async {
    try {
      await _db.collection('invoices').doc(invoiceId).update({
        'payment_plan': paymentPlan,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'InvoiceService',
        screen: 'setInvoicePaymentPlan',
        severity: 'error',
        contextData: {'invoiceId': invoiceId},
      );
      rethrow;
    }
  }

  /// Adds an escalation event/history entry (atomic arrayUnion).
  Future<void> addInvoiceEscalationEvent(
      String invoiceId, Map<String, dynamic> escalationEvent) async {
    try {
      await _db.collection('invoices').doc(invoiceId).update({
        'escalation_history': FieldValue.arrayUnion([escalationEvent]),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'InvoiceService',
        screen: 'addInvoiceEscalationEvent',
        severity: 'error',
        contextData: {'invoiceId': invoiceId},
      );
      rethrow;
    }
  }

  /// Fetches dunning workflow related fields for an invoice.
  Future<Map<String, dynamic>?> getInvoiceWorkflowFields(
      String invoiceId) async {
    try {
      final doc = await _db.collection('invoices').doc(invoiceId).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      return {
        'dunning_state': data['dunning_state'],
        'overdue_reminders': data['overdue_reminders'],
        'payment_plan': data['payment_plan'],
        'escalation_history': data['escalation_history'],
      };
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'InvoiceService',
        screen: 'getInvoiceWorkflowFields',
        severity: 'error',
        contextData: {'invoiceId': invoiceId},
      );
      rethrow;
    }
  }

  /// Removes payment plan from invoice.
  Future<void> removeInvoicePaymentPlan(String invoiceId) async {
    try {
      await _db.collection('invoices').doc(invoiceId).update({
        'payment_plan': FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'InvoiceService',
        screen: 'removeInvoicePaymentPlan',
        severity: 'error',
        contextData: {'invoiceId': invoiceId},
      );
      rethrow;
    }
  }

  /// Adds a support note (atomic arrayUnion).
  Future<void> addInvoiceSupportNote(
      String invoiceId, Map<String, dynamic> note) async {
    try {
      await _db.collection('invoices').doc(invoiceId).update({
        'support_notes': FieldValue.arrayUnion([note]),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'InvoiceService',
        screen: 'addInvoiceSupportNote',
        severity: 'error',
        contextData: {'invoiceId': invoiceId},
      );
      rethrow;
    }
  }

  /// Adds an attachment (atomic arrayUnion).
  Future<void> addInvoiceAttachment(
      String invoiceId, Map<String, dynamic> attachment) async {
    try {
      await _db.collection('invoices').doc(invoiceId).update({
        'attached_files': FieldValue.arrayUnion([attachment]),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'InvoiceService',
        screen: 'addInvoiceAttachment',
        severity: 'error',
        contextData: {'invoiceId': invoiceId},
      );
      rethrow;
    }
  }

  static Future<BillingSummaryData> getBillingSummary(
      {required String franchiseId}) async {
    // Example Firestore structure (adjust as needed)
    final invoices = await FirebaseFirestore.instance
        .collection('invoices')
        .where('franchiseId', isEqualTo: franchiseId)
        .get();
    double outstanding = 0;
    int overdue = 0;
    double paidLast30 = 0;
    final now = DateTime.now();
    for (var doc in invoices.docs) {
      final data = doc.data();
      if (data['status'] == 'overdue') overdue++;
      if (data['status'] == 'unpaid' || data['status'] == 'overdue') {
        outstanding += (data['amount_due'] ?? 0) * 1.0;
      }
      if (data['status'] == 'paid') {
        final paidDate = (data['paid_at'] as Timestamp?)?.toDate();
        if (paidDate != null && now.difference(paidDate).inDays <= 30) {
          paidLast30 += (data['amount_paid'] ?? 0) * 1.0;
        }
      }
    }
    return BillingSummaryData(
      totalOutstanding: outstanding,
      overdueCount: overdue,
      paidLast30Days: paidLast30,
    );
  }

  static Future<String> downloadSummary({
    required String franchiseId,
    BuildContext? context,
  }) async {
    try {
      // 1. Query all invoices for the franchise
      final invoices = await FirebaseFirestore.instance
          .collection('invoices')
          .where('franchiseId', isEqualTo: franchiseId)
          .get();

      // 2. Prepare CSV rows
      final csvRows = <List<String>>[
        [
          'Invoice ID',
          'Status',
          'Amount Due',
          'Amount Paid',
          'Due Date',
          'Paid At',
          'Created At'
        ]
      ];
      for (var doc in invoices.docs) {
        final data = doc.data();
        csvRows.add([
          doc.id,
          data['status']?.toString() ?? '',
          (data['amount_due'] ?? '').toString(),
          (data['amount_paid'] ?? '').toString(),
          (data['due_date'] is Timestamp)
              ? (data['due_date'] as Timestamp).toDate().toIso8601String()
              : '',
          (data['paid_at'] is Timestamp)
              ? (data['paid_at'] as Timestamp).toDate().toIso8601String()
              : '',
          (data['created_at'] is Timestamp)
              ? (data['created_at'] as Timestamp).toDate().toIso8601String()
              : '',
        ]);
      }
      final csvString =
          const ListToCsvConverter().convert(csvRows); // Uses csv package

      // 3. Save to file (for mobile/desktop), or return string (web)
      if (kIsWeb) {
        // Web: just return the CSV string for triggering download
        return csvString;
      } else {
        // Mobile/Desktop: save to Downloads or App Directory
        final directory = await getApplicationDocumentsDirectory();
        final filePath =
            '${directory.path}/billing_summary_${DateTime.now().millisecondsSinceEpoch}.csv';
        final file = File(filePath);
        await file.writeAsString(csvString);
        return filePath;
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'downloadSummary failed: $e',
        stack: stack.toString(),
        source: 'InvoiceService',
        screen: 'downloadSummary',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }
}
