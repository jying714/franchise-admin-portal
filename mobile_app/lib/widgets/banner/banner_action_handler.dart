import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/features/category/category_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/config/ui_config.dart';

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
      analyticsService.logEvent('banner_tap', {'banner_id': banner.id});
    }

    switch (banner.action.type) {
      case 'linkCategory':
        if (banner.action.value != null && categories != null) {
          final matchedCat = categories.firstWhere(
            (cat) => cat.id == banner.action.value,
            orElse: () => shared.Category(
              id: banner.action.value!,
              name: banner.action.value!,
              image: null,
              description: '',
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
                style: TextStyle(color: UiConfig.textColor),
              ),
              backgroundColor: UiConfig.errorColor,
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
                style: TextStyle(color: UiConfig.textColor),
              ),
              backgroundColor: UiConfig.warningColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                loc.invalidPromo,
                style: TextStyle(color: UiConfig.textColor),
              ),
              backgroundColor: UiConfig.errorColor,
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
              style: TextStyle(color: UiConfig.textColor),
            ),
            backgroundColor: UiConfig.surfaceColorDark,
          ),
        );
        break;

      default:
        // For any other action or 'none', do nothing.
        break;
    }
  }
}
