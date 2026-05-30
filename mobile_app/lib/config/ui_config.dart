import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:intl/intl.dart';

/// UI-specific branding for mobile app
/// Bridges shared shared.DesignTokens.+ shared.BrandingConfig.into Flutter types
class UiConfig {
  // Assets from BrandingConfig
  static const String logoMain = shared.BrandingConfig.logoMain;
  static const String defaultPizzaIcon = shared.BrandingConfig.defaultPizzaIcon;
  static const String adminEmptyStateImage =
      shared.BrandingConfig.adminEmptyStateImage;
  static const String menuItemPlaceholderImage =
      shared.BrandingConfig.menuItemPlaceholderImage;
  static const String ingredientPlaceholder =
      shared.BrandingConfig.ingredientPlaceholder;
  static const String defaultProfileIcon =
      shared.BrandingConfig.defaultProfileIcon;

  // Colors from DesignTokens
  static Color get accentColor =>
      _hexToColor(shared.DesignTokens.accentColorHex);
  static Color get brandRed => _hexToColor(shared.BrandingConfig.brandRedHex);
  static Color get backgroundColorDark =>
      _hexToColor(shared.DesignTokens.backgroundColorDarkHex);
  static Color get textColorDark =>
      _hexToColor(shared.DesignTokens.textColorDarkHex);
  static Color get successTextColor =>
      _hexToColor(shared.DesignTokens.successTextColorHex);
  static Color get disabledTextColor =>
      _hexToColor(shared.DesignTokens.disabledTextColorHex);
  static Color get errorBgColor =>
      _hexToColor(shared.DesignTokens.errorBgColorHex);
  static Color get surfaceColorDark =>
      _hexToColor(shared.DesignTokens.surfaceColorDarkHex);
  static Color get facebookColor =>
      _hexToColor(shared.DesignTokens.facebookColorHex);
  static Color get adminPrimaryColor =>
      _hexToColor(shared.DesignTokens.adminPrimaryColorHex);
  static Color get primaryColor =>
      _hexToColor(shared.DesignTokens.primaryColorHex);
  static Color get secondaryColor =>
      _hexToColor(shared.DesignTokens.secondaryColorHex);
  static Color get textColor => _hexToColor(shared.DesignTokens.textColorHex);
  static Color get foregroundColor =>
      _hexToColor(shared.DesignTokens.foregroundColorHex);
  static Color get foregroundColorDark =>
      _hexToColor(shared.DesignTokens.foregroundColorDarkHex); // ← Added
  static Color get hintTextColor =>
      _hexToColor(shared.DesignTokens.hintTextColorHex);
  static Color get surfaceColor =>
      _hexToColor(shared.DesignTokens.surfaceColorHex);
  static Color get successColor =>
      _hexToColor(shared.DesignTokens.successColorHex);
  static Color get errorColor => _hexToColor(shared.DesignTokens.errorColorHex);
  static Color get shimmerBaseColor =>
      _hexToColor(shared.DesignTokens.shimmerBaseColorHex);
  static Color get shimmerHighlightColor =>
      _hexToColor(shared.DesignTokens.shimmerHighlightColorHex);

  // Icons
  static IconData get emailIcon => Icons.email;
  static IconData get lockIcon => Icons.lock;
  static IconData get visibilityIcon => Icons.visibility;
  static IconData get visibilityOffIcon => Icons.visibility_off;

  // Dynamic
  static Color brandColorFor(String brandId) {
    final hex = shared.BrandingConfig.brandColorHexFor(brandId);
    return _hexToColor(hex);
  }

  static const Color dashboardCardColor = Colors.white;

  static Color get warningColor =>
      _hexToColor(shared.DesignTokens.warningColorHex);

  // Additional missing colors used across screens
  static Color get backgroundColor =>
      _hexToColor(shared.DesignTokens.backgroundColorHex);
  static Color get secondaryTextColor =>
      _hexToColor(shared.DesignTokens.secondaryTextColorHex);
  static Color get errorTextColor =>
      _hexToColor(shared.DesignTokens.errorTextColorHex);

  // Icon & Style helpers
  static IconData get favoriteIcon => Icons.favorite;
  static IconData get favoriteBorderIcon => Icons.favorite_border;
  static IconData get cartIcon => Icons.shopping_cart;

  // Banner & Card helpers
  static Color get bannerOverlayColor =>
      _hexToColor(shared.DesignTokens.bannerOverlayColorHex)
          .withAlpha(shared.DesignTokens.bannerOverlayAlpha);
  static Color get cardBorderColor =>
      _hexToColor(shared.DesignTokens.cardBorderColorHex);

  static EdgeInsets get defaultPadding =>
      EdgeInsets.all(shared.DesignTokens.defaultPadding);
  static EdgeInsets get screenPadding => const EdgeInsets.all(24.0);

  static FontWeight get bold => FontWeight.bold;
  static FontWeight get normal => FontWeight.normal;
  static FontWeight get medium => FontWeight.w500;

  // Spacing & Shape
  static EdgeInsets get defaultScreenPadding => const EdgeInsets.all(24.0);
  static EdgeInsets get cardPadding =>
      EdgeInsets.all(shared.DesignTokens.cardPadding);

  // Font Weights (fix String → FontWeight? errors)
  static FontWeight get fontWeightBold => FontWeight.bold;
  static FontWeight get fontWeightMedium => FontWeight.w500;
  static FontWeight get fontWeightNormal => FontWeight.normal;

  static const String logoSmall = shared.BrandingConfig.logoSmall;
  static const String logoLarge = shared.BrandingConfig.logoLarge;

  // Pre-built TextStyles (used across stabilized screens)
  static TextStyle get titleStyle => TextStyle(
        fontSize: shared.DesignTokens.titleFontSize,
        color: foregroundColorDark,
        fontWeight: fontWeightBold,
        fontFamily: shared.DesignTokens.fontFamily,
      );

  static TextStyle get bodyStyle => TextStyle(
        fontSize: shared.DesignTokens.bodyFontSize,
        color: textColorDark,
        fontFamily: shared.DesignTokens.fontFamily,
        fontWeight: fontWeightNormal,
      );

  static TextStyle get bodyBoldStyle => TextStyle(
        fontSize: shared.DesignTokens.bodyFontSize,
        color: textColorDark,
        fontWeight: fontWeightBold,
        fontFamily: shared.DesignTokens.fontFamily,
      );

  static TextStyle get captionStyle => TextStyle(
        fontSize: shared.DesignTokens.captionFontSize,
        color: secondaryTextColor,
        fontFamily: shared.DesignTokens.fontFamily,
        fontWeight: fontWeightNormal,
      );

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = int.parse('FF$cleaned', radix: 16);
    return Color(value);
  }

  // === NEW METHOD: Currency Formatting (Standard across app) ===
  static String currencyFormat(BuildContext context, double amount) {
    // Uses locale-aware formatting. Default to USD for Doughboys Pizzeria.
    // Can be extended later with FranchiseProvider locale.
    return NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
      locale: 'en_US',
    ).format(amount);
  }
}
