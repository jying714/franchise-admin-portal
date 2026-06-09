import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/onboarding_step_card.dart';

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
    final isLoading = infoProvider.loading ||
        franchise == null; // ← CHANGED: removed _hasLoadedFranchise dependency

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

    // Fully loaded UI (unchanged from your code)
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
              completed: progressProvider.isStepComplete('ingredientTypes'),
              onTap: () => _navigateToSection(context, 'onboardingFeatures'),
            ),
            OnboardingStepCard(
              stepNumber: 2,
              title: loc?.stepIngredients ?? 'Ingredients',
              subtitle: loc?.stepIngredientsDesc ?? '',
              completed: progressProvider.isStepComplete('ingredients'),
              onTap: () => _navigateToSection(context, 'onboardingIngredients'),
            ),
            OnboardingStepCard(
              stepNumber: 3,
              title: loc?.stepCategories ?? 'Categories',
              subtitle: loc?.stepCategoriesDesc ?? '',
              completed: progressProvider.isStepComplete('categories'),
              onTap: () => _navigateToSection(context, 'onboardingCategories'),
            ),
            OnboardingStepCard(
              stepNumber: 4,
              title: loc?.stepMenuItems ?? 'Menu Items',
              subtitle: loc?.stepMenuItemsDesc ?? '',
              completed: progressProvider.isStepComplete('menuItems'),
              onTap: () => _navigateToSection(context, 'onboardingMenuItems'),
            ),
            OnboardingStepCard(
              stepNumber: 5,
              title: loc?.stepReview ?? 'Review & Publish',
              subtitle: loc?.stepReviewDesc ?? '',
              completed: progressProvider.isStepComplete('review'),
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
    Navigator.pushNamed(context, '/admin/dashboard?section=$sectionKey');
  }
}
