// packages/shared_core/lib/src/core/providers/role_guard.dart

import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../utils/error_logger.dart';
import '../config/app_config.dart';

/// Callback for custom role logic
typedef RoleGuardCondition = bool Function(User user);

/// Pure logic role guard — NO Flutter, NO BuildContext, NO AppLocalizations
class RoleGuardLogic {
  final List<String>? allowedRoles;
  final List<String>? requireAnyRole;
  final List<String>? requireAllRoles;
  final RoleGuardCondition? customCondition;
  final bool developerBypass;
  final String? featureName;
  final AppConfig? appConfig;

  const RoleGuardLogic({
    this.allowedRoles,
    this.requireAnyRole,
    this.requireAllRoles,
    this.customCondition,
    this.developerBypass = true,
    this.featureName,
    this.appConfig,
  });

  /// Returns (passes, errorDetail)
  (bool, String?) evaluate(User? user) {
    if (user == null) {
      return (false, "No user available (not authenticated)");
    }

    if (developerBypass && (user.isDeveloper ?? false)) {
      return (true, null);
    }

    if (customCondition != null && customCondition!(user)) {
      return (true, null);
    }

    if (requireAllRoles != null && requireAllRoles!.isNotEmpty) {
      final passes = requireAllRoles!.every((r) => user.roles.contains(r));
      return (
        passes,
        passes ? null : "Missing required roles: $requireAllRoles"
      );
    }

    if (requireAnyRole != null && requireAnyRole!.isNotEmpty) {
      final passes = requireAnyRole!.any((r) => user.roles.contains(r));
      return (passes, passes ? null : "Missing any of roles: $requireAnyRole");
    }

    if (allowedRoles != null && allowedRoles!.isNotEmpty) {
      final passes = user.roles.any((r) => allowedRoles!.contains(r));
      return (
        passes,
        passes ? null : "Role not in allowed list: $allowedRoles"
      );
    }

    return (true, null); // Default: allow
  }

  void logUnauthorized(User? user, String? errorDetail) {
    ErrorLogger.log(
      message: "Unauthorized access attempt to $featureName: $errorDetail",
      source: 'RoleGuardLogic',
      contextData: {
        'roles': user?.roles,
        'feature': featureName,
        'errorType': 'Unauthorized',
      },
    );
  }
}
