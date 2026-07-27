// File: lib/admin/owner/platform_owner_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_switcher_dropdown.dart';
import 'package:franchise_admin_portal/widgets/dialogs/franchisee_invitation_dialog.dart';
import 'package:franchise_admin_portal/widgets/financials/platform_revenue_summary_panel.dart';
import 'package:franchise_admin_portal/admin/platform_owner/sections/platform_plans_summary_card.dart';
import 'package:franchise_admin_portal/admin/platform_owner/sections/franchise_subscription_summary_card.dart';
import 'package:franchise_admin_portal/admin/platform_owner/sections/quick_links_card.dart';
import 'package:franchise_admin_portal/widgets/header/settings_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/help_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/notifications_icon_button.dart';
import 'package:franchise_admin_portal/widgets/profile/user_avatar_menu.dart';
import 'package:franchise_admin_portal/core/providers/franchise_invitation_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/platform_financials_provider_impl.dart';

class PlatformOwnerDashboardScreen extends StatelessWidget {
  final String currentScreen;

  const PlatformOwnerDashboardScreen({
    Key? key,
    required this.currentScreen,
  }) : super(key: key);

  bool _isPlatformOwner(shared.User? user) {
    return user != null &&
        (user.roles.contains('platform_owner') ||
            user.roles.contains('developer'));
  }

  @override
  Widget build(BuildContext context) {
    print('[PlatformOwnerDashboardScreen] build called');

    final adminUserProvider =
        Provider.of<shared.AdminUserProvider>(context, listen: true);
    final user = adminUserProvider.user;
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null || loc == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // === Platform Owner Access Guard ===
    if (!_isPlatformOwner(user)) {
      shared.ErrorLogger.log(
        message: 'Unauthorized PlatformOwnerDashboardScreen access',
        source: 'PlatformOwnerDashboardScreen',
        severity: 'warning',
        contextData: {'userId': user.id ?? '', 'roles': user.roles},
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
                Text(loc.unauthorizedAccessTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.error, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(loc.unauthorizedAccessMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 26),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: const Icon(Icons.home_rounded),
                  label: Text(loc.returnHome),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 800;
    final gridColumns = isMobile ? 1 : 3;
    final gap = isMobile ? 12.0 : 22.0;

    return ChangeNotifierProvider<PlatformFinancialsProviderImpl>(
      create: (context) => PlatformFinancialsProviderImpl(
        firestore: Provider.of<shared.FirestoreService>(context, listen: false),
      )..loadFinancials(),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          titleSpacing: 0,
          elevation: 1,
          automaticallyImplyLeading: false,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          iconTheme: IconThemeData(color: colorScheme.onPrimary),
          actionsIconTheme: IconThemeData(color: colorScheme.onPrimary),
          title: Row(
            children: [
              const SizedBox(width: 8),
              Image.network(
                BrandingConfig.logoUrl ?? BrandingConfig.logoMain,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.domain,
                  size: 34,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.platformOwnerDashboardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                ),
              ),
            ],
          ),
          actions: [
            Theme(
              data: Theme.of(context).copyWith(
                canvasColor: colorScheme.surface,
              ),
              child: DashboardSwitcherDropdown(
                currentScreen: currentScreen,
                user: user,
              ),
            ),
            const SizedBox(width: 4),
            NotificationsIconButton(),
            HelpIconButton(),
            SettingsIconButton(),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: UserAvatarMenu(size: 36),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(gap),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              // One grid cell width (3 columns, 2 gaps between cells).
              final cellW = isMobile ? maxW : (maxW - 2 * gap) / 3;
              final cellH = cellW / (isMobile ? 1.5 : 2.8);
              final revenueW = isMobile ? maxW : cellW * 2 + gap;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isMobile) ...[
                      SizedBox(
                        height: cellH * 1.4,
                        width: maxW,
                        child: _platformRevenueSlot(colorScheme),
                      ),
                      SizedBox(height: gap),
                      SizedBox(
                        height: cellH,
                        width: maxW,
                        child: const FranchiseSubscriptionSummaryCard(),
                      ),
                    ] else
                      SizedBox(
                        height: cellH,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: revenueW,
                              child: _platformRevenueSlot(colorScheme),
                            ),
                            SizedBox(width: gap),
                            SizedBox(
                              width: cellW,
                              child: const FranchiseSubscriptionSummaryCard(),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: gap),
                    ChangeNotifierProvider<FranchiseeInvitationProviderImpl>(
                      create: (_) => FranchiseeInvitationProviderImpl(
                        service: shared.FranchiseeInvitationService(
                          firestoreService:
                              Provider.of<shared.FirestoreService>(
                            context,
                            listen: false,
                          ),
                        ),
                      )..fetchInvitations(),
                      child: GridView.count(
                        crossAxisCount: gridColumns,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: gap,
                        mainAxisSpacing: gap,
                        childAspectRatio: isMobile ? 1.5 : 2.8,
                        children: [
                          const QuickLinksCard(),
                          FranchiseInvitationPanel(
                            loc: loc,
                            colorScheme: colorScheme,
                          ),
                          FranchiseListPanel(
                            loc: loc,
                            colorScheme: colorScheme,
                          ),
                          PlatformSettingsPanel(
                            loc: loc,
                            colorScheme: colorScheme,
                          ),
                          OwnerAnnouncementsPanel(
                            loc: loc,
                            colorScheme: colorScheme,
                          ),
                          _futureFeaturePlaceholder(context, loc, colorScheme),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _platformRevenueSlot(ColorScheme colorScheme) {
    return Consumer<PlatformFinancialsProviderImpl>(
      builder: (context, provider, _) {
        if (provider.loading ||
            provider.overview == null ||
            provider.kpis == null) {
          return Card(
            elevation: DesignTokens.adminCardElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        if (provider.error != null) {
          return Card(
            color: colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, color: colorScheme.error, size: 32),
                  Text(provider.error ?? 'Unknown error'),
                  ElevatedButton(
                    onPressed: provider.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        // Single consolidated revenue card (stats + KPIs inside panel).
        return SizedBox.expand(
          child: ClipRect(
            child: const PlatformRevenueSummaryPanel(),
          ),
        );
      },
    );
  }

  Widget _futureFeaturePlaceholder(
      BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    return Card(
      color: colorScheme.surfaceVariant,
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.new_releases, color: colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              loc.futureFeaturesTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                loc.futureFeaturesBody,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === Modular Panels for Each Dashboard Section ===

// 1. Franchise Invitations
// 1. Franchise Invitations
class FranchiseInvitationPanel extends StatelessWidget {
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  const FranchiseInvitationPanel({
    required this.loc,
    required this.colorScheme,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: DesignTokens.adminCardElevation,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                    // Capture providers from the panel context (under the local
                    // ChangeNotifierProvider). The dialog route is on the root
                    // navigator and does not see that subtree unless we re-provide.
                    final invitationProvider =
                        Provider.of<FranchiseeInvitationProviderImpl>(
                      context,
                      listen: false,
                    );
                    final result = await showDialog(
                      context: context,
                      builder: (_) => ChangeNotifierProvider<
                          FranchiseeInvitationProviderImpl>.value(
                        value: invitationProvider,
                        child:
                            Provider<shared.FranchiseeInvitationProvider>.value(
                          value: invitationProvider,
                          child: const FranchiseeInvitationDialog(),
                        ),
                      ),
                    );
                    if (result == true) {
                      if (context.mounted) {
                        invitationProvider.fetchInvitations();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              AppLocalizations.of(context)?.invitationSent ??
                                  'Invitation sent'),
                          backgroundColor: colorScheme.primary,
                        ));
                      }
                    }
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(loc.inviteFranchisee),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              loc.pendingInvitations,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _pendingInvitesTable(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingInvitesTable(BuildContext context) {
    return Consumer<FranchiseeInvitationProviderImpl>(
      builder: (context, provider, child) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final pendingInvites = provider.invitations
            .where((invite) => invite.status == "pending")
            .toList();
        if (pendingInvites.isEmpty) {
          return Text(
            AppLocalizations.of(context)?.noPendingInvitations ??
                'No pending invitations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.secondary,
                ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: pendingInvites.length,
          itemBuilder: (context, index) {
            final invite = pendingInvites[index];
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.email_outlined, color: colorScheme.primary),
              title: Text(
                invite.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                "${invite.role ?? ''} • ${invite.status}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
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
                  if (confirm == true && invite.token != null) {
                    await provider.cancelInvitation(invite.token!);
                  }
                },
              ),
            );
          },
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business_rounded,
                    color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.franchiseNetworkTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          loc.featureComingSoon(loc.franchiseNetworkTitle)),
                      backgroundColor: colorScheme.primary,
                    ));
                  },
                  child: Text(loc.viewAllFranchises),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(child: _franchiseListTable(context)),
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
      color: colorScheme.secondary.withValues(alpha: 0.13),
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
                  color: colorScheme.secondary.withValues(alpha: 0.75),
                )),
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
              color: colorScheme.secondary.withValues(alpha: 0.34),
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
      color: colorScheme.secondary.withValues(alpha: 0.13),
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
                    color: colorScheme.secondary.withValues(alpha: 0.75))),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.platformSettingsTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                loc.platformSettingsComingSoon,
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.announcement, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.ownerAnnouncementsTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: loc.sendAnnouncement,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          loc.featureComingSoon(loc.ownerAnnouncementsTitle)),
                      backgroundColor: colorScheme.primary,
                    ));
                  },
                  icon: const Icon(Icons.add_alert),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
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
