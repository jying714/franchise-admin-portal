import 'dart:async';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/franchise_subscription_model.dart';
import 'package:franchise_admin_portal/core/models/platform_plan_model.dart';
import 'package:franchise_admin_portal/core/services/franchise_subscription_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class FranchiseSubscriptionNotifier extends ChangeNotifier {
  final FranchiseSubscriptionService _service;
  String _franchiseId;

  FranchiseSubscription? _currentSubscription;
  FranchiseSubscription? get currentSubscription => _currentSubscription;

  PlatformPlan? _activePlatformPlan;
  PlatformPlan? get activePlatformPlan => _activePlatformPlan;

  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  StreamSubscription<FranchiseSubscription?>? _subscriptionStream;

  FranchiseSubscriptionNotifier({
    required FranchiseSubscriptionService service,
    required String franchiseId,
  })  : _service = service,
        _franchiseId = franchiseId {
    if (franchiseId.isNotEmpty) {
      _initSubscription(franchiseId);
    }
  }

  void _initSubscription(String franchiseId) {
    _subscriptionStream?.cancel(); // Clear prior stream

    _subscriptionStream =
        _service.watchCurrentSubscription(franchiseId).listen((sub) async {
      print('[FranchiseSubscriptionNotifier] Received: ${sub?.platformPlanId}');

      if (sub == null) {
        print(
            '[FranchiseSubscriptionNotifier] Stream null, fallback to getCurrentSubscription()');
        try {
          final fallback = await _service.getCurrentSubscription(franchiseId);
          _currentSubscription = fallback;
          _hasLoaded = true;
          notifyListeners();
          print(
              '[FranchiseSubscriptionNotifier] Fallback subscription loaded.');
          await resolveActivePlan(); // resolve after fallback
        } catch (e, stack) {
          await ErrorLogger.log(
            message: 'Fallback getCurrentSubscription failed: $e',
            stack: stack.toString(),
            source: 'FranchiseSubscriptionNotifier',
            screen: 'subscription_logic',
            severity: 'error',
            contextData: {'franchiseId': franchiseId},
          );
        }
      } else {
        _currentSubscription = sub;
        _hasLoaded = true;
        notifyListeners();
        print('[FranchiseSubscriptionNotifier] Notified listeners.');
        await resolveActivePlan(); // resolve after real-time update
      }
    });
  }

  Future<void> resolveActivePlan() async {
    final planId = _currentSubscription?.platformPlanId;
    if (planId == null || planId.isEmpty) return;

    try {
      final plan = await _service.getPlatformPlanById(planId);
      _activePlatformPlan = plan;
      notifyListeners();
      print(
          '[FranchiseSubscriptionNotifier] Resolved active plan: ${plan?.name}');
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to fetch active platform plan: $e',
        stack: stack.toString(),
        source: 'FranchiseSubscriptionNotifier',
        screen: 'resolveActivePlan',
        severity: 'warning',
        contextData: {'planId': planId},
      );
    }
  }

  void updateFranchiseId(String newId) {
    if (newId.isNotEmpty && _franchiseId != newId) {
      _franchiseId = newId;
      _hasLoaded = false;
      _initSubscription(newId);
    }
  }

  @override
  void dispose() {
    _subscriptionStream?.cancel();
    super.dispose();
  }
}
