import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:franchise_admin_portal/core/models/dashboard_section.dart';
import 'package:franchise_admin_portal/core/models/user.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';

// Update import to your actual user model/provider location

/// Callback for custom logic
typedef RoleGuardCondition = bool Function(User user);

/// Flexible role-based access widget.
/// Use anywhere you want to show/hide/protect features or screens by role.
class RoleGuard extends StatelessWidget {
  /// Allowed user roles, e.g. ['owner', 'admin', 'manager', 'developer']
  final List<String>? allowedRoles;

  /// Require at least one of these exact roles
  final List<String>? requireAnyRole;

  /// If set, require user to have *all* these roles
  final List<String>? requireAllRoles;

  /// A custom role-check function, e.g. (user) => user.isOwner && user.isDeveloper
  final RoleGuardCondition? customCondition;

  /// Widget shown if the user passes the guard.
  final Widget child;

  /// Widget shown if the user is unauthorized (default: nice error card)
  final Widget? unauthorized;

  /// If true, allows developer users to always pass the guard.
  final bool developerBypass;

  /// For audit/error reporting
  final String? screen;
  final String? featureName;

  /// For future features/config integration
  final AppConfig? appConfig;

  const RoleGuard({
    Key? key,
    required this.child,
    this.allowedRoles,
    this.requireAnyRole,
    this.requireAllRoles,
    this.customCondition,
    this.unauthorized,
    this.developerBypass = true,
    this.screen,
    this.featureName,
    this.appConfig,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ----
    // Replace below with your actual User/profile/provider solution.
    // This example assumes a top-level InheritedWidget/provider for user.
    final user = context.watch<AdminUserProvider>().user;

    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final _appConfig = appConfig ?? AppConfig.instance;
    final _firestoreService = FirestoreService();

    // ----
    // Robust Role Logic:
    bool passes = false;
    String? errorDetail;

    if (user == null) {
      errorDetail = "No user available (not authenticated)";
    } else if (developerBypass && (user.isDeveloper ?? false)) {
      passes = true;
    } else if (customCondition != null && customCondition!(user)) {
      passes = true;
    } else if (requireAllRoles != null && requireAllRoles!.isNotEmpty) {
      passes = requireAllRoles!.every((r) => user.roles.contains(r));
      if (!passes)
        errorDetail = "Missing one or more required roles: $requireAllRoles";
    } else if (requireAnyRole != null && requireAnyRole!.isNotEmpty) {
      passes = requireAnyRole!.any((r) => user.roles.contains(r));
      if (!passes)
        errorDetail = "Missing all of any allowed roles: $requireAnyRole";
    } else if (allowedRoles != null && allowedRoles!.isNotEmpty) {
      passes = user.roles.any((r) => allowedRoles!.contains(r));
      if (!passes)
        errorDetail = "User role(s) not in allowedRoles: $allowedRoles";
    } else {
      // If no rule, allow everyone by default
      passes = true;
    }

    if (passes) {
      return child;
    }

    // 🔜 Future: More granular audit, config, feature toggles, etc.
    _firestoreService.logError(
      user?.defaultFranchise ??
          (user?.franchiseIds.isNotEmpty == true
              ? user!.franchiseIds.first
              : null),
      message:
          "Unauthorized access attempt${featureName != null ? ' to $featureName' : ''}: ${errorDetail ?? 'unknown reason'}",
      source: screen ?? 'RoleGuard',
      userId: user?.id,
      screen: screen ?? 'RoleGuard',
      stackTrace: null,
      errorType: 'Unauthorized',
      severity: 'warning',
      contextData: {
        'roles': user?.roles,
        'userId': user?.id,
        'feature': featureName,
      },
    );

    return unauthorized ??
        _DefaultUnauthorizedWidget(
          reason: errorDetail ?? loc.unauthorized_default_reason,
          loc: loc,
          colorScheme: colorScheme,
        );
  }
}

/// Default unauthorized widget shown by RoleGuard.
class _DefaultUnauthorizedWidget extends StatelessWidget {
  final String reason;
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  const _DefaultUnauthorizedWidget({
    Key? key,
    required this.reason,
    required this.loc,
    required this.colorScheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Card(
        color: colorScheme.error.withOpacity(0.13),
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: colorScheme.error, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.unauthorized_title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reason,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// Example user provider (replace with your own solution)
class UserProvider extends InheritedWidget {
  final User? user;

  const UserProvider({
    Key? key,
    required Widget child,
    this.user,
  }) : super(key: key, child: child);

  static UserProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UserProvider>();

  @override
  bool updateShouldNotify(covariant UserProvider oldWidget) =>
      user != oldWidget.user;
}
