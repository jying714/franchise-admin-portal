import 'package:flutter/material.dart';

/// =======================
/// DesignTokens
/// =======================
/// - All visual/UX tokens: colors, spacing, typography, radii, elevations
/// - Used everywhere for theme, UI styling, layout
/// - No asset/image paths, brand/legal, or Firestore config
/// - Future tokens reserved for forward compatibility
/// =======================
class DesignTokens {
  // ----------- Core Theme Colors -----------
  static const Color primaryColor = Color(0xFFD23215); // Brand red
  static const Color secondaryColor = Color(0xFF506A48); // Olive green
  static const Color accentColor = Color(0xFF00A7A7); // Teal
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Colors.green;

  static const Color backgroundColor = Color(0xFFF9F9F9); // App bg
  static const Color surfaceColor = Colors.white;

  // ----------- Base Text Colors -----------
  static const Color textColor = Colors.black;
  static const Color secondaryTextColor = Colors.black54;
  static const Color errorTextColor = errorColor;
  static const Color successTextColor = successColor;
  static const Color disabledTextColor = Colors.grey;
  static const Color linkTextColor = Colors.blue;
  static const Color hintTextColor = Colors.black38;
  static const Color foregroundColor = Colors.white;

  // ----------- Dark Mode Variants -----------
  static const Color textColorDark = Color(0xFFE4E6EB);
  static const Color foregroundColorDark = Colors.white;
  static const Color surfaceColorDark = Color(0xFF242526);
  static const Color backgroundColorDark = Color(0xFF18191A);

  // ----------- Dark AppBar and Foreground for Hybrid Approach -----------
  static const Color appBarBackgroundColorDark =
      Color(0xFF18191A); // Match background or a dark surface
  static const Color appBarForegroundColorDark =
      Color(0xFFE4E6EB); // Light text for dark app bar

// ----------- Optional: Muted Brand Red for Action in Dark (if you want softer buttons) -----------
  static const Color primaryColorDark =
      Color(0xFF9A2412); // Optional: a darker or muted version of brand red

// ----------- Divider for dark mode -----------
  static const Color dividerColorDark =
      Colors.white12; // Or your preferred divider color

// ----------- Update to hintTextColor -----------
  static const Color hintTextColorDark =
      Color(0xFFB0B3B8); // For input hints in dark mode

  // ----------- Social Icon Colors -----------
  static const Color googleColor = Color(0xFF4285F4);
  static const Color facebookColor = Color(0xFF1877F3);
  static const Color appleColor = Colors.black;
  static const Color phoneColor = Colors.green;

  // ----------- Overlay Colors & Opacity -----------
  static const Color bannerOverlayColor = Colors.black;
  static const int bannerOverlayAlpha = 128;
  static const Color gridCardOverlayColor = Colors.black;
  static const int gridCardOverlayAlpha = 80;

  // ----------- Shimmer & Loading -----------
  static const Color shimmerBaseColor = Color(0xFFE0E0E0);
  static const Color shimmerHighlightColor = Color(0xFFF5F5F5);

  // ----------- Radii / BorderRadius -----------
  static const double cardRadius = 8.0;
  static const double buttonRadius = 24.0;
  static const double dialogRadius = 16.0;
  static const double chipRadius = 32.0;
  static const double imageRadius = 12.0;
  static const double formFieldRadius = 12.0;
  static const double badgeRadius = 10.0;

  // ----------- Sizing / Borders -----------
  static const double iconSize = 24.0;
  static const double cardBorderWidth = 2.0;
  static const double categoryCardBorderWidth = 2.0;

  // ----------- Spacing, Elevation, Aspect Ratio -----------
  static const double gridSpacing = 8.0;
  static const double cardElevation = 4.0;
  static const double buttonElevation = 2.0;
  static const double badgeMinSize = 16.0;
  static const double cartBadgePadding = 2.0;
  static const double gridCardAspectRatio = 1.0;

  // ----------- Padding Defaults -----------
  static const EdgeInsets gridPadding = EdgeInsets.all(8.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(12.0);
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0);

  // ----------- Banner/Carousel Tokens -----------
  static const double bannerHeight = 200.0;
  static const double bannerBorderRadius = 12.0;
  static const Duration bannerAutoPlayInterval = Duration(seconds: 5);

  // ----------- Menu Item Images -----------
  static const double menuItemImageWidth = 100.0;
  static const double menuItemImageHeight = 100.0;

  // ----------- Logo Sizing -----------
  static const double logoHeightSmall = 40.0;
  static const double logoHeightMedium = 70.0;
  static const double logoHeightLarge = 80.0;

  // ----------- Typography Tokens -----------
  static const String fontFamily = 'Montserrat';
  static const double captionFontSize = 12.0;
  static const double bodyFontSize = 16.0;
  static const double titleFontSize = 20.0;
  static const FontWeight titleFontWeight = FontWeight.bold;
  static const FontWeight bodyFontWeight = FontWeight.normal;

  // ----------- Animation & Timing -----------
  static const Duration toastDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);

  // ----------- Icons -----------
  static const double iconSizeLarge = 40.0;
  static const double iconSizeXLarge = 80.0;

  static const IconData favoriteIcon = Icons.favorite;
  static const IconData favoriteBorderIcon = Icons.favorite_border;
  static const IconData cartIcon = Icons.shopping_cart;
  static const IconData errorIcon = Icons.wifi_off;
  static const IconData refreshIcon = Icons.refresh;
  static const IconData addIcon = Icons.add;
  static const IconData removeIcon = Icons.remove;
  static const IconData appleIcon = Icons.apple;
  static const IconData visibilityIcon = Icons.visibility;
  static const IconData visibilityOffIcon = Icons.visibility_off;
  static const IconData emailIcon = Icons.email;
  static const IconData lockIcon = Icons.lock;

  // ----------- Miscellaneous -----------
  static const Color warningColor = Colors.orange; // For password strength

  // ======================
  // === ADMIN-SPECIFIC ===
  // ======================
  // These tokens are appended for Admin/Editor UI consistency
  static const Color adminPrimaryColor = primaryColor;
  static const Color adminSecondaryColor = secondaryColor;
  static const Color adminBackground = backgroundColor;
  static const Color adminSurface = surfaceColor;
  static const double adminTitleFontSize = 20.0;
  static const double adminBodyFontSize = 16.0;
  static const double adminCaptionFontSize = 14.0;
  static const double adminButtonFontSize = 16.0;
  static const double adminTableFontSize = 15.0;
  static const double adminGridPadding = 16.0;
  static const double adminCardSpacing = 8.0;
  static const double adminCardRadius = 10.0;
  static const double adminButtonRadius = 8.0;
  static const double adminCardElevation = 2.0;
  static const double adminButtonElevation = 1.0;

  static const Color adminAccentColor =
      Color(0xFFD23215); // For critical admin actions
  static const double adminDialogRadius = 12.0;
  static const double adminDialogElevation = 4.0;
  static const double adminSpacing = 16.0;

  static const Color cardBorderColor =
      Color(0xFFE0E0E0); // or any color you prefer

  static const Color errorBgColor =
      Color(0xFFFFE5E5); // Light red background for errors

  static const Color appBarBackgroundColor = Color(0xFFD23215); // Example red
  static const Color appBarForegroundColor = Color(0xFFFFFFFF); // Example white
  static const Color appBarIconColor = Color(0xFFFFFFFF);
  static const double appBarElevation = 0;
  static const double appBarTitleFontSize = 20.0;
  static const FontWeight appBarTitleFontWeight = FontWeight.bold;
  static const String appBarFontFamily = 'YourFontFamily';
  static const double appBarLogoHeight = 40.0;

  // ----------- Feature dialogue tokens -----------
  static const double dialogBorderRadius = 16.0;
  static const double inputBorderRadius = 12.0;
  static const double buttonBorderRadius = 12.0;

  // ----------- Error Log/Chip Severity Tokens -----------
  static const Color errorChipColor = Color(0xFFFDEAEA);
  static const Color errorChipTextColor = Color(0xFFD23215);

  static const Color warningChipColor = Color(0xFFFFF8E1);
  static const Color warningChipTextColor = Color(0xFFF9A825);

  static const Color infoChipColor = Color(0xFFE3F2FD);
  static const Color infoChipTextColor = Color(0xFF1976D2);

  static const Color neutralChipColor = Color(0xFFF4F4F4);
  static const Color neutralChipTextColor = Color(0xFF606060);

  // Border radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 16.0;

  static const double radius2xl = 32.0;
  static const double paddingLg = 24.0;

  // KPI widget
  // Example for soft shadow (update to match your style)
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x11000000), // Subtle shadow
      blurRadius: 16,
      spreadRadius: 2,
      offset: Offset(0, 4),
    ),
  ];

  // ======================
  // === FUTURE TOKENS ====
  // ======================
  // Keep all future tokens here, *do not remove*.
}
