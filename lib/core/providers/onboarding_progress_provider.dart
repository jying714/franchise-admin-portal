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
      // Define the canonical onboarding steps here:
      final defaultSteps = [
        'ingredientTypes', // <-- New Step 1
        'ingredients', // Step 2
        'categories', // Step 3
        'menuItems', // Step 4
        'review', // Step 5
      ];

      // Always include all default steps, mark true if present/true in Firestore
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
