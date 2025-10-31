import 'package:flutter/material.dart';
import '../config/branding_config.dart';

class SafeLogoImage extends StatelessWidget {
  final double? height;
  final BoxFit fit;
  const SafeLogoImage({this.height, this.fit = BoxFit.contain, super.key});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      BrandingConfig.logoUrl,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          Image.asset(BrandingConfig.logoMain, height: height, fit: fit),
    );
  }
}


