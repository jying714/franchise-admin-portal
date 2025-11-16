// 📁 lib/core/providers/platform_plan_selection_provider.dart

import 'package:flutter/material.dart';
import '../models/platform_plan_model.dart';
import '../services/firestore_service_BACKUP.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';
import '../models/franchise_subscription_model.dart';
import '../services/franchise_subscription_service.dart';

class PlatformPlanSelectionProvider extends ChangeNotifier {
  PlatformPlan? _selectedPlan;
  bool _isLoading = false;
  String? _errorMessage;
  bool _success = false;

  PlatformPlan? get selectedPlan => _selectedPlan;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get success => _success;

  void selectPlan(PlatformPlan plan) {
    _selectedPlan = plan;
    _errorMessage = null;
    _success = false;
    notifyListeners();
  }

  void clear() {
    _selectedPlan = null;
    _errorMessage = null;
    _success = false;
    _isLoading = false;
    notifyListeners();
  }

  /// Submits the currently selected plan for the given franchise.
  Future<void> subscribeToPlan({
    required String franchiseId,
    required PlatformPlan plan,
    VoidCallback? onSuccess,
    String? successMessage,
    String? errorMessage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _success = false;
    notifyListeners();

    try {
      await FranchiseSubscriptionService().subscribeFranchiseToPlan(
        franchiseId: franchiseId,
        plan: plan,
      );

      _success = true;
      if (onSuccess != null) onSuccess();
      if (successMessage != null) {
        // Caller handles UI (SnackBar, etc.)
      }
    } catch (e, stack) {
      _errorMessage = errorMessage ?? 'Subscription failed';
      ErrorLogger.log(
        message: 'Plan subscription failed: $e',
        stack: stack.toString(),
        source: 'PlatformPlanSelectionProvider',
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

  FranchiseSubscription? _currentSubscription;

  FranchiseSubscription? get currentSubscription => _currentSubscription;

  Future<void> refreshSubscription(String franchiseId) async {
    try {
      final sub =
          await FirestoreService().getFranchiseSubscription(franchiseId);
      _currentSubscription = sub;
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to refresh subscription for franchise: $franchiseId',
        stack: stack.toString(),
        source: 'PlatformPlanSelectionProvider',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId, 'exception': e.toString()},
      );
    }
  }
}
