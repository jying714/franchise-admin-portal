import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class OnboardingProgressProvider extends ChangeNotifier {
  final FirestoreService firestore;
  final String franchiseId;

  Map<String, bool> _stepStatus = {};
  bool _loading = true;

  OnboardingProgressProvider({
    required this.firestore,
    required this.franchiseId,
  }) {
    _loadProgress();
  }

  Map<String, bool> get stepStatus => _stepStatus;
  bool get loading => _loading;

  bool isStepComplete(String stepKey) => _stepStatus[stepKey] == true;

  Future<void> _loadProgress() async {
    try {
      _loading = true;
      notifyListeners();

      final data = await firestore.getOnboardingProgress(franchiseId);
      if (data != null) {
        _stepStatus = {
          for (final entry in data.entries)
            if (entry.key != 'updatedAt' && entry.key != 'completedAt')
              entry.key: entry.value == true
        };
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to load onboarding progress',
        stack: stack.toString(),
        source: 'OnboardingProgressProvider',
        screen: 'onboarding_menu_screen',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markStepComplete(String stepKey) async {
    try {
      await firestore.updateOnboardingStep(
        franchiseId: franchiseId,
        stepKey: stepKey,
        completed: true,
      );
      _stepStatus[stepKey] = true;
      notifyListeners();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to mark onboarding step "$stepKey" complete',
        stack: stack.toString(),
        source: 'OnboardingProgressProvider',
        screen: 'onboarding_menu_screen',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'stepKey': stepKey},
      );
    }
  }
}
