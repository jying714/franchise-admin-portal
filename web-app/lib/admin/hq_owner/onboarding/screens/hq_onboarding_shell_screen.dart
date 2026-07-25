import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_switcher_dropdown.dart';
import 'package:franchise_admin_portal/widgets/dashboard/franchise_picker_dropdown.dart';
import 'package:franchise_admin_portal/widgets/header/help_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/notifications_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/settings_icon_button.dart';
import 'package:franchise_admin_portal/widgets/profile/user_avatar_menu.dart';
import 'package:franchise_admin_portal/widgets/admin/role_guard_widget.dart';
import 'package:franchise_admin_portal/core/providers/category_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/franchise_info_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/franchise_subscription_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/menu_item_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_progress_provider_impl.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/screens/onboarding_feature_setup_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/screens/onboarding_menu_foundation_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/screens/onboarding_menu_items_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/screens/onboarding_menu_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/screens/onboarding_review_screen.dart';

/// HQ Owner host for the 4-step franchise onboarding flow.
///
/// Phase 2 of Decision 7 migration: Continue from Owner HQ opens this shell
/// instead of [AdminDashboardScreen]. Admin onboarding tree remains intact
/// until Phase 4 cutover.
///
/// In-shell navigation: child screens call
/// `context.findAncestorStateOfType<HqOnboardingShellScreenState>()?.switchToSection(key)`.
class HqOnboardingShellScreen extends StatefulWidget {
  final String? initialSectionKey;
  final String currentScreen;

  const HqOnboardingShellScreen({
    super.key,
    this.initialSectionKey,
    this.currentScreen = 'hq-owner/onboarding',
  });

  @override
  State<HqOnboardingShellScreen> createState() =>
      HqOnboardingShellScreenState();
}

/// Public state so overview / foundation can call [switchToSection] with a
/// typed ancestor lookup (no dynamic cast required).
class HqOnboardingShellScreenState extends State<HqOnboardingShellScreen> {
  late final List<shared.DashboardSection> _sections;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _sections = _buildHqOnboardingSections();

    final key = widget.initialSectionKey ?? 'onboardingMenu';
    final index = _sections.indexWhere((s) => s.key == key);
    if (index != -1) {
      _selectedIndex = index;
    }
  }

  /// In-place section switch used by HQ [OnboardingMenuScreen] and foundation.
  void switchToSection(String sectionKey) {
    final index = _sections.indexWhere((s) => s.key == sectionKey);
    if (index != -1 && index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      debugPrint(
        '[HqOnboardingShellScreen] switchToSection: $sectionKey (index $index)',
      );
    } else if (index == -1) {
      debugPrint(
        '[HqOnboardingShellScreen] unknown section: $sectionKey',
      );
    }
  }

  List<shared.DashboardSection> _buildHqOnboardingSections() {
    return [
      shared.DashboardSection(
        key: 'onboardingMenu',
        title: 'Onboarding Overview',
        icon: Icons.list_alt_outlined,
        builder: (_) => const OnboardingMenuScreen(),
        sidebarOrder: 0,
        showInSidebar: true,
      ),
      shared.DashboardSection(
        key: 'onboarding_feature_setup',
        title: 'Step 1: Feature Setup',
        icon: Icons.tune,
        builder: (_) => const OnboardingFeatureSetupScreen(),
        sidebarOrder: 1,
        showInSidebar: true,
      ),
      shared.DashboardSection(
        key: 'onboarding_menu_foundation',
        title: 'Step 2: Core Menu Foundation',
        icon: Icons.foundation,
        builder: (_) => const OnboardingMenuFoundationScreen(),
        sidebarOrder: 2,
        showInSidebar: true,
      ),
      shared.DashboardSection(
        key: 'onboardingMenuItems',
        title: 'Step 3: Menu Items',
        icon: Icons.local_pizza_outlined,
        builder: (_) => const OnboardingMenuItemsScreen(),
        sidebarOrder: 3,
        showInSidebar: true,
      ),
      shared.DashboardSection(
        key: 'onboardingReview',
        title: 'Step 4: Review & Publish',
        icon: Icons.check_circle_outline,
        builder: (_) => const OnboardingReviewScreen(),
        sidebarOrder: 4,
        showInSidebar: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 800;
    final adminUserProvider = Provider.of<shared.AdminUserProvider>(context);
    final appUser = adminUserProvider.user;
    final franchiseProvider = context.watch<shared.FranchiseProvider>();
    final franchiseId = franchiseProvider.franchiseId;
    final loc = AppLocalizations.of(context);

    if (adminUserProvider.loading || appUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to HQ',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Icon(Icons.assignment_turned_in_outlined,
                color: DesignTokens.primaryColor, size: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                loc?.onboardingTitle ?? 'Franchise Onboarding',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
                child: _buildSidebar(context, colorScheme),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Container(
              width: 240,
              color: colorScheme.surface,
              child: SafeArea(
                child: _buildSidebar(context, colorScheme),
              ),
            ),
          Expanded(
            child: Builder(
              builder: (context) {
                return MultiProvider(
                  providers: [
                    Provider<shared.FranchiseSubscriptionProvider>.value(
                      value: Provider.of<FranchiseSubscriptionProviderImpl>(
                        context,
                        listen: false,
                      ),
                    ),
                    Provider<shared.CategoryProvider>.value(
                      value: Provider.of<CategoryProviderImpl>(
                        context,
                        listen: false,
                      ),
                    ),
                    Provider<shared.IngredientTypeProvider>.value(
                      value: Provider.of<IngredientTypeProviderImpl>(
                        context,
                        listen: false,
                      ),
                    ),
                    Provider<shared.IngredientMetadataProvider>.value(
                      value: Provider.of<IngredientMetadataProviderImpl>(
                        context,
                        listen: false,
                      ),
                    ),
                    Provider<shared.MenuItemProvider>.value(
                      value: Provider.of<MenuItemProviderImpl>(
                        context,
                        listen: false,
                      ),
                    ),
                    Provider<shared.FranchiseInfoProvider>.value(
                      value: Provider.of<FranchiseInfoProviderImpl>(
                        context,
                        listen: false,
                      ),
                    ),
                    Provider<shared.OnboardingProgressProvider>.value(
                      value: Provider.of<OnboardingProgressProviderImpl>(
                        context,
                        listen: false,
                      ),
                    ),
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
                              message: 'HQ onboarding section error: $e',
                              source: 'HqOnboardingShellScreen',
                              severity: 'error',
                              contextData: {
                                'sectionKey': section.key,
                                'sectionTitle': section.title,
                                'franchiseId': franchiseId,
                                'stack': stack.toString(),
                              },
                            );
                            return Center(
                              child: Text(
                                'Section failed: $e',
                                style: const TextStyle(color: Colors.red),
                              ),
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
    );
  }

  Widget _buildSidebar(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
        for (var i = 0; i < _sections.length; i++)
          _HqSidebarTile(
            section: _sections[i],
            isSelected: i == _selectedIndex,
            onTap: () {
              if (i != _selectedIndex) {
                setState(() => _selectedIndex = i);
              }
              if (Navigator.of(context).canPop() &&
                  MediaQuery.of(context).size.width < 800) {
                Navigator.of(context).pop();
              }
            },
            colorScheme: colorScheme,
          ),
      ],
    );
  }
}

class _HqSidebarTile extends StatelessWidget {
  final shared.DashboardSection section;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _HqSidebarTile({
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
