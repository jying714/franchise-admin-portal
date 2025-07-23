import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:franchise_admin_portal/core/models/franchise_info.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';

class FranchiseInfoProvider extends ChangeNotifier {
  final FirestoreService firestore;
  final FranchiseProvider franchiseProvider;

  FranchiseInfoProvider({
    required this.firestore,
    required this.franchiseProvider,
  });

  FranchiseInfo? _franchise;
  bool _loading = false;

  FranchiseInfo? get franchise => _franchise;
  bool get loading => _loading;

  /// Call this whenever the franchiseId changes.
  Future<void> loadFranchiseInfo() async {
    final id = franchiseProvider.franchiseId;
    if (id == null || id.isEmpty) {
      _franchise = null;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      final info = await firestore.getFranchiseInfo(id);
      _franchise = info;
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'FranchiseInfoProvider failed to load franchise: $e',
        stack: stack.toString(),
        source: 'FranchiseInfoProvider',
        screen: 'global',
        severity: 'error',
        contextData: {'franchiseId': id},
      );
      _franchise = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
