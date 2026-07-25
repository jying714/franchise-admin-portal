// File: lib/admin/hq_owner/onboarding/screens/onboarding_review_screen.dart

import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/onboarding_progress_indicator.dart';
// Import future widgets here as they are implemented
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/review/review_summary_table.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/review/issue_details_expansion.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/review/onboarding_data_export_button.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/review/publish_onboarding_button.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/review/onboarding_audit_trail.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_review_provider_impl.dart';

class OnboardingReviewScreen extends StatefulWidget {
  const OnboardingReviewScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingReviewScreen> createState() => _OnboardingReviewScreenState();
}

class _OnboardingReviewScreenState extends State<OnboardingReviewScreen> {
  OnboardingReviewProviderImpl? _reviewProvider;
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
            Provider.of<shared.FranchiseFeatureProvider>(context,
                listen: false);
        final ingredientTypeProvider =
            Provider.of<shared.IngredientTypeProvider>(context, listen: false);
        final ingredientMetadataProvider =
            Provider.of<shared.IngredientMetadataProvider>(context,
                listen: false);
        final categoryProvider =
            Provider.of<shared.CategoryProvider>(context, listen: false);
        final menuItemProvider =
            Provider.of<shared.MenuItemProvider>(context, listen: false);
        final firestoreService =
            Provider.of<shared.FirestoreService>(context, listen: false);
        final auditLogService =
            Provider.of<shared.AuditLogService>(context, listen: false);

        _reviewProvider = OnboardingReviewProviderImpl(
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
    final types =
        Provider.of<shared.IngredientTypeProvider>(context, listen: false)
            .ingredientTypes;
    final ingredients =
        Provider.of<shared.IngredientMetadataProvider>(context, listen: false)
            .ingredients;
    final categories =
        Provider.of<shared.CategoryProvider>(context, listen: false).categories;
    final menuItems =
        Provider.of<shared.MenuItemProvider>(context, listen: false).menuItems;

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
        '[OnboardingReviewScreen] â© Triggering initial _initValidation()...');
    _initValidation();
  }

  Future<void> _initValidation() async {
    if (_isValidating) {
      debugPrint(
          '[OnboardingReviewScreen._initValidation] ðŸš« Validation already running, skipping.');
      return;
    }
    _isValidating = true;

    try {
      setState(() => _loading = true);

      final franchiseId =
          Provider.of<shared.FranchiseProvider>(context, listen: false)
              .franchiseId;

      debugPrint(
          '\n[OnboardingReviewScreen._initValidation] ðŸš€ Starting validation for franchise "$franchiseId"...');

      // Reload only if needed; avoids unnecessary Firestore hits
      await Provider.of<shared.IngredientMetadataProvider>(context,
              listen: false)
          .load(forceReloadFromFirestore: false);

      await Provider.of<shared.IngredientTypeProvider>(context, listen: false)
          .load(
              franchiseIdOverride: franchiseId,
              forceReloadFromFirestore: false);

      await Provider.of<shared.CategoryProvider>(context, listen: false).load(
          franchiseIdOverride: franchiseId, forceReloadFromFirestore: false);

      await Provider.of<shared.MenuItemProvider>(context, listen: false).load(
          franchiseIdOverride: franchiseId, forceReloadFromFirestore: false);

      debugPrint(
          '[OnboardingReviewScreen._initValidation] âœ… Providers loaded, running validateAll()...');

      await _reviewProvider?.validateAll();

      setState(() {
        _loading = false;
        _error = null;
      });

      final issueCount = _reviewProvider?.validationResults.length ?? 0;
      debugPrint(
          '[OnboardingReviewScreen._initValidation] ðŸŽ¯ Validation complete. Issues found: $issueCount');
    } catch (e, st) {
      debugPrint('[OnboardingReviewScreen._initValidation][ERROR] âŒ $e\n$st');
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
      context.watch<shared.IngredientTypeProvider>().ingredientTypes,
      context.watch<shared.IngredientMetadataProvider>().ingredients,
      context.watch<shared.CategoryProvider>().categories,
      context.watch<shared.MenuItemProvider>().menuItems
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

    return ChangeNotifierProvider<OnboardingReviewProviderImpl>.value(
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
                  currentStep: 4,
                  totalSteps: 4,
                  stepLabel: loc.onboardingStepLabel(4, 4),
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

    // Use concrete Impl here because the local ChangeNotifierProvider.value in build provides the Impl
    final reviewProvider =
        Provider.of<OnboardingReviewProviderImpl>(context, listen: true);

    final franchiseId =
        Provider.of<shared.FranchiseProvider>(context, listen: false)
            .franchiseId;
    final userId = Provider.of<shared.AdminUserProvider>(context, listen: false)
            .user
            ?.id ??
        '';

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
                                              color: colorScheme.primary,
                                              size: 22),
                                          const SizedBox(width: 10),
                                          Flexible(
                                            child: Text(
                                              loc.onboardingReviewReadyToPublish ??
                                                  "All required information is complete. Ready to publish.",
                                              style: TextStyle(
                                                color: colorScheme.primary,
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
