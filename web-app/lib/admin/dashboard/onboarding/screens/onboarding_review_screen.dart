// File: lib/admin/dashboard/onboarding/screens/onboarding_review_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/onboarding_review_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/ingredient_type_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/ingredient_metadata_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/category_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/menu_item_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/franchise_feature_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/onboarding_progress_indicator.dart';
import '../../../../../../packages/shared_core/lib/src/core/services/audit_log_service.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/franchise_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/user_profile_notifier.dart';
// Import future widgets here as they are implemented
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/review/review_summary_table.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/review/issue_details_expansion.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/review/onboarding_data_export_button.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/review/publish_onboarding_button.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/review/onboarding_audit_trail.dart';

class OnboardingReviewScreen extends StatefulWidget {
  const OnboardingReviewScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingReviewScreen> createState() => _OnboardingReviewScreenState();
}

class _OnboardingReviewScreenState extends State<OnboardingReviewScreen> {
  OnboardingReviewProvider? _reviewProvider;
  bool _providerReady = false;
  bool _loading = true;
  String? _error;

  // Guards
  bool _didKickOffValidation = false;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    // Initial validation will be scheduled after dependencies resolve.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only set up provider & initial validation once.
    if (!_providerReady) {
      try {
        final franchiseFeatureProvider =
            Provider.of<FranchiseFeatureProvider>(context, listen: false);
        final ingredientTypeProvider =
            Provider.of<IngredientTypeProvider>(context, listen: false);
        final ingredientMetadataProvider =
            Provider.of<IngredientMetadataProvider>(context, listen: false);
        final categoryProvider =
            Provider.of<CategoryProvider>(context, listen: false);
        final menuItemProvider =
            Provider.of<MenuItemProvider>(context, listen: false);
        final firestoreService =
            Provider.of<FirestoreService>(context, listen: false);
        final auditLogService =
            Provider.of<AuditLogService>(context, listen: false);

        _reviewProvider = OnboardingReviewProvider(
          franchiseFeatureProvider: franchiseFeatureProvider,
          ingredientTypeProvider: ingredientTypeProvider,
          ingredientMetadataProvider: ingredientMetadataProvider,
          categoryProvider: categoryProvider,
          menuItemProvider: menuItemProvider,
          firestoreService: firestoreService,
          auditLogService: auditLogService,
        );

        _providerReady = true;
        setState(() {});

        // Schedule first validation after build completes.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scheduleFirstValidation();
        });
      } catch (e) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  bool _providersReady() {
    final types = context.read<IngredientTypeProvider>().ingredientTypes;
    final ingredients = context.read<IngredientMetadataProvider>().ingredients;
    final categories = context.read<CategoryProvider>().categories;
    final menuItems = context.read<MenuItemProvider>().menuItems;

    return types != null &&
        ingredients != null &&
        categories != null &&
        menuItems != null;
  }

  void _scheduleFirstValidation() {
    if (_didKickOffValidation) return;
    if (!_providersReady()) return;
    if (!mounted || _reviewProvider == null) return;

    _didKickOffValidation = true;
    debugPrint(
        '[OnboardingReviewScreen] ⏩ Triggering initial _initValidation()...');
    _initValidation();
  }

  Future<void> _initValidation() async {
    if (_isValidating) {
      debugPrint(
          '[OnboardingReviewScreen._initValidation] 🚫 Validation already running, skipping.');
      return;
    }
    _isValidating = true;

    try {
      setState(() => _loading = true);

      final franchiseId =
          Provider.of<FranchiseProvider>(context, listen: false).franchiseId;

      debugPrint(
          '\n[OnboardingReviewScreen._initValidation] 🚀 Starting validation for franchise "$franchiseId"...');

      // Reload only if needed; avoids unnecessary Firestore hits
      await Provider.of<IngredientMetadataProvider>(context, listen: false)
          .load(forceReloadFromFirestore: false);

      await Provider.of<IngredientTypeProvider>(context, listen: false)
          .loadIngredientTypes(franchiseId, forceReloadFromFirestore: false);

      await Provider.of<CategoryProvider>(context, listen: false)
          .loadCategories(franchiseId, forceReloadFromFirestore: false);

      await Provider.of<MenuItemProvider>(context, listen: false)
          .loadMenuItems(franchiseId, forceReloadFromFirestore: false);

      debugPrint(
          '[OnboardingReviewScreen._initValidation] ✅ Providers loaded, running validateAll()...');

      await _reviewProvider?.validateAll();

      setState(() {
        _loading = false;
        _error = null;
      });

      final issueCount = _reviewProvider?.validationResults.length ?? 0;
      debugPrint(
          '[OnboardingReviewScreen._initValidation] 🎯 Validation complete. Issues found: $issueCount');
    } catch (e, st) {
      debugPrint('[OnboardingReviewScreen._initValidation][ERROR] ❌ $e\n$st');
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    } finally {
      _isValidating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // Trigger rebuild when dependent providers change
    final _ = (
      context.watch<IngredientTypeProvider>().ingredientTypes,
      context.watch<IngredientMetadataProvider>().ingredients,
      context.watch<CategoryProvider>().categories,
      context.watch<MenuItemProvider>().menuItems
    );

    if (!_providerReady || _reviewProvider == null) {
      return Scaffold(
        backgroundColor: DesignTokens.backgroundColor,
        appBar: AppBar(
          title: Text(loc.onboardingReviewPublishTitle ?? "Review & Publish"),
          backgroundColor: colorScheme.surface,
          elevation: DesignTokens.adminCardElevation,
          iconTheme: IconThemeData(color: DesignTokens.appBarIconColor),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _scheduleFirstValidation();

    return ChangeNotifierProvider<OnboardingReviewProvider>.value(
      value: _reviewProvider!,
      child: Scaffold(
        backgroundColor: DesignTokens.backgroundColor,
        appBar: AppBar(
          title: Text(loc.onboardingReviewPublishTitle ?? "Review & Publish"),
          backgroundColor: colorScheme.surface,
          elevation: DesignTokens.adminCardElevation,
          iconTheme: IconThemeData(color: DesignTokens.appBarIconColor),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    top: 12.0, left: 16, right: 16, bottom: 6),
                child: OnboardingProgressIndicator(
                  currentStep: 6,
                  totalSteps: 6,
                  stepLabel: loc.onboardingStepLabel(6, 6),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: EmptyStateWidget(
                              iconData: Icons.error_outline,
                              title:
                                  loc.onboardingReviewFailed ?? "Review Failed",
                              message: _error!,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                            child: _OnboardingReviewContent(),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingReviewContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final reviewProvider = Provider.of<OnboardingReviewProvider>(context);
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    final userId =
        Provider.of<UserProfileNotifier>(context, listen: false).user?.id ?? '';

    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Map<String, dynamic> && routeArgs['focusItemId'] != null) {
      debugPrint(
        '[OnboardingReviewScreen] Focus requested for ingredientId="${routeArgs['focusItemId']}". '
        'Delegating to OnboardingIngredientsScreen to handle scrolling/highlighting.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1000;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    loc.onboardingReviewPublishTitle ?? "Review & Publish",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      letterSpacing: 0.2,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    loc.onboardingReviewPublishDesc ??
                        "Check for any missing information or schema issues before going live. All critical issues must be resolved.",
                    style: TextStyle(
                      fontSize: 17,
                      color: colorScheme.onBackground.withOpacity(0.74),
                      fontWeight: FontWeight.w400,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ),
                Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Card(
                        elevation: DesignTokens.adminCardElevation,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.adminCardRadius),
                        ),
                        color: colorScheme.surface,
                        margin: const EdgeInsets.only(bottom: 18, right: 18),
                        child: Padding(
                          padding: const EdgeInsets.all(22.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FocusTraversalGroup(
                                policy: OrderedTraversalPolicy(),
                                child: ReviewSummaryTable(),
                              ),
                              IssueDetailsExpansion(),
                              OnboardingDataExportButton(),
                              const SizedBox(height: 32),
                              PublishOnboardingButton(
                                franchiseId: franchiseId,
                                userId: userId,
                              ),
                              reviewProvider.isPublishable
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: Colors.green[700],
                                              size: 22),
                                          const SizedBox(width: 10),
                                          Flexible(
                                            child: Text(
                                              loc.onboardingReviewReadyToPublish ??
                                                  "All required information is complete. Ready to publish.",
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded,
                                              color: colorScheme.error,
                                              size: 22),
                                          const SizedBox(width: 10),
                                          Flexible(
                                            child: Text(
                                              loc.onboardingReviewFixErrors ??
                                                  "Resolve all blocking issues before you can publish.",
                                              style: TextStyle(
                                                color: colorScheme.error,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isWide)
                      Expanded(
                        flex: 3,
                        child: Card(
                          elevation: DesignTokens.adminCardElevation,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                DesignTokens.adminCardRadius),
                          ),
                          color: colorScheme.surface,
                          margin: const EdgeInsets.only(bottom: 18),
                          child: Padding(
                            padding: const EdgeInsets.all(22.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OnboardingAuditTrail(franchiseId: franchiseId),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 26),
              ],
            ),
          ),
        );
      },
    );
  }
}
