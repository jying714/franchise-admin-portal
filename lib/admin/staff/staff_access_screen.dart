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
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_unauthorized_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/utils/role_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription_access_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription/grace_period_banner.dart';

class StaffAccessScreen extends StatefulWidget {
  const StaffAccessScreen({super.key});

  @override
  State<StaffAccessScreen> createState() => _StaffAccessScreenState();
}

class _StaffAccessScreenState extends State<StaffAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _role = 'staff';

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return const Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }

    final franchiseId = context.watch<FranchiseProvider>().franchiseId;

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
          backgroundColor: DesignTokens.backgroundColor,
          floatingActionButton: FloatingActionButton(
            backgroundColor: DesignTokens.primaryColor,
            tooltip: loc.staffAddStaffTooltip,
            child: const Icon(Icons.person_add),
            onPressed: () =>
                _showAddStaffDialog(context, firestoreService, loc),
          ),
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
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            const Spacer(),
                            FloatingActionButton(
                              heroTag: "addStaffBtn",
                              mini: true,
                              backgroundColor: DesignTokens.primaryColor,
                              child: const Icon(Icons.person_add),
                              tooltip: loc.staffAddStaffTooltip,
                              onPressed: () => _showAddStaffDialog(
                                  context, firestoreService, loc),
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
                                    backgroundColor:
                                        DesignTokens.secondaryColor,
                                    child: Text(
                                      user.name.isNotEmpty ? user.name[0] : '?',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(user.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                      '${user.email} • ${user.roles.join(", ")}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
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
              Expanded(
                flex: 9,
                child: Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddStaffDialog(
      BuildContext context, FirestoreService service, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(loc.staffAddStaffDialogTitle),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: loc.staffNameLabel),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? loc.staffNameRequired
                      : null,
                  onSaved: (v) => _name = v!.trim(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(labelText: loc.staffEmailLabel),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? loc.staffEmailRequired
                      : null,
                  onSaved: (v) => _email = v!.trim(),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: InputDecoration(labelText: loc.staffRoleLabel),
                  items: [
                    DropdownMenuItem(
                        value: 'owner', child: Text(loc.staffRoleOwner)),
                    DropdownMenuItem(
                        value: 'manager', child: Text(loc.staffRoleManager)),
                    DropdownMenuItem(
                        value: 'staff', child: Text(loc.staffRoleStaff)),
                  ],
                  onChanged: (v) => setState(() => _role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.cancelButton)),
            ElevatedButton(
              onPressed: () async {
                final franchiseId =
                    Provider.of<FranchiseProvider>(context, listen: false)
                        .franchiseId;
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  try {
                    await service.addStaffUser(
                      name: _name,
                      email: _email,
                      roles: [_role],
                      franchiseIds: [franchiseId],
                    );
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
                        'name': _name,
                        'email': _email,
                        'role': _role,
                        'operation': 'add_staff'
                      },
                    );
                  }
                }
              },
              child: Text(loc.staffAddButton),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemoveStaff(BuildContext context, FirestoreService service,
      admin_user.User user, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.staffRemoveDialogTitle),
        content:
            Text('${loc.staffRemoveDialogBody}\n${user.name} (${user.email})'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.cancelButton)),
          ElevatedButton(
            onPressed: () async {
              final franchiseId =
                  Provider.of<FranchiseProvider>(context, listen: false)
                      .franchiseId;
              try {
                await service.removeStaffUser(user.id);
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
                    'operation': 'remove_staff'
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
