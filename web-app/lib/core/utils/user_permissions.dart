import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;

/// Centralized permission checks for roles across the app.
/// This avoids repeating `user?.isOwner || user?.isManager || ...` everywhere.
class UserPermissions {
  /// True if the user is a platform owner
  static bool isPlatformOwner(admin_user.User? user) {
    return user?.hasAnyRole(['platform_owner']) ?? false;
  }

  /// True if the user is an HQ owner (franchisee primary account holder)
  static bool isHqOwner(admin_user.User? user) {
    return user?.hasAnyRole(['hq_owner']) ?? false;
  }

  /// Can edit menu items (add/edit/customize)
  static bool canEditMenu(admin_user.User? user) {
    return user?.hasAnyRole([
          'platform_owner',
          'hq_owner',
          'manager',
          'developer',
          'admin',
        ]) ??
        false;
  }

  /// Can delete or export menu items
  static bool canDeleteMenu(admin_user.User? user) {
    return user?.hasAnyRole([
          'platform_owner',
          'hq_owner',
          'developer',
          'admin',
        ]) ??
        false;
  }

  /// Can view or manage orders
  static bool canAccessOrders(admin_user.User? user) {
    return user?.hasAnyRole([
          'platform_owner',
          'hq_owner',
          'manager',
          'developer',
          'admin',
        ]) ??
        false;
  }

  /// Can process refunds
  static bool canRefundOrders(admin_user.User? user) {
    return user?.hasAnyRole([
          'platform_owner',
          'hq_owner',
          'manager',
        ]) ??
        false;
  }

  /// Can access subscription management
  static bool canManageSubscriptions(admin_user.User? user) {
    return user?.hasAnyRole([
          'platform_owner',
          'hq_owner',
          'developer',
        ]) ??
        false;
  }

  /// Can access sensitive platform configuration
  static bool isPlatformPrivileged(admin_user.User? user) {
    return user?.hasAnyRole([
          'platform_owner',
          'developer',
        ]) ??
        false;
  }

  static bool canAccessMenuEditor(admin_user.User user) => user.hasAnyRole(
      ['platform_owner', 'hq_owner', 'manager', 'developer', 'admin']);

  static bool canManageCategories(admin_user.User? user) {
    return user?.hasAnyRole([
          'platform_owner',
          'hq_owner',
          'manager',
          'developer',
          'admin',
        ]) ??
        false;
  }

  static bool canAccessPromos(admin_user.User? user) {
    return user?.hasAnyRole([
          'platform_owner',
          'hq_owner',
          'manager',
          'developer',
          'admin',
          'staff',
        ]) ??
        false;
  }

  static bool canEditPromos(admin_user.User? user) {
    return user?.hasAnyRole([
          'platform_owner',
          'hq_owner',
          'manager',
          'developer',
          'admin',
        ]) ??
        false;
  }

  static bool canAccessPromoManagement(admin_user.User? user) {
    return user?.hasAnyRole([
          'platform_owner',
          'hq_owner',
          'manager',
          'developer',
          'admin',
          'staff',
        ]) ??
        false;
  }

  static bool canManageStaff(admin_user.User? user) {
    return user?.hasAnyRole([
          'platform_owner',
          'hq_owner',
          'manager',
          'admin',
          'developer',
        ]) ??
        false;
  }

  static bool canAccessChatManagement(admin_user.User? user) {
    return user?.hasAnyRole([
          'platform_owner',
          'hq_owner',
          'manager',
          'developer',
          'admin',
        ]) ??
        false;
  }
}

/// Optional: role-checking extension on the user model
extension UserRoleHelpers on admin_user.User {
  /// Returns true if user has any of the roles in [roles]
  bool hasAnyRole(List<String> roles) {
    return roles.any((role) => this.roles.contains(role));
  }
}
