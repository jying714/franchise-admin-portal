import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/screens/onboarding_ingredient_type_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/screens/onboarding_ingredients_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/screens/onboarding_categories_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/foundation/template_import_dialog.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/foundation/mobile_menu_preview_card.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/screens/hq_onboarding_shell_screen.dart';

class OnboardingMenuFoundationScreen extends StatefulWidget {
  const OnboardingMenuFoundationScreen({super.key});

  @override
  State<OnboardingMenuFoundationScreen> createState() =>
      _OnboardingMenuFoundationScreenState();
}

class _OnboardingMenuFoundationScreenState
    extends State<OnboardingMenuFoundationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabTitles = [
    'Ingredient Types',
    'Ingredients',
    'Categories'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Load data after first frame to avoid build-phase assertions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final franchiseProvider = Provider.of<shared.FranchiseProvider>(
        context,
        listen: false,
      );
      final franchiseId = franchiseProvider.franchiseId;

      if (franchiseId.isNotEmpty) {
        Provider.of<shared.CategoryProvider>(context, listen: false).load(
            franchiseIdOverride: franchiseId, forceReloadFromFirestore: true);

        Provider.of<shared.MenuItemProvider>(context, listen: false).load(
            franchiseIdOverride: franchiseId, forceReloadFromFirestore: true);
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) setState(() {});
  }

  Future<void> _showTemplateDialog() async {
    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder: (context) => const TemplateImportDialog(),
    );

    if (result != null && mounted) {
      // Phase 3 will handle actual import here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Template import is not wired yet — use tabs to add types, ingredients, and categories.',
          ),
        ),
      );

      // Refresh providers - use Provider.of pattern from reference file
      final franchiseProvider =
          Provider.of<shared.FranchiseProvider>(context, listen: false);
      final franchiseId = franchiseProvider.franchiseId;

      if (franchiseId.isNotEmpty) {
        Provider.of<shared.IngredientTypeProvider>(context, listen: false).load(
            franchiseIdOverride: franchiseId, forceReloadFromFirestore: true);
        Provider.of<shared.IngredientMetadataProvider>(context, listen: false)
            .load(forceReloadFromFirestore: true);
        Provider.of<shared.CategoryProvider>(context, listen: false).load(
            franchiseIdOverride: franchiseId, forceReloadFromFirestore: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final progressProvider = context.watch<shared.OnboardingProgressProvider>();
    final franchiseProvider = context.watch<shared.FranchiseProvider>();
    final franchiseId = franchiseProvider.franchiseId;
    final foundationProgress =
        progressProvider.getFoundationProgress(); // from Phase 1

    return Scaffold(
      appBar: AppBar(
        title: Text(
            loc?.coreMenuFoundationTitle ?? 'Step 2: Core Menu Foundation'),
        actions: [
          TextButton.icon(
            onPressed: _showTemplateDialog,
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Quick Start with Template'),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
          labelColor: shared.UiConfig.primaryColor,
          indicatorColor: shared.UiConfig.primaryColor,
        ),
      ),
      body: Row(
        children: [
          // Main Content - Tabs
          Expanded(
            flex: 7,
            child: TabBarView(
              controller: _tabController,
              children: const [
                IngredientTypeManagementScreen(),
                OnboardingIngredientsScreen(),
                OnboardingCategoriesScreen(),
              ],
            ),
          ),
          // Right Sidebar - Mobile Preview
          // Right Sidebar - Mobile Preview
          // Right Sidebar - Mobile Preview
          // Right Sidebar - Mobile Preview
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(color: Theme.of(context).dividerColor)),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: MobileMenuPreviewCard(
                franchiseId: franchiseId,
                currentTabIndex: _tabController.index,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Foundation Progress: ${(foundationProgress * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ElevatedButton(
                onPressed: () async {
                  if (foundationProgress >= 0.8) {
                    await progressProvider
                        .markStepComplete('onboarding_menu_foundation');

                    final hqShell = context.findAncestorStateOfType<
                        HqOnboardingShellScreenState>();
                    if (hqShell != null) {
                      hqShell.switchToSection('onboardingMenuItems');
                      return;
                    }

                    debugPrint(
                      '[OnboardingMenuFoundationScreen] ⚠️ No HQ shell; stay on foundation',
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Complete minimum requirements (3 categories, 10+ ingredients)',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Save Foundation & Continue to Menu Items'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
