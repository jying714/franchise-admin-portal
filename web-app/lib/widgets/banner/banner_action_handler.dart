// P1 Duplicated Widgets Batch 1 (May 30, 2026)
// Mobile canonical for customer flows (mobile_app/lib/widgets/banner/).
// Web banner/ kept only for admin previews. Update to barrel only (no src/).
// Safe for deletion in next batch if admin previews reuse via path dep on mobile_app or shared_ui pkg.
// No critical customer preview flows touched.

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// You may inject analytics or other services here as needed.

class BannerActionHandler {
  /// Handles what happens when a banner or its CTA is tapped.
  static Future<void> handle(
    BuildContext context,
    shared.Banner banner, {
    shared.AnalyticsService? analyticsService,
    AppLocalizations? loc,
    List<shared.Category>? categories,
  }) async {
    // Fallback for localization and analytics.
    loc ??= AppLocalizations.of(context)!;

    if (analyticsService != null) {
      void logBannerTap(String bannerId) {
        // Implement logging logic
      }
    }

    switch (banner.action.type) {
      case 'linkCategory':
        if (banner.action.value != null && categories != null) {
          final matchedCat = categories.firstWhere(
            (cat) => cat.id == banner.action.value,
            orElse: () => shared.Category(
              id: banner.action.value!,
              name: banner.action.value!,
              description: '',
              image: '',
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${loc.categorySelected}: ${matchedCat.name}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green[700],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                loc.noCategoriesAvailable,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;

      case 'promo':
        if (banner.action.value != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${loc.applyPromo}: ${banner.action.value}',
                style: const TextStyle(color: Colors.black),
              ),
              backgroundColor: Colors.yellow[200],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                loc.invalidPromo,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;

      case 'linkItem':
        // You can add item-specific navigation logic here if needed.
        // Example: push item details screen.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.notImplemented,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.grey[800],
          ),
        );
        break;

      default:
        // For any other action or 'none', do nothing.
        break;
    }
  }
}


