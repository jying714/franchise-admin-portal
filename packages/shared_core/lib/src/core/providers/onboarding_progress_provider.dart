// packages/shared_core/lib/src/core/providers/onboarding_progress_provider.dart
// PURE DART INTERFACE ONLY

abstract class OnboardingProgressProvider {
  Map<String, bool> get stepStatus;
  bool get loading;

  bool isStepComplete(String stepKey);
  Future<void> markStepComplete(String stepKey);
  Future<void> markStepIncomplete(String stepKey);
}
