import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/models/franchise_info.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';
import 'package:franchise_admin_portal/core/utils/role_guard.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/providers/franchise_info_provider.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/onboarding_step_card.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_progress_provider.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_intredient_type_screen.dart';

class OnboardingMenuScreen extends StatefulWidget {
  const OnboardingMenuScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingMenuScreen> createState() => _OnboardingMenuScreenState();
}

class _OnboardingMenuScreenState extends State<OnboardingMenuScreen> {
  String? franchiseId;
  String? _franchiseName;
  bool loading = true;

  final Map<String, bool> _stepCompletion = {
    'ingredients': false,
    'categories': false,
    'menuItems': false,
    'review': false,
  };

  @override
  void initState() {
    super.initState();
    print('[OnboardingMenuScreen] initState');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newFranchiseId = context.watch<FranchiseProvider>().franchiseId;
    if (newFranchiseId != franchiseId) {
      setState(() {
        franchiseId = newFranchiseId;
      });
      print('[OnboardingMenuScreen] Detected new franchiseId: $franchiseId');
    }
  }

  void _markStepComplete(String key) {
    setState(() {
      _stepCompletion[key] = true;
    });
    print('[OnboardingMenuScreen] Step marked complete: $key');
  }

  @override
  Widget build(BuildContext context) {
    print('[OnboardingMenuScreen] build() called');

    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<UserProfileNotifier>().user;
    final franchiseInfoProvider = context.watch<FranchiseInfoProvider>();
    final franchise = franchiseInfoProvider.franchise;
    final isLoading = franchiseInfoProvider.loading;

    final onboardingProgressProvider =
        context.watch<OnboardingProgressProvider>();
    final progress = onboardingProgressProvider.stepStatus;

    print('[OnboardingMenuScreen] progress: $progress');

    if (isLoading || onboardingProgressProvider.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (franchise == null) {
      return const Scaffold(
        body: Center(child: Text('Franchise not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.onboardingMenuTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.onboardingFor}: ${franchise.name} (#${franchise.id})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  OnboardingStepCard(
                    stepNumber: 1,
                    title: loc.stepIngredientTypes,
                    subtitle: loc.stepIngredientTypesDesc,
                    completed: progress['ingredientTypes'] == true,
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/dashboard?section=onboardingIngredientTypes',
                        (route) => false,
                      );
                    },
                  ),
                  OnboardingStepCard(
                    stepNumber: 2,
                    title: loc.stepIngredients,
                    subtitle: loc.stepIngredientsDesc,
                    completed: progress['ingredients'] == true,
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/dashboard?section=onboardingIngredients',
                        (route) => false,
                      );
                    },
                  ),
                  OnboardingStepCard(
                    stepNumber: 3,
                    title: loc.stepCategories,
                    subtitle: loc.stepCategoriesDesc,
                    completed: progress['categories'] == true,
                    onTap: () => Navigator.of(context)
                        .pushNamed('/onboarding/categories'),
                  ),
                  OnboardingStepCard(
                    stepNumber: 4,
                    title: loc.stepMenuItems,
                    subtitle: loc.stepMenuItemsDesc,
                    completed: progress['menuItems'] == true,
                    onTap: () => Navigator.of(context)
                        .pushNamed('/onboarding/menu_items'),
                  ),
                  OnboardingStepCard(
                    stepNumber: 5,
                    title: loc.stepReview,
                    subtitle: loc.stepReviewDesc,
                    completed: progress['review'] == true,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/onboarding/review'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.progressComingSoon,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
