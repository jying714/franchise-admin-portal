import 'package:flutter/material.dart';
import '../models/payout_filter.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

/// Provider for managing payout table filter/search state.
/// Integrates with FirestoreService's getPayoutsForFranchise().
///
/// Designed to be provided high in the widget tree for
/// PayoutListScreen and related filter/search widgets.
class PayoutFilterProvider extends ChangeNotifier {
  /// Internal filter state.
  PayoutFilter _filter = const PayoutFilter();

  /// Last error caught (for developer-only debug UI).
  String? _lastError;

  /// Returns current filter state.
  PayoutFilter get filter => _filter;

  /// Returns the current status filter value.
  String get status => _filter.status;

  /// Returns the current search query value.
  String get searchQuery => _filter.searchQuery;

  /// Returns the last error (if any).
  String? get lastError => _lastError;

  /// Set a new filter (replaces all fields)
  void setFilter(PayoutFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  /// Set status filter only.
  void setStatus(String status) {
    _filter = _filter.copyWith(status: status);
    notifyListeners();
  }

  /// Set the text search query.
  void setSearchQuery(String query) {
    _filter = _filter.copyWith(searchQuery: query);
    notifyListeners();
  }

  /// Set last error (optional developer use, e.g. after a failed fetch)
  void setError(Object? error, [StackTrace? stack, String? context]) {
    _lastError = error?.toString();
    ErrorLogger.log(
      message: 'PayoutFilterProvider Error: $_lastError',
      stack: stack?.toString(),
      source: 'PayoutFilterProvider',
      severity: 'warning',
    );
    notifyListeners();
  }

  /// Resets all filters to default.
  void clearFilters() {
    _filter = const PayoutFilter();
    notifyListeners();
  }
}
