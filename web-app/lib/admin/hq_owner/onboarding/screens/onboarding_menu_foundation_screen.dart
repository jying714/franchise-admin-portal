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

class FoundationFocusRequest {
  static bool showOrphansOnly = false;
  static String? firstOrphanId;

  static void clear() {
    showOrphansOnly = false;
    firstOrphanId = null;
  }
}

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
        Provider.of<shared.IngredientTypeProvider>(context, listen: false).load(
            franchiseIdOverride: franchiseId, forceReloadFromFirestore: true);
        Provider.of<shared.IngredientMetadataProvider>(context, listen: false)
            .load(forceReloadFromFirestore: true);
        Provider.of<shared.CategoryProvider>(context, listen: false).load(
            franchiseIdOverride: franchiseId, forceReloadFromFirestore: true);
        Provider.of<shared.MenuItemProvider>(context, listen: false).load(
            franchiseIdOverride: franchiseId, forceReloadFromFirestore: true);
      }

      // Menu Items CTA: land on Ingredients tab (index 1).
      if (FoundationFocusRequest.showOrphansOnly) {
        _tabController.index = 1;
        setState(() {});
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

    final typeProvider = context.watch<shared.IngredientTypeProvider>();
    final ingredientProvider =
        context.watch<shared.IngredientMetadataProvider>();
    final categoryProvider = context.watch<shared.CategoryProvider>();

    final typeCount = typeProvider.ingredientTypes.length;
    final categoryCount = categoryProvider.categories.length;
    final allIngredients = ingredientProvider.ingredients;
    final typeIds =
        typeProvider.ingredientTypes.map((t) => (t.id ?? '').trim()).toSet();
    bool isOrphan(shared.IngredientMetadata i) {
      final tid = (i.typeId ?? '').trim();
      return tid.isEmpty || !typeIds.contains(tid);
    }

    final orphanCount = allIngredients.where(isOrphan).length;
    final typedIngredientCount = allIngredients.length - orphanCount;

    // Live readiness 0–1 for the bottom label (not the old sub-step flags).
    double liveFoundationProgress = 0.0;
    if (typeCount >= 1) liveFoundationProgress += 0.25;
    if (categoryCount >= 1) liveFoundationProgress += 0.25;
    if (typedIngredientCount >= 5) liveFoundationProgress += 0.35;
    if (orphanCount == 0 && allIngredients.isNotEmpty) {
      liveFoundationProgress += 0.15;
    }
    liveFoundationProgress = liveFoundationProgress.clamp(0.0, 1.0);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        title: Text(
          loc?.coreMenuFoundationTitle ?? 'Step 2: Core Menu Foundation',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showTemplateDialog,
            icon: Icon(Icons.file_download_outlined,
                color: colorScheme.onSurface),
            label: Text(
              'Quick Start with Template',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
          // Selection = weight/size, not franchise primary (avoids red on “test”)
          labelColor: colorScheme.onSurface,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.55),
          labelStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          indicatorColor: colorScheme.onSurface,
          indicatorWeight: 2.5,
          dividerColor: theme.dividerColor,
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
                'Foundation Progress: ${(liveFoundationProgress * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ElevatedButton(
                onPressed: () async {
                  final failures = <String>[];
                  if (typeCount < 1) {
                    failures.add(
                        'Need at least 1 ingredient type (have $typeCount)');
                  }
                  if (categoryCount < 1) {
                    failures
                        .add('Need at least 1 category (have $categoryCount)');
                  }
                  if (typedIngredientCount < 5) {
                    failures.add(
                      'Need at least 5 ingredients with a type (have $typedIngredientCount)',
                    );
                  }
                  if (orphanCount > 0) {
                    failures.add(
                      '$orphanCount ingredient(s) missing a type — assign types before continuing',
                    );
                  }

                  if (failures.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(failures.join(' · '))),
                    );
                    return;
                  }

                  await progressProvider
                      .markStepComplete('onboarding_menu_foundation');

                  final hqShell = context
                      .findAncestorStateOfType<HqOnboardingShellScreenState>();
                  if (hqShell != null) {
                    hqShell.switchToSection('onboardingMenuItems');
                    return;
                  }

                  debugPrint(
                    '[OnboardingMenuFoundationScreen] ⚠️ No HQ shell; stay on foundation',
                  );
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
