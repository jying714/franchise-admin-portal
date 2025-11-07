import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' show BrandingConfig;

/// UI-specific branding for mobile app
/// Uses shared_core for data, adds Flutter-specific assets and colors
class UiConfig {
  // --------- Asset Paths (Mobile-Specific) ---------
  static const String logoMain = 'assets/images/logo.png';
  static const String logoSmall = 'assets/images/logo_small.png';
  static const String logoLarge = 'assets/logo/logo_large.png';
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

  // --------- App Bar ---------
  static const String appBarLogoAsset = 'assets/images/logo.png';
  static const bool showLogoInAppBar = false;

  // --------- Colors (Converted from shared_core hex) ---------
  static Color get brandRed => _hexToColor(BrandingConfig.brandRedHex);
  static Color get accentColor => _hexToColor(BrandingConfig.accentColorHex);

  static Color brandColorFor(String brandId) {
    final hex = BrandingConfig.brandColorHexFor(brandId);
    return _hexToColor(hex);
  }

  // --------- Dashboard (if used in mobile) ---------
  static const Color dashboardCardColor = Colors.white;

  // --------- Helper ---------
  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = int.parse('FF$cleaned', radix: 16);
    return Color(value);
  }
}
