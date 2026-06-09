import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/core/section_registry.dart';
import 'package:franchise_admin_portal/widgets/dashboard/role_badge.dart';
import 'package:franchise_admin_portal/widgets/dashboard/maintenance_banner.dart';
import 'package:franchise_admin_portal/widgets/dashboard/notifications_panel.dart';
import 'package:franchise_admin_portal/widgets/header/settings_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/help_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/notifications_icon_button.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/widgets/header/franchise_app_bar.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_switcher_dropdown.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/admin/role_guard_widget.dart';
import 'package:franchise_admin_portal/widgets/dashboard/franchise_picker_dropdown.dart';
import 'package:franchise_admin_portal/widgets/profile/user_avatar_menu.dart';
import 'package:franchise_admin_portal/core/providers/franchise_feature_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/franchise_info_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/category_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/menu_item_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_progress_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/franchise_subscription_provider_impl.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_menu_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String? initialSectionKey;
  final String currentScreen;

  const AdminDashboardScreen({
    super.key,
    this.initialSectionKey,
    this.currentScreen = '/admin/dashboard',
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final List<shared.DashboardSection> _sections;
  late final List<shared.DashboardSection> _sidebarSections;
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final franchiseProvider = context.watch<shared.FranchiseProvider>();
    final franchiseId = franchiseProvider.franchiseId;
    final adminUserProvider = Provider.of<shared.AdminUserProvider>(context);
    final appUser = adminUserProvider.user;

    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);

    final isMobile = MediaQuery.of(context).size.width < 800;
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    if (loc == null) {
      return const Scaffold(body: Center(child: Text('Localization missing!')));
    }

    if (adminUserProvider.loading || appUser == null || appUser.roles.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_sections.isEmpty) {
      shared.ErrorLogger.log(
        message: "No dashboard sections registered.",
        source: "AdminDashboardScreen",
        severity: "error",
        contextData: {'franchiseId': franchiseId},
      );
      return Scaffold(
        appBar: AppBar(title: const Text("ERROR: No sections")),
        body: const Center(child: Text("No dashboard sections registered.")),
      );
    }

    // Sidebar grouping
    final mainSidebarSections =
        _sidebarSections.where((s) => !s.key.startsWith('onboarding')).toList();
    final onboardingSidebarSections =
        _sidebarSections.where((s) => s.key.startsWith('onboarding')).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
            const RoleGuard(
              requireAnyRole: ['developer', 'platform_owner', 'hq_owner'],
              featureName: 'franchise_picker_dropdown',
              child: Padding(
                padding: EdgeInsets.only(right: 8),
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
                    color: colorScheme.surface,
                    child: SafeArea(
                      child: _buildSidebar(
                        context: context,
                        mainSidebarSections: mainSidebarSections,
                        onboardingSidebarSections: onboardingSidebarSections,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ),
                // Inside AdminDashboardScreen _AdminDashboardScreenState build(), replace the Expanded child LayoutBuilder with this:

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // === LIVE ALIASES (safe, no rebuilds during build) ===
                      final featureProv =
                          Provider.of<FranchiseFeatureProviderImpl>(context,
                              listen: false);
                      final infoProv = Provider.of<FranchiseInfoProviderImpl>(
                          context,
                          listen: false);
                      final metaProv =
                          Provider.of<IngredientMetadataProviderImpl>(context,
                              listen: false);
                      final catProv = Provider.of<CategoryProviderImpl>(context,
                          listen: false);
                      final typeProv = Provider.of<IngredientTypeProviderImpl>(
                          context,
                          listen: false);
                      final menuItemProv = Provider.of<MenuItemProviderImpl>(
                          context,
                          listen: false);
                      final onboardingProg =
                          Provider.of<OnboardingProgressProviderImpl>(context,
                              listen: false);
                      final subscriptionProv =
                          Provider.of<FranchiseSubscriptionProviderImpl>(
                              context,
                              listen: false);

                      return MultiProvider(
                        providers: [
                          Provider<shared.FranchiseFeatureProvider>.value(
                              value: featureProv),
                          Provider<shared.FranchiseInfoProvider>.value(
                              value: infoProv),
                          Provider<shared.IngredientMetadataProvider>.value(
                              value: metaProv),
                          Provider<shared.CategoryProvider>.value(
                              value: catProv),
                          Provider<shared.IngredientTypeProvider>.value(
                              value: typeProv),
                          Provider<shared.MenuItemProvider>.value(
                              value: menuItemProv),
                          Provider<shared.OnboardingProgressProvider>.value(
                              value: onboardingProg),
                          Provider<shared.FranchiseSubscriptionProvider>.value(
                              value: subscriptionProv),
                        ],
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: _sections.map((section) {
                            return Builder(
                              builder: (context) {
                                try {
                                  return section.builder(context);
                                } catch (e, stack) {
                                  shared.ErrorLogger.log(
                                    message: 'Dashboard section error: $e',
                                    source: "AdminDashboardScreen",
                                    severity: "error",
                                    contextData: {
                                      'sectionTitle': section.title,
                                      'franchiseId': franchiseId,
                                    },
                                  );
                                  return Center(
                                    child: Text('Section failed: $e',
                                        style:
                                            const TextStyle(color: Colors.red)),
                                  );
                                }
                              },
                            );
                          }).toList(),
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

  Widget _buildSidebar({
    required BuildContext context,
    required List<shared.DashboardSection> mainSidebarSections,
    required List<shared.DashboardSection> onboardingSidebarSections,
    required ColorScheme colorScheme,
  }) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final section in mainSidebarSections)
          _SidebarSectionTile(
            section: section,
            isSelected: _selectedIndex < _sections.length &&
                _sections[_selectedIndex].key == section.key,
            onTap: () {
              final index = _sections.indexWhere((s) => s.key == section.key);
              if (index != -1 && index != _selectedIndex) {
                setState(() => _selectedIndex = index);
              }
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            colorScheme: colorScheme,
          ),
        if (onboardingSidebarSections.isNotEmpty) ...[
          Padding(
            padding:
                const EdgeInsets.only(top: 24, bottom: 4, left: 14, right: 10),
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
                  setState(() => _selectedIndex = index);
                }
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
              colorScheme: colorScheme,
            ),
        ],
      ],
    );
  }
}

class _SidebarSectionTile extends StatelessWidget {
  final shared.DashboardSection section;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _SidebarSectionTile({
    super.key,
    required this.section,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

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
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: colorScheme.primary.withOpacity(0.10),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
