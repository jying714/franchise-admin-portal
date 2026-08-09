import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/widgets/subscription_access_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription/grace_period_banner.dart';
import 'package:franchise_admin_portal/widgets/staff/show_add_staff_dialog.dart';
import 'package:franchise_admin_portal/widgets/admin/role_guard_widget.dart';

/// HQ Portal users — who can sign into the web portal for this franchise.
/// Not station PIN staff (those live under Admin → Staff Management).
class StaffAccessScreen extends StatefulWidget {
  const StaffAccessScreen({super.key});

  @override
  State<StaffAccessScreen> createState() => _StaffAccessScreenState();
}

class _StaffAccessScreenState extends State<StaffAccessScreen> {
  Future<void> _openAddDialog(BuildContext context) async {
    final parentLoc = AppLocalizations.of(context);
    if (parentLoc == null) {
      shared.ErrorLogger.log(
        message: 'AppLocalizations.of(context) returned null.',
        source: 'staff_access_screen',
        severity: 'error',
        contextData: {
          'widget': 'Invite button',
          'event': 'open_add_staff_dialog',
        },
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Localizations.override(
          context: context,
          child: Builder(
            builder: (innerContext) {
              return AddStaffDialog(loc: parentLoc);
            },
          ),
        );
      },
    );
  }

  void _confirmRemoveStaff(
    BuildContext context,
    shared.FirestoreService service,
    shared.User user,
    AppLocalizations loc,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.staffRemoveDialogTitle),
        content: Text(
          '${loc.staffRemoveDialogBody}\n${user.name} (${user.email})',
        ),
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
                  Provider.of<shared.FranchiseProvider>(context, listen: false)
                      .franchiseId;
              try {
                await service.removeStaffUser(
                  user.id,
                  franchiseId: franchiseId,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Portal access removed')),
                );
              } catch (e, stack) {
                shared.ErrorLogger.log(
                  message: e.toString(),
                  stack: stack.toString(),
                  source: 'staff_access_screen',
                  severity: 'error',
                  contextData: {
                    'franchiseId': franchiseId,
                    'userId': user.id,
                    'name': user.name,
                    'email': user.email,
                    'operation': 'remove_staff',
                  },
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Remove failed: $e')),
                );
              }
            },
            child: Text(loc.staffRemoveButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }

    final franchiseId = context.watch<shared.FranchiseProvider>().franchiseId;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canPop = Navigator.of(context).canPop();

    return RoleGuard(
      // HQ-owned surface: portal login roster, not day-2 store ops.
      allowedRoles: const [
        'platform_owner',
        'hq_owner',
        'developer',
      ],
      featureName: 'staff_access_screen',
      screen: 'StaffAccessScreen',
      child: SubscriptionAccessGuard(
        child: Scaffold(
          backgroundColor: DesignTokens.backgroundColor,
          appBar: AppBar(
            elevation: DesignTokens.appBarElevation,
            backgroundColor: DesignTokens.appBarBackgroundColor,
            foregroundColor: DesignTokens.appBarForegroundColor,
            automaticallyImplyLeading: canPop,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portal users',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: DesignTokens.appBarForegroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Who can sign in to the web portal for this franchise',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: DesignTokens.appBarForegroundColor.withOpacity(0.85),
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  onPressed: () => _openAddDialog(context),
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: Text(loc.staffAddStaffTooltip),
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignTokens.secondaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GracePeriodBanner(),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      children: [
                        // ---- Pending invites ----
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('franchisee_invitations')
                              .where('status', isEqualTo: 'pending')
                              .snapshots(),
                          builder: (context, invSnap) {
                            if (!invSnap.hasData) {
                              return const SizedBox.shrink();
                            }
                            final fid = (franchiseId ?? '').trim();
                            final pending = invSnap.data!.docs.where((d) {
                              final data = d.data();
                              final type =
                                  (data['inviteType'] as String?)?.trim() ?? '';
                              final invFid =
                                  (data['franchiseId'] as String?)?.trim() ??
                                      '';
                              return type == 'portal_staff' &&
                                  fid.isNotEmpty &&
                                  invFid == fid;
                            }).toList();

                            if (pending.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Card(
                                elevation: DesignTokens.adminCardElevation,
                                color: DesignTokens.surfaceColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    DesignTokens.adminCardRadius,
                                  ),
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.mark_email_unread_outlined,
                                            color: DesignTokens.primaryColor,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Pending invites (${pending.length})',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: DesignTokens.textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Share the accept link until the invitee finishes signup.',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: DesignTokens.textColor
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...pending.map((d) {
                                        final data = d.data();
                                        final email =
                                            (data['email'] as String?) ?? '';
                                        final name =
                                            (data['name'] as String?) ?? '';
                                        final role =
                                            (data['role'] as String?) ??
                                                'manager';
                                        final token = d.id;
                                        final acceptUrl =
                                            '${Uri.base.origin}/#/invite-accept?token=$token';
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: CircleAvatar(
                                            backgroundColor: DesignTokens
                                                .primaryColor
                                                .withOpacity(0.12),
                                            child: Icon(
                                              Icons.person_outline,
                                              color: DesignTokens.primaryColor,
                                            ),
                                          ),
                                          title: Text(
                                            name.isNotEmpty ? name : email,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: DesignTokens.textColor,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '$email · $role · pending',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: DesignTokens.textColor
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'Copy accept link',
                                                icon: Icon(
                                                  Icons.link,
                                                  color:
                                                      DesignTokens.primaryColor,
                                                ),
                                                onPressed: () async {
                                                  await Clipboard.setData(
                                                    ClipboardData(
                                                        text: acceptUrl),
                                                  );
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Accept link copied'),
                                                    ),
                                                  );
                                                },
                                              ),
                                              IconButton(
                                                tooltip: 'Revoke invite',
                                                icon: Icon(
                                                  Icons.cancel_outlined,
                                                  color: colorScheme.error,
                                                ),
                                                onPressed: () async {
                                                  final ok =
                                                      await showDialog<bool>(
                                                    context: context,
                                                    builder: (ctx) =>
                                                        AlertDialog(
                                                      title: const Text(
                                                          'Revoke invite?'),
                                                      content: Text(
                                                        'Revoke pending invite for $email?\n'
                                                        'The accept link will stop working.',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(ctx)
                                                                  .pop(false),
                                                          child: const Text(
                                                              'Cancel'),
                                                        ),
                                                        ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                colorScheme
                                                                    .error,
                                                            foregroundColor:
                                                                colorScheme
                                                                    .onError,
                                                          ),
                                                          onPressed: () =>
                                                              Navigator.of(ctx)
                                                                  .pop(true),
                                                          child: const Text(
                                                              'Revoke'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (ok != true) return;
                                                  try {
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                            'franchisee_invitations')
                                                        .doc(token)
                                                        .update({
                                                      'status': 'revoked',
                                                      'revokedAt': FieldValue
                                                          .serverTimestamp(),
                                                    });
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Invite revoked for $email'),
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Revoke failed: $e'),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // ---- Active portal users ----
                        Card(
                          elevation: DesignTokens.adminCardElevation,
                          color: DesignTokens.surfaceColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.adminCardRadius,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.manage_accounts_outlined,
                                      color: DesignTokens.primaryColor,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Active portal users',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: DesignTokens.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Users with web login access for this franchise.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        DesignTokens.textColor.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                StreamBuilder<List<shared.User>>(
                                  stream: firestoreService
                                      .getStaffUsers(franchiseId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 24),
                                        child: LoadingShimmerWidget(),
                                      );
                                    }
                                    if (!snapshot.hasData ||
                                        snapshot.data!.isEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        child: EmptyStateWidget(
                                          title: loc.staffNoStaffTitle,
                                          message: loc.staffNoStaffMessage,
                                          imageAsset: BrandingConfig
                                              .adminEmptyStateImage,
                                          isAdmin: true,
                                        ),
                                      );
                                    }
                                    final staff = snapshot.data!;
                                    return ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: staff.length,
                                      separatorBuilder: (_, __) => Divider(
                                        color: DesignTokens.textColor
                                            .withOpacity(0.12),
                                      ),
                                      itemBuilder: (context, i) {
                                        final user = staff[i];
                                        final initial = user.name.isNotEmpty
                                            ? user.name[0].toUpperCase()
                                            : '?';
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                DesignTokens.secondaryColor,
                                            child: Text(
                                              initial,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            user.name.isNotEmpty
                                                ? user.name
                                                : user.email,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: DesignTokens.textColor,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${user.email} · ${user.roles.join(", ")}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: DesignTokens.textColor
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(
                                              Icons.person_remove_outlined,
                                              color: colorScheme.error,
                                            ),
                                            tooltip: loc.staffRemoveTooltip,
                                            onPressed: () =>
                                                _confirmRemoveStaff(
                                              context,
                                              firestoreService,
                                              user,
                                              loc,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
