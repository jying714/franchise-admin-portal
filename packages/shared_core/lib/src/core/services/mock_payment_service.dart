// packages/shared_core/lib/src/core/services/mock_payment_service.dart
//
// P2.3 foundations: Mock payment service for scalability testing and UI flows.
// NO real gateway integration (Stripe, etc.) yet. Swap impl behind this interface later.
// Used by checkout to simulate auth, capture, refunds for end-to-end testing.

import 'dart:async';

enum PaymentStatus { pending, authorized, captured, failed, refunded }

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final PaymentStatus status;
  final double? amount;

  const PaymentResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
    this.status = PaymentStatus.captured,
    this.amount,
  });
}

abstract class PaymentService {
  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required String paymentMethod, // 'card', 'apple_pay', etc.
    Map<String, dynamic>? metadata,
  });

  Future<PaymentResult> refundPayment(String transactionId, {double? amount});
}

/// Mock implementation - always succeeds after simulated latency.
/// Ideal for dev, demo, and CI flows. Replace with real impl in prod.
class MockPaymentService implements PaymentService {
  final Duration simulatedLatency;

  MockPaymentService({this.simulatedLatency = const Duration(milliseconds: 800)});

  @override
  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required String paymentMethod,
    Map<String, dynamic>? metadata,
  }) async {
    await Future.delayed(simulatedLatency);

    // Simulate occasional failure for testing error paths (5% chance)
    if (DateTime.now().millisecond % 20 == 0) {
      return PaymentResult(
        success: false,
        errorMessage: 'Mock: Card declined (insufficient funds simulation)',
        status: PaymentStatus.failed,
        amount: amount,
      );
    }

    final txId = 'mock_${DateTime.now().millisecondsSinceEpoch}_${paymentMethod.hashCode.abs()}';
    return PaymentResult(
      success: true,
      transactionId: txId,
      status: PaymentStatus.captured,
      amount: amount,
    );
  }

  @override
  Future<PaymentResult> refundPayment(String transactionId, {double? amount}) async {
    await Future.delayed(simulatedLatency ~/ 2);
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      status: PaymentStatus.refunded,
      amount: amount,
    );
  }
}

// Convenience factory for app bootstrap (mobile + tests)
PaymentService createPaymentService({bool useRealGateway = false}) {
  if (useRealGateway) {
    // Placeholder: when real impl added (e.g. StripeService), return it here.
    // For now always mock.
    assert(false, 'Real payment gateway not implemented in P2.3 foundations.');
  }
  return MockPaymentService();
}
