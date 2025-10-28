// File: lib/admin/developer/subscriptions/subscription_dev_tools_screen.dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/admin/devtools/subscriptions/manual_subscription_injector.dart';
import 'package:franchise_admin_portal/admin/devtools/subscriptions/subscription_state_toggler.dart';
import 'package:franchise_admin_portal/admin/devtools/subscriptions/plan_swapper_tool.dart';

class SubscriptionDevToolsScreen extends StatelessWidget {
  const SubscriptionDevToolsScreen({super.key});

  void _showDevGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧾 Subscription Dev Tools Guide'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('🔹 Manual Subscription Injector',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Create a new subscription manually for a selected franchise. '
                  'Used for testing plans, onboarding flows, or plan migrations.',
                ),
                SizedBox(height: 12),
                Text('🔹 Plan Swapper',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Replaces a franchise’s active subscription with a different plan. '
                  'Keeps an audit trail of the change.',
                ),
                SizedBox(height: 12),
                Text('🔹 State Toggler',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Quickly toggle the subscription between `active`, `paused`, and `canceled` states.',
                ),
                SizedBox(height: 12),
                Text('🔹 Trial Expiry Simulator',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Forcefully end or extend a trial period to test onboarding or expiration logic.',
                ),
                SizedBox(height: 12),
                Text('🔹 Raw Snapshot Viewer',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'View the raw Firestore data for a franchise’s subscription. Useful for debugging.',
                ),
                SizedBox(height: 12),
                Text('🔹 Billing Schedule Debugger',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Visualize and verify upcoming billing anchors, renewal dates, and status transitions.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.subscriptionTools,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Tool Guide',
            onPressed: () => _showDevGuide(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '🧩 Manual Controls',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ManualSubscriptionInjector(),

              SizedBox(height: 24),
              const PlanSwapperTool(),

              SizedBox(height: 24),
              const SubscriptionStateToggler(),

              SizedBox(height: 32),
              Text(
                '⏳ Trial Tools',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Placeholder(
                fallbackHeight: 50,
                color: Colors.redAccent,
              ), // TODO: TrialExpirySimulator()

              SizedBox(height: 32),
              Text(
                '🛠 Debugging & Snapshots',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Placeholder(
                fallbackHeight: 60,
                color: Colors.grey,
              ), // TODO: RawSubscriptionSnapshotViewer()

              SizedBox(height: 24),
              Placeholder(
                fallbackHeight: 50,
                color: Colors.indigo,
              ), // TODO: BillingScheduleDebugger()
            ],
          ),
        ),
      ),
    );
  }
}
