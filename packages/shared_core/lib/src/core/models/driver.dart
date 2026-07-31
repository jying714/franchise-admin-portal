class Driver {
  final String id;
  final String franchiseId;
  final String name;
  final double? payRate;
  final String status; // active, inactive
  final String? phoneNumber;

  Driver({
    required this.id,
    required this.franchiseId,
    required this.name,
    this.payRate,
    this.status = 'active',
    this.phoneNumber,
  });

  factory Driver.fromFirestore(Map<String, dynamic> data, String id) {
    return Driver(
      id: id,
      franchiseId: data['franchiseId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      payRate: (data['payRate'] as num?)?.toDouble(),
      status: data['status'] as String? ?? 'active',
      phoneNumber: data['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'franchiseId': franchiseId,
      'name': name,
      if (payRate != null) 'payRate': payRate,
      'status': status,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }

  Driver copyWith({
    String? id,
    String? franchiseId,
    String? name,
    double? payRate,
    String? status,
    String? phoneNumber,
  }) {
    return Driver(
      id: id ?? this.id,
      franchiseId: franchiseId ?? this.franchiseId,
      name: name ?? this.name,
      payRate: payRate ?? this.payRate,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}