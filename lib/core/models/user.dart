import 'package:cloud_firestore/cloud_firestore.dart';
import 'address.dart';

class User {
  static const String roleHqOwner = 'hq_owner';
  static const String roleHqManager = 'hq_manager';
  static const String roleOwner = 'owner';
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleStaff = 'staff';
  static const String roleCustomer = 'customer';
  static const String roleDeveloper = 'developer';
  static const String rolePlatformOwner = 'platform_owner';
  static const String roleFranchisee = 'franchisee';
  static const String roleStoreOwner = 'store_owner';

  final bool isActive;
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final List<String> roles;
  final List<Address> addresses;
  final String language;
  final String status;
  final String? defaultFranchise;
  final String? avatarUrl;
  final List<String> franchiseIds;

  bool get isHqOwner => roles.contains(roleHqOwner);
  bool get isHqManager => roles.contains(roleHqManager);
  bool get isOwner => roles.contains(roleOwner);
  bool get isAdmin => roles.contains(roleAdmin);
  bool get isManager => roles.contains(roleManager);
  bool get isStaff => roles.contains(roleStaff);
  bool get isPlatformOwner => roles.contains(rolePlatformOwner);
  bool get isFranchisee => roles.contains(roleFranchisee);
  bool get isStoreOwner => roles.contains(roleStoreOwner);
  bool get isCustomer =>
      roles.contains(roleCustomer) ||
      !(isHqOwner || isHqManager || isOwner || isAdmin || isManager || isStaff);
  bool get isDeveloper => roles.contains(roleDeveloper);

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.roles,
    List<Address>? addresses,
    required this.language,
    required this.status,
    this.defaultFranchise,
    this.avatarUrl,
    this.isActive = true,
    List<String>? franchiseIds,
  })  : addresses = addresses ?? [],
        franchiseIds = franchiseIds ?? <String>[];

  static User fromFirestore(Map<String, dynamic> data, String id) {
    final rolesFromDb =
        (data['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            <String>[];
    final franchiseIdsFromDb = (data['franchiseIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    return User(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? data['phone'] ?? '',
      roles: rolesFromDb,
      addresses: (data['addresses'] as List<dynamic>?)
              ?.map((e) => Address.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      language: data['language'] ?? 'en',
      status: data['status'] ?? 'active',
      defaultFranchise: data['defaultFranchise'],
      avatarUrl: data['avatarUrl'],
      isActive: data['isActive'] ?? true,
      franchiseIds: franchiseIdsFromDb,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber ?? '',
      'roles': roles,
      'addresses': addresses.map((e) => e.toMap()).toList(),
      'language': language,
      'status': status,
      'defaultFranchise': defaultFranchise,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'franchiseIds': franchiseIds,
    };
  }

  User copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    List<String>? roles,
    List<Address>? addresses,
    String? language,
    String? status,
    String? defaultFranchise,
    String? avatarUrl,
    bool? isActive,
    List<String>? franchiseIds,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roles: roles ?? this.roles,
      addresses: addresses ?? this.addresses,
      language: language ?? this.language,
      status: status ?? this.status,
      defaultFranchise: defaultFranchise ?? this.defaultFranchise,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      franchiseIds: franchiseIds ?? this.franchiseIds,
    );
  }
}
