// packages/shared_core/lib/src/core/providers/payout_filter_provider.dart
// PURE DART INTERFACE ONLY

import '../models/payout_filter.dart';

abstract class PayoutFilterProvider {
  PayoutFilter get filter;
  String get status;
  String get searchQuery;
  String? get lastError;

  void setFilter(PayoutFilter filter);
  void setStatus(String status);
  void setSearchQuery(String query);
  void setError(Object? error, [StackTrace? stack, String? context]);
  void clearFilters();
}
