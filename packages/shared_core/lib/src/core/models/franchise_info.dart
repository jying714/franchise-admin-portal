class FranchiseInfo {
  final String id;
  final String name;
  final String? logoUrl;
  final String? status;
  final String? ownerName;
  final String? phone;
  final String? businessEmail;
  final String? restaurantType;

  /// Stripe Connect account id for this franchise (e.g. acct_…). Null = not onboarded.
  final String? stripeConnectAccountId;

  /// Connect account status from Stripe (e.g. pending, restricted, enabled). Null if unknown.
  final String? stripeConnectStatus;

  /// True only when the connected account can accept charges. Default false (fail-closed).
  final bool paymentsEnabled;

  FranchiseInfo({
    required this.id,
    required this.name,
    this.logoUrl,
    this.status,
    this.ownerName,
    this.phone,
    this.businessEmail,
    this.restaurantType,
    this.stripeConnectAccountId,
    this.stripeConnectStatus,
    this.paymentsEnabled = false,
  });

  factory FranchiseInfo.fromMap(Map<String, dynamic> data, String id) {
    return FranchiseInfo(
      id: id,
      name: data['name'] ?? 'Unnamed Franchise',
      logoUrl: data['logoUrl'],
      status: data['status'] ?? 'active',
      ownerName: data['ownerName'],
      phone: data['phone'],
      businessEmail: data['businessEmail'],
      restaurantType: data['restaurantType'] as String?,
      stripeConnectAccountId: data['stripeConnectAccountId'] as String?,
      stripeConnectStatus: data['stripeConnectStatus'] as String?,
      paymentsEnabled: data['paymentsEnabled'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (status != null) 'status': status,
      if (ownerName != null) 'ownerName': ownerName,
      if (phone != null) 'phone': phone,
      if (businessEmail != null) 'businessEmail': businessEmail,
      if (restaurantType != null) 'restaurantType': restaurantType,
      if (stripeConnectAccountId != null)
        'stripeConnectAccountId': stripeConnectAccountId,
      if (stripeConnectStatus != null)
        'stripeConnectStatus': stripeConnectStatus,
      'paymentsEnabled': paymentsEnabled,
    };
  }
}
