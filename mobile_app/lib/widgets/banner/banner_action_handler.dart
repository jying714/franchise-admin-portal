import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/features/category/category_screen.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';

class BannerActionHandler {
  /// Handles what happens when a banner or its CTA is tapped.
  static Future<void> handle(
    BuildContext context,
    shared.Banner banner, {
    shared.AnalyticsService? analyticsService,
    AppLocalizations? loc,
    List<shared.Category>? categories,
  }) async {
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);

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
                style: TextStyle(color: shared.UiConfig.textColor),
              ),
              backgroundColor: shared.UiConfig.errorColor,
            ),
          );
        }
        break;

      case 'promo':
        final code = banner.action.value?.trim() ?? '';
        if (code.isNotEmpty) {
          franchiseProvider.setPendingPromoCode(code);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${loc.applyPromo}: ${code.toUpperCase()} — open checkout to use it',
                style: TextStyle(color: shared.UiConfig.textColor),
              ),
              backgroundColor: shared.UiConfig.warningColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                loc.invalidPromo,
                style: TextStyle(color: shared.UiConfig.textColor),
              ),
              backgroundColor: shared.UiConfig.errorColor,
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
              style: TextStyle(color: shared.UiConfig.textColor),
            ),
            backgroundColor: shared.UiConfig.surfaceColorDark,
          ),
        );
        break;

      default:
        // For any other action or 'none', do nothing.
        break;
    }
  }
}
