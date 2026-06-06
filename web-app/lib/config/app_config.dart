// web-app/lib/config/app_config.dart
// P2.5 Config Integration Sprint - Delegation Layer
// Single source of truth for the web-app: all code should import from here.
// Delegates to shared_core public barrel. Dynamic values driven by shared.FranchiseProvider.
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// AppConfig delegation layer for the admin portal.
/// - All collection names, constants, and helpers come from shared_core (SSoT).
/// - The `current` getter can incorporate shared.FranchiseProvider-driven values (branding, etc.).
/// - Legacy `env` preserved for minimal breakage during transition.
class AppConfig {
  // ===== DELEGATED STATIC CONSTANTS (from shared_core) =====
  static const String usersCollection = shared.AppConfig.usersCollection;
  static const String menuItemsCollection =
      shared.AppConfig.menuItemsCollection;
  static const String ordersCollection = shared.AppConfig.ordersCollection;
  static const String categoriesCollection =
      shared.AppConfig.categoriesCollection;
  static const String cartCollection = shared.AppConfig.cartCollection;
  static const String bannersCollection = shared.AppConfig.bannersCollection;
  static const String feedbackCollection = shared.AppConfig.feedbackCollection;
  static const String inventoryCollection =
      shared.AppConfig.inventoryCollection;
  static const String supportChatsCollection =
      shared.AppConfig.supportChatsCollection;
  static const String promotionsCollection =
      shared.AppConfig.promotionsCollection;
  static const String configCollection = shared.AppConfig.configCollection;
  static const String auditLogCollection = shared.AppConfig.auditLogCollection;

  static const String addressesSubcollection =
      shared.AppConfig.addressesSubcollection;
  static const String favoriteOrdersSubcollection =
      shared.AppConfig.favoriteOrdersSubcollection;

  static const int maxFavoriteMenuItemsLookup =
      shared.AppConfig.maxFavoriteMenuItemsLookup;

  static const Duration toastDuration = shared.AppConfig.toastDuration;

  static const String scheduledOrdersCollection =
      shared.AppConfig.scheduledOrdersCollection;

  static const String poweredBy = shared.AppConfig.poweredBy;

  static const int menuItemMaxImageSizeMB =
      shared.AppConfig.menuItemMaxImageSizeMB;
  static const int menuItemImageDim = shared.AppConfig.menuItemImageDim;
  static const int bulkUploadMaxRows = shared.AppConfig.bulkUploadMaxRows;
  static const List<String> allowedImageFormats =
      shared.AppConfig.allowedImageFormats;
  static const bool enableAuditLogs = shared.AppConfig.enableAuditLogs;
  static const bool enableCSVExport = shared.AppConfig.enableCSVExport;

  static const List<String> dietaryTags = shared.AppConfig.dietaryTags;
  static const List<String> allergenTags = shared.AppConfig.allergenTags;

  static const String promoExportDir = shared.AppConfig.promoExportDir;
  static const String analyticsExportDir = shared.AppConfig.analyticsExportDir;
  static const String dateFormat = shared.AppConfig.dateFormat;

  // ===== DYNAMIC / INSTANCE (driven by shared.FranchiseProvider where possible) =====
  /// Returns an AppConfig instance that can reflect current franchise branding.
  static shared.AppConfig get current {
    final fp =
        DesignTokens.franchiseProvider; // Correct access via DesignTokens
    return shared.AppConfig(
      apiBaseUrl: 'https://api.yourdomain.com',
      brandingColorHex: fp?.currentPrimaryColorHex ?? '#E31837',
      isProduction: true,
    );
  }

  /// Legacy env for minimal breakage (still creates a default instance).
  /// Prefer AppConfig.current or direct shared access for new code.
  static final shared.AppConfig env = shared.AppConfig(
    apiBaseUrl: 'https://api.yourdomain.com',
    brandingColorHex: '#C62828',
    isProduction: true,
  );

  // ===== DELEGATED STATIC HELPERS =====
  static String featureDisplayName(String featureKey) =>
      shared.AppConfig.featureDisplayName(featureKey);

  static String formatDate(DateTime? date) => shared.AppConfig.formatDate(date);

  /// Returns appropriate Chip background color for subscription/status
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
