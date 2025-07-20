import 'dart:async';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/franchise_subscription_model.dart';
import 'package:franchise_admin_portal/core/services/franchise_subscription_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class FranchiseSubscriptionNotifier extends ChangeNotifier {
  final FranchiseSubscriptionService _service;
  String _franchiseId;

  FranchiseSubscription? _currentSubscription;
  FranchiseSubscription? get currentSubscription => _currentSubscription;

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
        _service.watchCurrentSubscription(franchiseId).listen((sub) {
      print('[FranchiseSubscriptionNotifier] Received: ${sub?.platformPlanId}');
      _currentSubscription = sub;
      _hasLoaded = true;
      notifyListeners();
      print('[FranchiseSubscriptionNotifier] Notified listeners.');
    });
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
