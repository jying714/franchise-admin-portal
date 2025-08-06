// File: lib/admin/dashboard/onboarding/screens/onboarding_review_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_review_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider.dart';
import 'package:franchise_admin_portal/core/providers/category_provider.dart';
import 'package:franchise_admin_portal/core/providers/menu_item_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_feature_provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/onboarding_progress_indicator.dart';
import 'package:franchise_admin_portal/core/services/audit_log_service.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/user_profile_notifier.dart';
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
  late OnboardingReviewProvider _reviewProvider;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // ReviewProvider initialized in didChangeDependencies after all context Providers are available.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only instantiate if not already
    if (!mounted || _loading == false) return;
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
      _initValidation();
    } catch (e, st) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _initValidation() async {
    try {
      setState(() => _loading = true);
      await _reviewProvider.validateAll();
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider<OnboardingReviewProvider>.value(
      value: _reviewProvider,
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
              // Progress indicator and stepper consistent with other onboarding screens
              Padding(
                padding: const EdgeInsets.only(
                    top: 12.0, left: 16, right: 16, bottom: 6),
                child: OnboardingProgressIndicator(
                  currentStep: 6,
                  totalSteps: 6,
                  stepLabel: loc.onboardingStepLabel(6, 6), // "Step 6 of 6"
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

/// The main content scaffold for the review step.
/// This widget should lay out the grid/column structure for:
///  - Review summary table
///  - Issue drilldown/expansion
///  - Data export/download
///  - Publish button & confirmation
///  - Audit trail/history
/// All widgets should match the onboarding theme and spacing.

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1000;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== Title & Description =====
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

                // ===== Main Content: Summary table and details =====
                Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Left/Main Column: Review Summary Table + Drilldown + Data Export ---
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
                              // --- (Step 6) Review Summary Table Widget Here ---
                              ReviewSummaryTable(),

                              // --- (Step 7) Issue Drilldown/Expansion Widget Here ---
                              IssueDetailsExpansion(),

                              // --- (Step 8) Data Export/Download Widget Here ---
                              OnboardingDataExportButton(),

                              // Spacer for button row
                              const SizedBox(height: 32),

                              // --- (Step 9) Publish Button & Confirmation Dialog Widget Here ---
                              PublishOnboardingButton(
                                franchiseId: franchiseId,
                                userId: userId,
                              ),

                              // Info note about publish state
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
                    // --- Right Column: Audit Trail, future info panel, etc. ---
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
                                // --- (Step 10) Audit Trail/History Widget Here ---
                                OnboardingAuditTrail(franchiseId: franchiseId),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Spacer to keep publish button above bottom nav in mobile layout
                const SizedBox(height: 26),
              ],
            ),
          ),
        );
      },
    );
  }
}
