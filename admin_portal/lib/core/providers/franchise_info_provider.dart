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
    final fid = franchiseProvider.franchiseId;

    if (fid == null || fid.isEmpty || fid == 'unknown') {
      debugPrint(
          '[FranchiseInfoProvider] Skipping load — invalid franchiseId: "$fid"');

      if (_franchise != null) {
        _franchise = null;
        notifyListeners();
      }
      return;
    }

    if (_franchise?.id == fid) {
      // Already loaded — skip
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      debugPrint('[FranchiseInfoProvider] Loading franchise info for id=$fid');
      final info = await firestore.getFranchiseInfo(fid);
      _franchise = info;
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'FranchiseInfoProvider failed to load franchise: $e',
        stack: stack.toString(),
        source: 'FranchiseInfoProvider',
        screen: 'global',
        severity: 'error',
        contextData: {'franchiseId': fid},
      );
      _franchise = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Reload franchise info (useful after sidebar repair/add-new flows)
  Future<void> reload() async {
    await loadFranchiseInfo();
  }

  void clear() {
    _franchise = null;
    _loading = false;
    notifyListeners();
  }
}
