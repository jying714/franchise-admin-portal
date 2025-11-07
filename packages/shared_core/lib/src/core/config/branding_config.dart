/// Pure Dart branding configuration — shared across mobile, web, and functions
/// Contains only data that is not tied to Flutter UI or asset paths
class BrandingConfig {
  // --------- Franchise Details (Shared) ---------
  static const String franchiseName = "Doughboys Pizzeria";
  static const String franchiseAddress = "123 Main St, City, State";
  static const String franchisePhone = "(555) 123-4567";
  static const String poweredBy = "Powered by Dough Boys Tech";

  // --------- Brand Identity (Hex Strings) ---------
  static const String brandRedHex = "#D23215"; // Dough Boys Pizzeria Red
  static const String accentColorHex = "#D23215";

  // --------- URLs (External) ---------
  static const String termsOfServiceUrl = 'https://doughboys.com/terms';
  static const String privacyPolicyUrl = 'https://doughboys.com/privacy';

  // --------- App Bar Config (Shared Logic) ---------
  static const String appBarTitle = 'Menu Categories';

  // --------- Contact & Support ---------
  static const String primaryContact = 'support@doughboyspizzeria.com';

  // --------- KPI & Dashboard Logic ---------
  static String brandColorHexFor(String brandId) {
    // Future: map brandId → color
    return brandRedHex;
  }

  // --------- Landing Page (Shared Data) ---------
  static const String heroScreenshot =
      'https://via.placeholder.com/640x300.png?text=Landing+Hero';
  static const String adminDashboardScreenshot =
      'https://via.placeholder.com/480x240.png?text=Admin+Dashboard';
  static const String mobileAppScreenshot =
      'https://via.placeholder.com/240x480.png?text=Mobile+App';
  static const String menuEditorScreenshot =
      'https://via.placeholder.com/480x240.png?text=Menu+Editor';
  static const String demoVideoUrl = 'https://www.youtube.com/watch?v=yourdemo';
  static const String logoUrl =
      'https://via.placeholder.com/256x64.png?text=Logo';

  // ======================
  // === FUTURE TOKENS ====
  // ======================
  // static const String instagramHandle = "@doughboys";
  // static const String franchiseEmail = "contact@doughboys.com";
  // static const String franchiseSlogan = "Slice of Heaven Since 1999";
}
