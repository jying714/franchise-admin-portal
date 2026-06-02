import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:franchise_admin_portal/widgets/admin/role_guard_widget.dart';

class GracePeriodBanner extends StatelessWidget {
  final bool forceElevated;

  const GracePeriodBanner({
    super.key,
    this.forceElevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final subscription = context
        .watch<shared.FranchiseSubscriptionProvider>()
        .currentSubscription;

    if (subscription == null || !subscription.hasOverdueInvoice) {
      return const SizedBox.shrink();
    }

    final graceEndsAt = subscription.gracePeriodEndsAt;
    final isInGracePeriod =
        graceEndsAt != null && DateTime.now().isBefore(graceEndsAt);

    final bannerMessage = isInGracePeriod
        ? loc.gracePeriodWarning(DateFormat.yMMMMd().format(graceEndsAt))
        : loc.gracePeriodExpired;

    final actionLabel = loc.manageSubscription;

    return RoleGuard(
      allowedRoles: const ['hq_owner', 'developer', 'platform_owner'],
      child: MaterialBanner(
        backgroundColor: theme.colorScheme.error
            .withValues(alpha: 0.1), // Fixed deprecated withOpacity
        contentTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
        leading: Icon(Icons.warning_rounded, color: theme.colorScheme.error),
        content: Text(bannerMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/platform/plans');
            },
            child: Text(
              actionLabel,
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
        elevation: forceElevated ? 1 : 0,
      ),
    );
  }
}
