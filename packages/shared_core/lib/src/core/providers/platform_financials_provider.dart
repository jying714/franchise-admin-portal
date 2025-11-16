// packages/shared_core/lib/src/core/providers/platform_financials_provider.dart
// PURE DART INTERFACE ONLY

import '../models/platform_revenue_overview.dart';
import '../models/platform_financial_kpis.dart';

abstract class PlatformFinancialsProvider {
  PlatformRevenueOverview? get overview;
  PlatformFinancialKpis? get kpis;
  bool get loading;
  String? get error;

  Future<void> loadFinancials();
  Future<void> refresh();
  void clear();
}
