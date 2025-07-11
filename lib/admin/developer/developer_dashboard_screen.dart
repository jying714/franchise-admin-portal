import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_sidebar.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_bottom_nav_bar.dart';
import 'package:franchise_admin_portal/core/models/dashboard_section.dart';
import 'package:franchise_admin_portal/widgets/dialogs/franchise_selector_dialog_content.dart';
import 'package:franchise_admin_portal/core/providers/franchise_selector.dart';
import 'package:franchise_admin_portal/widgets/developer/overview_section.dart';
import 'package:franchise_admin_portal/widgets/developer/impersonation_tools_section.dart';
import 'package:franchise_admin_portal/widgets/developer/error_logs_section.dart';
import 'package:franchise_admin_portal/widgets/developer/feature_toggles_section.dart';
import 'package:franchise_admin_portal/widgets/developer/plugin_registry_section.dart';
import 'package:franchise_admin_portal/widgets/developer/schema_browser_section.dart';
import 'package:franchise_admin_portal/widgets/developer/audit_trail_section.dart';

class DeveloperDashboardScreen extends StatefulWidget {
  const DeveloperDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DeveloperDashboardScreen> createState() =>
      _DeveloperDashboardScreenState();
}

class _DeveloperDashboardScreenState extends State<DeveloperDashboardScreen> {
  late final List<DashboardSection> _sections;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _sections = _getDeveloperSections();
  }

  Future<void> _selectFranchiseDialog(BuildContext context) async {
    final selectedId = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 420,
          child: FranchiseSelector(
            onSelected: (franchiseId) {
              Navigator.of(context).pop(franchiseId);
            },
          ),
        ),
      ),
    );
    if (selectedId != null && selectedId.isNotEmpty) {
      await context.read<FranchiseProvider>().setFranchiseId(selectedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUser = Provider.of<AdminUserProvider>(context).user;
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    final isMobile = MediaQuery.of(context).size.width < 800;
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final roles = appUser?.roles ?? [];
    if (!roles.contains('developer')) {
      print('[DEBUG] Blocked. appUser=${appUser?.email}, roles=${roles}');
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          franchiseId == 'all'
              ? '${loc.developerDashboardTitle} — ${loc.allFranchisesLabel ?? "All Franchises"}'
              : '${loc.developerDashboardTitle} — $franchiseId',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_alt),
            tooltip: loc.switchFranchise,
            onPressed: () => _selectFranchiseDialog(context),
          ),
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
                  sections: _sections,
                  selectedIndex: _selectedIndex,
                  onSelect: (i) => setState(() => _selectedIndex = i),
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
                          firestoreService.logError(
                            franchiseId,
                            message: 'Developer dashboard section error: $e',
                            source: 'DeveloperDashboardScreen',
                            screen: section.title,
                            stackTrace: stack.toString(),
                            errorType: e.runtimeType.toString(),
                            contextData: {
                              'sectionIndex': _selectedIndex,
                              'sectionTitle': section.title,
                            },
                            userId: appUser?.id,
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

  List<DashboardSection> _getDeveloperSections() {
    return [
      DashboardSection(
        key: 'overview',
        title: 'Overview',
        icon: Icons.dashboard_outlined,
        builder: (context) => OverviewSection(
            franchiseId: context.watch<FranchiseProvider>().franchiseId),
        sidebarOrder: 0,
      ),
      DashboardSection(
        key: 'impersonationTools',
        title: 'Impersonation Tools',
        icon: Icons.switch_account_outlined,
        builder: (context) => ImpersonationToolsSection(
          franchiseId: context.watch<FranchiseProvider>().franchiseId,
        ),
        sidebarOrder: 1,
      ),
      DashboardSection(
        key: 'errorMonitoring',
        title: 'Error Logs',
        icon: Icons.bug_report_outlined,
        builder: (context) => ErrorLogsSection(
          franchiseId: context.watch<FranchiseProvider>().franchiseId,
        ),
        sidebarOrder: 2,
      ),
      DashboardSection(
        key: 'featureFlags',
        title: 'Feature Toggles',
        icon: Icons.toggle_on_outlined,
        builder: (context) => FeatureTogglesSection(
          franchiseId: context.watch<FranchiseProvider>().franchiseId,
        ),
        sidebarOrder: 3,
      ),
      DashboardSection(
        key: 'pluginRegistry',
        title: 'Plugin Registry',
        icon: Icons.extension_outlined,
        builder: (context) => PluginRegistrySection(
          franchiseId: context.watch<FranchiseProvider>().franchiseId,
        ),
        sidebarOrder: 4,
      ),
      DashboardSection(
        key: 'firestoreSchema',
        title: 'Schema Browser',
        icon: Icons.schema_outlined,
        builder: (context) => SchemaBrowserSection(
          franchiseId: context.watch<FranchiseProvider>().franchiseId,
        ),
        sidebarOrder: 5,
      ),
      DashboardSection(
        key: 'auditTrail',
        title: 'Audit Trail',
        icon: Icons.timeline_outlined,
        builder: (context) => AuditTrailSection(
          franchiseId: context.watch<FranchiseProvider>().franchiseId,
        ),
        sidebarOrder: 6,
      ),
    ];
  }
}
