import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/auth_service.dart';
import 'package:franchise_admin_portal/core/section_registry.dart';
import 'package:franchise_admin_portal/widgets/dashboard/global_search_bar.dart';
import 'package:franchise_admin_portal/widgets/dashboard/role_badge.dart';
import 'package:franchise_admin_portal/widgets/dashboard/maintenance_banner.dart';
import 'package:franchise_admin_portal/widgets/dashboard/notifications_panel.dart';
import 'package:franchise_admin_portal/widgets/header/settings_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/help_icon_button.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as app;
import 'package:franchise_admin_portal/widgets/header/franchise_app_bar.dart';
import 'package:franchise_admin_portal/widgets/header/profile_icon_button.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_switcher_dropdown.dart';
import 'package:franchise_admin_portal/core/providers/franchise_selector.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/role_guard.dart';
import 'package:franchise_admin_portal/widgets/dashboard/franchise_picker_dropdown.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final List<DashboardSection> _sections;
  int _selectedIndex = 0;
  bool _showMaintenanceBanner = false; // Replace with actual flag or state mgmt

  @override
  void initState() {
    super.initState();
    _sections = getSidebarSections();
  }

  void _showFranchiseSelectorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 420,
          child: FranchiseSelector(
            onSelected: (franchiseId) {
              Provider.of<FranchiseProvider>(context, listen: false)
                  .setFranchiseId(franchiseId);
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always listen for user profile changes
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;

    final userNotifier = Provider.of<UserProfileNotifier>(context);
    final appUser = userNotifier.user;

// New multi-role-safe loading guard:
    if (userNotifier.loading || appUser == null || appUser.roles.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    print(
        'userNotifier.loading: ${userNotifier.loading}, appUser: $appUser, roles: ${appUser?.roles}');

    print('AdminDashboardScreen build called');

    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final isMobile = MediaQuery.of(context).size.width < 800;
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final List<String> userRoles = appUser.roles;
    final bool isDeveloper = userRoles.contains('developer');
    final String userRoleLabel =
        userRoles.isNotEmpty ? userRoles.join(', ') : "admin";
    print(
        'ROLE CHECK: appUser.role = ${appUser.roles}, isDeveloper = $isDeveloper');

    final sections = _sections;
    if (sections.isEmpty) {
      ErrorLogger.log(
        message: "No dashboard sections registered.",
        source: "AdminDashboardScreen",
        screen: "AdminDashboardScreen",
        severity: "error",
        contextData: {},
      );
      return Scaffold(
        appBar: AppBar(
          backgroundColor: DesignTokens.primaryColor,
          title: Text("ERROR: No sections found"),
        ),
        body: Center(
          child: Text(
            "No dashboard sections registered.",
            style: TextStyle(fontSize: 20, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: colorScheme.surface,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Text(
              loc.adminDashboardTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(width: 20),
            if (!isMobile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 260,
                  child: GlobalSearchBar(),
                ),
              ),
            const Spacer(),
            // --- SWITCH FRANCHISE BUTTON (By ROLE) ---
            RoleGuard(
              requireAnyRole: ['developer', 'platform_owner', 'hq_owner'],
              featureName: 'franchise_picker_dropdown',
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  child: FranchisePickerDropdown(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            DashboardSwitcherDropdown(currentScreen: 'admin'),
            NotificationsIconButton(),
            const SizedBox(width: 8),
            HelpIconButton(),
            const SizedBox(width: 8),
            SettingsIconButton(),
            const SizedBox(width: 12),
            RoleBadge(role: userRoleLabel),
            const SizedBox(width: 8),
            ProfileIconButton(),
          ],
        ),
      ),
      drawer: isMobile
          ? Drawer(
              child: SafeArea(
                child: AdminSidebar(
                  sections: sections,
                  selectedIndex: _selectedIndex,
                  onSelect: (i) {
                    setState(() => _selectedIndex = i);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          MaintenanceBanner(
            show: _showMaintenanceBanner,
            message:
                "The system is in maintenance mode. Some features may be unavailable.",
          ),
          Expanded(
            child: Row(
              children: [
                if (!isMobile)
                  Container(
                    width: 230,
                    color: colorScheme.surface.withOpacity(0.97),
                    child: SafeArea(
                      child: AdminSidebar(
                        sections: sections,
                        selectedIndex: _selectedIndex,
                        onSelect: (i) => setState(() => _selectedIndex = i),
                      ),
                    ),
                  ),
                Expanded(
                  child: Semantics(
                    label: 'Dashboard content area',
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        for (final section in sections)
                          Builder(
                            builder: (context) {
                              try {
                                return section.builder(context);
                              } catch (e, stack) {
                                ErrorLogger.log(
                                  message: 'Dashboard section error: $e',
                                  source: 'AdminDashboardScreen',
                                  screen: section.title,
                                  stack: stack.toString(),
                                  severity: 'error',
                                  contextData: {
                                    'franchiseId': franchiseId,
                                    'sectionIndex': _selectedIndex,
                                    'sectionTitle': section.title,
                                    'errorType': e.runtimeType.toString(),
                                    'userId': appUser.id,
                                  },
                                );
                                print('Dashboard section error: $e\n$stack');
                                return Center(
                                  child: Text(
                                    'Section failed: $e',
                                    style: TextStyle(
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
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? AdminBottomNavBar(
              sections: sections,
              selectedIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
            )
          : null,
    );
  }
}

class AdminSidebar extends StatelessWidget {
  final List<DashboardSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const AdminSidebar({
    required this.sections,
    required this.selectedIndex,
    required this.onSelect,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userNotifier = Provider.of<UserProfileNotifier>(context);
    final appUser = userNotifier.user;
    if (appUser == null) {
      print('AdminSidebar: Waiting for user profile to load...');
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        for (int i = 0; i < sections.length; i++)
          ListTile(
            leading: Icon(sections[i].icon,
                color: i == selectedIndex
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.65)),
            title: Text(
              sections[i].title,
              style: TextStyle(
                fontWeight:
                    i == selectedIndex ? FontWeight.bold : FontWeight.w500,
                color: i == selectedIndex
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.88),
              ),
            ),
            selected: i == selectedIndex,
            onTap: () => onSelect(i),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            visualDensity: VisualDensity.comfortable,
          ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            icon: Icon(sections[0].icon),
            label: Text("Go to ${sections[0].title}"),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size.fromHeight(44),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: () => onSelect(0),
          ),
        ),
      ],
    );
  }
}

class AdminBottomNavBar extends StatelessWidget {
  final List<DashboardSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const AdminBottomNavBar({
    required this.sections,
    required this.selectedIndex,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appUser = Provider.of<app.User?>(context, listen: false);
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withOpacity(0.5),
      items: [
        for (final section in sections)
          BottomNavigationBarItem(
            icon: Icon(section.icon, size: 20),
            label: section.title.length > 12
                ? section.title.substring(0, 12) + '…'
                : section.title,
          ),
      ],
      type: BottomNavigationBarType.fixed,
      backgroundColor: colorScheme.surface,
    );
  }
}

class NotificationsIconButton extends StatefulWidget {
  const NotificationsIconButton({Key? key}) : super(key: key);

  @override
  State<NotificationsIconButton> createState() =>
      _NotificationsIconButtonState();
}

class _NotificationsIconButtonState extends State<NotificationsIconButton> {
  bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final int notificationCount = 0; // Replace with actual state/stream

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: "Notifications",
          icon: Icon(Icons.notifications_none_outlined,
              color: colorScheme.primary),
          onPressed: () async {
            setState(() => _panelOpen = !_panelOpen);
            if (_panelOpen) {
              await showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: colorScheme.background,
                  child: SizedBox(
                    width: 340,
                    child: NotificationsPanel(
                        notifications: []), // Fill with real notifications
                  ),
                ),
              );
              setState(() => _panelOpen = false);
            }
          },
        ),
        if (notificationCount > 0)
          Positioned(
            right: 8,
            top: 10,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
