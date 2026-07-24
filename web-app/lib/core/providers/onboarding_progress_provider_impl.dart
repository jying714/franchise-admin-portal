import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

/// Franchise-scoped onboarding step progress, implements shared.OnboardingProgressProvider, loads via Firestore.
class OnboardingProgressProviderImpl extends ChangeNotifier
    implements shared.OnboardingProgressProvider {
  final shared.FirestoreService _firestore;
  final String _franchiseId;

  Map<String, bool> _stepStatus = {};
  bool _loading = true;

  OnboardingProgressProviderImpl({
    required shared.FirestoreService firestore,
    required String franchiseId,
  })  : _firestore = firestore,
        _franchiseId = franchiseId {
    _loadProgress();
  }

  @override
  Map<String, bool> get stepStatus => _stepStatus;

  @override
  bool get loading => _loading;

  @override
  bool isStepComplete(String stepKey) => _stepStatus[stepKey] == true;

  /// NEW: Combined foundation progress (Types 25%, Ingredients 35%, Categories 40%)
  @override
  double getFoundationProgress() {
    final types = isStepComplete('ingredientTypes') ? 0.25 : 0.0;
    final ingredients = isStepComplete('ingredients') ? 0.35 : 0.0;
    final categories = isStepComplete('categories') ? 0.40 : 0.0;
    return (types + ingredients + categories).clamp(0.0, 1.0);
  }

  Future<void> _loadProgress() async {
    if (_franchiseId.isEmpty) {
      _stepStatus = {};
      _loading = false;
      notifyListeners();
      return;
    }

    try {
      _loading = true;
      notifyListeners();

      final data = await _firestore.getOnboardingProgress(_franchiseId);
      final defaultSteps = [
        'ingredientTypes',
        'ingredients',
        'categories',
        'menuItems',
        'review',
        'onboarding_menu_foundation', // new combined key
      ];

      _stepStatus = {
        for (final step in defaultSteps)
          step: data != null && data[step] == true
      };
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to load onboarding progress',
        stack: stack.toString(),
        source: 'OnboardingProgressProviderImpl',
        severity: 'warning',
        contextData: {'franchiseId': _franchiseId},
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> markStepComplete(String stepKey) async {
    if (_franchiseId.isEmpty) return;

    try {
      await _firestore.updateOnboardingStep(
        franchiseId: _franchiseId,
        stepKey: stepKey,
        completed: true,
      );
      _stepStatus[stepKey] = true;
      notifyListeners();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to mark onboarding step "$stepKey" complete',
        stack: stack.toString(),
        source: 'OnboardingProgressProviderImpl',
        severity: 'error',
        contextData: {'franchiseId': _franchiseId, 'stepKey': stepKey},
      );
    }
  }

  @override
  Future<void> markStepIncomplete(String stepKey) async {
    if (_franchiseId.isEmpty) return;

    try {
      await _firestore.updateOnboardingStep(
        franchiseId: _franchiseId,
        stepKey: stepKey,
        completed: false,
      );
      _stepStatus[stepKey] = false;
      notifyListeners();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to mark onboarding step "$stepKey" incomplete',
        stack: stack.toString(),
        source: 'OnboardingProgressProviderImpl',
        severity: 'error',
        contextData: {'franchiseId': _franchiseId, 'stepKey': stepKey},
      );
    }
  }
}
