import 'package:shared_core/src/core/utils/error_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/src/core/services/auth_service.dart';
import 'package:shared_core/src/core/models/dashboard_section.dart';
import 'package:franchise_admin_portal/admin/dashboard/section_registry.dart';
import 'package:franchise_admin_portal/widgets/dashboard/role_badge.dart';
import 'package:franchise_admin_portal/widgets/dashboard/maintenance_banner.dart';
import 'package:franchise_admin_portal/widgets/dashboard/notifications_panel.dart';
import 'package:franchise_admin_portal/widgets/header/settings_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/help_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/notifications_icon_button.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/src/core/models/user.dart' as app;
import 'package:franchise_admin_portal/widgets/header/franchise_app_bar.dart';
import 'package:shared_core/src/core/services/firestore_service.dart';
import 'package:shared_core/src/core/providers/user_profile_notifier.dart';
import 'package:shared_core/src/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_switcher_dropdown.dart';
import 'package:shared_core/src/core/providers/franchise_selector.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/src/core/providers/role_guard.dart';
import 'package:franchise_admin_portal/widgets/dashboard/franchise_picker_dropdown.dart';
import 'package:shared_core/src/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/widgets/profile/user_avatar_menu.dart';
import 'package:shared_core/src/core/providers/ingredient_type_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String? initialSectionKey;
  final String currentScreen;

  const AdminDashboardScreen({
    Key? key,
    this.initialSectionKey,
    this.currentScreen = '/admin/dashboard',
  }) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final List<DashboardSection> _sections;
  late final List<DashboardSection> _sidebarSections;
  int _selectedIndex = 0;
  bool _showMaintenanceBanner = false;
  bool _initializedFromKey = false;

  @override
  void initState() {
    super.initState();

    _sections = getAllDashboardSections();
    _sidebarSections = getSidebarSections();

    if (widget.initialSectionKey != null) {
      final index =
          _sections.indexWhere((s) => s.key == widget.initialSectionKey);
      if (index != -1) {
        _selectedIndex = index;
        _initializedFromKey = true;
        debugPrint(
            '[DEBUG][AdminDashboardScreen] ðŸ§­ Applied initialSectionKey: $_selectedIndex (${_sections[_selectedIndex].key})');
      } else {
        debugPrint(
            '[WARN][AdminDashboardScreen] initialSectionKey "${widget.initialSectionKey}" not found in _sections');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final typeProvider =
          Provider.of<IngredientTypeProvider>(context, listen: false);
      print(
          '[AdminDashboardScreen] IngredientTypeProvider FOUND: hashCode=${typeProvider.hashCode}');
    } catch (e) {
      print('[AdminDashboardScreen] IngredientTypeProvider NOT FOUND: $e');
    }

    print(
        '[DEBUG][AdminDashboardScreen][build] _selectedIndex: $_selectedIndex');
    // Apply initialSectionKey safely once _sections are loaded
    if (_sections.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sections.isNotEmpty) {
      print(
          '[DEBUG][AdminDashboardScreen][build] Section at selected index: ${_sections[_selectedIndex].key}');
    }
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    final adminUserProvider = Provider.of<AdminUserProvider>(context);
    final appUser = adminUserProvider.user;

    // Sidebar grouping
    final mainSidebarSections =
        _sidebarSections.where((s) => !s.key.startsWith('onboarding')).toList();
    final onboardingSidebarSections =
        _sidebarSections.where((s) => s.key.startsWith('onboarding')).toList();

    if (adminUserProvider.loading || appUser == null || appUser.roles.isEmpty) {
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

    if (_sections.isEmpty || _selectedIndex >= _sections.length) {
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

    // GUARD: Don't build dashboard unless franchiseId is valid and loaded
    if (franchiseId == null ||
        franchiseId.isEmpty ||
        franchiseId == 'unknown') {
      print(
          '[DEBUG][AdminDashboardScreen] franchiseId missing. Prompting user to select franchise.');
      // Show dashboard shell and picker, but overlay a modal or banner if you want.
      // Do NOT return/loading spinner here.
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        elevation: 1,
        automaticallyImplyLeading: false,
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
      ),
      drawer: isMobile
          ? Drawer(
              child: SafeArea(
                child: _buildSidebar(
                  context: context,
                  mainSidebarSections: mainSidebarSections,
                  onboardingSidebarSections: onboardingSidebarSections,
                  colorScheme: colorScheme,
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
                      child: _buildSidebar(
                        context: context,
                        mainSidebarSections: mainSidebarSections,
                        onboardingSidebarSections: onboardingSidebarSections,
                        colorScheme: colorScheme,
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
                            if (_selectedIndex >= _sections.length) {
                              print(
                                  '[DEBUG] Invalid _selectedIndex ($_selectedIndex) for sections length ${_sections.length}. Resetting to 0.');
                              _selectedIndex = 0;
                            }
                            return IndexedStack(
                              index: _selectedIndex,
                              children: [
                                for (final section in _sections)
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

  // Sidebar builder with Franchise Onboarding group and main sections
  Widget _buildSidebar({
    required BuildContext context,
    required List<DashboardSection> mainSidebarSections,
    required List<DashboardSection> onboardingSidebarSections,
    required ColorScheme colorScheme,
  }) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Main sidebar sections
        for (final section in mainSidebarSections)
          _SidebarSectionTile(
            section: section,
            isSelected: _selectedIndex < _sections.length &&
                _sections[_selectedIndex].key == section.key,
            onTap: () {
              final index = _sections.indexWhere((s) => s.key == section.key);
              if (index != -1 && index != _selectedIndex) {
                setState(() {
                  _selectedIndex = index;
                });
              }
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            colorScheme: colorScheme,
          ),

        // Franchise Onboarding label and steps
        if (onboardingSidebarSections.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
                top: 24.0, bottom: 4.0, left: 14.0, right: 10.0),
            child: Text(
              'Franchise Onboarding',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: colorScheme.primary,
                letterSpacing: 0.7,
              ),
            ),
          ),
          for (final section in onboardingSidebarSections)
            _SidebarSectionTile(
              section: section,
              isSelected: _selectedIndex < _sections.length &&
                  _sections[_selectedIndex].key == section.key,
              onTap: () {
                final index = _sections.indexWhere((s) => s.key == section.key);
                if (index != -1 && index != _selectedIndex) {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              colorScheme: colorScheme,
            ),
        ],
      ],
    );
  }
}

// Sidebar tile widget (icon, selection logic)
class _SidebarSectionTile extends StatelessWidget {
  final DashboardSection section;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _SidebarSectionTile({
    required this.section,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        section.icon,
        color: isSelected
            ? colorScheme.primary
            : colorScheme.onSurface.withOpacity(0.65),
      ),
      title: Text(
        section.title,
        style: TextStyle(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurface.withOpacity(0.9),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: colorScheme.primary.withOpacity(0.10),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}


