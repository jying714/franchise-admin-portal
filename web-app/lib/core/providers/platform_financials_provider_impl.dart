// web_app/lib/core/providers/platform_financials_provider_impl.dart

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class PlatformFinancialsProviderImpl extends ChangeNotifier
    implements PlatformFinancialsProvider {
  PlatformRevenueOverview? _overview;
  PlatformFinancialKpis? _kpis;
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  @override
  PlatformRevenueOverview? get overview => _overview;

  @override
  PlatformFinancialKpis? get kpis => _kpis;

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  Future<void> loadFinancials() async {
    _loading = true;
    _error = null;
    if (!_disposed) notifyListeners();

    try {
      final firestore = FirestoreServiceImpl(); // Use concrete impl
      final results = await Future.wait([
        firestore.fetchPlatformRevenueOverview(),
        firestore.fetchPlatformFinancialKpis(),
      ]);

      _overview = results[0] as PlatformRevenueOverview;
      _kpis = results[1] as PlatformFinancialKpis;
    } catch (e, stack) {
      debugPrint('Firestore error in loadFinancials: $e');
      _error = e.toString();
      ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'PlatformFinancialsProviderImpl',
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
