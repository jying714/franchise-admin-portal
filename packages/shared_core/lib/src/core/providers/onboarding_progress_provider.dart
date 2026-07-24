// packages/shared_core/lib/src/core/providers/onboarding_progress_provider.dart
// PURE DART INTERFACE ONLY

/// Pure interface for franchise onboarding step progress (stepStatus, loading, completion helpers).
abstract class OnboardingProgressProvider {
  Map<String, bool> get stepStatus;
  bool get loading;

  bool isStepComplete(String stepKey);
  Future<void> markStepComplete(String stepKey);
  Future<void> markStepIncomplete(String stepKey);

  /// For combined steps like Core Menu Foundation – returns weighted sub-progress (0.0 - 1.0)
  double getFoundationProgress();
}
