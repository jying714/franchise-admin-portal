import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

/// UI-specific branding for mobile app
/// Bridges shared DesignTokens + BrandingConfig into Flutter types
class UiConfig {
  // Assets from BrandingConfig
  static const String logoMain = BrandingConfig.logoMain;
  static const String defaultPizzaIcon = BrandingConfig.defaultPizzaIcon;
  static const String adminEmptyStateImage =
      BrandingConfig.adminEmptyStateImage;
  static const String menuItemPlaceholderImage =
      BrandingConfig.menuItemPlaceholderImage;
  static const String ingredientPlaceholder =
      BrandingConfig.ingredientPlaceholder;
  static const String defaultProfileIcon = BrandingConfig.defaultProfileIcon;

  // Colors from DesignTokens
  static Color get accentColor => _hexToColor(DesignTokens.accentColorHex);
  static Color get brandRed => _hexToColor(BrandingConfig.brandRedHex);
  static Color get backgroundColorDark =>
      _hexToColor(DesignTokens.backgroundColorDarkHex);
  static Color get textColorDark => _hexToColor(DesignTokens.textColorDarkHex);
  static Color get successTextColor =>
      _hexToColor(DesignTokens.successTextColorHex);
  static Color get disabledTextColor =>
      _hexToColor(DesignTokens.disabledTextColorHex);
  static Color get errorBgColor => _hexToColor(DesignTokens.errorBgColorHex);
  static Color get surfaceColorDark =>
      _hexToColor(DesignTokens.surfaceColorDarkHex);
  static Color get facebookColor => _hexToColor(DesignTokens.facebookColorHex);
  static Color get adminPrimaryColor =>
      _hexToColor(DesignTokens.adminPrimaryColorHex);
  static Color get primaryColor => _hexToColor(DesignTokens.primaryColorHex);
  static Color get secondaryColor =>
      _hexToColor(DesignTokens.secondaryColorHex);
  static Color get textColor => _hexToColor(DesignTokens.textColorHex);
  static Color get foregroundColor =>
      _hexToColor(DesignTokens.foregroundColorHex);
  static Color get foregroundColorDark =>
      _hexToColor(DesignTokens.foregroundColorDarkHex); // ← Added
  static Color get hintTextColor => _hexToColor(DesignTokens.hintTextColorHex);
  static Color get surfaceColor => _hexToColor(DesignTokens.surfaceColorHex);
  static Color get successColor => _hexToColor(DesignTokens.successColorHex);
  static Color get errorColor => _hexToColor(DesignTokens.errorColorHex);
  static Color get shimmerBaseColor =>
      _hexToColor(DesignTokens.shimmerBaseColorHex);
  static Color get shimmerHighlightColor =>
      _hexToColor(DesignTokens.shimmerHighlightColorHex);

  // Icons
  static IconData get emailIcon => Icons.email;
  static IconData get lockIcon => Icons.lock;
  static IconData get visibilityIcon => Icons.visibility;
  static IconData get visibilityOffIcon => Icons.visibility_off;

  // Dynamic
  static Color brandColorFor(String brandId) {
    final hex = BrandingConfig.brandColorHexFor(brandId);
    return _hexToColor(hex);
  }

  static const Color dashboardCardColor = Colors.white;

  static Color get warningColor => _hexToColor(DesignTokens.warningColorHex);

  // Additional missing colors used across screens
  static Color get backgroundColor =>
      _hexToColor(DesignTokens.backgroundColorHex);
  static Color get secondaryTextColor =>
      _hexToColor(DesignTokens.secondaryTextColorHex);
  static Color get errorTextColor =>
      _hexToColor(DesignTokens.errorTextColorHex);

  // Icon & Style helpers
  static IconData get favoriteIcon => Icons.favorite;
  static IconData get favoriteBorderIcon => Icons.favorite_border;
  static IconData get cartIcon => Icons.shopping_cart;

  // Banner & Card helpers
  static Color get bannerOverlayColor =>
      _hexToColor(DesignTokens.bannerOverlayColorHex)
          .withAlpha(DesignTokens.bannerOverlayAlpha);
  static Color get cardBorderColor =>
      _hexToColor(DesignTokens.cardBorderColorHex);

  static EdgeInsets get defaultPadding =>
      EdgeInsets.all(DesignTokens.defaultPadding);
  static EdgeInsets get screenPadding => const EdgeInsets.all(24.0);

  static FontWeight get bold => FontWeight.bold;
  static FontWeight get normal => FontWeight.normal;
  static FontWeight get medium => FontWeight.w500;

  // Spacing & Shape
  static EdgeInsets get defaultScreenPadding => const EdgeInsets.all(24.0);
  static EdgeInsets get cardPadding => EdgeInsets.all(DesignTokens.cardPadding);

  // Font Weights (fix String → FontWeight? errors)
  static FontWeight get fontWeightBold => FontWeight.bold;
  static FontWeight get fontWeightMedium => FontWeight.w500;
  static FontWeight get fontWeightNormal => FontWeight.normal;

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = int.parse('FF$cleaned', radix: 16);
    return Color(value);
  }
}
