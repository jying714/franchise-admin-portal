import 'package:flutter/material.dart';
import '../config/branding_config.dart';

class SafeLogoImage extends StatelessWidget {
  final double? height;
  final BoxFit fit;
  const SafeLogoImage({this.height, this.fit = BoxFit.contain, super.key});

  @override
  Widget build(BuildContext context) {
    final logoUrl = BrandingConfig.logoUrl;
    if (logoUrl == null || logoUrl.isEmpty) {
      return Image.asset(BrandingConfig.logoMain, height: height, fit: fit);
    }

    return Image.network(
      logoUrl,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          Image.asset(BrandingConfig.logoMain, height: height, fit: fit),
    );
  }
}
