// File: lib/admin/owner/platform_owner_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as app;
import 'package:franchise_admin_portal/core/providers/user_profile_notifier.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_switcher_dropdown.dart';
import 'package:franchise_admin_portal/core/providers/franchisee_invitation_provider.dart';
import 'package:franchise_admin_portal/widgets/financials/franchisee_invitation_service.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/widgets/dialogs/franchisee_invitation_dialog.dart';
import 'package:franchise_admin_portal/widgets/financials/platform_revenue_summary_panel.dart';
import 'package:franchise_admin_portal/core/providers/platform_financials_provider.dart';
import 'package:franchise_admin_portal/widgets/profile/user_avatar_menu.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/admin/owner/sections/platform_plans_summary_card.dart';
import 'package:franchise_admin_portal/admin/owner/sections/franchise_subscription_summary_card.dart';
import 'package:franchise_admin_portal/admin/owner/screens/full_platform_plans_screen.dart';
import 'package:franchise_admin_portal/admin/owner/sections/quick_links_card.dart';
import 'package:franchise_admin_portal/widgets/header/settings_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/help_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/notifications_icon_button.dart';

class PlatformOwnerDashboardScreen extends StatelessWidget {
  final String currentScreen;

  const PlatformOwnerDashboardScreen({
    Key? key,
    required this.currentScreen,
  }) : super(key: key);

  bool _isPlatformOwner(app.User? user) {
    // Adjust this logic as needed; assumes you have a 'platform_owner' or similar role.
    return user != null &&
        (user.roles.contains('platform_owner') ||
            user.roles.contains('developer'));
  }

  @override
  Widget build(BuildContext context) {
    print('[PlatformOwnerDashboardScreen] build called');
    final adminUserProvider =
        Provider.of<AdminUserProvider>(context, listen: false);
    final user = adminUserProvider.user;
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    print('[PlatformOwnerDashboardScreen] user: $user');
    print('[PlatformOwnerDashboardScreen] loc: $loc');
    if (user == null) {
      print('[PlatformOwnerDashboardScreen] user is null! Returning error.');
      return Scaffold(
        body: Center(child: Text('User profile missing. [debug]')),
      );
    }
    if (loc == null) {
      print('[PlatformOwnerDashboardScreen] loc is null! Localization error.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    // === Platform Owner Access Guard ===
    if (!_isPlatformOwner(user)) {
      // Log unauthorized access attempt
      ErrorLogger.log(
        message: 'Unauthorized PlatformOwnerDashboardScreen access',
        source: 'PlatformOwnerDashboardScreen',
        screen: 'PlatformOwnerDashboardScreen',
        severity: 'warning',
        contextData: {
          'userId': user?.id,
          'roles': user?.roles,
        },
      );
      return Center(
        child: Card(
          elevation: DesignTokens.adminCardElevation,
          color: colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded,
                    color: colorScheme.error, size: 46),
                const SizedBox(height: 18),
                Text(
                  loc.unauthorizedAccessTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  loc.unauthorizedAccessMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: const Icon(Icons.home_rounded),
                  label: Text(loc.returnHome),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // === Main Dashboard Layout ===
    final isWide = MediaQuery.of(context).size.width > 1200;
    final hPadding = isWide ? 38.0 : 16.0;
    final vPadding = isWide ? 28.0 : 14.0;

    return ChangeNotifierProvider(
        create: (_) => PlatformFinancialsProvider()..loadFinancials(),
        child: Scaffold(
          backgroundColor: colorScheme.background,
          appBar: AppBar(
            titleSpacing: 0,
            elevation: 1,
            title: Row(
              children: [
                const SizedBox(width: 8),
                Image.network(
                  BrandingConfig.logoUrl,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => SizedBox(
                    height: 36,
                    child: Center(
                      child:
                          Icon(Icons.domain, size: 34, color: Colors.grey[400]),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  loc.platformOwnerDashboardTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                ),
              ],
            ),
            actions: [
              DashboardSwitcherDropdown(
                currentScreen: '/platform-owner/dashboard',
                user: user,
              ),
              // Padding(
              //   padding: const EdgeInsets.only(right: 16),
              //   child: Chip(
              //     label: Text(
              //       loc.platformOwner,
              //       style: TextStyle(
              //         color: colorScheme.onPrimary,
              //         fontWeight: FontWeight.w600,
              //       ),
              //     ),
              //     backgroundColor: colorScheme.primary,
              //     avatar: const Icon(Icons.verified_user,
              //         color: Colors.white, size: 20),
              //   ),
              // ),
              const SizedBox(width: 8),
              NotificationsIconButton(),
              const SizedBox(width: 8),
              HelpIconButton(),
              const SizedBox(width: 8),
              SettingsIconButton(),
              const SizedBox(width: 8),
              UserAvatarMenu(size: 36),
              const SizedBox(width: 8),
            ],
          ),
          body: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
            child: ListView(
              children: [
                // --- Quick Links Card ---
                const QuickLinksCard(),

                const SizedBox(height: 36),
                // --- Franchise Invitation Panel ---
                ChangeNotifierProvider(
                  create: (context) => FranchiseeInvitationProvider(
                    service: FranchiseeInvitationService(
                      firestoreService:
                          Provider.of<FirestoreService>(context, listen: false),
                    ),
                  )..fetchInvitations(),
                  child: FranchiseInvitationPanel(
                      loc: loc, colorScheme: colorScheme),
                ),

                const SizedBox(height: 36),

                // --- Franchise List Panel ---
                FranchiseListPanel(loc: loc, colorScheme: colorScheme),

                const SizedBox(height: 36),

                // --- Global Financial Panel ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 36.0),
                  child: Consumer<PlatformFinancialsProvider>(
                    builder: (context, provider, _) {
                      if (provider.loading) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (provider.error != null) {
                        return Card(
                          color: colorScheme.errorContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(Icons.warning,
                                    color: colorScheme.error, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!
                                      .genericErrorOccurred,
                                  style: TextStyle(
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(provider.error!),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => provider.refresh(),
                                  child:
                                      Text(AppLocalizations.of(context)!.retry),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (provider.overview == null || provider.kpis == null) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return PlatformRevenueSummaryPanel(
                          // Optionally pass values if you want more fine-grained control
                          // (If your PlatformRevenueSummaryPanel consumes the Provider directly, you don't need to pass anything)
                          );
                    },
                  ),
                ),

                const SizedBox(height: 36),

                // --- Platform Analytics Panel ---
                PlatformAnalyticsPanel(loc: loc, colorScheme: colorScheme),

                const SizedBox(height: 36),

                // --- Platform plans summary card ---
                const PlatformPlansSummaryCard(),

                const SizedBox(height: 36),
                // --- Franchise subscriptions summary card ---
                const FranchiseSubscriptionSummaryCard(),

                const SizedBox(height: 36),

                // --- Platform Settings Panel ---
                PlatformSettingsPanel(loc: loc, colorScheme: colorScheme),

                const SizedBox(height: 36),

                // --- Owner Announcements Panel ---
                OwnerAnnouncementsPanel(loc: loc, colorScheme: colorScheme),

                const SizedBox(height: 36),

                // === Future Features Placeholder ===
                _futureFeaturePlaceholder(context, loc, colorScheme),
              ],
            ),
          ),
        ));
  }

  Widget _futureFeaturePlaceholder(
      BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    return Card(
      color: colorScheme.surfaceVariant,
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 22),
        child: Column(
          children: [
            Icon(Icons.new_releases, color: colorScheme.primary, size: 36),
            const SizedBox(height: 12),
            Text(
              loc.futureFeaturesTitle,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              loc.futureFeaturesBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// === Modular Panels for Each Dashboard Section ===

// 1. Franchise Invitations
class FranchiseInvitationPanel extends StatelessWidget {
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  const FranchiseInvitationPanel(
      {required this.loc, required this.colorScheme, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Wire up real invite logic
    return Card(
      elevation: DesignTokens.adminCardElevation,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mail_outline, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  loc.inviteFranchiseesTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showDialog(
                      context: context,
                      builder: (_) => const FranchiseeInvitationDialog(),
                    );
                    if (result == true) {
                      // Optionally refresh invitations or show a SnackBar
                      Provider.of<FranchiseeInvitationProvider>(context,
                              listen: false)
                          .fetchInvitations();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text(AppLocalizations.of(context)!.invitationSent),
                        backgroundColor: colorScheme.primary,
                      ));
                    }
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(loc.inviteFranchisee),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Placeholder table for pending invitations
            Text(
              loc.pendingInvitations,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _pendingInvitesTable(context),
          ],
        ),
      ),
    );
  }

  Widget _pendingInvitesTable(BuildContext context) {
    return Consumer<FranchiseeInvitationProvider>(
      builder: (context, provider, child) {
        if (provider.loading) {
          return Center(child: CircularProgressIndicator());
        }
        final pendingInvites = provider.invitations
            .where((invite) => invite.status == "pending")
            .toList();
        if (pendingInvites.isEmpty) {
          return Text(
            AppLocalizations.of(context)!.noPendingInvitations,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.secondary,
                ),
          );
        }
        // Display as a table/list
        return Column(
          children: pendingInvites.map((invite) {
            return ListTile(
              leading: Icon(Icons.email_outlined, color: colorScheme.primary),
              title: Text(invite.email),
              subtitle: Text("${invite.role ?? ''} • ${invite.status}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.cancel, color: colorScheme.error),
                    tooltip: loc.revokeInvitation,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(loc.revokeInvitation),
                          content: Text(loc.confirmRevokeInvitation),
                          actions: [
                            TextButton(
                              child: Text(loc.cancel),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                            ElevatedButton(
                              child: Text(loc.revoke),
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        if (invite.token != null) {
                          await provider.cancelInvitation(invite.token!);
                        } else {
                          // Handle gracefully (shouldn’t happen in valid UI)
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Invalid invitation token.'),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ));
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: colorScheme.secondary),
                    tooltip: loc.resendInvitation,
                    onPressed: () async {
                      // Optionally implement resend via provider
                      // await provider.resendInvitation(invite.token);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text(loc.featureComingSoon(loc.resendInvitation)),
                        backgroundColor: colorScheme.primary,
                      ));
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// 2. Franchise Network
class FranchiseListPanel extends StatelessWidget {
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  const FranchiseListPanel(
      {required this.loc, required this.colorScheme, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Wire up real data table of franchises
    return Card(
      elevation: DesignTokens.adminCardElevation,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business_rounded, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  loc.franchiseNetworkTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement view all franchises action
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          loc.featureComingSoon(loc.franchiseNetworkTitle)),
                      backgroundColor: colorScheme.primary,
                    ));
                  },
                  icon: const Icon(Icons.list),
                  label: Text(loc.viewAllFranchises),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _franchiseListTable(context),
          ],
        ),
      ),
    );
  }

  Widget _franchiseListTable(BuildContext context) {
    // TODO: Replace with real data (fetch from Firestore/service)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        AppLocalizations.of(context)!.noFranchisesFound,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.secondary,
            ),
      ),
    );
  }
}

// 3. Global Financials
class GlobalFinancialPanel extends StatelessWidget {
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  const GlobalFinancialPanel(
      {required this.loc, required this.colorScheme, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Integrate real stats and tables
    return Card(
      elevation: DesignTokens.adminCardElevation,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  loc.globalFinancialsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _financialSummary(context),
            const SizedBox(height: 18),
            _financialTable(context),
          ],
        ),
      ),
    );
  }

  Widget _financialSummary(BuildContext context) {
    // TODO: Display MRR/ARR, total revenue, overdue
    return Row(
      children: [
        _statCard(context, 'MRR', '--'),
        const SizedBox(width: 24),
        _statCard(context, 'ARR', '--'),
        const SizedBox(width: 24),
        _statCard(context, AppLocalizations.of(context)!.overdueInvoices, '--'),
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.secondary.withOpacity(0.13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary)),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.75))),
          ],
        ),
      ),
    );
  }

  Widget _financialTable(BuildContext context) {
    // TODO: Implement invoices, payouts, fee schedules
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        AppLocalizations.of(context)!.noFinancialData,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.secondary,
            ),
      ),
    );
  }
}

// 4. Platform Analytics
class PlatformAnalyticsPanel extends StatelessWidget {
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  const PlatformAnalyticsPanel(
      {required this.loc, required this.colorScheme, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Wire up real analytics and charting
    return Card(
      elevation: DesignTokens.adminCardElevation,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  loc.platformAnalyticsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Placeholder for KPIs
            Row(
              children: [
                _analyticsCard(context, loc.totalFranchises, '--'),
                const SizedBox(width: 22),
                _analyticsCard(context, loc.activeUsers, '--'),
                const SizedBox(width: 22),
                _analyticsCard(context, loc.totalOrders, '--'),
              ],
            ),
            const SizedBox(height: 24),
            // Placeholder for chart/graph
            Container(
              width: double.infinity,
              height: 160,
              color: colorScheme.surfaceVariant.withOpacity(0.34),
              child: Center(
                child: Text(
                  loc.analyticsComingSoon,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.secondary,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _analyticsCard(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.secondary.withOpacity(0.13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.75))),
          ],
        ),
      ),
    );
  }
}

// 5. Platform Settings
class PlatformSettingsPanel extends StatelessWidget {
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  const PlatformSettingsPanel(
      {required this.loc, required this.colorScheme, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Wire up real settings form and save logic
    return Card(
      elevation: DesignTokens.adminCardElevation,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  loc.platformSettingsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              loc.platformSettingsComingSoon,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.secondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// 6. Owner Announcements
class OwnerAnnouncementsPanel extends StatelessWidget {
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  const OwnerAnnouncementsPanel(
      {required this.loc, required this.colorScheme, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Wire up real announcements (compose and list)
    return Card(
      elevation: DesignTokens.adminCardElevation,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.announcement, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  loc.ownerAnnouncementsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement announcement compose dialog
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          loc.featureComingSoon(loc.ownerAnnouncementsTitle)),
                      backgroundColor: colorScheme.primary,
                    ));
                  },
                  icon: const Icon(Icons.add_alert),
                  label: Text(loc.sendAnnouncement),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                loc.noAnnouncements,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.secondary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
