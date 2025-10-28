import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/admin/devtools/platform/seed_platform_features_form.dart';
import 'package:franchise_admin_portal/admin/devtools/platform/seed_platform_plans_form.dart';
import 'package:franchise_admin_portal/admin/devtools/platform/remove_platform_plans_form.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/admin/devtools/platform/remove_platform_features_form.dart';

class PlatformFeaturePlanToolsScreen extends StatelessWidget {
  const PlatformFeaturePlanToolsScreen({super.key});

  void _showDevGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🛠️ Platform Feature + Plan Dev Guide'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Platform Feature Seeder',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Create or replace individual feature documents in `/platform_features`. '
                  'These documents define which modules are available to include in plan configurations.',
                ),
                SizedBox(height: 12),
                Text('Platform Plan Creator',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Create subscription plans in `/platform_plans`. '
                  'Each plan includes price, billing interval, and a list of feature keys from `/platform_features`.',
                ),
                SizedBox(height: 12),
                Text('Plan Snapshot Behavior',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Upon subscription, the selected plan’s features are snapshotted into the franchise\'s `franchise_subscriptions` '
                  'and seeded into `feature_metadata` under that franchise. Changes to `/platform_plans` do not retroactively affect existing subscriptions.',
                ),
                SizedBox(height: 12),
                Text('Delete Plan Behavior',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                    'A simple widget to delete a selected plan completely from the database.'),
                SizedBox(height: 12),
                Text('Delete Feature Behavior',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                    'A simple widget to delete a selected feature completely from the database.'),
                SizedBox(height: 12),
                Text('🔒 Locked Features',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Features not included in a plan will appear locked and uneditable in onboarding or admin screens.',
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
          loc.platformFeaturePlanTools,
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
            tooltip: 'Dev Guide',
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
              SeedPlatformFeaturesForm(),
              SizedBox(height: 64),

              const RemovePlatformFeaturesForm(),
              SizedBox(height: 64),

              SeedPlatformPlansForm(),
              SizedBox(height: 64),

              const RemovePlatformPlansForm(),
              SizedBox(height: 64),
              // Future expansion...
            ],
          ),
        ),
      ),
    );
  }
}
