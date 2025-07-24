import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/auth_service.dart';
import 'package:franchise_admin_portal/core/models/dashboard_section.dart';
import 'package:franchise_admin_portal/core/section_registry.dart';
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
import 'package:franchise_admin_portal/core/utils/role_guard.dart';
import 'package:franchise_admin_portal/widgets/dashboard/franchise_picker_dropdown.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/onboarding_sidebar_group.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_sidebar.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String? initialSectionKey;

  const AdminDashboardScreen({Key? key, this.initialSectionKey})
      : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final List<DashboardSection> _sections;
  int _selectedIndex = 0;
  bool _showMaintenanceBanner = false;

  @override
  void initState() {
    super.initState();
    _sections = getSidebarSections();

    final allSections = [..._sections, ...onboardingSteps];
    if (widget.initialSectionKey != null) {
      final matchIndex = allSections.indexWhere(
        (s) => s.key == widget.initialSectionKey,
      );
      if (matchIndex != -1) {
        _selectedIndex = matchIndex;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    final userNotifier = Provider.of<UserProfileNotifier>(context);
    final appUser = userNotifier.user;
    final mainSections = getSidebarSections();
    final onboardingStartIndex = mainSections.length;

    if (userNotifier.loading || appUser == null || appUser.roles.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final isMobile = MediaQuery.of(context).size.width < 800;
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    if (loc == null) {
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }

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

    final onboardingSections =
        sections.where((s) => s.key.startsWith('onboarding')).toList();

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
            if (!isMobile) const Spacer(),
            RoleGuard(
              requireAnyRole: ['developer', 'platform_owner', 'hq_owner'],
              featureName: 'franchise_picker_dropdown',
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FranchisePickerDropdown(),
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
            RoleBadge(role: appUser.roles.join(', ')),
            const SizedBox(width: 8),
            ProfileIconButton(),
          ],
        ),
      ),
      drawer: isMobile
          ? Drawer(
              child: SafeArea(
                child: AdminSidebar(
                  sections: mainSections,
                  selectedIndex: _selectedIndex,
                  onSelect: (i) {
                    setState(() => _selectedIndex = i);
                    Navigator.of(context).pop();
                  },
                  extraWidgets: [
                    OnboardingSidebarGroup(
                      steps: onboardingSteps, // ONLY onboarding steps
                      selectedIndex: _selectedIndex,
                      onSelect: (i) => setState(() => _selectedIndex = i),
                      startIndexOffset: onboardingStartIndex,
                    ),
                  ],
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
                        sections: mainSections,
                        selectedIndex: _selectedIndex,
                        onSelect: (i) => setState(() => _selectedIndex = i),
                        extraWidgets: [
                          OnboardingSidebarGroup(
                            steps: onboardingSteps,
                            selectedIndex: _selectedIndex,
                            onSelect: (i) => setState(() => _selectedIndex = i),
                            startIndexOffset: onboardingStartIndex,
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight,
                          maxWidth: constraints.maxWidth,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return IndexedStack(
                              index: _selectedIndex,
                              children: [
                                // All main sections first
                                for (final section in mainSections)
                                  Builder(
                                    builder: (context) {
                                      try {
                                        return SizedBox(
                                          width: constraints.maxWidth,
                                          height: constraints.maxHeight,
                                          child: section.builder(context),
                                        );
                                      } catch (e, stack) {
                                        ErrorLogger.log(
                                          message:
                                              'Dashboard section error: $e',
                                          source: 'AdminDashboardScreen',
                                          screen: section.title,
                                          stack: stack.toString(),
                                          severity: 'error',
                                          contextData: {
                                            'franchiseId': franchiseId,
                                            'sectionIndex': _selectedIndex,
                                            'sectionTitle': section.title,
                                            'errorType':
                                                e.runtimeType.toString(),
                                            'userId': appUser.id,
                                          },
                                        );
                                        return Center(
                                          child: Text(
                                            'Section failed: $e',
                                            style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 16),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                // Then all onboarding steps, in order
                                for (final section in onboardingSteps)
                                  Builder(
                                    builder: (context) {
                                      try {
                                        return SizedBox(
                                          width: constraints.maxWidth,
                                          height: constraints.maxHeight,
                                          child: section.builder(context),
                                        );
                                      } catch (e, stack) {
                                        ErrorLogger.log(
                                          message:
                                              'Onboarding section error: $e',
                                          source: 'AdminDashboardScreen',
                                          screen: section.title,
                                          stack: stack.toString(),
                                          severity: 'error',
                                          contextData: {
                                            'franchiseId': franchiseId,
                                            'sectionIndex': _selectedIndex,
                                            'sectionTitle': section.title,
                                            'errorType':
                                                e.runtimeType.toString(),
                                            'userId': appUser.id,
                                          },
                                        );
                                        return Center(
                                          child: Text(
                                            'Section failed: $e',
                                            style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 16),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final int notificationCount = 0; // Replace with live state

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IconButton(
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
                      child: const SizedBox(
                        width: 340,
                        // child: NotificationsPanel(notifications: []),
                      ),
                    ),
                  );
                  setState(() => _panelOpen = false);
                }
              },
            ),
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
      ),
    );
  }
}
