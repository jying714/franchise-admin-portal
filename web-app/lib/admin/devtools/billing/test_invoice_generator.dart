import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider_impl.dart'; // if needed elsewhere
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared;

class TestInvoiceGenerator extends StatefulWidget {
  const TestInvoiceGenerator({super.key});

  @override
  State<TestInvoiceGenerator> createState() => _TestInvoiceGeneratorState();
}

class _TestInvoiceGeneratorState extends State<TestInvoiceGenerator> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '99.00');
  final _currencyController = TextEditingController(text: 'USD');
  final _noteController = TextEditingController(text: 'Test invoice for QA');

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;
  String? _statusMessage;

  List<shared.FranchiseInfo> _franchises = [];
  shared.FranchiseInfo? _selectedFranchise;

  @override
  void initState() {
    super.initState();
    _loadFranchises();
  }

  Future<void> _loadFranchises() async {
    try {
      final firestoreService =
          Provider.of<shared.FirestoreService>(context, listen: false);
      final franchises = await firestoreService.fetchFranchiseList();
      if (mounted) {
        setState(() {
          _franchises = franchises;
        });
      }
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to load franchises: $e',
        stack: stack.toString(),
        source: 'TestInvoiceGenerator',
        severity: 'error',
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final franchise = _selectedFranchise;
    if (franchise == null) {
      setState(() => _statusMessage = 'Franchise must be selected.');
      return;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    try {
      final uuid = const Uuid().v4();
      final now = DateTime.now();
      final invoiceNumber =
          'TEST-${DateFormat('yyMMdd-HHmm').format(now)}-${uuid.substring(0, 6).toUpperCase()}';

      final invoice = shared.PlatformInvoice(
        id: uuid,
        franchiseeId: franchise.id ?? '',
        invoiceNumber: invoiceNumber,
        amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
        currency: _currencyController.text.trim().toUpperCase(),
        createdAt: now,
        dueDate: _dueDate,
        status: 'unpaid',
        issuedBy: 'platform',
        isTest: true,
        paymentIds: const [],
        lineItems: {
          'mockItem': {'label': 'Dev Item', 'amount': 9999}
        },
        note: _noteController.text.trim(),
      );

      final firestoreService =
          Provider.of<shared.FirestoreService>(context, listen: false);
      await firestoreService.createPlatformInvoice(invoice);

      if (mounted) {
        setState(() => _statusMessage = 'Test invoice created: $invoiceNumber');
      }
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to generate test invoice: $e',
        stack: stack.toString(),
        source: 'TestInvoiceGenerator',
        severity: 'error',
      );
      if (mounted) {
        setState(() => _statusMessage = 'Error generating invoice.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Test Invoice Generator',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<shared.FranchiseInfo>(
                decoration:
                    const InputDecoration(labelText: 'Select Franchise'),
                items: _franchises
                    .map((f) => DropdownMenuItem(value: f, child: Text(f.name)))
                    .toList(),
                value: _selectedFranchise,
                onChanged: (val) => setState(() => _selectedFranchise = val),
                validator: (val) =>
                    val == null ? 'Franchise is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration:
                    const InputDecoration(labelText: 'Amount (e.g. 99.00)'),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    (val == null || double.tryParse(val) == null)
                        ? 'Invalid amount'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currencyController,
                decoration:
                    const InputDecoration(labelText: 'Currency (e.g. USD)'),
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Invoice Note'),
              ),
              const SizedBox(height: 12),
              InputDatePickerFormField(
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDate: _dueDate,
                onDateSubmitted: (val) => setState(() => _dueDate = val),
                fieldLabelText: 'Due Date',
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: const Icon(Icons.play_circle_fill),
                label:
                    Text(_isSaving ? 'Creating...' : 'Generate Test Invoice'),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _statusMessage!.startsWith('Error')
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
