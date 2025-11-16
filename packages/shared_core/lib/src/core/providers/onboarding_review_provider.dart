// packages/shared_core/lib/src/core/providers/onboarding_review_provider.dart
// PURE DART INTERFACE ONLY

import '../models/onboarding_validation_issue.dart';

abstract class OnboardingReviewProvider {
  Map<String, List<OnboardingValidationIssue>> get allIssuesBySection;
  List<OnboardingValidationIssue> get allIssuesFlat;
  bool get isPublishable;
  DateTime? get lastValidatedAt;
  Map<String, dynamic> get lastExportSnapshot;

  Future<void> validateAll();
  String exportDataAsJson();
  Future<void> publishOnboarding(
      {required String franchiseId, required String userId});
  Future<void> refresh();
  List<OnboardingValidationIssue> get issues;
  List<OnboardingValidationIssue> get validationResults;
}
