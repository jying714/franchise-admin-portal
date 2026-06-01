// web-app/lib/core/providers/franchise_subscription_provider_impl.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'dart:async';

class FranchiseSubscriptionProviderImpl extends ChangeNotifier
    implements shared.FranchiseSubscriptionProvider {
  final shared.FranchiseSubscriptionService _service;
  String _franchiseId;

  shared.FranchiseSubscription? _currentSubscription;
  @override
  shared.FranchiseSubscription? get currentSubscription => _currentSubscription;

  shared.PlatformPlan? _activePlatformPlan;
  @override
  shared.PlatformPlan? get activePlatformPlan => _activePlatformPlan;

  bool _hasLoaded = false;
  @override
  bool get hasLoaded => _hasLoaded;

  @override
  String get franchiseId => _franchiseId;

  StreamSubscription<shared.FranchiseSubscription?>? _subscriptionStream;

  bool _planResolved = false;
  bool _resolvingPlan = false;

  List<String> _userRoles = [];

  FranchiseSubscriptionProviderImpl({
    required shared.FranchiseSubscriptionService service,
    required String franchiseId,
  })  : _service = service,
        _franchiseId = franchiseId {
    if (_shouldTrackSubscription(franchiseId)) {
      _initSubscription(franchiseId);
    }
  }

  @override
  void setUserRoles(List<String> roles) {
    _userRoles = roles;
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
            '[FranchiseSubscriptionProvider] Subscription tracking skipped for roles: $_userRoles');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint(
          '[FranchiseSubscriptionProvider] Listening to franchiseId: $franchiseId');
    }

    _subscriptionStream =
        _service.watchCurrentSubscription(franchiseId).listen((sub) async {
      if (kDebugMode) {
        debugPrint(
            '[FranchiseSubscriptionProvider] Stream emitted: ${sub?.platformPlanId}');
      }

      if (sub == null) {
        try {
          final fallback = await _service.getCurrentSubscription(franchiseId);
          _currentSubscription = fallback;
          _hasLoaded = true;
          notifyListeners();
          if (!_planResolved) await resolveActivePlan();
        } catch (e, stack) {
          shared.ErrorLogger.log(
            message: 'Fallback getCurrentSubscription failed: $e',
            stack: stack.toString(),
            source: 'FranchiseSubscriptionProviderImpl',
            contextData: {'franchiseId': franchiseId},
          );
        }
      } else {
        _currentSubscription = sub;
        _hasLoaded = true;
        notifyListeners();
        if (!_planResolved) await resolveActivePlan();
      }
    });
  }

  Future<void> resolveActivePlan() async {
    if (_planResolved || _resolvingPlan) return;

    if (_userRoles.contains('platform_owner') ||
        _userRoles.contains('developer')) return;

    final planId = _currentSubscription?.platformPlanId;
    if (planId == null || planId.isEmpty) return;

    _resolvingPlan = true;

    try {
      final plan = await _service.getPlatformPlanById(planId);
      _activePlatformPlan = plan;
      _planResolved = true;
      notifyListeners();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to fetch active platform plan: $e',
        stack: stack.toString(),
        source: 'FranchiseSubscriptionProviderImpl.resolveActivePlan',
        contextData: {'planId': planId},
      );
    } finally {
      _resolvingPlan = false;
    }
  }

  @override
  void updateFranchiseId(String newId) {
    if (newId.isEmpty || newId == _franchiseId) return;

    _franchiseId = newId;
    _hasLoaded = false;
    _planResolved = false;
    _resolvingPlan = false;

    if (_shouldTrackSubscription(newId)) {
      _initSubscription(newId);
    }
  }

  @override
  bool get isTrialExpired {
    final expiry = _currentSubscription?.trialEndsAt;
    return expiry != null && DateTime.now().isAfter(expiry);
  }

  @override
  bool get isOverdue {
    final status = _currentSubscription?.status.toLowerCase();
    return status == 'overdue' || status == 'past_due' || status == 'unpaid';
  }

  @override
  bool get isActivePlanCustom => _activePlatformPlan?.isCustom ?? false;

  @override
  void dispose() {
    _subscriptionStream?.cancel();
    super.dispose();
  }
}
