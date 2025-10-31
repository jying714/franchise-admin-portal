import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../packages/shared_core/lib/src/core/models/platform_invoice.dart';
import '../../../../../packages/shared_core/lib/src/core/models/franchise_info.dart';
import '../../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import '../../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';

class AdminWebhookSimulator extends StatefulWidget {
  const AdminWebhookSimulator({super.key});

  @override
  State<AdminWebhookSimulator> createState() => _AdminWebhookSimulatorState();
}

class _AdminWebhookSimulatorState extends State<AdminWebhookSimulator> {
  bool _loading = false;
  String? _selectedEvent;
  String? _selectedFranchiseId;
  PlatformInvoice? _selectedInvoice;
  List<FranchiseInfo> _franchises = [];
  List<PlatformInvoice> _invoices = [];
  double _delaySeconds = 0.0;

  final List<String> _webhookEvents = [
    'invoice.paid',
    'invoice.payment_failed',
    'invoice.upcoming',
  ];

  @override
  void initState() {
    super.initState();
    _loadFranchises();
  }

  Future<void> _loadFranchises() async {
    final fs = context.read<FirestoreService>();
    try {
      final list = await fs.getAllFranchises();
      setState(() {
        _franchises = list;
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        source: 'AdminWebhookSimulator',
        screen: 'dev_tools_screen',
        message: 'Failed to load franchises: $e',
        stack: stack.toString(),
        severity: 'error',
      );
    }
  }

  Future<void> _loadInvoicesForFranchise(String franchiseId) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      debugPrint(
          '[AdminWebhookSimulator] Skipping load — invalid franchiseId.');
      setState(() {
        _invoices = [];
        _loading = false;
      });
      return;
    }

    final fs = context.read<FirestoreService>();
    try {
      setState(() {
        _loading = true;
        _invoices = [];
        _selectedInvoice = null;
      });

      final invoices =
          await fs.getTestPlatformInvoices(franchiseeId: franchiseId);
      final testInvoices = invoices.where((i) => i.isTest).toList();

      debugPrint(
          '[AdminWebhookSimulator] Found ${testInvoices.length} test invoices for franchiseId=$franchiseId');

      setState(() {
        _invoices = testInvoices;
        _loading = false;
      });
    } catch (e, stack) {
      setState(() => _loading = false);
      await ErrorLogger.log(
        source: 'AdminWebhookSimulator',
        screen: 'dev_tools_screen',
        message: 'Failed to load test invoices: $e',
        stack: stack.toString(),
        severity: 'warning',
      );
    }
  }

  Future<void> _simulateEvent() async {
    if (_selectedEvent == null || _selectedInvoice == null) return;

    final invoice = _selectedInvoice!;
    final payload = invoice.toWebhookPayload();
    final delay = Duration(milliseconds: (_delaySeconds * 1000).round());

    try {
      await context.read<FirestoreService>().logSimulatedWebhookEvent({
        'eventType': _selectedEvent,
        'invoiceId': invoice.id,
        'franchiseeId': invoice.franchiseeId,
        'timestamp': DateTime.now().toIso8601String(),
        'payload': payload,
        'delaySeconds': _delaySeconds,
        'simulated': true,
      });

      await ErrorLogger.log(
        source: 'AdminWebhookSimulator',
        screen: 'dev_tools_screen',
        message:
            'Simulated webhook $_selectedEvent for invoice ${invoice.id} with $_delaySeconds sec delay.',
        severity: 'info',
        contextData: {
          'invoiceId': invoice.id,
          'franchiseeId': invoice.franchiseeId,
          'amount': invoice.amount,
          'eventType': _selectedEvent,
          'delaySeconds': _delaySeconds,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Webhook $_selectedEvent simulated for invoice ${invoice.invoiceNumber}'),
        ),
      );
    } catch (e, stack) {
      await ErrorLogger.log(
        source: 'AdminWebhookSimulator',
        screen: 'dev_tools_screen',
        message: 'Webhook simulation failed: $e',
        stack: stack.toString(),
        severity: 'error',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error occurred during webhook simulation.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    debugPrint(
        '[AdminWebhookSimulator] Loaded ${_invoices.length} test invoices');
    for (final inv in _invoices) {
      debugPrint(' - Invoice ${inv.invoiceNumber} (${inv.id})');
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Webhook Simulator',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 12),
            Text(
              'Use this to simulate webhook events like `invoice.paid` for a test invoice.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            /// Franchise selector
            DropdownButtonFormField<String>(
              value: _selectedFranchiseId,
              items: _franchises
                  .map((f) => DropdownMenuItem(
                        value: f.id,
                        child: Text(f.name),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedFranchiseId = val;
                  _selectedInvoice = null;
                });
                if (val != null) {
                  _loadInvoicesForFranchise(val);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Select Franchise',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedEvent,
              items: _webhookEvents
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedEvent = val),
              decoration: const InputDecoration(
                labelText: 'Webhook Event Type',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<PlatformInvoice>(
                value: _selectedInvoice,
                items: _invoices
                    .map((invoice) => DropdownMenuItem(
                          value: invoice,
                          child: Text(invoice.invoiceNumber),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedInvoice = val),
                decoration: const InputDecoration(
                  labelText: 'Select Invoice',
                  border: OutlineInputBorder(),
                ),
              ),

            if (_selectedInvoice != null) ...[
              const SizedBox(height: 8),
              Text(
                'Invoice ID: ${_selectedInvoice!.id}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.primary),
              ),
              Text(
                'Amount: ${_selectedInvoice!.amount} ${_selectedInvoice!.currency}',
                style: theme.textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 20),
            Text('Simulated Delay (seconds)',
                style: theme.textTheme.bodyMedium),
            Slider(
              value: _delaySeconds,
              min: 0,
              max: 10,
              divisions: 20,
              label: _delaySeconds.toStringAsFixed(1),
              onChanged: (val) => setState(() => _delaySeconds = val),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: (_selectedEvent == null || _selectedInvoice == null)
                  ? null
                  : _simulateEvent,
              icon: const Icon(Icons.send),
              label: const Text('Simulate Webhook'),
            ),
          ],
        ),
      ),
    );
  }
}
