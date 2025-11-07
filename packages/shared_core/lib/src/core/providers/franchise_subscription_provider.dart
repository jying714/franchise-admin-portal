import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/franchise_subscription_model.dart';
import '../models/platform_plan_model.dart';
import '../services/franchise_subscription_service.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

class FranchiseSubscriptionNotifier extends ChangeNotifier {
  final FranchiseSubscriptionService _service;
  String _franchiseId;

  FranchiseSubscription? _currentSubscription;
  FranchiseSubscription? get currentSubscription => _currentSubscription;

  PlatformPlan? _activePlatformPlan;
  PlatformPlan? get activePlatformPlan => _activePlatformPlan;

  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  String get franchiseId => _franchiseId;

  StreamSubscription<FranchiseSubscription?>? _subscriptionStream;

  // Guards
  bool _planResolved = false;
  bool _resolvingPlan = false;

  // Role handling
  List<String> _userRoles = [];
  void setUserRoles(List<String> roles) {
    _userRoles = roles;
  }

  FranchiseSubscriptionNotifier({
    required FranchiseSubscriptionService service,
    required String franchiseId,
  })  : _service = service,
        _franchiseId = franchiseId {
    if (_shouldTrackSubscription(franchiseId)) {
      _initSubscription(franchiseId);
    }
  }

  bool _shouldTrackSubscription(String franchiseId) {
    return franchiseId.isNotEmpty &&
        franchiseId != 'unknown' &&
        !_userRoles.contains('platform_owner') &&
        !_userRoles.contains('developer');
  }

  void _initSubscription(String franchiseId) {
    _subscriptionStream?.cancel();

    if (!_shouldTrackSubscription(franchiseId)) {
      if (kDebugMode) {
        debugPrint(
            '[FranchiseSubscriptionNotifier] ⛔ Subscription tracking skipped for roles: $_userRoles');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint(
          '[FranchiseSubscriptionNotifier] 📡 Listening to franchiseId: $franchiseId');
    }

    _subscriptionStream =
        _service.watchCurrentSubscription(franchiseId).listen((sub) async {
      if (kDebugMode) {
        debugPrint(
            '[FranchiseSubscriptionNotifier] 📥 Stream emitted subscription: ${sub?.platformPlanId}');
      }

      if (sub == null) {
        if (kDebugMode) {
          debugPrint(
              '[FranchiseSubscriptionNotifier] ⚠️ Stream returned null. Attempting fallback via getCurrentSubscription().');
        }

        try {
          final fallback = await _service.getCurrentSubscription(franchiseId);
          _currentSubscription = fallback;
          _hasLoaded = true;
          notifyListeners();
          if (kDebugMode) {
            debugPrint(
                '[FranchiseSubscriptionNotifier] ✅ Fallback subscription loaded.');
          }
          if (!_planResolved) {
            await resolveActivePlan();
          }
        } catch (e, stack) {
          ErrorLogger.log(
            message: 'Fallback getCurrentSubscription failed: $e',
            stack: stack.toString(),
            source: 'FranchiseSubscriptionNotifier',
            contextData: {'franchiseId': franchiseId},
          );
        }
      } else {
        _currentSubscription = sub;
        _hasLoaded = true;
        notifyListeners();
        if (kDebugMode) {
          debugPrint(
              '[FranchiseSubscriptionNotifier] ✅ Subscription received and listeners notified.');
        }
        if (!_planResolved) {
          await resolveActivePlan();
        }
      }
    });
  }

  Future<void> resolveActivePlan() async {
    if (_planResolved || _resolvingPlan) return;

    if (_userRoles.contains('platform_owner') ||
        _userRoles.contains('developer')) {
      if (kDebugMode) {
        debugPrint(
            '[FranchiseSubscriptionNotifier] ⛔ resolveActivePlan skipped for roles: $_userRoles');
      }
      return;
    }

    final planId = _currentSubscription?.platformPlanId;
    if (planId == null || planId.isEmpty) return;

    _resolvingPlan = true;

    try {
      final plan = await _service.getPlatformPlanById(planId);
      _activePlatformPlan = plan;
      _planResolved = true;
      notifyListeners();
      if (kDebugMode) {
        debugPrint(
            '[FranchiseSubscriptionNotifier] ✅ Resolved active plan: ${plan?.name}');
      }
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to fetch active platform plan: $e',
        stack: stack.toString(),
        source: 'FranchiseSubscriptionNotifier.resolveActivePlan',
        contextData: {'planId': planId},
      );
    } finally {
      _resolvingPlan = false;
    }
  }

  void updateFranchiseId(String newId) {
    if (newId.isEmpty || newId == _franchiseId) return;

    if (kDebugMode) {
      debugPrint(
          '[FranchiseSubscriptionNotifier] 🔁 Updating franchiseId to: $newId');
    }

    _franchiseId = newId;
    _hasLoaded = false;
    _planResolved = false;
    _resolvingPlan = false;

    if (_shouldTrackSubscription(newId)) {
      _initSubscription(newId);
    } else {
      if (kDebugMode) {
        debugPrint(
            '[FranchiseSubscriptionNotifier] Skipped initSubscription for $newId due to role or id constraints.');
      }
    }
  }

  // === Subscription Status Flags ===
  bool get isTrialExpired {
    final expiry = _currentSubscription?.trialEndsAt;
    return expiry != null && DateTime.now().isAfter(expiry);
  }

  bool get isOverdue {
    final status = _currentSubscription?.status.toLowerCase();
    return status == 'overdue' || status == 'past_due' || status == 'unpaid';
  }

  bool get isActivePlanCustom {
    return _activePlatformPlan?.isCustom ?? false;
  }

  @override
  void dispose() {
    _subscriptionStream?.cancel();
    super.dispose();
  }
}
