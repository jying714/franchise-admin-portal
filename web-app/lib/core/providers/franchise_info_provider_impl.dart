import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

class FranchiseInfoProviderImpl extends ChangeNotifier
    implements shared.FranchiseInfoProvider {
  final shared.FirestoreService _firestore;
  final shared.FranchiseProvider _franchiseProvider;

  shared.FranchiseInfo? _franchise;
  bool _loading = false;

  FranchiseInfoProviderImpl({
    required shared.FirestoreService firestore,
    required shared.FranchiseProvider franchiseProvider,
  })  : _firestore = firestore,
        _franchiseProvider = franchiseProvider;

  @override
  shared.FranchiseInfo? get franchise => _franchise;

  @override
  bool get loading => _loading;

  @override
  Future<void> loadFranchiseInfo() async {
    final fid = _franchiseProvider.franchiseId;

    if (fid == null || fid.isEmpty || fid == 'unknown') {
      if (_franchise != null) {
        _franchise = null;
        notifyListeners();
      }
      return;
    }

    if (_franchise?.id == fid) return;

    _loading = true;
    notifyListeners();

    try {
      final info = await _firestore.getFranchiseInfo(fid);
      _franchise = info;
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'FranchiseInfoProvider failed to load franchise: $e',
        stack: stack.toString(),
        source: 'FranchiseInfoProviderImpl',
        contextData: {'franchiseId': fid},
      );
      _franchise = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> reload() async => loadFranchiseInfo();

  @override
  void clear() {
    _franchise = null;
    _loading = false;
    notifyListeners();
  }
}
