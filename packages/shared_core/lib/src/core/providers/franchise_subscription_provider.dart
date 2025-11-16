// packages/shared_core/lib/src/core/providers/franchise_subscription_provider.dart
// PURE DART INTERFACE ONLY

import '../models/franchise_subscription_model.dart';
import '../models/platform_plan_model.dart';

abstract class FranchiseSubscriptionProvider {
  FranchiseSubscription? get currentSubscription;
  PlatformPlan? get activePlatformPlan;
  bool get hasLoaded;
  String get franchiseId;

  void setUserRoles(List<String> roles);
  void updateFranchiseId(String newId);
  bool get isTrialExpired;
  bool get isOverdue;
  bool get isActivePlanCustom;
}
