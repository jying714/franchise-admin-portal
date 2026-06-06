import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_sidebar.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_bottom_nav_bar.dart';
import 'package:franchise_admin_portal/widgets/dialogs/franchise_selector_dialog_content.dart';
import 'package:franchise_admin_portal/widgets/developer/overview_section.dart';
import 'package:franchise_admin_portal/widgets/developer/impersonation_tools_section.dart';
import 'package:franchise_admin_portal/widgets/developer/error_logs_section.dart';
import 'package:franchise_admin_portal/widgets/developer/feature_toggles_section.dart';
import 'package:franchise_admin_portal/widgets/developer/plugin_registry_section.dart';
import 'package:franchise_admin_portal/widgets/developer/schema_browser_section.dart';
import 'package:franchise_admin_portal/widgets/developer/audit_trail_section.dart';
import 'package:franchise_admin_portal/admin/hq_owner/owner_hq_dashboard_screen.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_switcher_dropdown.dart';
import 'package:franchise_admin_portal/admin/devtools/billing/billing_subscription_tools_screen.dart';
import 'package:franchise_admin_portal/admin/devtools/widgets/dev_tools_sidebar_group.dart';
import 'package:franchise_admin_portal/admin/devtools/subscriptions/subscription_dev_tools_screen.dart';
import 'package:franchise_admin_portal/admin/devtools/platform/platform_feature_plan_tools_screen.dart';
import 'package:franchise_admin_portal/widgets/header/settings_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/help_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/notifications_icon_button.dart';
import 'package:franchise_admin_portal/widgets/profile/user_avatar_menu.dart';
import 'package:franchise_admin_portal/widgets/dashboard/franchise_picker_dropdown.dart';
import 'package:franchise_admin_portal/core/section_registry.dart'; // DashboardSection

class DeveloperDashboardScreen extends StatefulWidget {
  final String currentScreen;

  const DeveloperDashboardScreen({
    super.key,
    required this.currentScreen,
  });

  @override
  State<DeveloperDashboardScreen> createState() =>
      _DeveloperDashboardScreenState();
}

class _DeveloperDashboardScreenState extends State<DeveloperDashboardScreen> {
  late final List<shared.DashboardSection> _sections;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _sections = _getDeveloperSections();
  }

  Future<void> _selectFranchiseDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const SizedBox(
          width: 420,
          child: FranchiseSelectorDialogContent(),
        ),
      ),
    );
    // The dialog updates the FranchiseProvider internally — no extra handling needed
  }

  @override
  Widget build(BuildContext context) {
    final appUser = Provider.of<shared.AdminUserProvider>(context).user;
    if (appUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final franchiseId = context.watch<shared.FranchiseProvider>().franchiseId;
    final isMobile = MediaQuery.of(context).size.width < 800;
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final roles = appUser.roles;
    if (!roles.contains('developer')) {
      return Scaffold(
        body: Center(
          child: Text(
            loc.unauthorizedAccess,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      );
    }

    final showFranchise = franchiseId != 'all' &&
        franchiseId != 'unknown' &&
        franchiseId.isNotEmpty;
    final appBarTitle = showFranchise
        ? '${loc.developerDashboardTitle} — $franchiseId'
        : loc.developerDashboardTitle;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          FranchisePickerDropdown(),
          const SizedBox(width: 8),
          DashboardSwitcherDropdown(
            currentScreen: widget.currentScreen,
            user: appUser,
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
      body: Row(
        children: [
          if (!isMobile)
            Container(
              width: 230,
              color: colorScheme.surface.withOpacity(0.97),
              child: SafeArea(
                child: AdminSidebar(
                  sections: _sections.where((s) => s.sidebarOrder < 7).toList(),
                  selectedIndex: _selectedIndex,
                  onSelect: (i) => setState(() => _selectedIndex = i),
                  extraWidgets: [
                    DevToolsSidebarGroup(
                      label: 'Dev Tools',
                      icon: Icons.build_outlined,
                      tools:
                          _sections.where((s) => s.sidebarOrder >= 7).toList(),
                      selectedIndex: _selectedIndex,
                      startIndexOffset: 0,
                      onSelect: (i) => setState(() => _selectedIndex = i),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Semantics(
              label: 'Developer dashboard content area',
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  for (final section in _sections)
                    Builder(
                      builder: (context) {
                        try {
                          return section.builder(context);
                        } catch (e, stack) {
                          shared.ErrorLogger.log(
                            message: 'Developer dashboard section error: $e',
                            source: 'DeveloperDashboardScreen',
                            stack: stack.toString(),
                            severity: 'error',
                            contextData: {
                              'franchiseId': franchiseId,
                              'sectionIndex': _selectedIndex,
                              'sectionTitle': section.title,
                              'errorType': e.runtimeType.toString(),
                              if (appUser.id != null) 'userId': appUser.id,
                            },
                          );
                          return Center(
                            child: Text(
                              'Section failed: $e',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 16),
                            ),
                          );
                        }
                      },
                    )
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? AdminBottomNavBar(
              sections: _sections,
              selectedIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
            )
          : null,
    );
  }

  List<shared.DashboardSection> _getDeveloperSections() {
    String? getFranchiseOrNull(BuildContext context) {
      final id = context.watch<shared.FranchiseProvider>().franchiseId;
      return (id == 'unknown' || id.isEmpty) ? null : id;
    }

    return [
      shared.DashboardSection(
        key: 'overview',
        title: 'Overview',
        icon: Icons.dashboard_outlined,
        builder: (context) =>
            OverviewSection(franchiseId: getFranchiseOrNull(context)),
        sidebarOrder: 0,
      ),
      shared.DashboardSection(
        key: 'impersonationTools',
        title: 'Impersonation Tools',
        icon: Icons.switch_account_outlined,
        builder: (context) => ImpersonationToolsSection(
          franchiseId: getFranchiseOrNull(context),
        ),
        sidebarOrder: 1,
      ),
      shared.DashboardSection(
        key: 'errorMonitoring',
        title: 'Error Logs',
        icon: Icons.bug_report_outlined,
        builder: (context) => ErrorLogsSection(
          franchiseId: getFranchiseOrNull(context),
        ),
        sidebarOrder: 2,
      ),
      shared.DashboardSection(
        key: 'featureFlags',
        title: 'Feature Toggles',
        icon: Icons.toggle_on_outlined,
        builder: (context) => FeatureTogglesSection(
          franchiseId: getFranchiseOrNull(context),
        ),
        sidebarOrder: 3,
      ),
      shared.DashboardSection(
        key: 'pluginRegistry',
        title: 'Plugin Registry',
        icon: Icons.extension_outlined,
        builder: (context) => PluginRegistrySection(
          franchiseId: getFranchiseOrNull(context),
        ),
        sidebarOrder: 4,
      ),
      shared.DashboardSection(
        key: 'firestoreSchema',
        title: 'Schema Browser',
        icon: Icons.schema_outlined,
        builder: (context) => SchemaBrowserSection(
          franchiseId: getFranchiseOrNull(context),
        ),
        sidebarOrder: 5,
      ),
      shared.DashboardSection(
        key: 'auditTrail',
        title: 'Audit Trail',
        icon: Icons.timeline_outlined,
        builder: (context) => AuditTrailSection(
          franchiseId: getFranchiseOrNull(context),
        ),
        sidebarOrder: 6,
      ),
      // --- DEV TOOLS GROUP ---
      shared.DashboardSection(
        key: 'billingSubscriptionTools',
        title: 'Billing Tools',
        icon: Icons.receipt_long_outlined,
        builder: (context) => const BillingSubscriptionToolsScreen(),
        sidebarOrder: 7,
      ),
      shared.DashboardSection(
        key: 'subscriptionDevTools',
        title: 'Subscription Tools',
        icon: Icons.subscriptions_outlined,
        builder: (context) => const SubscriptionDevToolsScreen(),
        sidebarOrder: 8,
      ),
      shared.DashboardSection(
        key: 'platformFeaturePlanTools',
        title: 'Platform Feature & Plan Tools',
        icon: Icons.tune_outlined,
        builder: (context) => const PlatformFeaturePlanToolsScreen(),
        sidebarOrder: 9,
      ),
    ];
  }
}
