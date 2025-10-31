import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../../../../../packages/shared_core/lib/src/core/models/platform_invoice.dart';
import '../../../../../packages/shared_core/lib/src/core/models/platform_payment.dart';
import '../../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import '../../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/mock_payment_data.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/mock_payment_form.dart';

class MockPaymentTester extends StatefulWidget {
  final PlatformInvoice invoice;

  const MockPaymentTester({super.key, required this.invoice});

  @override
  State<MockPaymentTester> createState() => _MockPaymentTesterState();
}

class _MockPaymentTesterState extends State<MockPaymentTester> {
  MockPaymentData? _mockData;
  bool _submitting = false;
  String? _result;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 24),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.mockPaymentHeader,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.mockPaymentDisclaimer,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            MockPaymentForm(
              onValidated: (mock) => setState(() => _mockData = mock),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: (_mockData == null || _submitting)
                  ? null
                  : () => _submitMockPayment(context),
              icon: const Icon(Icons.payment),
              label:
                  Text(_submitting ? 'Submitting...' : 'Submit Mock Payment'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text(
                _result!,
                style: TextStyle(
                  color:
                      _result!.startsWith('Error') ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitMockPayment(BuildContext context) async {
    final fs = context.read<FirestoreService>();
    final invoice = widget.invoice;
    final mock = _mockData!;
    final loc = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final paymentId = const Uuid().v4();

    final payment = PlatformPayment(
      id: paymentId,
      franchiseeId: invoice.franchiseeId,
      invoiceId: invoice.id,
      amount: invoice.amount,
      currency: invoice.currency,
      paymentMethod: 'mock_card',
      type: 'one_time',
      status: 'completed',
      attempts: 1,
      sourceSystem: 'admin_portal',
      createdAt: now,
      executedAt: now,
      note: 'Mock payment submitted via dev tool',
      isTest: true,
      methodDetails: {
        'cardType': mock.maskedCardString.split(' ').first,
        'maskedCard': mock.maskedCardString,
      },
    );

    try {
      setState(() {
        _submitting = true;
        _result = null;
      });

      await fs.createPlatformPayment(payment);
      await fs.markPlatformInvoicePaid(invoice.id, 'mock_card');

      setState(() {
        _result = '✅ Payment submitted and invoice marked as paid.';
        _submitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.mockPaymentValidated)),
      );
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to simulate payment: $e',
        stack: stack.toString(),
        source: 'MockPaymentTester',
        screen: 'dev_tools_screen',
        severity: 'error',
      );

      if (!mounted) return;
      setState(() {
        _result = '❌ Error: $e';
        _submitting = false;
      });
    }
  }
}
