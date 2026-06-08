import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/onboarding_step_card.dart';

class OnboardingMenuScreen extends StatefulWidget {
  const OnboardingMenuScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingMenuScreen> createState() => _OnboardingMenuScreenState();
}

class _OnboardingMenuScreenState extends State<OnboardingMenuScreen> {
  String? _franchiseId;
  int _loadAttempts = 0;
  bool _isLoading = true;

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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newFranchiseId =
        context.watch<shared.FranchiseProvider>().franchiseId;
    print('[OnboardingMenuScreen] Detected franchiseId: $newFranchiseId');

    if (newFranchiseId != _franchiseId &&
        newFranchiseId != 'unknown' &&
        newFranchiseId.isNotEmpty) {
      _franchiseId = newFranchiseId;
      _loadAttempts = 0;
      _triggerLoadFranchiseInfo();
    }
  }

  void _triggerLoadFranchiseInfo() {
    if (_loadAttempts >= 5) {
      print('[OnboardingMenuScreen] Max load attempts reached');
      setState(() => _isLoading = false);
      return;
    }

    _loadAttempts++;
    print(
        '[OnboardingMenuScreen] Triggering loadFranchiseInfo() attempt $_loadAttempts');

    Future.delayed(Duration(milliseconds: 100 * _loadAttempts), () {
      if (!mounted) return;
      final infoProvider =
          Provider.of<shared.FranchiseInfoProvider>(context, listen: false);
      final franchiseProvider =
          Provider.of<shared.FranchiseProvider>(context, listen: false);

      // Extra force
      if (franchiseProvider.franchiseId == 'test') {
        franchiseProvider.forceRefreshFranchiseId('test');
      }
      infoProvider.loadFranchiseInfo();
    });
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
    final isLoading = infoProvider.loading || _isLoading;

    print(
        '[OnboardingMenuScreen] build() called - franchiseId=$franchiseId, franchise=${franchise?.name}, loading=$isLoading');

    if (isLoading || franchise == null) {
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
                onPressed: _triggerLoadFranchiseInfo,
                child: const Text('Reload Franchise'),
              ),
            ],
          ),
        ),
      );
    }

    // Normal UI
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Onboarding - ${franchise.name}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            // Your OnboardingStepCard list here (keep your existing cards)
            OnboardingStepCard(
              stepNumber: 1,
              title: loc?.stepFeatures ?? 'Features',
              subtitle: loc?.stepFeaturesDesc ?? '',
              completed: _stepCompletion['features'] ?? false,
              onTap: () => _navigateToSection(context, 'onboardingFeatures'),
            ),
            // ... add the rest of your step cards (ingredients, categories, menuItems, review) ...
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
    Navigator.pushNamed(context, '/dashboard?section=$sectionKey');
  }
}
