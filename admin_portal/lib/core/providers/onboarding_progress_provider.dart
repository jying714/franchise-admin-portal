import 'package:flutter/material.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/core/utils/error_logger.dart';

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
    print(
        '[DEBUG][OnboardingProgressProvider] Loading for franchiseId: "$franchiseId"');
    if (franchiseId.isEmpty) {
      print(
          '[ERROR][OnboardingProgressProvider] FranchiseId is empty! Skipping progress load.');
      await ErrorLogger.log(
        message: 'Failed to load onboarding progress for empty franchiseId',
        stack: '',
        source: 'OnboardingProgressProvider',
        screen: 'onboarding_menu_screen',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      _stepStatus = {};
      _loading = false;
      notifyListeners();
      return;
    }
    try {
      _loading = true;
      notifyListeners();

      final data = await firestore.getOnboardingProgress(franchiseId);
      final defaultSteps = [
        'ingredientTypes',
        'ingredients',
        'categories',
        'menuItems',
        'review',
      ];

      _stepStatus = {
        for (final step in defaultSteps)
          step: data != null && data[step] == true
      };
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
    if (franchiseId.isEmpty) {
      print(
          '[ERROR][OnboardingProgressProvider] Cannot mark step complete: franchiseId is empty!');
      await ErrorLogger.log(
        message:
            'Failed to mark onboarding step "$stepKey" complete: franchiseId is empty',
        stack: '',
        source: 'OnboardingProgressProvider',
        screen: 'onboarding_menu_screen',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'stepKey': stepKey},
      );
      return;
    }
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

  Future<void> markStepIncomplete(String stepKey) async {
    if (franchiseId.isEmpty) {
      print(
          '[ERROR][OnboardingProgressProvider] Cannot mark step incomplete: franchiseId is empty!');
      await ErrorLogger.log(
        message:
            'Failed to mark onboarding step "$stepKey" incomplete: franchiseId is empty',
        stack: '',
        source: 'OnboardingProgressProvider',
        screen: 'onboarding_menu_screen',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'stepKey': stepKey},
      );
      return;
    }
    try {
      await firestore.updateOnboardingStep(
        franchiseId: franchiseId,
        stepKey: stepKey,
        completed: false,
      );
      _stepStatus[stepKey] = false;
      notifyListeners();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to mark onboarding step "$stepKey" incomplete',
        stack: stack.toString(),
        source: 'OnboardingProgressProvider',
        screen: 'onboarding_menu_screen',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'stepKey': stepKey},
      );
    }
  }
}
