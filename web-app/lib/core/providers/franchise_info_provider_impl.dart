import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

class FranchiseInfoProviderImpl extends ChangeNotifier
    implements shared.FranchiseInfoProvider {
  final shared.FirestoreService _firestore;
  final shared.FranchiseProvider _franchiseProvider;

  shared.FranchiseInfo? _franchise;
  bool _loading = false;
  String? _lastLoadedId;

  FranchiseInfoProviderImpl({
    required shared.FirestoreService firestore,
    required shared.FranchiseProvider franchiseProvider,
  })  : _firestore = firestore,
        _franchiseProvider = franchiseProvider {
    // Bind to every change from the single source of truth
    _franchiseProvider.onFranchiseChanged = _onFranchiseChanged;

    // Aggressive initial + post-handoff loads
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWithRetry());
    Future.delayed(const Duration(milliseconds: 200), _loadWithRetry);
    Future.delayed(const Duration(milliseconds: 600), _loadWithRetry);
    Future.delayed(const Duration(milliseconds: 1400), _loadWithRetry);
  }

  @override
  shared.FranchiseInfo? get franchise => _franchise;

  @override
  bool get loading => _loading;

  void _onFranchiseChanged() {
    print(
        '[FranchiseInfoProviderImpl] onFranchiseChanged triggered - forcing reload');
    _lastLoadedId = null; // Force fresh
    _loadWithRetry();
  }

  Future<void> _loadWithRetry() async {
    // Always read the LATEST from the single source of truth
    final fid = _franchiseProvider.franchiseId;
    print(
        '[FranchiseInfoProviderImpl] _loadWithRetry() called with CURRENT fid: "$fid"');

    if (fid == null || fid.isEmpty || fid == 'unknown' || fid == 'default') {
      print(
          '[FranchiseInfoProviderImpl] Invalid fid → no-op (preserve previous if any)');
      return;
    }

    if (_lastLoadedId == fid && _franchise != null) {
      print('[FranchiseInfoProviderImpl] Already loaded for $fid');
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      final info = await _firestore.getFranchiseInfo(fid);
      if (info != null) {
        print(
            '[FranchiseInfoProviderImpl] SUCCESS: Loaded "${info.name}" (id: ${info.id})');
        _franchise = info;
        _lastLoadedId = fid;
      } else {
        print(
            '[FranchiseInfoProviderImpl] WARNING: getFranchiseInfo returned null for $fid');
        _franchise = null;
      }
    } catch (e, stack) {
      print('[FranchiseInfoProviderImpl] ERROR loading $fid: $e');
      shared.ErrorLogger.log(
        message: 'FranchiseInfoProvider failed to load franchise',
        source: 'FranchiseInfoProviderImpl',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': fid},
      );
      _franchise = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> loadFranchiseInfo() async => _loadWithRetry();

  @override
  Future<void> reload() async {
    _lastLoadedId = null;
    await _loadWithRetry();
  }

  @override
  void clear() {
    _franchise = null;
    _lastLoadedId = null;
    _loading = false;
    notifyListeners();
  }
}
