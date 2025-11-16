// packages/shared_core/lib/src/core/services/franchise_subscription_service.dart
// PURE DART ABSTRACT INTERFACE ONLY

import '../models/franchise_subscription_model.dart';
import '../models/platform_plan_model.dart';

abstract class FranchiseSubscriptionService {
  // Core Lifecycle
  Future<void> subscribeFranchiseToPlan({
    required String franchiseId,
    required PlatformPlan plan,
  });

  Future<void> updateFranchiseSubscription({
    required String documentId,
    required Map<String, dynamic> data,
  });

  Future<void> saveFranchiseSubscription(FranchiseSubscription subscription);
  Future<void> deleteFranchiseSubscription(String id);
  Future<void> deleteManyFranchiseSubscriptions(List<String> ids);

  // Queries
  Future<List<FranchiseSubscription>> getAllFranchiseSubscriptions();
  Stream<List<FranchiseSubscription>> watchAllFranchiseSubscriptions();
  Future<FranchiseSubscription?> getCurrentSubscription(String franchiseId);
  Future<FranchiseSubscription?> getActiveSubscriptionForFranchise(
      String franchiseId);
  Stream<FranchiseSubscription?> watchCurrentSubscription(String franchiseId);

  // Platform Plans
  Future<PlatformPlan?> getPlatformPlanById(String planId);
  Future<List<PlatformPlan>> getAllPlatformPlans();
  Future<List<PlatformPlan>> getPlatformPlans();
}
