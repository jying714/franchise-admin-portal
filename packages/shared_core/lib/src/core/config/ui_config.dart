// packages/shared_core/lib/src/core/config/ui_config.dart
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:intl/intl.dart';

/// UI-specific configuration bridge for both web and mobile.
class UiConfig {
  static shared.FranchiseProvider? _fp;

  static void setFranchiseProvider(shared.FranchiseProvider provider) {
    _fp = provider;
  }

  static shared.FranchiseProvider? get franchiseProvider => _fp;

  static String get dynamicAppName => _fp?.currentAppName ?? 'Franchise App';

  // Assets
  static String get logoMain => shared.BrandingConfig.logoMain;
  static String get logoSmall => shared.BrandingConfig.logoSmall;
  static String get logoLarge => shared.BrandingConfig.logoLarge;
  static String get defaultPizzaIcon => shared.BrandingConfig.defaultPizzaIcon;
  static String get adminEmptyStateImage =>
      shared.BrandingConfig.adminEmptyStateImage;
  static String get menuItemPlaceholderImage =>
      shared.BrandingConfig.menuItemPlaceholderImage;
  static String get ingredientPlaceholder =>
      shared.BrandingConfig.ingredientPlaceholder;
  static String get defaultProfileIcon =>
      shared.BrandingConfig.defaultProfileIcon;

  // Colors (franchise-aware)
  static Color get primaryColor {
    final hex =
        _fp?.currentPrimaryColorHex ?? shared.DesignTokens.primaryColorHex;
    return _hexToColor(hex);
  }

  static Color get secondaryColor {
    final hex =
        _fp?.currentSecondaryColorHex ?? shared.DesignTokens.secondaryColorHex;
    return _hexToColor(hex);
  }

  static Color get adminPrimaryColor => primaryColor; // alias for consistency

  static Color get bannerOverlayColor =>
      _hexToColor(shared.DesignTokens.bannerOverlayColorHex)
          .withAlpha(shared.DesignTokens.bannerOverlayAlpha);

  static Color get dividerColor =>
      _hexToColor(shared.DesignTokens.cardBorderColorHex);
  static Color get cardColor => surfaceColor;
  static Color get shimmerHighlightColor =>
      _hexToColor(shared.DesignTokens.shimmerHighlightColorHex);
  static Color get cardBorderColor =>
      _hexToColor(shared.DesignTokens.cardBorderColorHex);
  static Color get disabledTextColor =>
      _hexToColor(shared.DesignTokens.disabledTextColorHex);

  static Color get hintTextColor =>
      _hexToColor(shared.DesignTokens.hintTextColorHex);

  static Color get facebookColor =>
      _hexToColor(shared.DesignTokens.facebookColorHex);

  static Color get surfaceColorDark =>
      _hexToColor(shared.DesignTokens.surfaceColorDarkHex);

  static EdgeInsets get defaultPadding =>
      EdgeInsets.all(shared.DesignTokens.defaultPadding);
  static Color get successColor =>
      _hexToColor(shared.DesignTokens.successColorHex);
  static Color get backgroundColor =>
      _hexToColor(shared.DesignTokens.backgroundColorHex);
  static Color get accentColor =>
      _hexToColor(shared.DesignTokens.accentColorHex);
  static Color get textColor => _hexToColor(shared.DesignTokens.textColorHex);
  static Color get textColorDark =>
      _hexToColor(shared.DesignTokens.textColorDarkHex);
  static Color get foregroundColorDark =>
      _hexToColor(shared.DesignTokens.foregroundColorDarkHex);
  static Color get secondaryTextColor =>
      _hexToColor(shared.DesignTokens.secondaryTextColorHex);
  static Color get errorColor => _hexToColor(shared.DesignTokens.errorColorHex);
  static Color get backgroundColorDark =>
      _hexToColor(shared.DesignTokens.backgroundColorDarkHex);
  static Color get warningColor =>
      _hexToColor(shared.DesignTokens.warningColorHex);
  static Color get surfaceColor =>
      _hexToColor(shared.DesignTokens.surfaceColorHex);
  static Color get onPrimaryColor => foregroundColorDark;

  static Color get errorTextColor =>
      _hexToColor(shared.DesignTokens.errorTextColorHex);

  static Color get foregroundColor =>
      _hexToColor(shared.DesignTokens.foregroundColorHex);

  static Color get shimmerBaseColor =>
      _hexToColor(shared.DesignTokens.shimmerBaseColorHex);

  static Color get shadowColor => Colors.black;

  static EdgeInsets get defaultScreenPadding => const EdgeInsets.all(24.0);

  static EdgeInsets get cardPadding =>
      EdgeInsets.all(shared.DesignTokens.cardPadding);

  // Icons
  static IconData get emailIcon => Icons.email;
  static IconData get lockIcon => Icons.lock;
  static IconData get visibilityIcon => Icons.visibility;
  static IconData get visibilityOffIcon => Icons.visibility_off;
  static IconData get favoriteIcon => Icons.favorite;
  static IconData get favoriteBorderIcon => Icons.favorite_border;
  static IconData get cartIcon => Icons.shopping_cart;

  // Font Weights
  static FontWeight get fontWeightBold => FontWeight.bold;
  static FontWeight get fontWeightMedium => FontWeight.w500;
  static FontWeight get fontWeightNormal => FontWeight.normal;

  // Font Weight aliases for backward compatibility
  static FontWeight get bold => FontWeight.bold;
  static FontWeight get normal => FontWeight.normal;

  // TextStyles
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
      );

  static TextStyle get bodyBoldStyle =>
      bodyStyle.copyWith(fontWeight: fontWeightBold);

  static TextStyle get captionStyle => TextStyle(
        fontSize: shared.DesignTokens.captionFontSize,
        color: secondaryTextColor,
        fontFamily: shared.DesignTokens.fontFamily,
        fontWeight: fontWeightNormal,
      );

  // Currency
  static String currencyFormat(double amount) {
    return NumberFormat.currency(
            symbol: '\$', decimalDigits: 2, locale: 'en_US')
        .format(amount);
  }

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = int.parse('FF$cleaned', radix: 16);
    return Color(value);
  }

  /// Remote logo URL from current franchise branding
  static String? get currentLogoUrl {
    final direct = _fp?.currentLogoUrl;
    if (direct != null && direct.isNotEmpty) return direct;

    final nested = _fp?.currentBranding;
    if (nested is Map<String, dynamic>) {
      return (nested['logoUrl'] as String?) ?? (nested['logo'] as String?);
    }
    return null;
  }

  /// Returns appropriate Chip background color for subscription/status (moved from AppConfig)
  static Color statusColor(String status, ThemeData theme) {
    final lower = status.toLowerCase().trim();
    switch (lower) {
      case 'active':
      case 'trialing':
        return Colors.green.shade100;
      case 'paused':
        return Colors.orange.shade100;
      case 'canceled':
      case 'cancelled':
      case 'past_due':
      case 'overdue':
        return Colors.red.shade100;
      case 'unpaid':
        return Colors.amber.shade100;
      default:
        return theme.colorScheme.surfaceVariant.withOpacity(0.6);
    }
  }
}
