import 'package:flutter/material.dart';
import 'package:admin_portal/config/branding_config.dart';
import 'package:admin_portal/config/design_tokens.dart';

/// A reusable menu item image widget with fallback to the default pizza icon.
/// Accepts network or asset image URLs, with sizing consistent across the app.
class MenuItemImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;

  const MenuItemImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final double w = width ?? DesignTokens.menuItemImageWidth;
    final double h = height ?? DesignTokens.menuItemImageHeight;
    final BoxFit boxFit = fit ?? BoxFit.cover;

    final image = (imageUrl != null && imageUrl!.isNotEmpty)
        ? Image.network(
            imageUrl!,
            width: w,
            height: h,
            fit: boxFit,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              BrandingConfig.defaultPizzaIcon,
              width: w,
              height: h,
              fit: boxFit,
            ),
          )
        : Image.asset(
            BrandingConfig.defaultPizzaIcon,
            width: w,
            height: h,
            fit: boxFit,
          );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }
    return image;
  }
}
