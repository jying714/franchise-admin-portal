// File: lib/landing_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'config/design_tokens.dart';
import 'config/branding_config.dart';
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
    // This can be connected to your logging backend if needed.
    // Removed Firestore dependency here to keep landing page pure.
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // === HERO SECTION ===
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
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
                              Navigator.of(context).pushNamed('/sign-in'),
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
              _simpleSection(
                context,
                icon: Icons.info_outline,
                title: loc.appLandingAboutTitle,
                content: loc.appLandingAboutBody,
              ),

              // === FEATURES SECTION ===
              _featuresSection(context, loc),

              // === SCREENSHOTS/GALLERY SECTION ===
              _gallerySection(context, loc),

              // === DEMO VIDEO (OPTIONAL) ===
              if (demoVideoUrl.isNotEmpty) _demoVideoSection(context, loc),

              // === FUTURE FEATURE PLACEHOLDER ===
              _simpleSection(
                context,
                icon: Icons.new_releases,
                title: loc.futureFeaturesTitle,
                content: loc.futureFeaturesBody,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Simple Section Widget without provider dependencies
  Widget _simpleSection(BuildContext context,
      {required IconData icon,
      required String title,
      required String content}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(content, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _featuresSection(BuildContext context, AppLocalizations loc) {
    final features = [
      _Feature(icon: Icons.phone_android, text: loc.featureMobileOrdering),
      _Feature(icon: Icons.storefront, text: loc.featureFranchiseManagement),
      _Feature(icon: Icons.menu_book, text: loc.featureCustomMenus),
      _Feature(icon: Icons.attach_money, text: loc.featureFinancialTools),
      _Feature(icon: Icons.security, text: loc.featureRoleBasedAccess),
      _Feature(icon: Icons.bar_chart, text: loc.featureAnalytics),
      _Feature(icon: Icons.support_agent, text: loc.featureSupportTools),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.star_rounded,
                size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(loc.appLandingFeaturesTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Column(
              children: features
                  .map((f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Icon(f.icon,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(f.text,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gallerySection(BuildContext context, AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.photo_library_rounded,
                size: 36, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(loc.appLandingGalleryTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (ctx, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _screenshotCard(context, mobileAppScreenshot, 'Mobile App'),
                    _screenshotCard(
                        context, adminDashboardScreenshot, 'Admin Dashboard'),
                    _screenshotCard(context,
                        BrandingConfig.menuEditorScreenshot, 'Menu Editor'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _demoVideoSection(BuildContext context, AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.play_circle_fill_rounded,
                size: 36, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(loc.appLandingDemoTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
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
                  Text(loc.videoDemoPlaceholder,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: Text(loc.watchDemo),
                    onPressed: () {
                      // TODO: Use url_launcher or webview to open external demo video
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
}

// Simple class to hold feature data
class _Feature {
  final IconData icon;
  final String text;

  _Feature({required this.icon, required this.text});
}
