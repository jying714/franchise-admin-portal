// web-app/lib/core/services/franchise_onboarding_service_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_core/src/core/services/franchise_onboarding_service.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

class FranchiseOnboardingServiceImpl implements FranchiseOnboardingService {
  final FirebaseFirestore _db;

  FranchiseOnboardingServiceImpl({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> markOnboardingComplete(String franchiseId) async {
    final franchiseRef = _db.collection('franchises').doc(franchiseId);

    try {
      await franchiseRef.update({
        'onboardingStatus': 'complete',
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
      });

      ErrorLogger.log(
        message: 'Franchise onboarding marked complete',
        source: 'FranchiseOnboardingServiceImpl',
        severity: 'info',
        contextData: {
          'franchiseId': franchiseId,
        },
      );
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to mark onboarding complete: $e',
        source: 'FranchiseOnboardingServiceImpl',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
        },
      );
      rethrow;
    }
  }

  @override
  Future<bool> isOnboardingComplete(String franchiseId) async {
    try {
      final doc = await _db.collection('franchises').doc(franchiseId).get();
      return doc.data()?['onboardingStatus'] == 'complete';
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Error checking onboarding status: $e',
        source: 'FranchiseOnboardingServiceImpl',
        severity: 'warning',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
        },
      );
      return false;
    }
  }
}
