import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/user_permissions.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/core/providers/user_profile_notifier.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_unauthorized_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/role_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription_access_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription/grace_period_banner.dart';
import 'package:franchise_admin_portal/widgets/staff/show_add_staff_dialog.dart';

class StaffAccessScreen extends StatefulWidget {
  const StaffAccessScreen({super.key});

  @override
  State<StaffAccessScreen> createState() => _StaffAccessScreenState();
}

class _StaffAccessScreenState extends State<StaffAccessScreen> {
  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }

    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    final colorScheme = Theme.of(context).colorScheme;

    return RoleGuard(
      allowedRoles: const [
        'platform_owner',
        'hq_owner',
        'manager',
        'developer',
        'admin'
      ],
      featureName: 'staff_access_screen',
      screen: 'StaffAccessScreen',
      child: SubscriptionAccessGuard(
        child: Scaffold(
          backgroundColor: colorScheme.background,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 11,
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GracePeriodBanner(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              loc.staffAccessTitle,
                              style: TextStyle(
                                color: colorScheme.onBackground,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            const Spacer(),
                            FloatingActionButton(
                              heroTag: "addStaffBtn",
                              mini: true,
                              backgroundColor: colorScheme.primary,
                              child: const Icon(Icons.person_add),
                              tooltip: loc.staffAddStaffTooltip,
                              onPressed: () async {
                                final parentLoc = AppLocalizations.of(context);
                                if (parentLoc == null) {
                                  await ErrorLogger.log(
                                    message:
                                        'AppLocalizations.of(context) returned null.',
                                    source: 'staff_access_screen',
                                    screen: 'StaffAccessScreen',
                                    severity: 'error',
                                    contextData: {
                                      'widget': 'FloatingActionButton',
                                      'event': 'open_add_staff_dialog',
                                    },
                                  );
                                  return;
                                }

                                await showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (BuildContext dialogContext) {
                                    return Localizations.override(
                                      context: context,
                                      child: Builder(
                                        builder: (innerContext) {
                                          final loc =
                                              AppLocalizations.of(innerContext);
                                          if (loc == null) {
                                            ErrorLogger.log(
                                              message:
                                                  'Localization still null after Localizations.override.',
                                              source: 'staff_access_screen',
                                              screen: 'StaffAccessScreen',
                                              severity: 'error',
                                              contextData: {
                                                'widget': 'AddStaffDialog',
                                                'issue':
                                                    'AppLocalizations.of(innerContext) returned null',
                                              },
                                            );
                                            return const AlertDialog(
                                              content: Text(
                                                  'Localization failed [AddStaffDialog]'),
                                            );
                                          }
                                          return AddStaffDialog(loc: loc);
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<List<admin_user.User>>(
                          stream: firestoreService.getStaffUsers(franchiseId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LoadingShimmerWidget();
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return EmptyStateWidget(
                                title: loc.staffNoStaffTitle,
                                message: loc.staffNoStaffMessage,
                                imageAsset: BrandingConfig.adminEmptyStateImage,
                                isAdmin: true,
                              );
                            }
                            final staff = snapshot.data!;
                            return ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: staff.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, i) {
                                final user = staff[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: colorScheme.secondary,
                                    child: Text(
                                      user.name.isNotEmpty ? user.name[0] : '?',
                                      style: TextStyle(
                                          color: colorScheme.onSecondary),
                                    ),
                                  ),
                                  title: Text(
                                    user.name,
                                    style: TextStyle(
                                      color: colorScheme.onBackground,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${user.email} • ${user.roles.join(", ")}',
                                    style: TextStyle(
                                        color: colorScheme.onBackground
                                            .withOpacity(0.75)),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete,
                                        color: colorScheme.error),
                                    tooltip: loc.staffRemoveTooltip,
                                    onPressed: () => _confirmRemoveStaff(
                                        context, firestoreService, user, loc),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Expanded(flex: 9, child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRemoveStaff(BuildContext context, FirestoreService service,
      admin_user.User user, AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.staffRemoveDialogTitle),
        content:
            Text('${loc.staffRemoveDialogBody}\n${user.name} (${user.email})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancelButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () async {
              final franchiseId =
                  Provider.of<FranchiseProvider>(context, listen: false)
                      .franchiseId;
              try {
                await service.removeStaffUser(user.id);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              } catch (e, stack) {
                await ErrorLogger.log(
                  message: e.toString(),
                  stack: stack.toString(),
                  source: 'staff_access_screen',
                  screen: 'StaffAccessScreen',
                  severity: 'error',
                  contextData: {
                    'franchiseId': franchiseId,
                    'userId': user.id,
                    'name': user.name,
                    'email': user.email,
                    'operation': 'remove_staff',
                  },
                );
              }
            },
            child: Text(loc.staffRemoveButton),
          ),
        ],
      ),
    );
  }
}
