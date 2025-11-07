/// Pure Dart design tokens — shared across mobile, web, and functions
/// Contains only numeric values, strings, durations, and enums
/// No Flutter dependencies
class DesignTokens {
  // ----------- Typography -----------
  static const String fontFamily = 'Montserrat';
  static const double captionFontSize = 12.0;
  static const double bodyFontSize = 16.0;
  static const double titleFontSize = 20.0;
  static const double adminTitleFontSize = 20.0;
  static const double adminBodyFontSize = 16.0;
  static const double adminCaptionFontSize = 14.0;
  static const double adminButtonFontSize = 16.0;
  static const double adminTableFontSize = 15.0;
  static const double appBarTitleFontSize = 20.0;

  // ----------- Font Weights (as strings for Firestore/theme mapping) -----------
  static const String titleFontWeight = 'bold';
  static const String bodyFontWeight = 'normal';
  static const String appBarTitleFontWeight = 'bold';

  // ----------- Radii -----------
  static const double cardRadius = 8.0;
  static const double buttonRadius = 24.0;
  static const double dialogRadius = 16.0;
  static const double chipRadius = 32.0;
  static const double imageRadius = 12.0;
  static const double formFieldRadius = 12.0;
  static const double badgeRadius = 10.0;
  static const double cardBorderRadiusLarge = 24.0;
  static const double cardBorderRadiusSmall = 10.0;
  static const double adminCardRadius = 10.0;
  static const double adminButtonRadius = 8.0;
  static const double adminDialogRadius = 12.0;
  static const double dialogBorderRadius = 16.0;
  static const double inputBorderRadius = 12.0;
  static const double buttonBorderRadius = 12.0;
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 16.0;
  static const double radius2xl = 32.0;

  // ----------- Sizing -----------
  static const double iconSize = 24.0;
  static const double iconSizeLarge = 40.0;
  static const double iconSizeXLarge = 80.0;
  static const double badgeMinSize = 16.0;
  static const double cartBadgePadding = 2.0;
  static const double gridCardAspectRatio = 1.0;
  static const double bannerHeight = 200.0;
  static const double bannerBorderRadius = 12.0;
  static const double menuItemImageWidth = 100.0;
  static const double menuItemImageHeight = 100.0;
  static const double logoHeightSmall = 40.0;
  static const double logoHeightMedium = 70.0;
  static const double logoHeightLarge = 80.0;
  static const double appBarLogoHeight = 40.0;

  // ----------- Spacing & Padding Values -----------
  static const double gridSpacing = 8.0;
  static const double adminGridPadding = 16.0;
  static const double adminCardSpacing = 8.0;
  static const double adminSpacing = 16.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;

  // ----------- Borders -----------
  static const double cardBorderWidth = 2.0;
  static const double categoryCardBorderWidth = 2.0;

  // ----------- Elevation (as double) -----------
  static const double cardElevation = 4.0;
  static const double buttonElevation = 2.0;
  static const double adminCardElevation = 2.0;
  static const double adminButtonElevation = 1.0;
  static const double adminDialogElevation = 4.0;
  static const double appBarElevation = 0.0;

  // ----------- Animation & Timing -----------
  static const int toastDurationSeconds = 2;
  static const int animationDurationMs = 300;
  static const int bannerAutoPlayIntervalSeconds = 5;

  // ----------- Overlay Opacity -----------
  static const int bannerOverlayAlpha = 128;
  static const int gridCardOverlayAlpha = 80;

  // ----------- Icon Names (as strings) -----------
  static const String favoriteIcon = 'favorite';
  static const String favoriteBorderIcon = 'favorite_border';
  static const String cartIcon = 'shopping_cart';
  static const String errorIcon = 'wifi_off';
  static const String refreshIcon = 'refresh';
  static const String addIcon = 'add';
  static const String removeIcon = 'remove';
  static const String appleIcon = 'apple';
  static const String visibilityIcon = 'visibility';
  static const String visibilityOffIcon = 'visibility_off';
  static const String emailIcon = 'email';
  static const String lockIcon = 'lock';

  // ----------- Admin-Specific (Shared) -----------
  static const String appBarFontFamily = 'YourFontFamily';

  // ======================
  // === FUTURE TOKENS ====
  // ======================
}
