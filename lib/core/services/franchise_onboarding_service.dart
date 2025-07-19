// 📁 lib/core/services/franchise_onboarding_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class FranchiseOnboardingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Marks the franchise's onboarding status as completed.
  Future<void> markOnboardingComplete(String franchiseId) async {
    final franchiseRef = _db.collection('franchises').doc(franchiseId);

    try {
      await franchiseRef.update({
        'onboardingStatus': 'complete',
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
      });

      await ErrorLogger.log(
        message: 'Franchise onboarding marked complete',
        source: 'FranchiseOnboardingService',
        screen: 'available_platform_plans_screen',
        severity: 'info',
        contextData: {
          'franchiseId': franchiseId,
        },
      );
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to mark onboarding complete: $e',
        source: 'FranchiseOnboardingService',
        screen: 'available_platform_plans_screen',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
        },
      );
      rethrow;
    }
  }

  /// Returns whether the franchise is flagged as having completed onboarding.
  Future<bool> isOnboardingComplete(String franchiseId) async {
    try {
      final doc = await _db.collection('franchises').doc(franchiseId).get();
      return doc.data()?['onboardingStatus'] == 'complete';
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Error checking onboarding status: $e',
        source: 'FranchiseOnboardingService',
        screen: 'available_platform_plans_screen',
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
