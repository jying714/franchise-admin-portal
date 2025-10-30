import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_portal/core/providers/franchise_subscription_provider.dart';
import 'package:admin_portal/core/providers/user_profile_notifier.dart';
import 'package:admin_portal/core/providers/admin_user_provider.dart';

class SubscriptionAccessGuard extends StatelessWidget {
  final Widget child;

  const SubscriptionAccessGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AdminUserProvider>().user;

    // Bypass check for privileged roles
    final roles = user?.roles ?? [];
    final isBypass =
        roles.contains('platform_owner') || roles.contains('developer');
    debugPrint('[SubscriptionAccessGuard] User roles: ${user?.roles}');
    debugPrint('[SubscriptionAccessGuard] isBypass: $isBypass');
    if (isBypass) return child;

    final sub =
        context.watch<FranchiseSubscriptionNotifier>().currentSubscription;

    if (sub == null || sub.status != 'active') {
      return const Center(child: Text('No active subscription.'));
    }

    final now = DateTime.now();
    final isBlocked = sub.hasOverdueInvoice &&
        (sub.gracePeriodEndsAt != null && now.isAfter(sub.gracePeriodEndsAt!));

    if (isBlocked) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_rounded, color: Colors.red, size: 64),
              SizedBox(height: 16),
              Text(
                'Your subscription is overdue and past the grace period.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Please update your billing info or contact support to regain access.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return child;
  }
}
