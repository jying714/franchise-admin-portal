import 'package:flutter/material.dart';
import 'package:franchise_mobile_app/core/models/banner.dart' as model;
import 'package:franchise_mobile_app/core/models/category.dart';
import 'package:franchise_mobile_app/features/category/category_screen.dart';
import 'package:franchise_mobile_app/core/services/analytics_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// You may inject analytics or other services here as needed.

class BannerActionHandler {
  /// Handles what happens when a banner or its CTA is tapped.
  static Future<void> handle(
    BuildContext context,
    model.Banner banner, {
    AnalyticsService? analyticsService,
    AppLocalizations? loc,
    List<Category>? categories,
  }) async {
    // Fallback for localization and analytics.
    loc ??= AppLocalizations.of(context)!;

    if (analyticsService != null) {
      analyticsService.logBannerTap(banner.id);
    }

    switch (banner.action.type) {
      case 'linkCategory':
        if (banner.action.value != null && categories != null) {
          final matchedCat = categories.firstWhere(
            (cat) => cat.id == banner.action.value,
            orElse: () => Category(
              id: banner.action.value!,
              name: banner.action.value!,
              description: '',
              image: '',
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryScreen(
                categoryId: matchedCat.id,
                categoryName: matchedCat.name,
              ),
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


