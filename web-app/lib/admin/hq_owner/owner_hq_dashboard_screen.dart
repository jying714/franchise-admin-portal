import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/dashboard/role_badge.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_switcher_dropdown.dart';
import 'package:franchise_admin_portal/widgets/dashboard/franchise_picker_dropdown.dart';
import 'package:franchise_admin_portal/widgets/financials/franchise_financial_kpi_card.dart';
import 'package:franchise_admin_portal/widgets/financials/cash_flow_forecast_card.dart';
import 'package:franchise_admin_portal/widgets/financials/invoices_card.dart';
import 'package:franchise_admin_portal/widgets/financials/payout_status_card.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/alerts_card.dart';
import 'package:franchise_admin_portal/widgets/dashboard/billing_summary_card.dart';
import 'package:franchise_admin_portal/widgets/profile/user_avatar_menu.dart';
import 'package:franchise_admin_portal/widgets/header/settings_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/help_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/notifications_icon_button.dart';

class OwnerHQDashboardScreen extends StatelessWidget {
  final String currentScreen;

  const OwnerHQDashboardScreen({
    super.key,
    this.currentScreen = 'hq-owner/dashboard',
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: true);
    final adminUserProvider =
        Provider.of<shared.AdminUserProvider>(context, listen: true);
    final adminUser = adminUserProvider.user;

    // Ensure initialization (defensive)
    if (adminUser != null &&
        (franchiseProvider.franchiseId == 'unknown' ||
            franchiseProvider.franchiseId.isEmpty)) {
      franchiseProvider.initializeWithUser(adminUser);
    }

    final franchiseId = franchiseProvider.franchiseId != 'unknown' &&
            franchiseProvider.franchiseId.isNotEmpty
        ? franchiseProvider.franchiseId
        : (adminUser?.defaultFranchise ??
            (adminUser?.franchiseIds?.isNotEmpty == true
                ? adminUser!.franchiseIds!.first
                : 'test'));

    final isMobile = MediaQuery.of(context).size.width < 800;
    final gridColumns = isMobile ? 1 : 3;
    final gap = isMobile ? 12.0 : 22.0;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        elevation: DesignTokens.adminCardElevation,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Icon(Icons.business_center_rounded,
                color: DesignTokens.primaryColor),
            const SizedBox(width: 12),
            Text(
              loc.ownerHQDashboardTitle ?? "Franchise HQ Dashboard",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            const Spacer(),
            FranchisePickerDropdown(),
            const SizedBox(width: 14),
            DashboardSwitcherDropdown(
              currentScreen: currentScreen,
              user: adminUser!,
            ),
            const SizedBox(width: 8),
            NotificationsIconButton(),
            const SizedBox(width: 8),
            HelpIconButton(),
            const SizedBox(width: 8),
            SettingsIconButton(),
            const SizedBox(width: 8),
            UserAvatarMenu(),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(gap),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: gridColumns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: gap,
                mainAxisSpacing: gap,
                childAspectRatio: isMobile ? 1.8 : 2.4,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 180),
                    child: FranchiseFinancialKpiCard(franchiseId: franchiseId),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 220),
                    child: CashFlowForecastCard(franchiseId: franchiseId),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 220),
                    child: InvoicesCard(
                      totalInvoices: 0,
                      openInvoiceCount: 0,
                      overdueInvoiceCount: 0,
                      overdueAmount: 0.0,
                      paidInvoiceCount: 0,
                      outstandingBalance: 0.0,
                      lastInvoiceDate: null,
                      onViewAllPressed: () =>
                          Navigator.of(context).pushNamed('/hq/invoices'),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 220),
                    child: PayoutStatusCard(),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 220),
                    child: BillingSummaryCard(),
                  ),
                ],
              ),
              SizedBox(height: gap),
              GridView.count(
                crossAxisCount: gridColumns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: gap,
                mainAxisSpacing: gap,
                childAspectRatio: isMobile ? 1.8 : 2.4,
                children: [
                  const MultiBrandOverviewPanel(),
                  AlertsCard(
                    franchiseId: franchiseId,
                    userId: adminUser?.id ?? '',
                  ),
                  const QuickLinksPanel(),
                ],
              ),
              SizedBox(height: gap),
              const FutureFeaturePlaceholderPanel(),
              SizedBox(height: gap),
              Card(
                elevation: DesignTokens.adminCardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.adminCardRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Branding Preview',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                color: DesignTokens.primaryColor,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Primary',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                color: DesignTokens.secondaryColor,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Secondary',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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

// === Supporting Widgets (kept minimal & clean) ===

class MultiBrandOverviewPanel extends StatelessWidget {
  const MultiBrandOverviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surfaceVariant,
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: shared.UiConfig.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.multiBrandSnapshot ?? "Multi-Brand Overview",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            // TODO: Replace with real multi-brand data from provider
            const Text("Additional brands coming soon..."),
          ],
        ),
      ),
    );
  }
}

class QuickLinksPanel extends StatelessWidget {
  const QuickLinksPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surfaceVariant,
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: shared.UiConfig.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.quickLinks ?? "Quick Links",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickLinkTile(
                  icon: Icons.description,
                  label: loc.viewInvoices ?? "Invoices",
                  onTap: () => Navigator.of(context).pushNamed('/hq/invoices'),
                ),
                _QuickLinkTile(
                  icon: Icons.payments,
                  label: loc.payoutStatus ?? "Payouts",
                  onTap: () => Navigator.of(context).pushNamed('/hq/payouts'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        avatar: Icon(icon, color: DesignTokens.primaryColor),
        label: Text(label),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class FutureFeaturePlaceholderPanel extends StatelessWidget {
  const FutureFeaturePlaceholderPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: shared.UiConfig.defaultPadding,
        child: Text(loc.comingSoonFeatures ?? "Future Features - Coming Soon"),
      ),
    );
  }
}
