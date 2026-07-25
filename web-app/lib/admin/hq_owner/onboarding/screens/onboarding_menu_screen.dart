import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/onboarding_step_card.dart';
import 'package:franchise_admin_portal/core/utils/onboarding_navigation_utils.dart';
import 'package:franchise_admin_portal/admin/dashboard/admin_dashboard_screen.dart';

class OnboardingMenuScreen extends StatefulWidget {
  const OnboardingMenuScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingMenuScreen> createState() => _OnboardingMenuScreenState();
}

class _OnboardingMenuScreenState extends State<OnboardingMenuScreen> {
  bool _hasLoadedFranchise = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    print('[OnboardingMenuScreen] initState');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final franchiseProvider = context.watch<shared.FranchiseProvider>();
    final infoProvider = context.watch<shared.FranchiseInfoProvider>();
    final franchiseId = franchiseProvider.franchiseId;

    print(
        '[OnboardingMenuScreen] didChangeDependencies - franchiseId: $franchiseId, hasLoaded: $_hasLoadedFranchise');

    if (!_hasLoadedFranchise &&
        franchiseId != 'unknown' &&
        franchiseId.isNotEmpty) {
      _hasLoadedFranchise = true;
      print(
          '[OnboardingMenuScreen] Valid franchiseId → forcing loadFranchiseInfo');

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await infoProvider.loadFranchiseInfo();
        if (mounted) setState(() {});
      });
    }

    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        Provider.of<shared.IngredientTypeProvider>(context, listen: false).load(
            franchiseIdOverride: franchiseId, forceReloadFromFirestore: true);
        Provider.of<shared.IngredientMetadataProvider>(context, listen: false)
            .load(forceReloadFromFirestore: true);
        Provider.of<shared.CategoryProvider>(context, listen: false).load(
            franchiseIdOverride: franchiseId, forceReloadFromFirestore: true);
        Provider.of<shared.MenuItemProvider>(context, listen: false).load(
            franchiseIdOverride: franchiseId, forceReloadFromFirestore: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final franchiseProvider = context.watch<shared.FranchiseProvider>();
    final infoProvider = context.watch<shared.FranchiseInfoProvider>();
    final progressProvider = context.watch<shared.OnboardingProgressProvider>();
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final franchiseId = franchiseProvider.franchiseId;
    final franchise = infoProvider.franchise;
    final isLoading = infoProvider.loading || franchise == null;

    print(
        '[OnboardingMenuScreen] build() - franchiseId=$franchiseId, franchise=${franchise?.name ?? "null"}, loading=$isLoading');

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading franchise data...'),
            ],
          ),
        ),
      );
    }

    if (franchiseId == 'unknown' || franchiseId.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(loc?.franchiseNotFound ?? 'Franchise not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => infoProvider.loadFranchiseInfo(),
                child: const Text('Reload Franchise'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Onboarding – ${franchise?.name ?? franchiseId}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            OnboardingStepCard(
              stepNumber: 1,
              title: loc?.stepFeatures ?? 'Features',
              subtitle: loc?.stepFeaturesDesc ?? '',
              completed:
                  progressProvider.isStepComplete('onboarding_feature_setup'),
              onTap: () =>
                  _navigateToSection(context, 'onboarding_feature_setup'),
            ),
            OnboardingStepCard(
              stepNumber: 2,
              title: loc?.coreMenuFoundation ?? 'Core Menu Foundation',
              subtitle:
                  'Build your menu foundation with types, ingredients, and categories',
              completed:
                  progressProvider.isStepComplete('onboarding_menu_foundation'),
              onTap: () =>
                  _navigateToSection(context, 'onboarding_menu_foundation'),
            ),
            OnboardingStepCard(
              stepNumber: 3,
              title: loc?.stepMenuItems ?? 'Menu Items',
              subtitle: loc?.stepMenuItemsDesc ?? '',
              completed: progressProvider.isStepComplete('onboardingMenuItems'),
              onTap: () => _navigateToSection(context, 'onboardingMenuItems'),
            ),
            OnboardingStepCard(
              stepNumber: 4,
              title: loc?.stepReview ?? 'Review & Publish',
              subtitle: loc?.stepReviewDesc ?? '',
              completed: progressProvider.isStepComplete('onboardingReview'),
              onTap: () => _navigateToSection(context, 'onboardingReview'),
            ),
            const SizedBox(height: 16),
            Text(
              loc?.progressComingSoon ?? 'More steps coming soon',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSection(BuildContext context, String sectionKey) {
    debugPrint('[OnboardingMenuScreen] Navigating to section: $sectionKey');

    // Try in-place switch first (preferred)
    final dashboardState =
        context.findAncestorStateOfType<State<AdminDashboardScreen>>();
    if (dashboardState != null) {
      // Call the public method we just added
      (dashboardState as dynamic).switchToSection(sectionKey);
      debugPrint('[OnboardingMenuScreen] ✅ Switched via public method');
      return;
    }

    // Fallback: named route
    final route = OnboardingNavigationUtils.resolveRoute(sectionKey, null);
    if (route.isNotEmpty) {
      Navigator.pushNamed(context, route).then((_) {
        debugPrint('[OnboardingMenuScreen] Navigation to $route completed');
      }).catchError((e) {
        debugPrint('[OnboardingMenuScreen] Navigation error: $e');
      });
    } else {
      Navigator.pushNamed(context, '/admin/dashboard');
    }
  }
}
