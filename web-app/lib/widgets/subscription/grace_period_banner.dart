import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:franchise_admin_portal/core/providers/franchise_subscription_provider.dart';
import 'package:franchise_admin_portal/core/providers/role_guard.dart';

/// A banner widget that alerts HQ owners or developers if their subscription is overdue or in grace period.
class GracePeriodBanner extends StatelessWidget {
  final bool forceElevated;

  const GracePeriodBanner({Key? key, this.forceElevated = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final subscription =
        context.watch<FranchiseSubscriptionNotifier>().currentSubscription;

    // Don't show anything if subscription is missing or valid
    if (subscription == null || !subscription.hasOverdueInvoice) {
      return const SizedBox.shrink();
    }

    final graceEndsAt = subscription.gracePeriodEndsAt;
    final isInGracePeriod =
        graceEndsAt != null && DateTime.now().isBefore(graceEndsAt);
    final hasExpired =
        graceEndsAt != null && DateTime.now().isAfter(graceEndsAt);

    // Customize banner content
    final bannerMessage = isInGracePeriod
        ? loc.gracePeriodWarning(DateFormat.yMMMMd().format(graceEndsAt))
        : loc.gracePeriodExpired;

    final actionLabel = loc.manageSubscription;

    return RoleGuard(
      allowedRoles: const ['hq_owner', 'developer', 'platform_owner'],
      child: MaterialBanner(
        backgroundColor: theme.colorScheme.error.withOpacity(0.1),
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
