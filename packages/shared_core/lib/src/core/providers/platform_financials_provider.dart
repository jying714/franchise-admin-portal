import 'package:flutter/material.dart';
import '../models/platform_revenue_overview.dart';
import '../models/platform_financial_kpis.dart';
import '../services/firestore_service.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

/// Provider for platform-level revenue and KPI aggregates.
/// Robust state management for the platform owner dashboard.
class PlatformFinancialsProvider extends ChangeNotifier {
  PlatformRevenueOverview? _overview;
  PlatformFinancialKpis? _kpis;
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  PlatformRevenueOverview? get overview => _overview;
  PlatformFinancialKpis? get kpis => _kpis;
  bool get loading => _loading;
  String? get error => _error;

  /// Call to fetch both aggregates for the dashboard.
  Future<void> loadFinancials() async {
    _loading = true;
    _error = null;
    if (!_disposed) notifyListeners();
    try {
      final results = await Future.wait([
        FirestoreService().fetchPlatformRevenueOverview(),
        FirestoreService().fetchPlatformFinancialKpis(),
      ]);
      _overview = results[0] as PlatformRevenueOverview;
      _kpis = results[1] as PlatformFinancialKpis;
      _loading = false;
      if (!_disposed) notifyListeners();
    } catch (e, stack) {
      debugPrint('Firestore error in loadFinancials: $e');
      debugPrint('Stack trace: $stack');
      ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'PlatformFinancialsProvider',
        severity: 'error',
      );
      _error = e.toString();
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Refresh on demand, or when settings change.
  Future<void> refresh() => loadFinancials();

  /// Clear all state (optional for logouts/tests)
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
