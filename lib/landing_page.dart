// File: lib/landing_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';
import 'config/design_tokens.dart';
import 'config/branding_config.dart';
import 'core/services/firestore_service.dart';
import 'widgets/dashboard/dashboard_section_card.dart';
import 'widgets/empty_state_widget.dart';

// Placeholders for screenshots and video assets
const heroScreenshot = BrandingConfig.heroScreenshot;
const adminDashboardScreenshot = BrandingConfig.adminDashboardScreenshot;
const mobileAppScreenshot = BrandingConfig.mobileAppScreenshot;
const demoVideoUrl = BrandingConfig.demoVideoUrl;

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  // Error logging for async widget build failures
  Future<void> _logError(
      BuildContext context, Object error, StackTrace? stack) async {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    try {
      await firestoreService.logError(
        'public',
        message: error.toString(),
        source: 'landing_page',
        screen: 'LandingPage',
        stackTrace: stack?.toString(),
        severity: 'error',
        contextData: {},
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: FutureBuilder(
          future: Future.value(true),
          builder: (ctx, snapshot) {
            if (snapshot.hasError) {
              // Log any build-time errors
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _logError(context, snapshot.error!, snapshot.stackTrace);
              });
              return EmptyStateWidget(
                title: loc.error,
                message: loc.pleaseTryAgain,
                imageAsset: BrandingConfig.bannerPlaceholder,
                onRetry: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LandingPage())),
                buttonText: loc.retry,
              );
            }
            // Main landing content
            return SingleChildScrollView(
              child: Column(
                children: [
                  // === HERO SECTION ===
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 48, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.89),
                          colorScheme.secondary.withOpacity(0.11),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // App Logo
                        if (BrandingConfig.logoUrl.isNotEmpty)
                          Image.network(
                            BrandingConfig.logoUrl,
                            height: 72,
                            fit: BoxFit.contain,
                          ),
                        const SizedBox(height: 24),
                        // Headline
                        Text(
                          loc.appLandingHeroHeadline,
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        // Subheadline
                        Text(
                          loc.appLandingHeroSubheadline,
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 20,
                            color: colorScheme.onPrimary.withOpacity(0.88),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 26),
                        // Hero screenshot/gallery
                        ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.network(
                            heroScreenshot,
                            height: media.size.height > 750 ? 360 : 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Main CTA buttons
                        Wrap(
                          spacing: 18,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(context).pushNamed('/login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.secondary,
                                foregroundColor: colorScheme.onSecondary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      DesignTokens.adminButtonRadius),
                                ),
                                textStyle: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Text(loc.login),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                // Open a contact/demo request (future)
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                side: BorderSide(
                                    color: colorScheme.primary, width: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 16),
                                textStyle: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Text(loc.bookDemo),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // === ABOUT SECTION ===
                  DashboardSectionCard(
                    icon: Icons.info_outline,
                    title: loc.appLandingAboutTitle,
                    builder: (context) => Text(
                      loc.appLandingAboutBody,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  // === FEATURES SECTION ===
                  DashboardSectionCard(
                    icon: Icons.star_rounded,
                    title: loc.appLandingFeaturesTitle,
                    builder: (context) => Column(
                      children: [
                        _featureRow(context, Icons.phone_android,
                            loc.featureMobileOrdering),
                        _featureRow(context, Icons.storefront,
                            loc.featureFranchiseManagement),
                        _featureRow(
                            context, Icons.menu_book, loc.featureCustomMenus),
                        _featureRow(context, Icons.attach_money,
                            loc.featureFinancialTools),
                        _featureRow(context, Icons.security,
                            loc.featureRoleBasedAccess),
                        _featureRow(
                            context, Icons.bar_chart, loc.featureAnalytics),
                        _featureRow(context, Icons.support_agent,
                            loc.featureSupportTools),
                        // Add more features as you grow!
                      ],
                    ),
                  ),
                  // === SCREENSHOTS/GALLERY SECTION ===
                  DashboardSectionCard(
                    icon: Icons.photo_library_rounded,
                    title: loc.appLandingGalleryTitle,
                    builder: (context) => _galleryGrid(context),
                  ),
                  // === DEMO VIDEO (OPTIONAL) ===
                  if (demoVideoUrl.isNotEmpty)
                    DashboardSectionCard(
                      icon: Icons.play_circle_fill_rounded,
                      title: loc.appLandingDemoTitle,
                      builder: (context) => _videoPlayerPlaceholder(context),
                    ),
                  // === DEVELOPER-ONLY SECTION (GUARD) ===
                  Consumer<UserProfileNotifier>(
                    builder: (context, userProfileNotifier, _) {
                      final user = userProfileNotifier.user;
                      final isDev = user != null &&
                          (user.roles?.contains('developer') == true ||
                              user.email == 'youradmin@email.com');
                      if (!isDev) return const SizedBox.shrink();
                      return DashboardSectionCard(
                        icon: Icons.code,
                        title: loc.devPanelTitle,
                        builder: (context) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.devPanelDesc,
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 6),
                            OutlinedButton(
                              onPressed: () {/* ... */},
                              child: Text(loc.devPanelFeatureToggles),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // === FUTURE FEATURE PLACEHOLDER ===
                  DashboardSectionCard(
                    icon: Icons.new_releases,
                    title: loc.futureFeaturesTitle,
                    builder: (context) => Text(
                      loc.futureFeaturesBody,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  // === FOOTER ===
                  _footer(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper: feature row
  Widget _featureRow(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 28),
          const SizedBox(width: 15),
          Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  // Helper: Gallery grid
  Widget _galleryGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _screenshotCard(
                context, BrandingConfig.mobileAppScreenshot, 'Mobile App'),
            _screenshotCard(context, BrandingConfig.adminDashboardScreenshot,
                'Admin Dashboard'),
            _screenshotCard(
                context, BrandingConfig.menuEditorScreenshot, 'Menu Editor'),
            // Add more screenshots as needed
          ],
        );
      },
    );
  }

  Widget _screenshotCard(BuildContext context, String url, String label) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (url.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(url, height: 150, fit: BoxFit.cover),
            ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  // Placeholder for demo video: you can swap this for an actual video player widget.
  Widget _videoPlayerPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.secondary, width: 2),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline,
              size: 60, color: colorScheme.secondary),
          const SizedBox(height: 10),
          Text(AppLocalizations.of(context)!.videoDemoPlaceholder,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text(AppLocalizations.of(context)!.watchDemo),
            onPressed: () {
              // Launch demo video (external link)
              // TODO: Use url_launcher or webview
            },
          ),
        ],
      ),
    );
  }

  // Footer section, localized and fully themed
  Widget _footer(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: isDark ? colorScheme.surfaceVariant : colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          // Contact/Social
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(BrandingConfig.primaryContact,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 16),
              Icon(Icons.public, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text('doughboyspizzeria.com',
                  style: Theme.of(context).textTheme.bodyMedium),
              // Add more socials as needed
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${loc.copyright} © ${DateTime.now().year} Doughboys Pizzeria. ${loc.allRightsReserved}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
