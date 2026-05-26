import 'package:flutter/material.dart';

class DesignTokens {
  // Colors
  static const Color primaryColor = Colors.deepOrange;
  static const Color secondaryColor = Color(0xFFFFC107);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color textColor = Colors.black87;
  static const Color secondaryTextColor = Colors.grey;
  static const Color foregroundColor = Colors.white;
  static const Color foregroundColorDark = Colors.black87;
  static const Color errorColor = Colors.red;
  static const Color errorTextColor = Colors.red;
  static const Color hintTextColor = Colors.grey;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;

  // Typography
  static const String fontFamily = 'Roboto';
  static const double titleFontSize = 20.0;
  static const double bodyFontSize = 14.0;
  static const double captionFontSize = 12.0;
  static const FontWeight titleFontWeight = FontWeight.bold;
  static const FontWeight bodyFontWeight = FontWeight.normal;

  // Spacing & Layout
  static const double gridSpacing = 16.0;
  static const EdgeInsets gridPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(12.0);
  static const double cardRadius = 8.0;
  static const double cardElevation = 2.0;

  // Components
  static const double iconSize = 24.0;
  static const double logoHeightMedium = 60.0;
  static const double logoHeightLarge = 120.0;
  static const double logoHeightSmall = 40.0;
  static const double formFieldRadius = 8.0;
  static const double buttonRadius = 8.0;
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const double buttonElevation = 2.0;

  // Images
  static const double menuItemImageWidth = 120.0;
  static const double menuItemImageHeight = 120.0;

  // Durations
  static const Duration toastDuration = Duration(seconds: 2);

  // Additional commonly used in your code
  static const Color shimmerBaseColor = Color(0xFFE0E0E0);
  static const Color shimmerHighlightColor = Color(0xFFF5F5F5);
}
