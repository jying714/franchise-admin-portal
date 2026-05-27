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

  // ----------- Font Weights -----------
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

  // ----------- Spacing & Padding -----------
  static const double gridSpacing = 8.0;
  static const double adminGridPadding = 16.0;
  static const double adminCardSpacing = 8.0;
  static const double adminSpacing = 16.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;
  static const double cardPadding = 16.0;
  static const double buttonPadding = 16.0;
  static const double gridPadding = 16.0;

  // ----------- Borders -----------
  static const double cardBorderWidth = 2.0;
  static const double categoryCardBorderWidth = 2.0;

  // ----------- Elevation -----------
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
  static const double animationDuration = 300.0;

  // ----------- Overlay Opacity -----------
  static const int bannerOverlayAlpha = 128;
  static const int gridCardOverlayAlpha = 80;
  static const double bannerOverlayAlphaDouble = 0.5;

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

  // ----------- Colors (Hex strings for shared use) -----------
  static const String accentColorHex = '#E31837';
  static const String backgroundColorDarkHex = '#121212';
  static const String textColorDarkHex = '#FFFFFF';
  static const String successTextColorHex = '#4CAF50';
  static const String disabledTextColorHex = '#9E9E9E';
  static const String errorBgColorHex = '#FFEBEE';
  static const String surfaceColorDarkHex = '#1E1E1E';
  static const String facebookColorHex = '#1877F2';
  static const String adminPrimaryColorHex = '#E31837';
  static const String primaryColorHex = '#E31837';
  static const String secondaryColorHex = '#FFD700';
  static const String textColorHex = '#FFFFFF';
  static const String foregroundColorHex = '#FFFFFF';
  static const String hintTextColorHex = '#9E9E9E';
  static const String surfaceColorHex = '#1E1E1E';
  static const String successColorHex = '#4CAF50';
  static const String errorColorHex = '#F44336';
  static const String shimmerBaseColorHex = '#E0E0E0';
  static const String shimmerHighlightColorHex = '#F5F5F5';

  // ----------- Direct Getters for All Screens -----------
  static String get accentColor => accentColorHex;
  static String get backgroundColorDark => backgroundColorDarkHex;
  static String get textColorDark => textColorDarkHex;
  static String get successTextColor => successTextColorHex;
  static String get disabledTextColor => disabledTextColorHex;
  static String get errorBgColor => errorBgColorHex;
  static String get surfaceColorDark => surfaceColorDarkHex;
  static String get facebookColor => facebookColorHex;
  static String get adminPrimaryColor => adminPrimaryColorHex;
  static String get primaryColor => primaryColorHex;
  static String get secondaryColor => secondaryColorHex;
  static String get textColor => textColorHex;
  static String get foregroundColor => foregroundColorHex;
  static String get hintTextColor => hintTextColorHex;
  static String get surfaceColor => surfaceColorHex;
  static String get successColor => successColorHex;
  static String get errorColor => errorColorHex;
  static String get shimmerBaseColor => shimmerBaseColorHex;
  static String get shimmerHighlightColor => shimmerHighlightColorHex;

  // ----------- Missing Getters from Full Analyze (All Screens) -----------
  static const String backgroundColorHex = '#121212';
  static const String foregroundColorDarkHex = '#FFFFFF';
  static const String secondaryTextColorHex = '#9E9E9E';
  static const String errorTextColorHex = '#F44336';
  static const String warningColorHex = '#FF9800';

  static String get backgroundColor => backgroundColorHex;
  static String get foregroundColorDark => foregroundColorDarkHex;
  static String get secondaryTextColor => secondaryTextColorHex;
  static String get errorTextColor => errorTextColorHex;
  static String get warningColor => warningColorHex;
  static int get toastDuration => 2; // int for most usage

  // ======================
  // === FUTURE TOKENS ====
  // ======================
}
