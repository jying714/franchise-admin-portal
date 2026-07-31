class Staff {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String role; // owner, manager, cashier
  final String status; // active, inactive
  final List<String> permissions;

  /// Franchise this staff record belongs to (station scope).
  final String? franchiseId;

  /// Hourly pay rate for thin financial tracking (Decision 14).
  final double? hourlyPay;

  /// Stored PIN verifier only — never plaintext PIN.
  /// Format up to implementer (e.g. salt$hash); null = PIN not set.
  final String? pinHash;

  /// When true, staff may unlock the POS station with PIN.
  final bool posEnabled;

  Staff({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    required this.status,
    required this.permissions,
    this.franchiseId,
    this.hourlyPay,
    this.pinHash,
    this.posEnabled = false,
  });

  factory Staff.fromFirestore(Map<String, dynamic> data, String id) {
    return Staff(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      role: data['role'] ?? 'cashier',
      status: data['status'] ?? 'active',
      permissions:
          (data['permissions'] as List<dynamic>?)?.cast<String>() ?? [],
      franchiseId: data['franchiseId'] as String?,
      hourlyPay: (data['hourlyPay'] as num?)?.toDouble(),
      pinHash: data['pinHash'] as String?,
      posEnabled: data['posEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'status': status,
      'permissions': permissions,
      if (franchiseId != null) 'franchiseId': franchiseId,
      if (hourlyPay != null) 'hourlyPay': hourlyPay,
      if (pinHash != null) 'pinHash': pinHash,
      'posEnabled': posEnabled,
    };
  }

  Staff copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    String? status,
    List<String>? permissions,
    String? franchiseId,
    double? hourlyPay,
    String? pinHash,
    bool? posEnabled,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      franchiseId: franchiseId ?? this.franchiseId,
      hourlyPay: hourlyPay ?? this.hourlyPay,
      pinHash: pinHash ?? this.pinHash,
      posEnabled: posEnabled ?? this.posEnabled,
    );
  }
}
