/// Pure Dart branding configuration — shared across mobile, web, and functions
class BrandingConfig {
  // --------- Franchise Details (Shared) ---------
  static const String franchiseName = "Doughboys Pizzeria";
  static const String franchiseAddress = "123 Main St, City, State";
  static const String franchisePhone = "(555) 123-4567";
  static const String poweredBy = "Powered by Dough Boys Tech";

  // --------- Brand Identity (Hex Strings) ---------
  static const String brandRedHex = "#D23215";
  static const String accentColorHex = "#D23215";

  // --------- Assets (Paths - used by mobile & web) ---------
  static const String logoMain = 'assets/images/logo.png';
  static const String logoSmall = 'assets/images/logo_small.png';
  static const String logoLarge = 'assets/images/logo_large.png';
  static const String defaultPizzaIcon = 'assets/icons/pizza.png';
  static const String defaultCategoryIcon =
      'assets/images/default_category_icon.png';
  static const String adminEmptyStateImage = 'assets/images/admin_empty.png';
  static const String menuItemPlaceholderImage =
      'assets/images/menu_item_placeholder.png';
  static const String ingredientPlaceholder =
      'assets/images/ingredient_placeholder.png';
  static const String defaultProfileIcon = 'assets/images/default_profile.png';
  static const String bannerPlaceholder =
      'assets/images/banner_placeholder.png';

  // --------- URLs ---------
  static const String termsOfServiceUrl = 'https://franchisehq.io/terms';
  static const String privacyPolicyUrl = 'https://franchisehq.io/privacy';

  // --------- App Bar ---------
  static const bool showLogoInAppBar = true;
  static const String appBarLogoAsset = 'assets/images/logo_small.png';

  // --------- Dynamic Logic ---------
  static String brandColorHexFor(String brandId) {
    // Future white-label logic
    return brandRedHex;
  }

  // ======================
  // === FUTURE TOKENS ====
  // ======================
}
