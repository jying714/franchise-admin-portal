import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// UI-specific branding configuration for the web app (P2.5)
/// Dynamic values now come from shared.FranchiseProvider via DesignTokens (SSoT).
class BrandingConfig {
  // Static asset paths (app-specific, not in shared_core)
  static const String logoMain = 'assets/images/logo.png';
  static const String logoSmall = 'assets/images/logo_small.png';
  static const String logoLarge = 'assets/logo/logo_large.png';
  static const String logoLargeLegacy = 'assets/images/logo_large.png';
  static const String defaultPizzaIcon = 'assets/icons/pizza.png';
  static const String defaultPizzaIconLegacy = 'assets/images/default_pizza_icon.png';
  static const String defaultCategoryIcon = 'assets/images/default_category_icon.png';
  static const String bannerPlaceholder = 'assets/images/banner_placeholder.png';
  static const String fallbackAppIcon = 'assets/images/pizza_icon.png';
  static const String adminEmptyStateImage = 'assets/images/admin_empty.png';
  static const String menuItemPlaceholderImage = 'assets/images/menu_item_placeholder.png';
  static const String ingredientPlaceholder = 'assets/images/ingredient_placeholder.png';
  static const String bulkUploadCSVIcon = 'assets/icons/csv_upload.png';
  static const String exportCSVIcon = 'assets/icons/export_csv.png';
  static const String defaultProfileIcon = 'assets/images/default_profile.png';
  static const String appBarLogoAsset = 'assets/images/logo.png';
  static const bool showLogoInAppBar = false;

  // === DYNAMIC (P2.5) ===
  static Color get brandRed => DesignTokens.primaryColor;
  static Color get accentColor => DesignTokens.secondaryColor;
  static const Color dashboardCardColor = Colors.white;

  static Color brandColorFor(String brandId) {
    // In real usage this would look up per-franchise; for now delegate to dynamic primary
    return DesignTokens.primaryColor;
  }

  // Live from shared.FranchiseProvider (via DesignTokens bridge) - P2.5 dynamic
  static String? get currentLogoUrl => DesignTokens.currentLogoUrl;
  static String get currentAppName => DesignTokens.currentAppName;

  // Back-compat getters used by many screens (delegate to dynamic when available)
  static String? get logoUrl => DesignTokens.currentLogoUrl;
  static String get logoMain => 'assets/images/logo.png'; // keep asset default, dynamic via currentLogoUrl in widgets

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}

