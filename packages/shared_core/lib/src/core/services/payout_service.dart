// packages/shared_core/lib/src/core/services/payout_service.dart

/// Pure interface — no Firebase, no Flutter
abstract class PayoutService {
  /// Returns the sum of all payouts across the platform in the past [days] days
  Future<double> sumRecentPlatformPayouts({int days = 30});
}
