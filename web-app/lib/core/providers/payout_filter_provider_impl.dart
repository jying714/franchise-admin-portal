// web_app/lib/core/providers/payout_filter_provider_impl.dart

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class PayoutFilterProviderImpl extends ChangeNotifier
    implements PayoutFilterProvider {
  PayoutFilter _filter = const PayoutFilter();
  String? _lastError;

  @override
  PayoutFilter get filter => _filter;

  @override
  String get status => _filter.status;

  @override
  String get searchQuery => _filter.searchQuery;

  @override
  String? get lastError => _lastError;

  @override
  void setFilter(PayoutFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  @override
  void setStatus(String status) {
    _filter = _filter.copyWith(status: status);
    notifyListeners();
  }

  @override
  void setSearchQuery(String query) {
    _filter = _filter.copyWith(searchQuery: query);
    notifyListeners();
  }

  @override
  void setError(Object? error, [StackTrace? stack, String? context]) {
    _lastError = error?.toString();
    ErrorLogger.log(
      message: 'PayoutFilterProvider Error: $_lastError',
      stack: stack?.toString(),
      source: 'PayoutFilterProviderImpl',
      severity: 'warning',
      contextData: context != null ? {'context': context} : null,
    );
    notifyListeners();
  }

  @override
  void clearFilters() {
    _filter = const PayoutFilter();
    notifyListeners();
  }
}
