/// A model representing filters and search for the payouts table.
/// Integrates with FirestoreService's getPayoutsForFranchise().
/// Suitable for use with Provider or other state management.
/// NO Flutter, NO BuildContext, NO AppLocalizations
class PayoutFilter {
  final String searchQuery;
  final String status;

  const PayoutFilter({
    this.searchQuery = '',
    this.status = 'all',
  });

  PayoutFilter copyWith({
    String? searchQuery,
    String? status,
  }) {
    return PayoutFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toQueryMap() {
    final map = <String, dynamic>{};
    if (status != 'all') map['status'] = status;
    if (searchQuery.trim().isNotEmpty) map['search'] = searchQuery.trim();
    return map;
  }

  /// Returns raw English status label (no localization in shared_core)
  String get statusLabel {
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

  /// Returns raw English dropdown items (no BuildContext)
  static List<Map<String, String>> get statusDropdownItems {
    return [
      {'value': 'all', 'label': 'All'},
      {'value': 'pending', 'label': 'Pending'},
      {'value': 'sent', 'label': 'Sent'},
      {'value': 'failed', 'label': 'Failed'},
    ];
  }
}
