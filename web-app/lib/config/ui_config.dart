// web_app/lib/core/config/ui_config.dart
import 'package:flutter/material.dart';
import 'package:shared_core/src/core/config/app_config.dart';
import 'package:intl/intl.dart';

class UiConfig {
  // App-specific singleton instance bridging to shared_core
  static final AppConfig env = AppConfig(
    apiBaseUrl: 'https://api.yourdomain.com',
    brandingColorHex: '#C62828',
    isProduction: true,
  );

  // App-specific assets should live in the app, not shared_core
  static const String adminEmptyStateImage = 'assets/images/admin_empty.png';

  static Color statusColor(String status, ThemeData theme) {
    switch (status) {
      case 'active':
        return theme.colorScheme.primaryContainer;
      case 'paused':
        return theme.colorScheme.secondaryContainer;
      case 'trialing':
        return theme.colorScheme.tertiaryContainer;
      case 'canceled':
        return theme.colorScheme.errorContainer;
      default:
        return theme.colorScheme.outlineVariant;
    }
  }

  // Helper to convert hex to Color if/when you want to use brandingColorHex
  static Color brandingColor() {
    final hex = env.brandingColorHex.replaceAll('#', '');
    final value = int.parse('FF$hex', radix: 16);
    return Color(value);
  }

  static String formatDueDate(DateTime? date) =>
      date != null ? DateFormat.yMMMd().format(date) : '';

  static String formatTotal(double amount, String currency) =>
      NumberFormat.simpleCurrency(name: currency).format(amount);
}
