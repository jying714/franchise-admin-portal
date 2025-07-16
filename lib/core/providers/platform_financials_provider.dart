import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/platform_revenue_overview.dart';
import 'package:franchise_admin_portal/core/models/platform_financial_kpis.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

/// Provider for platform-level revenue and KPI aggregates.
/// Robust state management for the platform owner dashboard.
class PlatformFinancialsProvider extends ChangeNotifier {
  PlatformRevenueOverview? _overview;
  PlatformFinancialKpis? _kpis;
  bool _loading = false;
  String? _error;

  PlatformRevenueOverview? get overview => _overview;
  PlatformFinancialKpis? get kpis => _kpis;
  bool get loading => _loading;
  String? get error => _error;

  /// Call to fetch both aggregates for the dashboard.
  Future<void> loadFinancials() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        FirestoreService().fetchPlatformRevenueOverview(),
        FirestoreService().fetchPlatformFinancialKpis(),
      ]);
      _overview = results[0] as PlatformRevenueOverview;
      _kpis = results[1] as PlatformFinancialKpis;
      _loading = false;
      notifyListeners();
    } catch (e, stack) {
      // Print the full Firestore error (including index URL) to your terminal:
      debugPrint('Firestore error in loadFinancials: $e');
      debugPrint('Stack trace: $stack');
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'PlatformFinancialsProvider',
        screen: 'loadFinancials',
        severity: 'error',
      );
      _error = e.toString();
      _loading = false;
      notifyListeners();
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
    notifyListeners();
  }

  // 💡 Future Feature Placeholder:
  // Add more advanced metrics/fields as your dashboard evolves!
}
