import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/core/models/dashboard_section.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/user_profile_notifier.dart';
import 'package:franchise_admin_portal/widgets/dashboard/role_badge.dart';
import 'package:franchise_admin_portal/admin/developer/developer_dashboard_screen.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_switcher_dropdown.dart';
import 'package:franchise_admin_portal/widgets/financials/franchise_financial_kpi_card.dart';
import 'package:franchise_admin_portal/widgets/dashboard/franchise_picker_dropdown.dart';
import 'package:franchise_admin_portal/core/models/franchise_info.dart';
import 'package:franchise_admin_portal/widgets/financials/cash_flow_forecast_card.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/alerts_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/invoice_list_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/invoice_detail_screen.dart';
import 'package:franchise_admin_portal/widgets/financials/invoice_export_dialog.dart';
import 'package:franchise_admin_portal/admin/hq_owner/invoice_audit_trail_widget.dart';
import 'package:franchise_admin_portal/admin/hq_owner/invoice_search_bar.dart';
import 'package:franchise_admin_portal/widgets/financials/invoice_data_table.dart';
import 'package:franchise_admin_portal/widgets/financials/invoices_card.dart';
import 'package:franchise_admin_portal/widgets/dashboard/billing_summary_card.dart';
import 'package:franchise_admin_portal/widgets/financials/payout_status_card.dart';
import 'package:franchise_admin_portal/widgets/profile/user_avatar_menu.dart';
import 'package:franchise_admin_portal/core/services/franchise_subscription_service.dart';
import 'package:franchise_admin_portal/core/models/franchise_subscription_model.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/widgets/header/settings_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/help_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/notifications_icon_button.dart';

/// Developer/HQ-only: Entry-point for HQ/Owner dashboard.
/// Add this to your DashboardSection registry for 'hq_owner'.
class OwnerHQDashboardScreen extends StatelessWidget {
  final String currentScreen;

  const OwnerHQDashboardScreen({
    super.key,
    required this.currentScreen,
  });

  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.currentUser?.getIdTokenResult(true).then((token) {
      print('[DEBUG] Firebase ID token claims: ${token.claims}');
    });
    print('[OwnerHQDashboardScreen] build called');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final franchiseProvider =
          Provider.of<FranchiseProvider>(context, listen: false);
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);

      if (franchiseProvider.allFranchises.isEmpty) {
        final franchises = await firestoreService.getFranchises();
        franchiseProvider.setAllFranchises(franchises);
      }

      // Set initial franchiseId if none is selected yet
      if (!franchiseProvider.isFranchiseSelected &&
          franchiseProvider.allFranchises.isNotEmpty) {
        String initialId;
        final user =
            Provider.of<AdminUserProvider>(context, listen: false).user;
        if (user != null &&
            user.defaultFranchise != null &&
            user.defaultFranchise!.isNotEmpty) {
          initialId = user.defaultFranchise!;
        } else {
          initialId = franchiseProvider.allFranchises.first.id;
        }
        await franchiseProvider.setInitialFranchiseId(initialId);
      }
    });
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    final user = Provider.of<AdminUserProvider>(context).user;
    final franchiseId = Provider.of<FranchiseProvider>(context).franchiseId;
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final userProfileUrl =
        user?.avatarUrl ?? FirebaseAuth.instance.currentUser?.photoURL ?? '';
    // HQ/Owner-only guard (not visible to regular managers, staff, etc)
    final allowedRoles = ['hq_owner', 'hq_manager', 'developer'];
    if (user == null || !user.roles.any((r) => allowedRoles.contains(r))) {
      // Log and show unauthorized
      Future.microtask(() => ErrorLogger.log(
            message: "Unauthorized HQ Dashboard access attempt.",
            source: "OwnerHQDashboardScreen",
            screen: "OwnerHQDashboardScreen",
            severity: "warning",
            contextData: {
              'roles': user?.roles,
              'attempt': 'access',
              'userId': user?.id ?? "unknown",
              'franchiseId': franchiseId,
            },
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
            DashboardSwitcherDropdown(
              currentScreen: '/hq-owner/dashboard',
              user:
                  Provider.of<AdminUserProvider>(context, listen: false).user!,
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
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: FirestoreService()
                          .getInvoiceStatsForFranchise(franchiseId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error loading invoice stats'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return InvoicesCard(
                            totalInvoices: 0,
                            openInvoiceCount: 0,
                            overdueInvoiceCount: 0,
                            overdueAmount: 0.0,
                            paidInvoiceCount: 0,
                            outstandingBalance: 0.0,
                            lastInvoiceDate: null,
                            onViewAllPressed: () {
                              Navigator.of(context).pushNamed('/hq/invoices');
                            },
                          );
                        }
                        final stats = snapshot.data!;
                        return InvoicesCard(
                          totalInvoices: stats['totalInvoices'] ?? 0,
                          openInvoiceCount: stats['openInvoiceCount'] ?? 0,
                          overdueInvoiceCount:
                              stats['overdueInvoiceCount'] ?? 0,
                          overdueAmount: stats['overdueAmount'] ?? 0.0,
                          paidInvoiceCount: stats['paidInvoiceCount'] ?? 0,
                          outstandingBalance:
                              stats['outstandingBalance'] ?? 0.0,
                          lastInvoiceDate: stats['lastInvoiceDate'],
                          onViewAllPressed: () {
                            Navigator.of(context).pushNamed('/hq/invoices');
                          },
                        );
                      },
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 220),
                    child: PayoutStatusCard(),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 220),
                    child: BillingSummaryCard(),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 180),
                    child: StreamBuilder<FranchiseSubscription?>(
                      stream: FranchiseSubscriptionService()
                          .watchCurrentSubscription(franchiseId),
                      builder: (context, snapshot) {
                        print(
                            '[HQDashboard] StreamBuilder state=${snapshot.connectionState}, hasData=${snapshot.hasData}, hasError=${snapshot.hasError}');

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          print(
                              '[HQDashboard] Waiting for subscription data...');
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          print(
                              '[HQDashboard] ERROR loading subscription: ${snapshot.error}');
                          return Center(
                              child: Text(AppLocalizations.of(context)
                                      ?.subscriptionLoadError ??
                                  'Error loading subscription'));
                        }

                        final subscription = snapshot.data;
                        if (subscription == null) {
                          print('[HQDashboard] No active subscription found.');
                          return Card(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  AppLocalizations.of(context)
                                          ?.noActiveSubscription ??
                                      'No active subscription',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ),
                          );
                        }

                        final snapshotMap = subscription.planSnapshot;
                        final planName = snapshotMap?['name'] ?? 'Unknown Plan';
                        final price = snapshotMap?['price']
                                ?.toStringAsFixed(2) ??
                            subscription.priceAtSubscription.toStringAsFixed(2);
                        final interval = snapshotMap?['billingInterval'] ??
                            subscription.billingInterval ??
                            'unknown';
                        print(
                            '[HQDashboard] Rendering active subscription card: Plan=${planName}, Price=$price, Interval=$interval');

                        return Card(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                DesignTokens.adminCardRadius),
                          ),
                          elevation: DesignTokens.adminCardElevation,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context)
                                        ?.activePlanLabel ??
                                    'Active Platform Plan'),
                                const SizedBox(height: 8),
                                Text(
                                  planName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '\$$price / $interval',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Subscribed on: ${subscription.subscribedAt?.toLocal().toString().split(' ').first ?? 'unknown'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
                    franchiseId: user.franchiseIds.isNotEmpty
                        ? user.franchiseIds.first
                        : '',
                    userId: user.id,
                    developerMode: user.isDeveloper,
                  ),
                  QuickLinksPanel(
                    key: UniqueKey(), // Optional: force rebuild if needed
                    // Pass no args if your QuickLinksPanel uses Provider or context internally
                    // Just make sure the widget uses context for navigation and localization
                  ),
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
    print('[MultiBrandOverviewPanel] build called');
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
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

/// QUICK LINKS PANEL
class QuickLinksPanel extends StatelessWidget {
  const QuickLinksPanel({super.key});
  @override
  Widget build(BuildContext context) {
    print('[QuickLinksPanel] build called');
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
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
                    Navigator.of(context).pushNamed('/hq/invoices');
                  },
                  color: colorScheme.primary,
                ),
                _QuickLinkTile(
                  icon: Icons.payments,
                  label: loc.payoutStatus ?? "Payouts",
                  onTap: () {
                    Navigator.of(context).pushNamed('/hq/payouts');
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
                _QuickLinkTile(
                  icon: Icons.notifications,
                  label: loc.franchiseAlerts ?? "Alerts",
                  onTap: () => Navigator.of(context).pushNamed('/alerts'),
                  color: colorScheme.primary,
                ),
                _QuickLinkTile(
                  icon: Icons.credit_card,
                  label: loc.viewPlatformPlans ?? "Platform Plans",
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed('/hq-owner/available-plans');
                  },
                  color: colorScheme.tertiary,
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
    print('[FutureFeaturePlaceholderPanel] build called');
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
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
