// 📁 lib/core/providers/platform_plan_selection_provider.dart

import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/platform_plan_model.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    required BuildContext context,
    required String franchiseId,
    VoidCallback? onSuccess,
  }) async {
    final loc = AppLocalizations.of(context)!;
    final plan = _selectedPlan;
    if (plan == null) {
      _errorMessage = loc.genericErrorOccurred;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _success = false;
    notifyListeners();

    try {
      await FirestoreService().subscribeFranchiseToPlan(
        franchiseId: franchiseId,
        plan: plan,
      );
      _success = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.subscriptionSuccessMessage)),
      );

      // ⬅️ Trigger success flow
      if (onSuccess != null) onSuccess();
    } catch (e, stack) {
      _errorMessage = loc.genericErrorOccurred;
      await ErrorLogger.log(
        message: 'Plan subscription failed: $e',
        stack: stack.toString(),
        source: 'PlatformPlanSelectionProvider',
        screen: 'available_platform_plans_screen',
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
          'planId': plan.id,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.genericErrorOccurred),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
