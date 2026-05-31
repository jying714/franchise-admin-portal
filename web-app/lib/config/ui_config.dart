// web_app/lib/core/config/ui_config.dart
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:intl/intl.dart';

class UiConfig {
  // Legacy env (minimal breakage)
  static final shared.AppConfig env = shared.AppConfig(
    apiBaseUrl: 'https://api.yourdomain.com',
    brandingColorHex: '#C62828',
    isProduction: true,
  );

  static const String adminEmptyStateImage = 'assets/images/admin_empty.png';

  // === P2.5 DYNAMIC (UiConfig is dominant) ===
  static Color get primaryColor => DesignTokens.primaryColor;
  static Color get secondaryColor => DesignTokens.secondaryColor;
  static String get currentAppName => DesignTokens._fp?.currentAppName ?? 'Franchise Admin';
  static String? get currentLogoUrl => DesignTokens._fp?.currentLogoUrl;

  static Color statusColor(String status, ThemeData theme) {
    switch (status) {
      case 'active': return theme.colorScheme.primaryContainer;
      case 'paused': return theme.colorScheme.secondaryContainer;
      case 'trialing': return theme.colorScheme.tertiaryContainer;
      case 'canceled': return theme.colorScheme.errorContainer;
      default: return theme.colorScheme.outlineVariant;
    }
  }

  static Color brandingColor() => DesignTokens.primaryColor;

  static String formatDueDate(DateTime? date) =>
      date != null ? DateFormat.yMMMd().format(date) : '';
  static String formatTotal(double amount, String currency) =>
      NumberFormat.simpleCurrency(name: currency).format(amount);

  // Recommended text styles + padding (UiConfig dominant)
  static TextStyle get titleStyle => TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.adminTitleFontSize,
        fontWeight: FontWeight.bold,
      );
  static TextStyle get bodyStyle => TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.adminBodyFontSize,
      );
  static TextStyle get bodyBoldStyle => bodyStyle.copyWith(fontWeight: FontWeight.w600);

  static EdgeInsets get defaultPadding => DesignTokens.adminCardPadding;
}
