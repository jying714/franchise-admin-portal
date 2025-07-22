import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/admin/devtools/billing/admin_webhook_simulator.dart';
import 'package:franchise_admin_portal/admin/devtools/billing/mock_payment_editor.dart';
import 'package:franchise_admin_portal/admin/devtools/billing/test_invoice_generator.dart';
import 'package:franchise_admin_portal/admin/devtools/billing/test_invoice_cleaner.dart';
import 'package:franchise_admin_portal/admin/devtools/billing/clear_all_test_invoices_button.dart';
import 'package:franchise_admin_portal/admin/devtools/billing/mock_payment_tester.dart';

class BillingSubscriptionToolsScreen extends StatelessWidget {
  const BillingSubscriptionToolsScreen({super.key});

  void _showDevGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧾 Billing & Subscription Dev Guide'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('🔹 Test Invoice Generator',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Use this to create mock invoices for a specific franchise. '
                  'These invoices are flagged as test data and can be used in webhook simulations or payment flows.',
                ),
                SizedBox(height: 12),
                Text('🔹 Webhook Simulator',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Simulate Stripe-style webhook events for test invoices. '
                  'Select a franchise and test invoice, then choose a webhook type like `invoice.paid`. '
                  'Results are logged and can be audited via Firestore or the ErrorLogger.',
                ),
                SizedBox(height: 12),
                Text('🔹 Mock Payment Editor',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Generate mock payment records tied to a franchise or invoice. '
                  'Supports input for method, status, source, and attempts. '
                  'Use this for testing how the platform handles payment edge cases.',
                ),
                SizedBox(height: 12),
                Text('🔹 Test Invoice Cleaner',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'View, reset, or delete test invoices. Useful for keeping the test environment clean or reproducing failed flows.',
                ),
                SizedBox(height: 12),
                Text('🔹 Logs & Audit Trails',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'All test tool actions are logged via `ErrorLogger`. '
                  'Visit Firestore > platform_logs to view full context, errors, or confirmation of test flows.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing & Subscription Tools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Tool Guide',
            onPressed: () => _showDevGuide(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '🧪 Test Data Utilities',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ClearAllTestInvoicesButton(),
              SizedBox(height: 24),
              TestInvoiceGenerator(),
              SizedBox(height: 32),

              Text(
                '📦 Webhook Testing',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              AdminWebhookSimulator(),
              SizedBox(height: 32),

              Text(
                '💳 Mock Payment Simulator',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              MockPaymentEditor(),
              SizedBox(height: 32),

              Text(
                '🧹 Test Invoice Cleaner',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TestInvoiceCleaner(),

              SizedBox(height: 32),
              // Future tool slots...
            ],
          ),
        ),
      ),
    );
  }
}
