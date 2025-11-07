// web-app/lib/core/services/payout_service_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_core/src/core/services/payout_service.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

class PayoutServiceImpl implements PayoutService {
  final FirebaseFirestore _db;

  PayoutServiceImpl({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  @override
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
      ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'PayoutServiceImpl',
        severity: 'error',
      );
      rethrow;
    }
  }
}
