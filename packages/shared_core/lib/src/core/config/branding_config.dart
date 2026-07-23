/// Pure Dart branding configuration — Single source of truth across mobile, web, admin, and functions.
/// Asset paths kept generic; apps can override locally if needed.
/// This is the shared_core branding model (single source of truth).
/// Values are currently static defaults.
/// Franchise-scoped / dynamic loading is the responsibility of Phase 1 Workstream B.
/// Do not add new fields in this file until scoping work is complete.
class BrandingConfig {
  // --------- Franchise Details (Shared) ---------
  static const String franchiseName = "Doughboys Pizzeria";
  static const String franchiseAddress = "123 Main St, City, State";
  static const String franchisePhone = "(555) 123-4567";
  static const String poweredBy = "Powered by Dough Boys Tech";

  // --------- Brand Identity (Hex Strings) ---------
  static const String brandRedHex = "#D23215";
  static const String accentColorHex = "#D23215";

  // --------- Assets (Generic paths - used by mobile & web) ---------
  static const String logoMain = 'assets/images/logo.png';
  static const String logoSmall = 'assets/images/logo_small.png';
  static const String logoLarge = 'assets/images/logo_large.png';
  static const String logoLargeLegacy = 'assets/images/logo_large.png';
  static const String defaultPizzaIcon = 'assets/icons/pizza.png';
  static const String defaultPizzaIconLegacy =
      'assets/images/default_pizza_icon.png';
  static const String defaultCategoryIcon =
      'assets/images/default_category_icon.png';
  static const String bannerPlaceholder =
      'assets/images/banner_placeholder.png';
  static const String fallbackAppIcon = 'assets/images/pizza_icon.png';
  static const String adminEmptyStateImage = 'assets/images/admin_empty.png';
  static const String menuItemPlaceholderImage =
      'assets/images/menu_item_placeholder.png';
  static const String ingredientPlaceholder =
      'assets/images/ingredient_placeholder.png';
  static const String bulkUploadCSVIcon = 'assets/icons/csv_upload.png';
  static const String exportCSVIcon = 'assets/icons/export_csv.png';
  static const String defaultProfileIcon = 'assets/images/default_profile.png';
  static const String appBarLogoAsset = 'assets/images/logo.png';

  // --------- App Bar & UI Behavior ---------
  static const bool showLogoInAppBar =
      false; // web default; mobile can override

  // --------- URLs ---------
  static const String termsOfServiceUrl = 'https://franchisehq.io/terms';
  static const String privacyPolicyUrl = 'https://franchisehq.io/privacy';

  // --------- Dynamic Logic ---------
  static String brandColorHexFor(String brandId) {
    // Future white-label / per-franchise logic
    return brandRedHex;
  }

  static String get defaultFranchiseLogo => logoMain;
  static String get appIcon => logoSmall;
}
