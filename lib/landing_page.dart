import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'config/design_tokens.dart';
import 'config/branding_config.dart';
import 'widgets/empty_state_widget.dart';
import 'dart:ui';

// Demo asset URLs (swap for real URLs in production)
const heroScreenshot =
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?fit=crop&w=900&q=80';
const adminDashboardScreenshot =
    'https://images.unsplash.com/photo-1464983953574-0892a716854b?fit=crop&w=900&q=80';
const mobileAppScreenshot =
    'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?fit=crop&w=900&q=80';
const menuEditorScreenshot =
    'https://images.unsplash.com/photo-1526178613658-3f1622045567?fit=crop&w=900&q=80';
const demoVideoUrl = ''; // e.g., 'https://www.youtube.com/watch?v=xxxx'

class GlassHero extends StatelessWidget {
  final bool isMobile;
  const GlassHero({required this.isMobile, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('[landing_page.dart] build: Unauthenticated landing page');
    final colorScheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 1000),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 28 : 52,
        horizontal: isMobile ? 0 : 0,
      ),
      child: Stack(
        children: [
          // Glassmorphism card
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.82),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                    width: 1.5,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 34 : 52,
                  horizontal: isMobile ? 20 : 44,
                ),
                child: isMobile
                    ? _verticalContent(context)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _verticalContent(context)),
                          const SizedBox(width: 32),
                          // Hero Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.network(
                              heroScreenshot,
                              width: 320,
                              height: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[100], height: 220),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 700;

    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (BrandingConfig.logoUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Image.network(
              BrandingConfig.logoUrl,
              height: 68,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => SizedBox(),
            ),
          ),
        Text(
          "The Modern Franchise Platform",
          style: TextStyle(
            fontSize: isMobile ? 21 : 28,
            color: Colors.green[700],
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "All-in-One SaaS for Food Service Franchises",
          style: TextStyle(
            fontSize: isMobile ? 34 : 48,
            fontWeight: FontWeight.bold,
            color: Colors.black.withOpacity(0.94),
            height: 1.14,
            fontFamily: DesignTokens.fontFamily,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 22),
        Text(
          "Ordering • Customization • Analytics • Modular Admin Tools\nFor Franchise, Restaurant, and Food-Service Brands",
          style: TextStyle(
            fontSize: isMobile ? 16 : 20,
            color: Colors.black.withOpacity(0.68),
            fontWeight: FontWeight.w400,
            fontFamily: DesignTokens.fontFamily,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 34),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          alignment: WrapAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                print('[landing_page.dart] Login button pressed');
                Navigator.of(context).pushNamed('/sign-in');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                elevation: 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 38, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text("Login"),
            ),
            OutlinedButton(
              onPressed: () {
                // TODO: Open contact form or demo request modal
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green[700],
                side: BorderSide(color: Colors.green[700]!, width: 2.2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 38, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text("Book a Demo"),
            ),
          ],
        ),
      ],
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  // Error logging for async widget build failures
  Future<void> _logErrorToBackend(String message,
      {String? stack, Map<String, dynamic>? contextData}) async {
    print('[landing_page.dart] _logErrorToBackend called: $message');
    final uri = Uri.parse(
        'https://us-central1-doughboyspizzeria-2b3d2.cloudfunctions.net/logPublicError');
    try {
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'stack': stack ?? '',
          'contextData': contextData ?? {},
        }),
      );
      print('[landing_page.dart] _logErrorToBackend: POST succeeded');
    } catch (e) {
      print(
          '[landing_page.dart] _logErrorToBackend: Failed to send log to backend: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ==== HERO SECTION ====
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 40 : 80,
                  horizontal: isMobile ? 16 : 0,
                ),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: Center(
                      child: GlassHero(
                        isMobile: isMobile,
                      ),
                    ),
                  ),
                ),
              ),

              // ==== ABOUT/BRAND VALUE SECTION ====
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 40, horizontal: 38),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline,
                                color: colorScheme.primary, size: 36),
                            const SizedBox(height: 10),
                            Text(
                              "Why Choose FranchiseHQ?",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "Empower your brand with a unified, modular cloud platform built for modern food-service franchises. Launch your own branded ordering apps, customize workflows, and manage locations, staff, analytics, and menus — all from one scalable, secure SaaS hub.",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ==== FEATURES SECTION ====
              Container(
                width: double.infinity,
                color: colorScheme.background,
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Key Platform Features",
                          style: TextStyle(
                            fontSize: 26,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 1 : 3,
                            mainAxisSpacing: 24,
                            crossAxisSpacing: 24,
                            childAspectRatio: 1.8,
                          ),
                          children: [
                            _featureCard(
                                Icons.phone_android,
                                "Mobile Ordering & Branded Apps",
                                "Launch iOS/Android/Tablet apps with your own logo & menu."),
                            _featureCard(
                                Icons.dashboard_customize,
                                "Modular Admin Tools",
                                "Custom workflows, dashboards, permissions & brand settings."),
                            _featureCard(
                                Icons.menu_book,
                                "Live Menu Management",
                                "Drag-n-drop builder, dayparting, images, and modifiers."),
                            _featureCard(
                                Icons.attach_money,
                                "Integrated Payments & Analytics",
                                "Full payment support, real-time sales, location/region analytics."),
                            _featureCard(Icons.lock, "Role-Based Secure Access",
                                "Owner, franchisee, and staff-level controls — multi-location ready."),
                            _featureCard(
                                Icons.support_agent,
                                "Integrated Support",
                                "Built-in chat, ticketing, knowledge base, and feedback."),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ==== SCREENSHOTS/GALLERY SECTION ====
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 38, horizontal: 10),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Product Showcase",
                          style: TextStyle(
                            fontSize: 25,
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 26),
                        GridView.count(
                          crossAxisCount: isMobile ? 1 : 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _galleryCard(
                                mobileAppScreenshot, "Mobile App Experience"),
                            _galleryCard(
                                adminDashboardScreenshot, "Admin Dashboard"),
                            _galleryCard(menuEditorScreenshot,
                                "Menu Editor & Customization"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ==== DEMO VIDEO SECTION ====
              if (demoVideoUrl.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 30, horizontal: 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_circle_fill_rounded,
                                  size: 54, color: colorScheme.primary),
                              const SizedBox(height: 18),
                              Text("See It In Action",
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary)),
                              const SizedBox(height: 10),
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.play_circle_outline,
                                      size: 68,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.open_in_new),
                                label: const Text("Watch Demo Video"),
                                onPressed: () {
                                  // TODO: open demo video url in new tab
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ==== FUTURE FEATURE / CTA ====
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      color: colorScheme.background,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 34, horizontal: 28),
                        child: Column(
                          children: [
                            Icon(Icons.new_releases_rounded,
                                color: colorScheme.secondary, size: 36),
                            const SizedBox(height: 10),
                            Text(
                              "White-Label, API-first. Launch Fast.",
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.secondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Talk to our team about custom integrations, multi-brand support, and migration assistance. Our modular platform grows with you.",
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ==== FOOTER ====
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 14),
                child: Text(
                  "© ${DateTime.now().year} FranchiseHQ | Modular SaaS for Restaurants & Franchises | info@yourplatform.com",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Custom UI Card Widgets ----

  static Widget _featureCard(IconData icon, String title, String desc) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 34, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                desc,
                style: TextStyle(
                    fontSize: 15, color: Colors.grey[700], height: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _galleryCard(String url, String label) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              url,
              height: 155,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 155,
                color: Colors.grey[200],
                child:
                    Icon(Icons.broken_image, size: 50, color: Colors.grey[400]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
