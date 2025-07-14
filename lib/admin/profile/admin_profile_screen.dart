import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final userProvider = Provider.of<AdminUserProvider>(context);
    final user = userProvider.user;
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.profile)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    const allowedRoles = [
      'developer',
      'admin',
      'manager',
      'hq_owner',
      'hq_manager'
    ];
    if (!user.roles.any((r) => allowedRoles.contains(r))) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.profile)),
        body: Center(
          child: Text(
            loc.unauthorizedAccess,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: loc.refresh,
            onPressed: () async {
              try {
                userProvider.listenToAdminUser(firestoreService, user.id);
              } catch (e, stack) {
                ErrorLogger.log(
                  message: 'Failed to refresh admin profile',
                  source: 'AdminProfileScreen',
                  screen: 'Profile',
                  stack: stack.toString(),
                  contextData: {
                    'franchiseId': franchiseId,
                    'errorType': e.runtimeType.toString(),
                    'userId': user.id,
                  },
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: Text(
                  user.name.isNotEmpty ? user.name[0] : '?',
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user.name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  user.email,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),

              _sectionHeader(context, loc.accountDetails),
              _infoRow(context, loc.role, user.roles.join(', ')),
              _infoRow(context, loc.status, user.status),
              _infoRow(context, loc.language, user.language),
              _infoRow(
                  context, loc.defaultFranchise, user.defaultFranchise ?? ''),

              const Divider(height: 32),
              _sectionHeader(context, loc.settings),
              _infoRow(
                  context, loc.themeMode, loc.systemDefault), // placeholder
              _infoRow(context, loc.notifications, loc.enabled), // placeholder

              const Divider(height: 32),
              _sectionHeader(context, loc.futureFeatures),
              _infoRow(context, 'Permissions', '🔒 Placeholder'),
              _infoRow(context, 'Impersonation', '🔧 Placeholder'),
              _infoRow(context, 'Plugin Access', '🧩 Placeholder'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
