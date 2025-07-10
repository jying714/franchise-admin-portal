import 'package:cloud_firestore/cloud_firestore.dart';
import 'address.dart';

class User {
  static const String roleOwner = 'owner';
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleStaff = 'staff';
  static const String roleCustomer = 'customer';
  static const String roleDeveloper = 'developer';

  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String role;
  final List<Address> addresses;
  final String language;

  final String status;
  final String defaultFranchise;

  bool get isOwner => role == roleOwner;
  bool get isAdmin => role == roleAdmin;
  bool get isManager => role == roleManager;
  bool get isStaff => role == roleStaff;
  bool get isCustomer =>
      role == roleCustomer || !(isOwner || isAdmin || isManager || isStaff);
  bool get isDeveloper => role == roleDeveloper;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    List<Address>? addresses,
    required this.language,
    required this.status,
    required this.defaultFranchise,
  }) : addresses = addresses ?? [];

  static User fromFirestore(Map<String, dynamic> data, String id) {
    print('User.fromFirestore called for $id with data: $data');
    final rawRole = data['role'];
    final String effectiveRole =
        (rawRole is String && rawRole.isNotEmpty) ? rawRole : roleCustomer;
    print('User.fromFirestore: about to return User(...) for $id');
    return User(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? data['phone'] ?? '',
      role: effectiveRole,
      addresses: (data['addresses'] as List<dynamic>?)
              ?.map((e) => Address.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      language: data['language'] ?? 'en',
      status: data['status'] ?? 'active',
      defaultFranchise: data['defaultFranchise'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber ?? '',
      'role': role.isNotEmpty ? role : roleCustomer,
      'addresses': addresses.map((e) => e.toMap()).toList(),
      'language': language,
      'status': status,
      'defaultFranchise': defaultFranchise,
    };
  }

  User copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    List<Address>? addresses,
    String? language,
    String? status,
    String? defaultFranchise,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      addresses: addresses ?? this.addresses,
      language: language ?? this.language,
      status: status ?? this.status,
      defaultFranchise: defaultFranchise ?? this.defaultFranchise,
    );
  }
}
