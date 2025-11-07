// packages/shared_core/lib/src/core/services/franchise_onboarding_service.dart

/// Pure interface — no Firebase, no Flutter
abstract class FranchiseOnboardingService {
  /// Marks the franchise's onboarding status as completed
  Future<void> markOnboardingComplete(String franchiseId);

  /// Returns whether the franchise is flagged as having completed onboarding
  Future<bool> isOnboardingComplete(String franchiseId);
}
