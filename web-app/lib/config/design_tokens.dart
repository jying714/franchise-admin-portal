import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' show DesignTokens;

/// Flutter-specific design tokens for web app
/// Wraps shared_core numeric values and adds Colors, EdgeInsets, etc.
class DesignTokens {
  // ----------- Core Theme Colors -----------
  static Color get primaryColor => _hexToColor('#D23215');
  static Color get secondaryColor => _hexToColor('#506A48');
  static Color get accentColor => _hexToColor('#00A7A7');
  static Color get errorColor => _hexToColor('#E53935');
  static Color get dangerColor => errorColor;
  static Color get successColor => Colors.green;
  static Color get highlightColor => primaryColor;
  static Color get backgroundColor => _hexToColor('#F9F9F9');
  static Color get surfaceColor => Colors.white;

  // ----------- Text Colors -----------
  static const Color textColor = Colors.black;
  static const Color secondaryTextColor = Colors.black54;
  static const Color errorTextColor = errorColor;
  static const Color successTextColor = successColor;
  static const Color disabledTextColor = Colors.grey;
  static const Color linkTextColor = Colors.blue;
  static const Color hintTextColor = Colors.black38;
  static const Color foregroundColor = Colors.white;

  // ----------- Dark Mode -----------
  static const Color textColorDark = Color(0xFFE4E6EB);
  static const Color foregroundColorDark = Colors.white;
  static const Color surfaceColorDark = Color(0xFF242526);
  static const Color backgroundColorDark = Color(0xFF18191A);
  static const Color appBarBackgroundColorDark = Color(0xFF18191A);
  static const Color appBarForegroundColorDark = Color(0xFFE4E6EB);
  static const Color primaryColorDark = Color(0xFF9A2412);
  static const Color dividerColorDark = Colors.white12;
  static const Color hintTextColorDark = Color(0xFFB0B3B8);

  // ----------- Social -----------
  static const Color googleColor = Color(0xFF4285F4);
  static const Color facebookColor = Color(0xFF1877F3);
  static const Color appleColor = Colors.black;
  static const Color phoneColor = Colors.green;

  // ----------- Overlay -----------
  static const Color bannerOverlayColor = Colors.black;
  static const Color gridCardOverlayColor = Colors.black;

  // ----------- Shimmer -----------
  static const Color shimmerBaseColor = Color(0xFFE0E0E0);
  static const Color shimmerHighlightColor = Color(0xFFF5F5F5);

  // ----------- Radii (from shared) -----------
  static double get cardRadius => DesignTokens.cardRadius;
  static double get buttonRadius => DesignTokens.buttonRadius;
  // ... repeat for all radii

  // ----------- Sizing (from shared) -----------
  static double get iconSize => DesignTokens.iconSize;
  // ... repeat

  // ----------- Padding -----------
  static EdgeInsets get gridPadding => EdgeInsets.all(DesignTokens.gridSpacing);
  static EdgeInsets get cardPadding => EdgeInsets.all(12.0);
  static EdgeInsets get buttonPadding =>
      EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0);

  // ----------- Duration -----------
  static Duration get toastDuration =>
      Duration(seconds: DesignTokens.toastDurationSeconds);
  static Duration get animationDuration =>
      Duration(milliseconds: DesignTokens.animationDurationMs);
  static Duration get bannerAutoPlayInterval =>
      Duration(seconds: DesignTokens.bannerAutoPlayIntervalSeconds);

  // ----------- Icons -----------
  static IconData get favoriteIcon => Icons.favorite;
  static IconData get favoriteBorderIcon => Icons.favorite_border;
  // ... map string → IconData

  // ----------- BoxShadow -----------
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x11000000),
      blurRadius: 16,
      spreadRadius: 2,
      offset: Offset(0, 4),
    ),
  ];

  // ----------- Admin UI -----------
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

  // ----------- Chip Colors -----------
  static const Color errorChipColor = Color(0xFFFDEAEA);
  static const Color errorChipTextColor = Color(0xFFD23215);
  static const Color warningChipColor = Color(0xFFFFF8E1);
  static const Color warningChipTextColor = Color(0xFFF9A825);
  static const Color infoChipColor = Color(0xFFE3F2FD);
  static const Color infoChipTextColor = Color(0xFF1976D2);
  static const Color neutralChipColor = Color(0xFFF4F4F4);
  static const Color neutralChipTextColor = Color(0xFF606060);

  // ----------- Helper -----------
  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
