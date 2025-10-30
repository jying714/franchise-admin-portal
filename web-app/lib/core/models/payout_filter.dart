import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// A model representing filters and search for the payouts table.
/// Integrates with FirestoreService's getPayoutsForFranchise().
/// Suitable for use with Provider or other state management.
class PayoutFilter {
  /// Text entered into the general search box.
  final String searchQuery;

  /// Status filter: 'all', 'pending', 'sent', 'failed'
  final String status;

  /// Additional fields (future extensible: date range, method, amount, etc.)
  // final DateTimeRange? dateRange;
  // final String? payoutMethod;

  const PayoutFilter({
    this.searchQuery = '',
    this.status = 'all',
    // this.dateRange,
    // this.payoutMethod,
  });

  /// Returns a copy with new values
  PayoutFilter copyWith({
    String? searchQuery,
    String? status,
    // DateTimeRange? dateRange,
    // String? payoutMethod,
  }) {
    return PayoutFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      status: status ?? this.status,
      // dateRange: dateRange ?? this.dateRange,
      // payoutMethod: payoutMethod ?? this.payoutMethod,
    );
  }

  /// Converts to a Firestore query map for backend search
  Map<String, dynamic> toQueryMap() {
    final map = <String, dynamic>{};
    if (status != 'all') map['status'] = status;
    if (searchQuery.trim().isNotEmpty) map['search'] = searchQuery.trim();
    // if (dateRange != null) {
    //   map['startDate'] = dateRange!.start.toIso8601String();
    //   map['endDate'] = dateRange!.end.toIso8601String();
    // }
    // if (payoutMethod != null) map['method'] = payoutMethod;
    return map;
  }

  /// Returns the status label for UI (localized)
  /// Returns the status label for UI (localized)
  String statusLabel(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[PayoutFilter] loc is null! Localization not available for this context.');
      // Fallback to status code itself or English string
      switch (status) {
        case 'pending':
          return 'Pending';
        case 'sent':
          return 'Sent';
        case 'failed':
          return 'Failed';
        case 'all':
        default:
          return 'All';
      }
    }
    switch (status) {
      case 'pending':
        return loc.pending;
      case 'sent':
        return loc.sent;
      case 'failed':
        return loc.failed;
      case 'all':
      default:
        return loc.all ?? 'All';
    }
  }

  /// Returns the list of filter status dropdown items (localized)
  static List<DropdownMenuItem<String>> statusDropdownItems(
      BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[PayoutFilter] loc is null! Localization not available for this context.');
      // Fallback to English
      return [
        DropdownMenuItem(value: 'all', child: Text('All')),
        DropdownMenuItem(value: 'pending', child: Text('Pending')),
        DropdownMenuItem(value: 'sent', child: Text('Sent')),
        DropdownMenuItem(value: 'failed', child: Text('Failed')),
      ];
    }
    return [
      DropdownMenuItem(value: 'all', child: Text(loc.all ?? 'All')),
      DropdownMenuItem(value: 'pending', child: Text(loc.pending)),
      DropdownMenuItem(value: 'sent', child: Text(loc.sent)),
      DropdownMenuItem(value: 'failed', child: Text(loc.failed)),
    ];
  }
}
