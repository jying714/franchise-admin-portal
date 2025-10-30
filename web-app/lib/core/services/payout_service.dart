import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

/// Service class for platform-wide and franchise payout operations.
/// Integrates error logging and Firestore queries for SaaS use.
class PayoutService {
  final FirebaseFirestore _db;

  PayoutService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Returns the sum of all payouts across the platform in the past [days] days.
  Future<double> sumRecentPlatformPayouts({int days = 30}) async {
    try {
      final now = DateTime.now();
      final since = now.subtract(Duration(days: days));
      final query = _db.collection('payouts').where('created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since));
      final docs = await query.get();

      double sum = 0;
      for (var doc in docs.docs) {
        final data = doc.data();
        sum += (data['amount'] ?? 0).toDouble();
      }
      return sum;
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'PayoutService',
        screen: 'sumRecentPlatformPayouts',
        severity: 'error',
      );
      rethrow;
    }
  }

  // 💡 Future Feature Placeholder:
  // Add more aggregation, filtering, and payout-related methods here for the platform/HQ/franchise levels as needed.
}
