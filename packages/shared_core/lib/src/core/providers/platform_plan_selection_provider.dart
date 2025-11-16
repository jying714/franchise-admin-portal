// packages/shared_core/lib/src/core/providers/platform_plan_selection_provider.dart
// PURE DART INTERFACE ONLY

import '../models/platform_plan_model.dart';
import '../models/franchise_subscription_model.dart';

abstract class PlatformPlanSelectionProvider {
  PlatformPlan? get selectedPlan;
  bool get isLoading;
  String? get errorMessage;
  bool get success;
  FranchiseSubscription? get currentSubscription;

  void selectPlan(PlatformPlan plan);
  void clear();

  Future<void> subscribeToPlan({
    required String franchiseId,
    required PlatformPlan plan,
    String? successMessage,
    String? errorMessage,
  });

  Future<void> refreshSubscription(String franchiseId);
}
