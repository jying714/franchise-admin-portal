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

  void _selectFranchiseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.switchFranchise),
        content: const SizedBox(
          width: 500,
          child: FranchiseSelectorDialogContent(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
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

    if (appUser == null || appUser.role != 'developer') {
      print(
          '[DEBUG] Blocked. appUser=${appUser?.email}, role=${appUser?.role}');
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
        title: Text(loc.developerDashboardTitle),
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
                            userId: appUser.id,
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
        builder: (_) => const Center(child: Text('Developer Overview Screen')),
        sidebarOrder: 0,
      ),
      DashboardSection(
        key: 'impersonationTools',
        title: 'Impersonation Tools',
        icon: Icons.switch_account_outlined,
        builder: (_) => const Center(
            child: Text('Franchise impersonation manager placeholder')),
        sidebarOrder: 1,
      ),
      DashboardSection(
        key: 'errorMonitoring',
        title: 'Error Logs',
        icon: Icons.bug_report_outlined,
        builder: (_) =>
            const Center(child: Text('Error monitoring dashboard placeholder')),
        sidebarOrder: 2,
      ),
      DashboardSection(
        key: 'featureFlags',
        title: 'Feature Toggles',
        icon: Icons.toggle_on_outlined,
        builder: (_) =>
            const Center(child: Text('Feature toggle manager placeholder')),
        sidebarOrder: 3,
      ),
      DashboardSection(
        key: 'pluginRegistry',
        title: 'Plugin Registry',
        icon: Icons.extension_outlined,
        builder: (_) =>
            const Center(child: Text('Plugin injection tool placeholder')),
        sidebarOrder: 4,
      ),
      DashboardSection(
        key: 'firestoreSchema',
        title: 'Schema Browser',
        icon: Icons.schema_outlined,
        builder: (_) =>
            const Center(child: Text('Firestore schema browser placeholder')),
        sidebarOrder: 5,
      ),
      DashboardSection(
        key: 'auditTrail',
        title: 'Audit Trail',
        icon: Icons.timeline_outlined,
        builder: (_) => const Center(
            child: Text('Cross-franchise audit trail placeholder')),
        sidebarOrder: 6,
      ),
    ];
  }
}
