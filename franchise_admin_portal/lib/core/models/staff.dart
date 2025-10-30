class Staff {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String role; // owner, manager, cashier
  final String status; // active, inactive
  final List<String> permissions;

  Staff({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    required this.status,
    required this.permissions,
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
    };
  }
}
