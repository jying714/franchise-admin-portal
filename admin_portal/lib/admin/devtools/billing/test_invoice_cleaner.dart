import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin_portal/core/utils/error_logger.dart';

class TestInvoiceCleaner extends StatefulWidget {
  const TestInvoiceCleaner({super.key});

  @override
  State<TestInvoiceCleaner> createState() => _TestInvoiceCleanerState();
}

class _TestInvoiceCleanerState extends State<TestInvoiceCleaner> {
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _testInvoicesFuture;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _invoices = [];
  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedInvoice;

  @override
  void initState() {
    super.initState();
    _testInvoicesFuture = _fetchTestInvoices();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _fetchTestInvoices() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('platform_invoices')
          .where('isTest', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      _invoices = snapshot.docs;
      if (_invoices.isNotEmpty) {
        _selectedInvoice = _invoices.first;
      }
      return _invoices;
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to load test invoices: $e',
        stack: stack.toString(),
        source: 'TestInvoiceCleaner',
        screen: 'dev_tools',
        severity: 'error',
      );
      rethrow;
    }
  }

  Future<void> _deleteInvoice(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('platform_invoices')
          .doc(id)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice deleted.')),
      );
      _refresh();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to delete invoice: $e',
        stack: stack.toString(),
        source: 'TestInvoiceCleaner',
        screen: 'dev_tools',
        severity: 'error',
        contextData: {'invoiceId': id},
      );
    }
  }

  Future<void> _resetInvoice(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('platform_invoices')
          .doc(id)
          .update({
        'status': 'unpaid',
        'paidAt': FieldValue.delete(),
        'paymentIds': [],
        'lastPaymentMethod': FieldValue.delete(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice reset.')),
      );
      _refresh();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to reset invoice: $e',
        stack: stack.toString(),
        source: 'TestInvoiceCleaner',
        screen: 'dev_tools',
        severity: 'error',
        contextData: {'invoiceId': id},
      );
    }
  }

  Future<void> _bulkReset() async {
    for (final doc in _invoices) {
      await _resetInvoice(doc.id);
    }
  }

  Future<void> _bulkDelete() async {
    for (final doc in _invoices) {
      await _deleteInvoice(doc.id);
    }
  }

  void _refresh() {
    setState(() {
      _testInvoicesFuture = _fetchTestInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      future: _testInvoicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text('Failed to load invoices: ${snapshot.error}'),
            ),
          );
        }

        final invoices = snapshot.data ?? [];
        if (invoices.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('No test invoices found.')),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: _bulkReset,
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: _bulkDelete,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<
                  QueryDocumentSnapshot<Map<String, dynamic>>>(
                value: _selectedInvoice,
                items: invoices.map((doc) {
                  final data = doc.data();
                  return DropdownMenuItem(
                    value: doc,
                    child: Text(data['invoiceNumber'] ?? doc.id),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedInvoice = val),
                decoration: const InputDecoration(
                  labelText: 'Select Invoice',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedInvoice != null)
                Card(
                  child: ListTile(
                    title: Text(
                        'Invoice: ${_selectedInvoice!.data()['invoiceNumber'] ?? _selectedInvoice!.id}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Franchisee: ${_selectedInvoice!.data()['franchiseeId'] ?? 'unknown'}'),
                        Text(
                            'Amount: \$${_selectedInvoice!.data()['amount'] ?? '--'}'),
                        if (_selectedInvoice!.data()['createdAt'] != null)
                          Text(
                              'Created: ${_selectedInvoice!.data()['createdAt'].toDate().toLocal()}'),
                        if (_selectedInvoice!.data()['paidAt'] != null)
                          Text(
                              'Paid At: ${_selectedInvoice!.data()['paidAt'].toDate().toLocal()}'),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.orange),
                          tooltip: 'Reset',
                          onPressed: () => _resetInvoice(_selectedInvoice!.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () => _deleteInvoice(_selectedInvoice!.id),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
