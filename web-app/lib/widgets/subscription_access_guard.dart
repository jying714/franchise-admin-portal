import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

class SubscriptionAccessGuard extends StatelessWidget {
  final Widget child;

  const SubscriptionAccessGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<shared.AdminUserProvider>(
      context,
      listen: false,
    ).user;

    // Bypass for privileged roles
    final roles = user?.roles ?? [];
    final isBypass = roles.contains('platform_owner') ||
        roles.contains('developer') ||
        roles.contains('hq_owner');

    if (isBypass) return child;

    final subscription = Provider.of<shared.FranchiseSubscriptionProvider>(
      context,
      listen: true,
    ).currentSubscription;

    // Improved active subscription check
    if (subscription == null || subscription.status != 'active') {
      return const Center(child: Text('No active subscription.'));
    }

    // Only block on overdue + past grace period
    final now = DateTime.now();
    final isBlocked = subscription.hasOverdueInvoice &&
        (subscription.gracePeriodEndsAt != null &&
            now.isAfter(subscription.gracePeriodEndsAt!));

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
                'Please update your billing info or contact support.',
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
