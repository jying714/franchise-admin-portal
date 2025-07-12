import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/core/models/dashboard_section.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';
import 'package:franchise_admin_portal/widgets/dashboard/role_badge.dart';
import 'package:franchise_admin_portal/admin/developer/developer_dashboard_screen.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_switcher_dropdown.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/franchise_financial_kpi_card.dart';
import 'package:franchise_admin_portal/widgets/dashboard/franchise_picker_dropdown.dart';
import 'package:franchise_admin_portal/core/models/franchise_info.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/cash_flow_forecast_card.dart';

/// Developer/HQ-only: Entry-point for HQ/Owner dashboard.
/// Add this to your DashboardSection registry for 'hq_owner'.
class OwnerHQDashboardScreen extends StatelessWidget {
  const OwnerHQDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final user = Provider.of<UserProfileNotifier>(context).user;
    final franchiseId = Provider.of<FranchiseProvider>(context).franchiseId;
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    // HQ/Owner-only guard (not visible to regular managers, staff, etc)
    final allowedRoles = ['hq_owner', 'hq_manager', 'developer'];
    if (user == null || !user.roles.any((r) => allowedRoles.contains(r))) {
      // Log and show unauthorized
      Future.microtask(() => firestoreService.logError(
            franchiseId,
            message: "Unauthorized HQ Dashboard access attempt.",
            source: "OwnerHQDashboardScreen",
            screen: "OwnerHQDashboardScreen",
            userId: user?.id ?? "unknown",
            severity: "warning",
            contextData: {'roles': user?.roles, 'attempt': 'access'},
          ));
      return Scaffold(
        body: Center(
          child: Card(
            color: colorScheme.errorContainer,
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: colorScheme.error, size: 48),
                  const SizedBox(height: 18),
                  Text(loc.unauthorizedAccessTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(loc.unauthorizedAccessMessage,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: colorScheme.onErrorContainer)),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.home),
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    label: Text(loc.returnHome),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final franchiseProvider =
          Provider.of<FranchiseProvider>(context, listen: false);
      if (franchiseProvider.allFranchises.isEmpty) {
        try {
          final firestoreService =
              Provider.of<FirestoreService>(context, listen: false);
          final franchises = await firestoreService.getFranchises();
          franchiseProvider.setAllFranchises(franchises);
        } catch (e) {
          // Optional: Show error/snackbar if needed
        }
      }
    });
    final isMobile = MediaQuery.of(context).size.width < 800;
    final gridColumns = isMobile ? 1 : 3;
    final gap = isMobile ? 12.0 : 22.0;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Icon(Icons.business_center_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              loc.ownerHQDashboardTitle ?? "Franchise HQ Dashboard",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const Spacer(),
            // --- ADD DEVELOPER DASHBOARD SWITCH IF USER IS DEVELOPER ---
            FranchisePickerDropdown(),
            const SizedBox(width: 14), // Optional: space before other controls
            DashboardSwitcherDropdown(currentScreen: 'hq'),
            RoleBadge(
                role: user.roles.isNotEmpty ? user.roles.first : "hq_owner"),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : AssetImage(BrandingConfig.defaultProfileIcon)
                      as ImageProvider,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(gap),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Fixed childAspectRatio for consistent card heights
              GridView.count(
                crossAxisCount: gridColumns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: gap,
                mainAxisSpacing: gap,
                childAspectRatio: isMobile ? 1.8 : 2.4,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 180,
                      maxHeight: 320,
                    ),
                    child: FranchiseFinancialKpiCard(
                      franchiseId: franchiseId,
                      brandId: user.defaultFranchise,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 220),
                    child: CashFlowForecastCard(
                      franchiseId: franchiseId,
                      brandId: user.defaultFranchise,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 220),
                    child: OutstandingInvoicesCard(),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 220),
                    child: PayoutStatusSummary(),
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
                children: const [
                  MultiBrandOverviewPanel(),
                  FranchiseAlertsList(),
                  QuickLinksPanel(),
                ],
              ),
              SizedBox(height: gap + 4),
              FutureFeaturePlaceholderPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.13),
          child: Icon(icon, color: color),
          radius: 18,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13, color: textColor.withOpacity(0.72))),
            Text(value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: textColor,
                )),
          ],
        ),
      ],
    );
  }
}

/// OUTSTANDING INVOICES
class OutstandingInvoicesCard extends StatelessWidget {
  const OutstandingInvoicesCard({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    // TODO: Replace with real data stream
    final invoiceCount = 4;
    final overdueAmount = 1254.90;

    return Card(
      color: colorScheme.surfaceVariant,
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.outstandingInvoices ?? "Outstanding Invoices",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.description_outlined, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  "$invoiceCount ${loc.openInvoices ?? 'Open'}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 16),
                Icon(Icons.error_outline, color: colorScheme.error),
                const SizedBox(width: 6),
                Text(
                  "\$${overdueAmount.toStringAsFixed(2)} ${loc.overdue ?? 'Overdue'}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: colorScheme.error),
                ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text(loc.viewInvoices ?? "View All"),
              onPressed: () {
                // TODO: Route to invoices screen
              },
            )
          ],
        ),
      ),
    );
  }
}

/// PAYOUT STATUS SUMMARY
class PayoutStatusSummary extends StatelessWidget {
  const PayoutStatusSummary({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    // TODO: Replace with real data stream
    final pending = 2;
    final sent = 8;
    final failed = 1;

    return Card(
      color: colorScheme.surfaceVariant,
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.payoutStatus ?? "Payouts",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatusDot(color: colorScheme.primary),
                const SizedBox(width: 4),
                Text("${loc.pending ?? "Pending"}: $pending",
                    style: TextStyle(color: colorScheme.primary)),
                const SizedBox(width: 14),
                _StatusDot(color: colorScheme.secondary),
                const SizedBox(width: 4),
                Text("${loc.sent ?? "Sent"}: $sent",
                    style: TextStyle(color: colorScheme.secondary)),
                const SizedBox(width: 14),
                _StatusDot(color: colorScheme.error),
                const SizedBox(width: 4),
                Text("${loc.failed ?? "Failed"}: $failed",
                    style: TextStyle(color: colorScheme.error)),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.payments_outlined),
              label: Text(loc.viewPayouts ?? "View All"),
              onPressed: () {
                // TODO: Route to payout history screen
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(radius: 6, backgroundColor: color);
  }
}

/// MULTI-BRAND / MULTI-FRANCHISE SNAPSHOT
class MultiBrandOverviewPanel extends StatelessWidget {
  const MultiBrandOverviewPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    // TODO: Replace with real data stream
    final brands = [
      {'name': 'Doughboys', 'count': 7, 'revenue': 38000.0},
      {'name': 'PastaKing', 'count': 4, 'revenue': 15289.2},
    ];

    return Card(
      color: colorScheme.surfaceVariant,
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.multiBrandSnapshot ?? "Multi-Brand Overview",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final brand in brands) ...[
              Row(
                children: [
                  Icon(Icons.store_mall_directory, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(brand['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Text("${loc.locations ?? 'Stores'}: ${brand['count']}"),
                  const SizedBox(width: 14),
                  Text("\$${(brand['revenue'] as double).toStringAsFixed(0)}",
                      style: TextStyle(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
            ],
            if (brands.isEmpty)
              Text(loc.noBrands ?? "No additional brands linked.",
                  style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.swap_horiz),
              label: Text(loc.switchBrand ?? "Switch Brand"),
              onPressed: () {
                // TODO: Implement brand switcher dialog
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ALERTS LIST (Compliance, Overdues, Paused Stores)
class FranchiseAlertsList extends StatelessWidget {
  const FranchiseAlertsList({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    // TODO: Replace with real stream of alerts
    final alerts = [
      {
        'type': 'overdue',
        'icon': Icons.warning_amber_rounded,
        'color': colorScheme.error,
        'text':
            loc.overduePaymentAlert ?? "Overdue franchise payment: Store #101"
      },
      {
        'type': 'compliance',
        'icon': Icons.policy_outlined,
        'color': colorScheme.secondary,
        'text': loc.complianceAlert ?? "Compliance doc missing: W-9 required"
      },
      {
        'type': 'paused',
        'icon': Icons.pause_circle_filled,
        'color': colorScheme.primary,
        'text': loc.storePausedAlert ?? "Store #104 is paused for season"
      },
    ];

    return Card(
      color: colorScheme.surfaceVariant,
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.franchiseAlerts ?? "Alerts",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            for (final alert in alerts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(alert['icon'] as IconData,
                        color: alert['color'] as Color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(alert['text'] as String)),
                  ],
                ),
              ),
            if (alerts.isEmpty)
              Text(loc.noAlerts ?? "No active alerts.",
                  style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.notifications),
              label: Text(loc.alertHistory ?? "View Alert History"),
              onPressed: () {
                // TODO: Route to full alerts/history screen
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// QUICK LINKS PANEL
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.quickLinks ?? "Quick Links",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _QuickLinkTile(
                  icon: Icons.description,
                  label: loc.viewInvoices ?? "Invoices",
                  onTap: () {
                    // TODO: Route to invoices screen
                  },
                  color: colorScheme.primary,
                ),
                _QuickLinkTile(
                  icon: Icons.payments,
                  label: loc.payoutStatus ?? "Payouts",
                  onTap: () {
                    // TODO: Route to payout screen
                  },
                  color: colorScheme.secondary,
                ),
                _QuickLinkTile(
                  icon: Icons.account_balance,
                  label: loc.bankAccounts ?? "Bank Accounts",
                  onTap: () {
                    // TODO: Route to bank accounts screen
                  },
                  color: colorScheme.primaryContainer,
                ),
                _QuickLinkTile(
                  icon: Icons.analytics,
                  label: loc.reporting ?? "Reports",
                  onTap: () {
                    // TODO: Route to reports/analytics
                  },
                  color: colorScheme.secondaryContainer,
                ),
                _QuickLinkTile(
                  icon: Icons.support_agent,
                  label: loc.billingSupport ?? "Billing Support",
                  onTap: () {
                    // TODO: Route to support/chat
                  },
                  color: colorScheme.primary,
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
  final Color color;
  const _QuickLinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        avatar: Icon(icon, color: color),
        label: Text(label),
        backgroundColor: color.withOpacity(0.13),
        labelStyle: TextStyle(
            fontWeight: FontWeight.w500, color: colorScheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

/// FUTURE FEATURE PLACEHOLDER PANEL
class FutureFeaturePlaceholderPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // Placeholders for: Announcements, Tax Docs, Compliance, Bulk Ops, Custom Billing, Multi-Currency, Scheduled Reports, API Integrations, etc.
    final futureFeatures = [
      {
        'icon': Icons.campaign_rounded,
        'label': loc.announcements ?? "HQ Announcements",
        'desc': loc.announcementsDesc ??
            "Coming soon: Company-wide bulletins and major updates.",
      },
      {
        'icon': Icons.document_scanner,
        'label': loc.taxDocs ?? "1099/W-9 Export",
        'desc': loc.taxDocsDesc ??
            "Generate and export annual payout tax forms for all franchisees.",
      },
      {
        'icon': Icons.language,
        'label': loc.multiCurrency ?? "Multi-Currency",
        'desc': loc.multiCurrencyDesc ??
            "Enable international/multi-currency payment support.",
      },
      {
        'icon': Icons.playlist_add_check_circle,
        'label': loc.bulkOps ?? "Bulk Operations",
        'desc': loc.bulkOpsDesc ??
            "Send invoices, set fees, or pause multiple stores at once.",
      },
      {
        'icon': Icons.integration_instructions,
        'label': loc.integrations ?? "Accounting/API Integrations",
        'desc': loc.integrationsDesc ??
            "Connect with QuickBooks, Xero, Sage, and more.",
      },
      {
        'icon': Icons.schedule,
        'label': loc.scheduledReports ?? "Scheduled Reports",
        'desc': loc.scheduledReportsDesc ??
            "Schedule, download, or auto-email custom finance reports.",
      },
    ];

    return Card(
      color: colorScheme.surfaceVariant.withOpacity(0.85),
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.comingSoonFeatures ?? "Future Features",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              runSpacing: 14,
              spacing: 24,
              children: [
                for (final feature in futureFeatures)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(feature['icon'] as IconData,
                          color: colorScheme.outline, size: 28),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(feature['label'] as String,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(feature['desc'] as String,
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
