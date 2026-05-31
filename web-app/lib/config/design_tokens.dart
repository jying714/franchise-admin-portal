import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

/// Flutter-specific design tokens for web app (P2.5 Web-App Cleanup)
/// Single source of truth bridge:
/// - Delegates scalars/radii/elevation/fonts to shared_core.DesignTokens
/// - Dynamic colors (primary/secondary) pulled from FranchiseProvider.current* (white-label)
/// - Set via DesignTokens.setFranchiseProvider(...) once at bootstrap (main.dart)
class DesignTokens {
  static shared.FranchiseProvider? _fp;

  /// Public getter for other delegation layers (AppConfig, etc.).
  static shared.FranchiseProvider? get franchiseProvider => _fp;

  /// Call once early (e.g. main.dart after MultiProvider) so all static getters see live branding.
  static void setFranchiseProvider(shared.FranchiseProvider? provider) {
    _fp = provider;
  }

  // === DYNAMIC BRANDING (FranchiseProvider wins) ===
  static Color get primaryColor {
    final hex = _fp?.currentPrimaryColorHex ?? shared.DesignTokens.primaryColorHex;
    return _hexToColor(hex);
  }

  static Color get secondaryColor {
    final hex = _fp?.currentSecondaryColorHex ?? shared.DesignTokens.secondaryColorHex;
    return _hexToColor(hex);
  }

  static Color get accentColor => _hexToColor(shared.DesignTokens.accentColorHex);
  static Color get errorColor => _hexToColor('#E53935');
  static Color get dangerColor => errorColor;
  static Color get successColor => Colors.green;
  static Color get highlightColor => primaryColor;
  static Color get backgroundColor => _hexToColor('#F9F9F9');
  static Color get surfaceColor => Colors.white;

  // Text colors (can be extended with branding later)
  static const Color textColor = Colors.black;
  static const Color secondaryTextColor = Colors.black54;
  static const Color errorTextColor = Colors.red;
  static const Color successTextColor = Colors.green;
  static const Color disabledTextColor = Colors.grey;
  static const Color linkTextColor = Colors.blue;
  static const Color hintTextColor = Colors.black38;
  static const Color foregroundColor = Colors.white;

  // Dark mode fallbacks (static for now)
  static const Color textColorDark = Color(0xFFE4E6EB);
  static const Color foregroundColorDark = Colors.white;
  static const Color surfaceColorDark = Color(0xFF242526);
  static const Color backgroundColorDark = Color(0xFF18191A);
  static const Color appBarBackgroundColorDark = Color(0xFF18191A);
  static const Color appBarForegroundColorDark = Color(0xFFE4E6EB);
  static const Color primaryColorDark = Color(0xFF9A2412);
  static const Color dividerColorDark = Colors.white12;
  static const Color hintTextColorDark = Color(0xFFB0B3B8);

  // Social / overlay / shimmer (static)
  static const Color googleColor = Color(0xFF4285F4);
  static const Color facebookColor = Color(0xFF1877F3);
  static const Color appleColor = Colors.black;
  static const Color phoneColor = Colors.green;
  static const Color bannerOverlayColor = Colors.black;
  static const Color gridCardOverlayColor = Colors.black;
  static const Color shimmerBaseColor = Color(0xFFE0E0E0);
  static const Color shimmerHighlightColor = Color(0xFFF5F5F5);

  // === FULL DELEGATION TO SHARED (P2.5 SSoT) ===
  // Typography
  static String get fontFamily => shared.DesignTokens.fontFamily;
  static double get bodyFontSize => shared.DesignTokens.bodyFontSize;
  static double get titleFontSize => shared.DesignTokens.titleFontSize;
  static double get adminTitleFontSize => shared.DesignTokens.adminTitleFontSize;
  static double get adminBodyFontSize => shared.DesignTokens.adminBodyFontSize;
  static double get adminCaptionFontSize => shared.DesignTokens.adminCaptionFontSize;
  static double get adminButtonFontSize => shared.DesignTokens.adminButtonFontSize;
  static double get adminTableFontSize => shared.DesignTokens.adminTableFontSize;
  static double get appBarTitleFontSize => shared.DesignTokens.appBarTitleFontSize;

  static String get bodyFontWeight => shared.DesignTokens.bodyFontWeight;
  static String get titleFontWeight => shared.DesignTokens.titleFontWeight;
  static String get appBarTitleFontWeight => shared.DesignTokens.appBarTitleFontWeight;

  // Radii (all of them)
  static double get cardRadius => shared.DesignTokens.cardRadius;
  static double get buttonRadius => shared.DesignTokens.buttonRadius;
  static double get dialogRadius => shared.DesignTokens.dialogRadius;
  static double get chipRadius => shared.DesignTokens.chipRadius;
  static double get imageRadius => shared.DesignTokens.imageRadius;
  static double get formFieldRadius => shared.DesignTokens.formFieldRadius;
  static double get badgeRadius => shared.DesignTokens.badgeRadius;
  static double get cardBorderRadiusLarge => shared.DesignTokens.cardBorderRadiusLarge;
  static double get cardBorderRadiusSmall => shared.DesignTokens.cardBorderRadiusSmall;
  static double get adminCardRadius => shared.DesignTokens.adminCardRadius;
  static double get adminButtonRadius => shared.DesignTokens.adminButtonRadius;
  static double get adminDialogRadius => shared.DesignTokens.adminDialogRadius;
  static double get dialogBorderRadius => shared.DesignTokens.dialogBorderRadius;
  static double get inputBorderRadius => shared.DesignTokens.inputBorderRadius;
  static double get buttonBorderRadius => shared.DesignTokens.buttonBorderRadius;
  static double get radiusSm => shared.DesignTokens.radiusSm;
  static double get radiusMd => shared.DesignTokens.radiusMd;
  static double get radiusLg => shared.DesignTokens.radiusLg;
  static double get radius2xl => shared.DesignTokens.radius2xl;

  // Sizing
  static double get iconSize => shared.DesignTokens.iconSize;
  static double get iconSizeLarge => shared.DesignTokens.iconSizeLarge;
  static double get iconSizeXLarge => shared.DesignTokens.iconSizeXLarge;
  static double get badgeMinSize => shared.DesignTokens.badgeMinSize;
  static double get cartBadgePadding => shared.DesignTokens.cartBadgePadding;
  static double get gridCardAspectRatio => shared.DesignTokens.gridCardAspectRatio;
  static double get bannerHeight => shared.DesignTokens.bannerHeight;
  static double get bannerBorderRadius => shared.DesignTokens.bannerBorderRadius;
  static double get menuItemImageWidth => shared.DesignTokens.menuItemImageWidth;
  static double get menuItemImageHeight => shared.DesignTokens.menuItemImageHeight;
  static double get logoHeightSmall => shared.DesignTokens.logoHeightSmall;
  static double get logoHeightMedium => shared.DesignTokens.logoHeightMedium;
  static double get logoHeightLarge => shared.DesignTokens.logoHeightLarge;
  static double get appBarLogoHeight => shared.DesignTokens.appBarLogoHeight;

  // Spacing / Padding / Borders / Elevation
  static double get gridSpacing => shared.DesignTokens.gridSpacing;
  static double get adminGridPadding => shared.DesignTokens.adminGridPadding;
  static double get adminCardSpacing => shared.DesignTokens.adminCardSpacing;
  static double get adminSpacing => shared.DesignTokens.adminSpacing;
  static double get paddingMd => shared.DesignTokens.paddingMd;
  static double get paddingLg => shared.DesignTokens.paddingLg;
  static double get cardPaddingVal => shared.DesignTokens.cardPadding;
  static double get buttonPaddingVal => shared.DesignTokens.buttonPadding;
  static double get gridPaddingVal => shared.DesignTokens.gridPadding;
  static double get cardBorderWidth => shared.DesignTokens.cardBorderWidth;
  static double get categoryCardBorderWidth => shared.DesignTokens.categoryCardBorderWidth;

  static double get cardElevation => shared.DesignTokens.cardElevation;
  static double get buttonElevation => shared.DesignTokens.buttonElevation;
  static double get adminCardElevation => shared.DesignTokens.adminCardElevation;
  static double get adminButtonElevation => shared.DesignTokens.adminButtonElevation;
  static double get adminDialogElevation => shared.DesignTokens.adminDialogElevation;
  static double get appBarElevation => shared.DesignTokens.appBarElevation;

  // Durations
  static Duration get toastDuration => Duration(seconds: shared.DesignTokens.toastDurationSeconds);
  static Duration get animationDuration => Duration(milliseconds: shared.DesignTokens.animationDurationMs);
  static Duration get bannerAutoPlayInterval => Duration(seconds: shared.DesignTokens.bannerAutoPlayIntervalSeconds);

  // Admin UI (dynamic primary wins)
  static Color get adminPrimaryColor => primaryColor;
  static Color get adminSecondaryColor => secondaryColor;
  static Color get adminBackground => backgroundColor;
  static Color get adminSurface => surfaceColor;
  static Color get adminAccentColor => primaryColor;
  static Color get cardBorderColor => _hexToColor('#E0E0E0');
  static Color get errorBgColor => _hexToColor('#FFE5E5');
  static Color get appBarBackgroundColor => primaryColor;
  static Color get appBarForegroundColor => Colors.white;
  static Color get appBarIconColor => Colors.white;

  // Chip colors (static for now)
  static const Color errorChipColor = Color(0xFFFDEAEA);
  static const Color errorChipTextColor = Color(0xFFD23215);
  static const Color warningChipColor = Color(0xFFFFF8E1);
  static const Color warningChipTextColor = Color(0xFFF9A825);
  static const Color infoChipColor = Color(0xFFE3F2FD);
  static const Color infoChipTextColor = Color(0xFF1976D2);
  static const Color neutralChipColor = Color(0xFFF4F4F4);
  static const Color neutralChipTextColor = Color(0xFF606060);

  // BoxShadow
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x11000000), blurRadius: 16, spreadRadius: 2, offset: Offset(0, 4)),
  ];

  // Icons (string → IconData map for shared consistency)
  static IconData iconFromString(String name) {
    switch (name) {
      case 'favorite': return Icons.favorite;
      case 'favorite_border': return Icons.favorite_border;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'add': return Icons.add;
      case 'remove': return Icons.remove;
      case 'email': return Icons.email;
      case 'lock': return Icons.lock;
      default: return Icons.help_outline;
    }
  }

  static IconData get favoriteIcon => iconFromString(shared.DesignTokens.favoriteIcon);
  static IconData get favoriteBorderIcon => iconFromString(shared.DesignTokens.favoriteBorderIcon);

  // Padding helpers
  static EdgeInsets get gridPadding => EdgeInsets.all(shared.DesignTokens.gridSpacing);
  static EdgeInsets get cardPadding => EdgeInsets.all(shared.DesignTokens.cardPadding);
  static EdgeInsets get buttonPadding => EdgeInsets.symmetric(horizontal: 20, vertical: 12);
  static EdgeInsets get adminCardPadding => EdgeInsets.all(shared.DesignTokens.adminCardSpacing);

  // Helper
  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
