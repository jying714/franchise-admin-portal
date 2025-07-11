import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;

/// General role access checks
bool isAdminOrHigher(admin_user.User? user) {
  if (user == null) return false;
  return user.roles.contains(admin_user.User.roleOwner) ||
      user.roles.contains(admin_user.User.roleAdmin) ||
      user.roles.contains(admin_user.User.roleManager);
}

bool isDeveloper(admin_user.User? user) {
  return user?.roles.contains(admin_user.User.roleDeveloper) ?? false;
}

bool isAuthorized(admin_user.User? user) {
  return isAdminOrHigher(user) || isDeveloper(user);
}

/// Screen-specific access
bool canAccessDashboard(admin_user.User? user) => isAuthorized(user);

bool canEditMenu(admin_user.User? user) {
  if (user == null) return false;
  return user.roles.contains(admin_user.User.roleOwner) ||
      user.roles.contains(admin_user.User.roleAdmin);
}

bool canManageInventory(admin_user.User? user) {
  if (user == null) return false;
  return user.roles.contains(admin_user.User.roleOwner) ||
      user.roles.contains(admin_user.User.roleAdmin) ||
      user.roles.contains(admin_user.User.roleManager);
}

bool canViewAnalytics(admin_user.User? user) => isAdminOrHigher(user);

bool canManageStaff(admin_user.User? user) {
  if (user == null) return false;
  return user.roles.contains(admin_user.User.roleOwner) ||
      user.roles.contains(admin_user.User.roleAdmin);
}

bool canManageFranchiseSettings(admin_user.User? user) =>
    user?.roles.contains(admin_user.User.roleOwner) ?? false;

bool canViewErrorLogs(admin_user.User? user) =>
    isAdminOrHigher(user) || isDeveloper(user);

bool canAccessDeveloperTools(admin_user.User? user) =>
    isDeveloper(user) ||
    user?.email == 'j.ying714@gmail.com'; // Optional override
