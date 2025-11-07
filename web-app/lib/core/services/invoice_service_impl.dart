// web-app/lib/core/services/invoice_service_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_core/src/core/services/invoice_service.dart';
import 'package:shared_core/src/core/models/invoice.dart';
import 'package:shared_core/src/core/models/platform_invoice.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

class InvoiceServiceImpl implements InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  CollectionReference _franchiseInvoicesRef(String franchiseId) => _firestore
      .collection('platforms')
      .doc('default') // Assuming single platform
      .collection('franchises')
      .doc(franchiseId)
      .collection('invoices');

  CollectionReference _platformInvoicesRef(String platformId) =>
      _firestore.collection('platforms').doc(platformId).collection('invoices');

  @override
  Future<Invoice> createInvoice({
    required String franchiseId,
    required double amount,
    required String currency,
    required String status,
    String? description,
    DateTime? dueDate,
  }) async {
    try {
      final data = {
        'amount': amount,
        'currency': currency,
        'status': status,
        'description': description ?? '',
        'dueDate': dueDate ?? FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final ref = await _franchiseInvoicesRef(franchiseId).add(data);
      final doc = await ref.get();
      return Invoice.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to create invoice for franchise $franchiseId',
        stack: stack.toString(),
        source: 'InvoiceServiceImpl.createInvoice',
        contextData: {'franchiseId': franchiseId, 'amount': amount},
      );
      rethrow;
    }
  }

  @override
  Future<Invoice> updateInvoice({
    required String invoiceId,
    required String franchiseId,
    double? amount,
    String? currency,
    String? status,
    String? description,
    DateTime? dueDate,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp()
      };
      if (amount != null) updates['amount'] = amount;
      if (currency != null) updates['currency'] = currency;
      if (status != null) updates['status'] = status;
      if (description != null) updates['description'] = description;
      if (dueDate != null) updates['dueDate'] = dueDate;

      await _franchiseInvoicesRef(franchiseId).doc(invoiceId).update(updates);
      final doc = await _franchiseInvoicesRef(franchiseId).doc(invoiceId).get();
      return Invoice.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e, stack) {
      ErrorLogger.log(
        message:
            'Failed to update invoice $invoiceId for franchise $franchiseId',
        stack: stack.toString(),
        source: 'InvoiceServiceImpl.updateInvoice',
        contextData: {'invoiceId': invoiceId, 'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  @override
  Future<Invoice> markAsPaid({
    required String invoiceId,
    required String franchiseId,
    required String paymentMethod,
    double? amountPaid,
  }) async {
    try {
      final updates = {
        'status': 'paid',
        'paymentMethod': paymentMethod,
        'amountPaid': amountPaid ?? 0.0,
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _franchiseInvoicesRef(franchiseId).doc(invoiceId).update(updates);
      final doc = await _franchiseInvoicesRef(franchiseId).doc(invoiceId).get();
      return Invoice.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e, stack) {
      ErrorLogger.log(
        message:
            'Failed to mark invoice $invoiceId as paid for franchise $franchiseId',
        stack: stack.toString(),
        source: 'InvoiceServiceImpl.markAsPaid',
        contextData: {'invoiceId': invoiceId, 'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  @override
  Future<void> sendInvoice({
    required String invoiceId,
    required String franchiseId,
    required String recipientEmail,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendInvoiceEmail');
      await callable.call({
        'invoiceId': invoiceId,
        'franchiseId': franchiseId,
        'recipientEmail': recipientEmail,
      });
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to send invoice $invoiceId for franchise $franchiseId',
        stack: stack.toString(),
        source: 'InvoiceServiceImpl.sendInvoice',
        contextData: {
          'invoiceId': invoiceId,
          'franchiseId': franchiseId,
          'recipientEmail': recipientEmail,
        },
      );
      rethrow;
    }
  }

  @override
  Stream<List<Invoice>> streamInvoices({
    required String franchiseId,
    List<String>? statuses,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    Query query = _franchiseInvoicesRef(franchiseId)
        .orderBy('createdAt', descending: true)
        .limit(100); // Reasonable limit

    if (statuses != null && statuses.isNotEmpty) {
      query = query.where('status', whereIn: statuses);
    }
    if (fromDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: fromDate);
    }
    if (toDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: toDate);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((doc) =>
            Invoice.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  @override
  Future<List<Invoice>> getInvoices({
    required String franchiseId,
    List<String>? statuses,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      Query query = _franchiseInvoicesRef(franchiseId)
          .orderBy('createdAt', descending: true)
          .limit(100);

      if (statuses != null && statuses.isNotEmpty) {
        query = query.where('status', whereIn: statuses);
      }
      if (fromDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: fromDate);
      }
      if (toDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: toDate);
      }

      final snap = await query.get();
      return snap.docs
          .map((doc) =>
              Invoice.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to get invoices for franchise $franchiseId',
        stack: stack.toString(),
        source: 'InvoiceServiceImpl.getInvoices',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  @override
  Future<String> generateInvoicePdf({
    required String invoiceId,
    required String franchiseId,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateInvoicePdf');
      final result = await callable.call({
        'invoiceId': invoiceId,
        'franchiseId': franchiseId,
      });
      return result.data as String; // Base64 PDF
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to generate PDF for invoice $invoiceId',
        stack: stack.toString(),
        source: 'InvoiceServiceImpl.generateInvoicePdf',
        contextData: {'invoiceId': invoiceId, 'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  @override
  Future<String> exportInvoicesToCsv({
    required String franchiseId,
    List<String>? statuses,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final callable = _functions.httpsCallable('exportInvoicesToCsv');
      final result = await callable.call({
        'franchiseId': franchiseId,
        if (statuses != null) 'statuses': statuses,
        if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
        if (toDate != null) 'toDate': toDate.toIso8601String(),
      });
      return result.data as String; // CSV string
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to export invoices for franchise $franchiseId',
        stack: stack.toString(),
        source: 'InvoiceServiceImpl.exportInvoicesToCsv',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getOverdueSummary(String franchiseId) async {
    try {
      final callable = _functions.httpsCallable('getOverdueInvoiceSummary');
      final result = await callable.call({'franchiseId': franchiseId});
      return result.data as Map<String, dynamic>;
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to get overdue summary for franchise $franchiseId',
        stack: stack.toString(),
        source: 'InvoiceServiceImpl.getOverdueSummary',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  @override
  Future<PlatformInvoice> createPlatformInvoice({
    required String platformId,
    required double amount,
    required String currency,
    required String status,
    String? description,
    DateTime? dueDate,
  }) async {
    try {
      final data = {
        'amount': amount,
        'currency': currency,
        'status': status,
        'description': description ?? '',
        'dueDate': dueDate ?? FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final ref = await _platformInvoicesRef(platformId).add(data);
      final doc = await ref.get();
      return PlatformInvoice.fromMap(
          doc.id, doc.data() as Map<String, dynamic>);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to create platform invoice for platform $platformId',
        stack: stack.toString(),
        source: 'InvoiceServiceImpl.createPlatformInvoice',
        contextData: {'platformId': platformId, 'amount': amount},
      );
      rethrow;
    }
  }

  @override
  Stream<List<PlatformInvoice>> streamPlatformInvoices({
    required String platformId,
    List<String>? statuses,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    Query query = _platformInvoicesRef(platformId)
        .orderBy('createdAt', descending: true)
        .limit(100);

    if (statuses != null && statuses.isNotEmpty) {
      query = query.where('status', whereIn: statuses);
    }
    if (fromDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: fromDate);
    }
    if (toDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: toDate);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((doc) =>
            PlatformInvoice.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }
}
