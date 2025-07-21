import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_subscription_provider.dart';

class SubscriptionAccessGuard extends StatelessWidget {
  final Widget child;

  const SubscriptionAccessGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
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
