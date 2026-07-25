// web-app/lib/core/providers/platform_financials_provider_impl.dart

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

class PlatformFinancialsProviderImpl extends ChangeNotifier
    implements shared.PlatformFinancialsProvider {
  final shared.FirestoreService _firestore;

  PlatformFinancialsProviderImpl({required shared.FirestoreService firestore})
      : _firestore = firestore;
  shared.PlatformRevenueOverview? _overview;
  shared.PlatformFinancialKpis? _kpis;
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  shared.PlatformRevenueOverview? get overview => _overview;

  shared.PlatformFinancialKpis? get kpis => _kpis;

  bool get loading => _loading;

  String? get error => _error;

  @override
  Future<void> loadFinancials() async {
    _loading = true;
    _error = null;
    if (!_disposed) notifyListeners();

    try {
      final results = await Future.wait([
        _firestore.fetchPlatformRevenueOverview(),
        _firestore.fetchPlatformFinancialKpis(),
      ]);

      _overview = results[0] as shared.PlatformRevenueOverview?;
      _kpis = results[1] as shared.PlatformFinancialKpis?;
    } catch (e, stack) {
      debugPrint('Firestore error in loadFinancials: $e');
      _error = e.toString();
      shared.ErrorLogger.log(
        message: 'Failed to load platform financials',
        stack: stack.toString(),
        source: 'PlatformFinancialsProviderImpl.loadFinancials',
        severity: 'error',
      );
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  Future<void> refresh() => loadFinancials();

  @override
  void clear() {
    _overview = null;
    _kpis = null;
    _loading = false;
    _error = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
