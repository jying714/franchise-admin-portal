// web-app/lib/widgets/admin/role_guard_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/src/core/providers/role_guard.dart';
import 'package:shared_core/src/core/models/user.dart';
import 'package:shared_core/src/core/providers/admin_user_provider.dart';

/// Flutter wrapper — UI only
class RoleGuard extends StatelessWidget {
  final List<String>? allowedRoles;
  final List<String>? requireAnyRole;
  final List<String>? requireAllRoles;
  final RoleGuardCondition? customCondition;
  final Widget child;
  final Widget? unauthorized;
  final bool developerBypass;
  final String? screen;
  final String? featureName;

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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AdminUserProvider>().user;
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // Block incomplete onboarding
    if ((user?.isFranchisee ?? false) && !(user?.onboardingComplete ?? false)) {
      return _buildUnauthorized(
        context,
        loc.onboardingRequiredBody,
        loc,
        colorScheme,
      );
    }

    final logic = RoleGuardLogic(
      allowedRoles: allowedRoles,
      requireAnyRole: requireAnyRole,
      requireAllRoles: requireAllRoles,
      customCondition: customCondition,
      developerBypass: developerBypass,
      featureName: featureName,
    );

    final (passes, errorDetail) = logic.evaluate(user);

    if (passes) {
      return child;
    }

    logic.logUnauthorized(user, errorDetail);

    return unauthorized ??
        _buildUnauthorized(
          context,
          errorDetail ?? loc.unauthorized_default_reason,
          loc,
          colorScheme,
        );
  }

  Widget _buildUnauthorized(
    BuildContext context,
    String reason,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    return Scaffold(
      body: Center(
        child: Card(
          color: colorScheme.error.withOpacity(0.13),
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: colorScheme.error, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.unauthorized_title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 3),
                      Text(reason,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
