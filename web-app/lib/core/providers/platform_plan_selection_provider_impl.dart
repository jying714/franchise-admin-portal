// web_app/lib/core/providers/platform_plan_selection_provider_impl.dart

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class PlatformPlanSelectionProviderImpl extends ChangeNotifier
    implements PlatformPlanSelectionProvider {
  PlatformPlan? _selectedPlan;
  bool _isLoading = false;
  String? _errorMessage;
  bool _success = false;
  FranchiseSubscription? _currentSubscription;

  @override
  PlatformPlan? get selectedPlan => _selectedPlan;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool get success => _success;

  @override
  FranchiseSubscription? get currentSubscription => _currentSubscription;

  @override
  void selectPlan(PlatformPlan plan) {
    _selectedPlan = plan;
    _errorMessage = null;
    _success = false;
    notifyListeners();
  }

  @override
  void clear() {
    _selectedPlan = null;
    _errorMessage = null;
    _success = false;
    _isLoading = false;
    _currentSubscription = null;
    notifyListeners();
  }

  @override
  Future<void> subscribeToPlan({
    required String franchiseId,
    required PlatformPlan plan,
    String? successMessage,
    String? errorMessage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _success = false;
    notifyListeners();

    try {
      final service = FranchiseSubscriptionServiceImpl(); // ← Use impl
      await service.subscribeFranchiseToPlan(
        franchiseId: franchiseId,
        plan: plan,
      );

      _success = true;
    } catch (e, stack) {
      _errorMessage = errorMessage ?? 'Subscription failed';
      ErrorLogger.log(
        message: 'Plan subscription failed: $e',
        stack: stack.toString(),
        source: 'PlatformPlanSelectionProviderImpl',
        contextData: {
          'franchiseId': franchiseId,
          'planId': plan.id,
        },
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> refreshSubscription(String franchiseId) async {
    try {
      final firestore = FirestoreServiceImpl(); // ← Use impl
      final sub = await firestore.getFranchiseSubscription(franchiseId);
      _currentSubscription = sub;
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to refresh subscription for franchise: $franchiseId',
        stack: stack.toString(),
        source: 'PlatformPlanSelectionProviderImpl',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
    }
  }
}
