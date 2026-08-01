import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart' show ThemeMode;

/// Result of a station card attempt.
class CardPresentResult {
  final bool success;
  final String? paymentIntentId;
  final String? errorMessage;
  final bool wasMock;

  const CardPresentResult({
    required this.success,
    this.paymentIntentId,
    this.errorMessage,
    this.wasMock = false,
  });
}

/// Station card collection.
///
/// - Prefer real Connect PaymentIntent + PaymentSheet (same CF as mobile).
/// - Physical reader is NOT required; PaymentSheet is software card entry.
/// - If [STRIPE_PK] is missing or CF fails precondition, optional mock fallback
///   when [allowMockFallback] is true (pilot without Stripe on this binary).
class CardPresentService {
  const CardPresentService();

  /// When true and Stripe is unavailable, simulate success (dev only).
  static const bool allowMockFallback = true;

  Future<CardPresentResult> collectPayment({
    required String franchiseId,
    required String orderId,
    required int amountCents,
    String merchantDisplayName = 'Station',
  }) async {
    if (amountCents < 50) {
      return const CardPresentResult(
        success: false,
        errorMessage: 'Amount too small for card (min \$0.50)',
      );
    }

    const stripePk = String.fromEnvironment('STRIPE_PK', defaultValue: '');
    if (stripePk.isEmpty) {
      return _mockOrFail(
        reason: 'STRIPE_PK not set on this station build',
        orderId: orderId,
        amountCents: amountCents,
        franchiseId: franchiseId,
      );
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createOrderPaymentIntent',
      );
      final piResult = await callable.call(<String, dynamic>{
        'franchiseId': franchiseId,
        'amountCents': amountCents,
        'currency': 'usd',
        'orderId': orderId,
      });
      final piData = Map<String, dynamic>.from(piResult.data as Map);
      final clientSecret = piData['clientSecret'] as String?;
      final paymentIntentId = piData['paymentIntentId'] as String?;
      if (clientSecret == null || clientSecret.isEmpty) {
        return const CardPresentResult(
          success: false,
          errorMessage: 'PaymentIntent missing clientSecret',
        );
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName,
          style: ThemeMode.light,
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      // ignore: avoid_print
      print(
        '[POS] card PaymentSheet success franchise=$franchiseId '
        'order=$orderId amountCents=$amountCents pi=$paymentIntentId',
      );

      return CardPresentResult(
        success: true,
        paymentIntentId: paymentIntentId,
        wasMock: false,
      );
    } on StripeException catch (e) {
      final msg = e.error.localizedMessage ?? e.error.message ?? '$e';
      debugPrint('[POS] PaymentSheet: $msg');
      // User cancel is not a hard failure message for till — treat as cancel.
      final canceled = e.error.code == FailureCode.Canceled;
      return CardPresentResult(
        success: false,
        errorMessage: canceled ? 'Card payment canceled' : msg,
      );
    } on FirebaseFunctionsException catch (e) {
      final msg = e.message ?? e.code;
      debugPrint('[POS] createOrderPaymentIntent: $msg');
      // Payments not set up → optional mock for pilot hardware nights.
      if (e.code == 'failed-precondition' && allowMockFallback) {
        return _mockOrFail(
          reason: 'Payments not set up — using mock card',
          orderId: orderId,
          amountCents: amountCents,
          franchiseId: franchiseId,
        );
      }
      return CardPresentResult(
        success: false,
        errorMessage: 'Payment setup failed: $msg',
      );
    } catch (e, st) {
      debugPrint('[POS] card collect failed: $e\n$st');
      return CardPresentResult(
        success: false,
        errorMessage: 'Card payment failed: $e',
      );
    }
  }

  Future<CardPresentResult> _mockOrFail({
    required String reason,
    required String orderId,
    required int amountCents,
    required String franchiseId,
  }) async {
    if (!allowMockFallback) {
      return CardPresentResult(success: false, errorMessage: reason);
    }
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final piId = 'mock_pi_${orderId}_${DateTime.now().millisecondsSinceEpoch}';
    // ignore: avoid_print
    print(
      '[POS] card MOCK ($reason) franchise=$franchiseId '
      'order=$orderId amountCents=$amountCents pi=$piId',
    );
    return CardPresentResult(
      success: true,
      paymentIntentId: piId,
      wasMock: true,
    );
  }
}
