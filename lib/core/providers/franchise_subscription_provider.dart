import 'dart:async';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/franchise_subscription_model.dart';
import 'package:franchise_admin_portal/core/services/franchise_subscription_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class FranchiseSubscriptionNotifier extends ChangeNotifier {
  final FranchiseSubscriptionService _service;
  late String _franchiseId;

  FranchiseSubscriptionNotifier({
    required FranchiseSubscriptionService service,
    required String franchiseId,
  }) : _service = service {
    _franchiseId = franchiseId;
    _init();
  }

  FranchiseSubscription? _currentSubscription;
  FranchiseSubscription? get currentSubscription => _currentSubscription;

  StreamSubscription<FranchiseSubscription?>? _subscriptionStream;

  Future<void> _init() async {
    try {
      _subscriptionStream =
          _service.watchCurrentSubscription(_franchiseId).listen((sub) {
        print(
            '[FranchiseSubscriptionNotifier] Received subscription: ${sub?.platformPlanId}');
        _currentSubscription = sub;
        notifyListeners();
        print(
            '[FranchiseSubscriptionNotifier] Received subscription update: ${sub?.platformPlanId ?? 'null'}');

        notifyListeners();
        print('[FranchiseSubscriptionNotifier] Notified listeners.');
      });
    } catch (e, stack) {
      print('[FranchiseSubscriptionNotifier] Initialization error: $e');
      await ErrorLogger.log(
        message: 'FranchiseSubscriptionNotifier initialization failed: $e',
        stack: stack.toString(),
        source: 'FranchiseSubscriptionNotifier',
        screen: 'provider_init',
        severity: 'error',
        contextData: {'franchiseId': _franchiseId},
      );
    }
  }

  void updateFranchiseId(String newId) {
    if (_franchiseId != newId) {
      _franchiseId = newId;
      _subscriptionStream?.cancel();
      _init();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscriptionStream?.cancel();
    super.dispose();
  }
}
