import 'package:flutter/material.dart';
import 'package:doughboys_pizzeria_final/config/branding_config.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';

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
    final Widget imageWidget;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        imageUrl!,
        width: width ?? DesignTokens.menuItemImageWidth,
        height: height ?? DesignTokens.menuItemImageHeight,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          BrandingConfig.defaultPizzaIcon,
          width: width ?? DesignTokens.menuItemImageWidth,
          height: height ?? DesignTokens.menuItemImageHeight,
          fit: fit,
        ),
      );
    } else {
      imageWidget = Image.asset(
        BrandingConfig.defaultPizzaIcon,
        width: width ?? DesignTokens.menuItemImageWidth,
        height: height ?? DesignTokens.menuItemImageHeight,
        fit: fit,
      );
    }

    // Only wrap in ClipRRect if borderRadius is provided.
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }
    return imageWidget;
  }
}
