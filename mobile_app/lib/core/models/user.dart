import 'package:shared_core/shared_core.dart' as shared;

class User extends shared.User {
  final List<dynamic> orders;
  final List<dynamic> favorites;
  final List<dynamic> scheduledOrders;
  final dynamic loyalty; // Loyalty object or map
  final String role;

  User({
    required super.id,
    required super.name,
    required super.email,
    super.phoneNumber,
    required super.roles,
    super.addresses,
    required super.language,
    required super.status,
    super.defaultFranchise,
    super.avatarUrl,
    super.isActive,
    super.franchiseIds,
    super.completeProfile,
    super.onboardingComplete,
    super.updatedAt,
    this.orders = const [],
    this.favorites = const [],
    this.scheduledOrders = const [],
    this.loyalty,
    this.role = 'customer',
  });
  static const String roleCustomer = 'customer';
  static const String roleAdmin = 'admin';
  static const String roleOwner = 'owner';
  // Add factory if needed, but for compile, this may help some casts
}
