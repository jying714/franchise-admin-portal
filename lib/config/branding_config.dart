import 'package:flutter/material.dart';

class BrandingConfig {
  // --------- Franchise Details ---------
  static const String franchiseName = "Doughboys Pizzeria";
  static const String franchiseAddress = "123 Main St, City, State";
  static const String franchisePhone = "(555) 123-4567";
  static const String poweredBy = "Powered by Dough Boys Tech";

  // --------- Logos ---------
  static const String logoMain = 'assets/images/logo.png';
  static const String logoSmall = 'assets/images/logo_small.png';
  static const String logoLarge = 'assets/logo/logo_large.png';
  static const String logoLargeLegacy = 'assets/images/logo_large.png';

  // --------- Icons & Images ---------
  static const String defaultPizzaIcon = 'assets/icons/pizza.png';
  static const String defaultPizzaIconLegacy =
      'assets/images/default_pizza_icon.png';
  static const String defaultCategoryIcon =
      'assets/images/default_category_icon.png';
  static const String bannerPlaceholder =
      'assets/images/banner_placeholder.png';
  static const String fallbackAppIcon = 'assets/images/pizza_icon.png';

  // --------- Admin/Editor Assets ---------
  static const String adminEmptyStateImage = 'assets/images/admin_empty.png';
  static const String menuItemPlaceholderImage =
      'assets/images/menu_item_placeholder.png';
  static const Color brandRed = Color(0xFFD23215); // Dough Boys Pizzeria Red

  // --------- Bulk Upload, Export, Misc ---------
  static const String bulkUploadCSVIcon = 'assets/icons/csv_upload.png';
  static const String exportCSVIcon = 'assets/icons/export_csv.png';

  // --------- Legal/Docs ---------
  static const String termsOfServiceUrl = 'https://doughboys.com/terms';
  static const String privacyPolicyUrl = 'https://doughboys.com/privacy';

  // app bar

  static const String appBarLogoAsset =
      'assets/images/logo.png'; // Path to logo
  static const bool showLogoInAppBar = false; // Default to false
  static const String appBarTitle = 'Menu Categories';

  // Profile Page
  static const String defaultProfileIcon = 'assets/images/default_profile.png';

  // kpi
  static Color brandColorFor(String brandId) {
    // Extend this logic if brand-specific colors are used
    return brandRed; // fallback to default brand color
  }

  // Recommended dashboard card background (adjust to your design, e.g. neutral surface or white)
  static const Color dashboardCardColor = Colors.white;

// Accent color (typically your brand color or another action/CTA color)
  static const Color accentColor = brandRed;
  // landing page
  static const String heroScreenshot =
      'https://yourcdn.com/assets/landing_hero.png';
  static const String adminDashboardScreenshot =
      'https://yourcdn.com/assets/admin_dashboard.png';
  static const String mobileAppScreenshot =
      'https://yourcdn.com/assets/mobile_app.png';
  static const String menuEditorScreenshot =
      'https://yourcdn.com/assets/menu_editor.png';
  static const String demoVideoUrl =
      'https://www.youtube.com/watch?v=yourdemo'; // or leave blank if not available
  static const String logoUrl = 'https://yourcdn.com/assets/logo.png';
  static const String primaryContact =
      'support@doughboyspizzeria.com'; // or your real contact email

  // ======================
  // === FUTURE TOKENS ====
  // ======================
  // static const String instagramHandle = "@doughboys";
  // static const String franchiseEmail = "contact@doughboys.com";
  // static const String franchiseSlogan = "Slice of Heaven Since 1999";
}
