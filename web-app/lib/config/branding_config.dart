// web-app/lib/config/branding_config.dart
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared_core;
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// Web-specific branding delegation layer (P2.5)
/// All core values now come from shared_core.BrandingConfig
class BrandingConfig {
  // Web-specific overrides / additional assets if any
  static const String logoMain = 'assets/images/logo.png';
  static const String logoSmall = 'assets/images/logo_small.png';

  // Delegate everything else to shared_core
  static shared_core.BrandingConfig get shared => shared_core.BrandingConfig();

  static String get franchiseName => shared_core.BrandingConfig.franchiseName;
  static String get franchiseAddress =>
      shared_core.BrandingConfig.franchiseAddress;
  static String get franchisePhone => shared_core.BrandingConfig.franchisePhone;
  static String get poweredBy => shared_core.BrandingConfig.poweredBy;

  static String get brandRedHex => shared_core.BrandingConfig.brandRedHex;
  static String get accentColorHex => shared_core.BrandingConfig.accentColorHex;

  static String get logoLarge => shared_core.BrandingConfig.logoLarge;
  static String get defaultPizzaIcon =>
      shared_core.BrandingConfig.defaultPizzaIcon;
  static String get defaultCategoryIcon => shared_core
      .BrandingConfig.defaultCategoryIcon; // Added for category_card.dart
  static String get adminEmptyStateImage =>
      shared_core.BrandingConfig.adminEmptyStateImage;
  static String get menuItemPlaceholderImage =>
      shared_core.BrandingConfig.menuItemPlaceholderImage;
  static String get ingredientPlaceholder =>
      shared_core.BrandingConfig.ingredientPlaceholder;
  static String get defaultProfileIcon =>
      shared_core.BrandingConfig.defaultProfileIcon;
  static String get bannerPlaceholder =>
      shared_core.BrandingConfig.bannerPlaceholder;
  static String get fallbackAppIcon =>
      shared_core.BrandingConfig.fallbackAppIcon;
  static String get appBarLogoAsset =>
      shared_core.BrandingConfig.appBarLogoAsset;

  static bool get showLogoInAppBar =>
      shared_core.BrandingConfig.showLogoInAppBar;

  // Dynamic (franchise-aware)
  static Color get brandRed => DesignTokens.primaryColor;
  static Color get accentColor => DesignTokens.secondaryColor;
  static const Color dashboardCardColor = Colors.white;

  static Color brandColorFor(String brandId) => DesignTokens.primaryColor;

  static String? get currentLogoUrl => shared_core.UiConfig.currentLogoUrl;
  static String get currentAppName =>
      shared_core.UiConfig.dynamicAppName ?? 'Doughboys Pizzeria';

  static String? get logoUrl => currentLogoUrl;
}
