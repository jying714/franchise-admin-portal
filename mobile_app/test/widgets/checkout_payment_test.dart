// mobile_app/test/widgets/checkout_payment_test.dart
// Expanded P2 test coverage for MockPaymentService integration in checkout.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart' as shared;

void main() {
  group('Checkout + MockPaymentService (P2.3 expanded)', () {
    testWidgets('MockPaymentService can be instantiated and returns success result', (tester) async {
      final paymentService = shared.createPaymentService();

      final result = await paymentService.processPayment(
        amount: 42.50,
        currency: 'USD',
        paymentMethod: 'card',
        metadata: {'franchiseId': 'test_fid'},
      );

      expect(result.success, isTrue);
      expect(result.transactionId, isNotNull);
      expect(result.amount, 42.50);
    });

    testWidgets('MockPaymentService refund path works', (tester) async {
      final paymentService = shared.createPaymentService();

      final refund = await paymentService.refundPayment('mock_tx_123', amount: 10.0);
      expect(refund.success, isTrue);
      expect(refund.status, shared.PaymentStatus.refunded);
    });
  });
}
